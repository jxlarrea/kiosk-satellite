import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app_container.dart';
import '../../core/events.dart';
import '../../l10n/messages.dart';
import '../../managers/alarms/alarm_manager.dart';
import '../../managers/browser/visibility_mask_script.dart';
import '../../managers/camera/models.dart';
import '../../managers/device/screen_capture.dart';
import '../../managers/navigation/compass_layout.dart';
import '../../managers/settings/definitions.dart' as defs;
import '../dashboard_view_picker.dart';
import '../kiosk_drawer.dart';
import 'compass_stage.dart';

/// Compass navigation at run time: which view of the layout is on screen,
/// bringing a view up and putting the others away, and the snapshots the
/// swipe draws (compass_stage.dart).
///
/// Every view is the one the app already has, opened and closed through
/// the same commands the drawer, the gestures and Home Assistant use: a
/// dashboard view is the one WebView moved to its path, the others are
/// the full-screen pages drawn over it. So the layout costs nothing until
/// a view is swiped to, and the WebView never has a twin.
class CompassController {
  CompassController(this.c);

  final AppContainer c;

  /// The slot on screen.
  final current = ValueNotifier<CompassSlot>(CompassSlot.center);

  /// Whether the Menu view is up. It is Compass's own page, drawn by the
  /// kiosk screen from this.
  final menuVisible = ValueNotifier<bool>(false);

  /// The exit gesture (and the PIN, when one is set) earned the full Menu
  /// on a locked kiosk. Dropped when the Menu goes away, as the drawer
  /// drops it when it closes.
  final menuUnlocked = ValueNotifier<bool>(false);

  /// What the swipe is drawing, null while nothing moves.
  final stage = ValueNotifier<CompassStageModel?>(null);

  /// The swipe's stage covers the whole screen and the dashboard is out of
  /// the frame (the kiosk screen takes its plane offstage on this).
  final planeCovered = ValueNotifier<bool>(false);

  /// Takes the dashboard out of the frame under the swipe, or brings it
  /// back. The page is told nothing: the same mask the screensaver's freeze
  /// uses keeps it seeing itself visible, so a swipe never reads as the
  /// tab going to the background.
  Future<void> coverPlane(bool covered) async {
    if (planeCovered.value == covered) return;
    if (covered) unawaited(c.browser.runJs(maskVisibilityJs(true)));
    planeCovered.value = covered;
    if (!covered) unawaited(c.browser.runJs(maskVisibilityJs(false)));
  }

  /// Whether [view] keeps the dashboard out of the frame on its own: the
  /// Menu, the Music Library, the calendar and a full-screen Now Playing
  /// freeze the page under them a second after they open
  /// (BrowserManager.setCovered), which takes the plane offstage. A swipe that lands on one leaves the
  /// plane out rather than bring it back for that second: each time the
  /// plane enters or leaves the frame Flutter switches surfaces, and the
  /// switch shows a black frame.
  bool keepsPlaneOut(CompassView view) => switch (view.kind) {
    'music_library' || 'calendar' || 'menu' => true,
    'now_playing' => c.screensaver.nowPlayingCovers.value,
    _ => false,
  };

  /// The plane in or out of the frame as the view on screen wants it,
  /// once no swipe is drawing. Completes when the change is made.
  Future<void> settlePlane() =>
      coverPlane(planeCovered.value && keepsPlaneOut(currentView));

  CompassLayout _layout = const CompassLayout();
  CompassLayout get layout => _layout;

  bool get enabled => c.settings.get(defs.navStyle) == 'compass';
  bool get zoom => c.settings.get(defs.navCompassAnimation) != 'slide';
  bool get showPosition => c.settings.get(defs.navCompassPosition);

  CompassView get currentView =>
      _layout.viewAt(current.value) ?? _layout.center;

  /// Set while this controller opens and closes views itself, so the
  /// visibility listeners below do not read its own moves as someone
  /// else's.
  bool _switching = false;

  final Map<String, ui.Image> _shots = {};
  final List<String> _shotOrder = [];

  /// Snapshots kept at most: the views around the one on screen and a few
  /// more. A full snapshot is a few MB on a tablet.
  static const _shotLimit = 6;

  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<ActivityDetected>? _activitySub;
  Timer? _returnTimer;
  late final List<Listenable> _watched = [
    c.musicLibrary.visible,
    c.calendar.visible,
    c.alarms.visible,
    // Now Playing on screen is a screensaver session with its view.
    c.screensaver.activeView,
    c.screensaver.nowPlayingCovers,
    c.camera.activeViewId,
    c.launcher.visible,
    c.intercom.rosterVisible,
  ];

  /// The stored layout as it runs. With the remote admin off and no Menu
  /// placed, a Menu is added, or there would be no way back into Settings
  /// (the drawer keeps its Settings row for the same reason).
  CompassLayout _readLayout() {
    final stored = CompassLayout.decode(c.settings.get(defs.navCompassLayout));
    return c.settings.get(defs.remoteEnabled) ? stored : stored.withMenu();
  }

  void start() {
    _layout = _readLayout();
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.navCompassLayout.key ||
          e.key == defs.remoteEnabled.key) {
        final before = currentView;
        _layout = _readLayout();
        // A layout without the view on screen anymore lands on the center.
        if (_layout.viewAt(current.value) == null) {
          current.value = CompassSlot.center;
        }
        _dropStaleShots();
        // A new view in hand, such as another center or the center's
        // dashboard view picked again, shows right away.
        final now = currentView;
        if (now.key != before.key ||
            now.path != before.path ||
            now.id != before.id) {
          unawaited(_bringUp());
        }
      } else if (e.key == defs.haHoldMode.key ||
          e.key == defs.navCompassReturnMinutes.key) {
        _armReturn();
      } else if (e.key == defs.navStyle.key && !enabled) {
        menuVisible.value = false;
        menuUnlocked.value = false;
        current.value = CompassSlot.center;
        _clearShots();
      } else if (e.key == defs.navStyle.key) {
        unawaited(_bringUp(gentle: true));
      }
    });
    // The kiosk starts on the dashboard. A center that is not one opens
    // once the screen is up.
    _startTimer = Timer(
      const Duration(seconds: 1),
      () => unawaited(_bringUp(gentle: true)),
    );
    _activitySub = c.bus
        .on<ActivityDetected>()
        .where((e) => e.source == 'touch')
        .listen((_) => _armReturn());
    for (final l in _watched) {
      l.addListener(_onOverlayChanged);
    }
    menuVisible.addListener(() {
      if (!menuVisible.value) menuUnlocked.value = false;
      // Opaque and full screen, like the Music Library: the page under it
      // stops drawing, and with the dashboard out of the frame Flutter
      // draws the menu on its own surface. Left in, hybrid composition
      // drew the menu through overlay layers that cut the tops off its
      // small labels.
      c.browser.setCovered('compass menu', covered: menuVisible.value);
    });
  }

  Timer? _startTimer;

  /// True while a swipe moves: the plugin overlays drawn on top step aside,
  /// since the snapshots under them already show them.
  final overlaysHidden = ValueNotifier<bool>(false);

  /// Shows the view in hand. [gentle] is for the start and for switching
  /// to Compass: it leaves the screen alone while something else is up,
  /// such as Now Playing launched by a track or the screensaver, and the
  /// center opens once that closes.
  Future<void> _bringUp({bool gentle = false}) async {
    if (!enabled || stage.value != null || _switching) return;
    final view = currentView;
    if (gentle &&
        (view.isDashboard ||
            _isUp(view) ||
            _anythingUp ||
            c.screensaver.isActive)) {
      return;
    }
    await show(current.value);
  }

  void dispose() {
    _startTimer?.cancel();
    _verifyTimer?.cancel();
    _settingsSub?.cancel();
    _activitySub?.cancel();
    _returnTimer?.cancel();
    _settleTimer?.cancel();
    for (final l in _watched) {
      l.removeListener(_onOverlayChanged);
    }
    _clearShots();
    current.dispose();
    planeCovered.dispose();
    overlaysHidden.dispose();
    menuVisible.dispose();
    menuUnlocked.dispose();
    stage.dispose();
  }

  // ── What can show ───────────────────────────────────────────────────

  /// Whether [view] has anything to show right now. A swipe skips a view
  /// that does not, as it skips an empty place: Now Playing with nothing
  /// loaded, the intercom while it cannot call.
  bool available(CompassView view) =>
      _allowedLocked(view) && _hasSomething(view);

  /// What a locked kiosk lets a visitor reach, the same rules the drawer's
  /// quick menu follows: each view needs its Allowed Action, and the Menu
  /// shows only with Allow menu with quick actions on and something in it
  /// to offer. Otherwise only the exit gesture (and its PIN) opens the
  /// Menu, as it opens the full drawer. The dashboard is the kiosk itself
  /// and always shows; so does the center, which a swipe never skips.
  bool _allowedLocked(CompassView view) {
    if (!c.kiosk.locked) return true;
    bool allowed(defs.SettingDef<bool> action) => c.settings.get(action);
    return switch (view.kind) {
      'menu' =>
        menuUnlocked.value ||
            (allowed(defs.kioskAllowDrawer) &&
                KioskDrawer.visibleItems(c, restricted: true).isNotEmpty),
      'app_launcher' => allowed(defs.kioskAllowApps),
      'camera' => allowed(defs.kioskAllowCamera),
      'intercom' => allowed(defs.kioskAllowIntercom),
      'alarms' => allowed(defs.kioskAllowAlarms),
      'calendar' => allowed(defs.kioskAllowCalendar),
      'music_library' => allowed(defs.kioskAllowMusicLibrary),
      'now_playing' => allowed(defs.kioskAllowSendspinPlayer),
      _ => true,
    };
  }

  bool _hasSomething(CompassView view) => switch (view.kind) {
    'menu' => true,
    'now_playing' =>
      compassKindConfigurable(c, view.kind) &&
          c.sendspin.nowPlaying.value != null &&
          !c.screensaver.nowPlayingBlocked,
    'camera' => compassCameraViews(c).any((v) => v.id == view.id),
    'app_launcher' =>
      compassKindConfigurable(c, view.kind) &&
          (c.kiosk.locked ? c.launcher.kioskApps : c.launcher.apps).isNotEmpty,
    'intercom' => c.intercom.enabled && c.intercom.available,
    _ => compassKindConfigurable(c, view.kind),
  };

  /// Whether a swipe may start now: Compass is on and the view on screen
  /// is the one the layout says, with nothing else drawn over it. A camera
  /// view opened by the doorbell, a ringing alarm, a call, a link page or
  /// the screensaver all keep the swipe out until they are gone.
  bool get swipeReady {
    if (!enabled || stage.value != null) return false;
    if (c.voice.covers.value) return false;
    // Now Playing runs as a screensaver session. As a Compass view it is
    // the one on screen, not a screensaver to wake from.
    final nowPlaying = currentView.kind == 'now_playing' && _nowPlayingUp;
    if (c.screensaver.isActive && !nowPlaying) return false;
    if (c.kiosk.lockdownActive) return false;
    if (c.browser.overlayUrl.value != null) return false;
    // A plugin's window draws over the dashboard, in its layer. On another
    // view it waits underneath, hidden, and must not hold the swipe up.
    if (c.plugins.windows.value.isNotEmpty && currentView.isDashboard) {
      return false;
    }
    if (c.dlna.media.value != null) return false;
    final phase = c.alarms.status.value.phase;
    if (phase == AlarmPhase.ringing || phase == AlarmPhase.sunrise) {
      return false;
    }
    if (c.intercom.screenShown && !c.intercom.rosterVisible.value) {
      return false;
    }
    // Now Playing draws over every other view. One left open under it,
    // such as the library a track was started from, is not in the way,
    // and it is where the kiosk lands when Now Playing closes.
    if (nowPlaying) return true;
    final view = currentView;
    bool only(bool up, String kind) => !up || view.kind == kind;
    final camera = c.camera.activeViewId.value;
    return only(c.musicLibrary.visible.value, 'music_library') &&
        only(c.calendar.visible.value, 'calendar') &&
        only(c.alarms.visible.value, 'alarms') &&
        only(_nowPlayingUp, 'now_playing') &&
        only(c.launcher.visible.value, 'app_launcher') &&
        only(c.intercom.rosterVisible.value, 'intercom') &&
        only(menuVisible.value, 'menu') &&
        (camera == null || (view.kind == 'camera' && view.id == camera));
  }

  // ── Moving ──────────────────────────────────────────────────────────

  /// Brings the view at [slot] up and puts every other Compass view away.
  /// Completes once the view has been asked to show; a dashboard view
  /// completes when the page has moved.
  Future<void> show(CompassSlot slot) async {
    final view = _layout.viewAt(slot);
    if (view == null) return;
    current.value = slot;
    _switching = true;
    try {
      if (view.kind == 'now_playing') {
        // The screensaver refuses Now Playing over a camera view, so the
        // other views go first. The camera's state reaches the screensaver
        // over the bus, a turn later.
        await _closeAllBut(view);
        await Future<void>.delayed(Duration.zero);
        await _open(view);
      } else {
        await _open(view);
        await _closeAllBut(view);
      }
    } finally {
      _switching = false;
    }
    // Moved without a swipe (back, the timer, a page closed by hand): a
    // plane a swipe left out comes back if this view shows the dashboard.
    if (stage.value == null) await settlePlane();
    _armReturn();
    _verifyShown(slot);
  }

  Timer? _verifyTimer;

  /// A view can refuse to open, such as Now Playing during a voice turn.
  /// Once it has had time to come up, a view still missing is handled like
  /// one that closed: the kiosk lands on what is up, or the center.
  void _verifyShown(CompassSlot slot) {
    _verifyTimer?.cancel();
    _verifyTimer = Timer(const Duration(milliseconds: 1500), () {
      if (current.value != slot || stage.value != null || _switching) return;
      final view = currentView;
      if (view.isDashboard || _isUp(view)) return;
      _settle();
    });
  }

  /// Straight to the center, no swipe drawn: back, the exit gesture's
  /// counterpart and the return timer.
  Future<void> goCenter() => show(CompassSlot.center);

  /// Straight to the Menu, [unlocked] for the full one on a locked kiosk.
  Future<void> goMenu({bool unlocked = false}) async {
    final slot = _layout.slotOf(CompassView.menu);
    if (slot == null) return;
    // A locked kiosk without its quick menu opens the Menu only through
    // the exit gesture, which asks for [unlocked].
    if (!unlocked && !available(CompassView.menu)) return;
    menuUnlocked.value = unlocked;
    await show(slot);
    // show() drops the unlock with the Menu it reopens from scratch.
    menuUnlocked.value = unlocked;
  }

  Future<void> _open(CompassView view) async {
    switch (view.kind) {
      case 'menu':
        menuVisible.value = true;
      case 'dashboard':
        await _showDashboard(view.path);
      case 'music_library':
        await c.commands.execute('openMusicLibrary', const {});
      case 'calendar':
        await c.commands.execute('openCalendar', const {});
      case 'alarms':
        await c.commands.execute('openAlarms', const {});
      case 'now_playing':
        await c.sendspin.showFullscreen();
      case 'camera':
        if (c.camera.activeViewId.value != view.id) {
          await c.camera.showView(view.id, instant: true);
        }
      case 'app_launcher':
        c.launcher.open(unlocked: !c.kiosk.locked);
      case 'intercom':
        await c.commands.execute('intercomOpen', const {});
    }
  }

  Future<void> _closeAllBut(CompassView view) async {
    if (view.kind != 'menu') menuVisible.value = false;
    if (view.kind != 'music_library' && c.musicLibrary.visible.value) {
      await c.commands.execute('hideMusicLibrary', const {});
    }
    if (view.kind != 'calendar' && c.calendar.visible.value) {
      await c.commands.execute('hideCalendar', const {});
    }
    if (view.kind != 'alarms' && c.alarms.visible.value) {
      await c.commands.execute('hideAlarms', const {});
    }
    if (view.kind != 'now_playing' && _nowPlayingUp) {
      await c.commands.execute('hideNowPlaying', const {});
    }
    final camera = c.camera.activeViewId.value;
    if (camera != null && !(view.kind == 'camera' && view.id == camera)) {
      c.camera.hideView(instant: true);
    }
    if (view.kind != 'app_launcher' && c.launcher.visible.value) {
      c.launcher.visible.value = false;
    }
    if (view.kind != 'intercom' && c.intercom.rosterVisible.value) {
      c.intercom.rosterVisible.value = false;
    }
  }

  /// The navigation path the kiosk starts on, the one the home dashboard
  /// ("") stands for. Empty when the start page is not a Home Assistant
  /// view.
  String get homePath =>
      dashboardPathOfUrl(
        c.browser.startUrl,
        c.homeAssistant.baseUrl,
        pages: c.homeAssistant.customPages,
      ) ??
      '';

  Future<void> _showDashboard(String path) async {
    final target = path.isEmpty ? homePath : path;
    if (target.isEmpty) {
      if (c.browser.currentUrl != c.browser.startUrl) {
        await c.commands.execute('loadUrl', {'url': c.browser.startUrl});
      }
      return;
    }
    await c.homeAssistant.navigateToViewPath(target, awaitSelfHeal: false);
  }

  /// Someone else opened or closed a page: a gesture, Home Assistant, the
  /// page's own close button. Opening a view the layout holds makes it the
  /// current one. Closing the view on screen lands on the center, which
  /// always shows.
  Timer? _settleTimer;

  /// Pages change in steps that are not one moment: Now Playing's library
  /// button stops the screensaver and opens the library a beat later. The
  /// layout is read again once things have settled, not on every edge,
  /// or the gap between the two reads as the view in hand going away.
  void _onOverlayChanged() {
    if (_switching || !enabled || stage.value != null) return;
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 300), _settle);
  }

  void _settle() {
    if (_switching || !enabled || stage.value != null) return;
    final view = currentView;
    // A view of the layout came up over the one in hand: it is the
    // current one now.
    for (final slot in _layout.slots) {
      final candidate = _layout.viewAt(slot);
      if (candidate == null || candidate.key == view.key) continue;
      if (!candidate.isDashboard && !candidate.isMenu && _isUp(candidate)) {
        current.value = slot;
        if (candidate.kind != 'menu') menuVisible.value = false;
        return;
      }
    }
    if (view.isDashboard || _isUp(view)) return;
    // The view in hand went away. A page the layout does not hold may have
    // taken its place (the library from Now Playing): it keeps the screen,
    // and the center comes back once it closes.
    if (_anythingUp) {
      current.value = CompassSlot.center;
      return;
    }
    unawaited(goCenter());
  }

  /// Now Playing is on screen: a screensaver session showing its view.
  /// The player's own fullscreenActive only says a track would take the
  /// screensaver's place, and stays on for as long as music plays.
  bool get _nowPlayingUp =>
      c.screensaver.isActive && c.screensaver.nowPlayingShown;

  /// Any page Compass could be under, whether the layout holds it or not.
  bool get _anythingUp =>
      c.musicLibrary.visible.value ||
      c.calendar.visible.value ||
      c.alarms.visible.value ||
      _nowPlayingUp ||
      c.camera.activeViewId.value != null ||
      c.launcher.visible.value ||
      c.intercom.rosterVisible.value ||
      menuVisible.value;

  bool _isUp(CompassView view) => switch (view.kind) {
    'music_library' => c.musicLibrary.visible.value,
    'calendar' => c.calendar.visible.value,
    'alarms' => c.alarms.visible.value,
    'now_playing' => _nowPlayingUp,
    'camera' => c.camera.activeViewId.value == view.id,
    'app_launcher' => c.launcher.visible.value,
    'intercom' => c.intercom.rosterVisible.value,
    'menu' => menuVisible.value,
    _ => true,
  };

  /// Hold Mode pins the view on screen, so the timer stands down while it
  /// is on and starts over when it goes off.
  void _armReturn() {
    _returnTimer?.cancel();
    final minutes = c.settings.get(defs.navCompassReturnMinutes).toInt();
    if (!enabled || minutes <= 0 || c.settings.get(defs.haHoldMode)) return;
    _returnTimer = Timer(Duration(minutes: minutes), () {
      if (current.value.isCenter || stage.value != null) return;
      if (c.settings.get(defs.haHoldMode)) return;
      // A ringing alarm or a call keeps its screen; the next touch arms
      // the timer again.
      if (!swipeReady && !c.screensaver.isActive) return;
      unawaited(goCenter());
    });
  }

  // ── The page's word on a touch ──────────────────────────────────────

  CompassPageHint? _hint;
  DateTime? _hintAt;

  /// The page probe's report on the touch that just went down
  /// (compass_page_script.dart).
  void pageTouched(Object? args) {
    _hint = CompassPageHint.fromJson(args);
    _hintAt = DateTime.now();
  }

  void clearPageHint() {
    _hint = null;
    _hintAt = null;
  }

  /// The page's report, if one came in after [since]: the touch that went
  /// down then.
  CompassPageHint? pageHintSince(DateTime since) {
    final at = _hintAt;
    if (at == null || at.isBefore(since)) return null;
    return _hint;
  }

  // ── Snapshots ───────────────────────────────────────────────────────

  ui.Image? shotOf(CompassView view) => _shots[view.key];

  /// The display as it is now, kept for [view]. Width capped: the swipe
  /// draws it no larger than the screen, and a tablet panel's full width
  /// is several times the memory for no visible gain once it shrinks.
  Future<ui.Image?> capture(CompassView view, {required int width}) async {
    final image = await ScreenCapture.captureImage(width: width);
    if (image == null) return null;
    _keep(view.key, image.clone());
    return image;
  }

  void _keep(String key, ui.Image image) {
    _shots.remove(key)?.dispose();
    _shotOrder.remove(key);
    _shots[key] = image;
    _shotOrder.add(key);
    while (_shotOrder.length > _shotLimit) {
      _shots.remove(_shotOrder.removeAt(0))?.dispose();
    }
  }

  void _dropStaleShots() {
    final keys = {for (final s in _layout.slots) _layout.viewAt(s)?.key};
    for (final key in [..._shotOrder]) {
      if (!keys.contains(key)) {
        _shots.remove(key)?.dispose();
        _shotOrder.remove(key);
      }
    }
  }

  void _clearShots() {
    for (final image in _shots.values) {
      image.dispose();
    }
    _shots.clear();
    _shotOrder.clear();
  }
}

/// What the swipe draws, frame by frame. The painter listens to it; the
/// widgets never rebuild while it moves.
class CompassStageModel extends ChangeNotifier {
  CompassStageModel({
    required this.from,
    required this.move,
    required this.target,
    required this.travel,
    required this.tiles,
    required this.zoom,
  });

  /// The slot the swipe started on.
  final CompassSlot from;
  final CompassMove move;
  final CompassSlot target;

  /// Where [target] lies from [from], in view widths and heights.
  final Offset travel;

  /// Every view drawn: the one the swipe started on at (0, 0) and its
  /// neighbors at their offsets in view widths and heights.
  final List<CompassTile> tiles;
  final bool zoom;

  /// The current view's snapshot arrived: until then nothing is drawn.
  bool ready = false;

  /// How far toward [target], 0 to 1.
  double progress = 0;

  /// The size the views are drawn at, 1 for full screen.
  double scale = 1;

  /// The whole stage fades over the live view at the end of a landing.
  double opacity = 1;

  /// The display could not be captured: the swipe switches views on
  /// release with nothing drawn.
  bool noSnapshot = false;

  void update({double? progress, double? scale, double? opacity}) {
    if (progress != null) this.progress = progress;
    if (scale != null) this.scale = scale;
    if (opacity != null) this.opacity = opacity;
    notifyListeners();
  }

  void markReady() {
    ready = true;
    notifyListeners();
  }
}

class CompassTile {
  CompassTile({
    required this.view,
    required this.dx,
    required this.dy,
    required this.label,
    required this.icon,
    this.image,
  });

  final CompassView view;
  final int dx;
  final int dy;
  final String label;
  final IconData icon;
  ui.Image? image;
}

/// Whether a kind of view is set up on this kiosk at all, so the layout
/// can hold it: the Music Library needs a source to browse, Now Playing
/// its view switched on, a camera a camera view, the App Launcher its
/// apps and the intercom the intercom.
bool compassKindConfigurable(AppContainer c, String kind) => switch (kind) {
  'dashboard' || 'menu' || 'calendar' || 'alarms' => true,
  'music_library' => c.musicLibrary.available.isNotEmpty,
  'now_playing' =>
    c.settings.get(defs.sendspinPlayerActive) &&
        c.settings.get(defs.sendspinFullscreen),
  'camera' => compassCameraViews(c).isNotEmpty,
  'app_launcher' =>
    c.settings.get(defs.launcherEnabled) && c.launcher.apps.isNotEmpty,
  'intercom' => c.intercom.enabled,
  _ => false,
};

/// The camera views a layout can show: the ones with cameras in them. An
/// empty view shows nothing, so the kiosk menu leaves it out too.
List<CameraViewConfig> compassCameraViews(AppContainer c) => [
  for (final v in c.camera.config.views)
    if (v.cameraIds.isNotEmpty) v,
];

/// The glyph a view is known by, the one the drawer and the settings use.
IconData compassViewIcon(CompassView view) => switch (view.kind) {
  'menu' => Icons.menu,
  'dashboard' => Icons.dashboard_outlined,
  'music_library' => Icons.library_music_outlined,
  'calendar' => Icons.calendar_month_outlined,
  'alarms' => Icons.alarm,
  'now_playing' => Icons.album_outlined,
  'camera' => Icons.videocam_outlined,
  'app_launcher' => Icons.apps_outlined,
  'intercom' => Icons.speaker_phone_outlined,
  _ => Icons.crop_square,
};

/// The name a view goes by on the map, the dialog and the swipe.
String compassViewLabel(
  BuildContext context,
  AppContainer c,
  CompassView view,
) {
  final strings = l10n(context);
  switch (view.kind) {
    case 'menu':
      return strings.compassMenu;
    case 'dashboard':
      if (view.path.isEmpty) return strings.compassHomeDashboard;
      final list = DashboardCatalog.current.value;
      final match = list == null
          ? null
          : DashboardCatalog.match(list, view.path);
      if (match == null) return view.path;
      final d = match.dashboard;
      return match.view == null || d.page || d.views.length < 2
          ? d.label(context)
          : match.view!.title;
    case 'music_library':
      return strings.libraryTitle;
    case 'calendar':
      return strings.calendarTitle;
    case 'alarms':
      return strings.alarmsTitle;
    case 'now_playing':
      return strings.drawerNowPlaying;
    case 'camera':
      for (final v in c.camera.config.views) {
        if (v.id == view.id) return v.name;
      }
      return strings.drawerCameraView;
    case 'app_launcher':
      return strings.compassAppLauncher;
    case 'intercom':
      return strings.drawerIntercom;
  }
  return view.kind;
}
