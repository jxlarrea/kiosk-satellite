import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import 'alarm_ring_overlay.dart';
import 'alarms_overlay.dart';
import 'calendar_overlay.dart';
import 'music_library_overlay.dart';
import '../core/permissions.dart';

import '../app_container.dart';
import '../l10n/messages.dart';
import '../l10n/gesture_messages.dart';
import 'screensaver_view.dart';
import '../core/events.dart';
import '../managers/browser/carousel_script.dart';
import '../managers/browser/color_scheme_script.dart';
import '../managers/browser/disable_suspend_script.dart';
import '../managers/browser/dashboard_camera_script.dart';
import '../managers/browser/ha_session_script.dart';
import '../managers/browser/vs_suppress_script.dart';
import '../managers/browser/haptics_script.dart';
import '../managers/device/haptics.dart';
import '../managers/device/tap_sound.dart';
import '../managers/browser/no_cache_script.dart';
import '../managers/browser/pull_to_refresh_script.dart';
import '../managers/browser/dashboards_watch_script.dart';
import '../managers/browser/socket_watch_script.dart';
import '../managers/browser/viewport_zoom_script.dart';
import '../managers/browser/visibility_mask_script.dart';
import '../managers/browser/url_filter.dart';
import '../managers/browser/ws_filter_script.dart';
import '../managers/kiosk/app_link.dart';
import '../managers/kiosk/kiosk_link.dart';
import '../managers/wake_word/background_listening.dart';
import '../managers/proxy/media_rewrite_script.dart';
import '../managers/sendspin/music_assistant_api.dart';
import '../managers/home_assistant/kiosk_mode.dart';
import '../managers/gestures/gesture_mappings.dart';
import '../managers/browser/browser_manager.dart';
import '../managers/plugins/plugin_camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart' show CameraFacing;
import '../managers/settings/definitions.dart' as defs;
import 'app_launcher_overlay.dart';
import 'ui_scale.dart' show UiScaleExempt, uiScaleFactor;
import 'lockdown_shield.dart';
import 'notification_overlay.dart';
import 'plugin_overlay.dart';
import 'offline_notice.dart';
import 'dlna_media_overlay.dart';
import 'camera_view_overlay.dart';
import 'code_scanner.dart';
import 'face_preview_overlay.dart';
import 'fleet_settings.dart';
import 'intercom_settings.dart';
import 'back_nav.dart';
import 'key_nav.dart';
import 'kiosk_drawer.dart';
import 'sendspin_player_overlay.dart';
import 'assist/assist_overlay.dart';
import 'toast.dart';
import 'settings_screen.dart';
import 'voice_timer_overlay.dart';
import 'web_console_panel.dart';
import 'webview_server_trust.dart';

/// Watches the navigator for the kiosk screen (issue #377): a dialog
/// pushed over it — the exit confirm, the PIN prompt, a picker — must flip
/// the native key routing to Flutter, or the dpad keeps feeding the
/// dashboard WebView behind the modal. Registered on the MaterialApp in
/// main.dart.
final kioskRouteObserver = RouteObserver<ModalRoute<void>>();

/// The kiosk itself: a fullscreen WebView with the JS bridge, the
/// screensaver overlay, and a slide-out menu (swipe from the left edge —
/// Fully Kiosk behavior).
class KioskScreen extends StatefulWidget {
  const KioskScreen({
    super.key,
    required this.container,
    this.showMenuHint = false,
  });

  final AppContainer container;

  /// Show the menu-gesture hint once (set when arriving from the wizard).
  final bool showMenuHint;

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  AppContainer get c => widget.container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) kioskRouteObserver.subscribe(this, route);
    // ModalRoute.of registers an inherited dependency, so navigation capture
    // must initialize here after initState completes (issue #493).
    _syncNavCapture();
  }

  /// A route was pushed over the kiosk (a dialog, the settings) or popped
  /// back off: the key capture depends on it (see [kioskRouteObserver]).
  @override
  void didPushNext() => _syncNavCapture();

  @override
  void didPopNext() => _syncNavCapture();

  bool _consoleOpen = false;
  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<KioskExitGesture>? _gestureSub;
  StreamSubscription<GestureActionCompleted>? _gestureResultSub;
  StreamSubscription<WebConsoleRequested>? _consoleReqSub;
  StreamSubscription<KioskBackPressed>? _backSub;
  StreamSubscription<HomeKeyPressed>? _homeSub;
  StreamSubscription<WakeWordDetected>? _wakeSub;
  StreamSubscription<CameraViewStateChanged>? _cameraSub;
  StreamSubscription<ScreensaverStateChanged>? _saverSub;
  StreamSubscription<WebViewRebuildRequested>? _rebuildSub;
  StreamSubscription<WebViewMissing>? _missingSub;

  /// Whether the Activity has attached to the process-wide engine. The
  /// dashboard WebView build waits for this: the Dart isolate boots in
  /// Application.onCreate, so on slow devices the widget tree is up before
  /// the Activity is, and a platform view created in that window dies with
  /// an unretried MissingPluginException — a black screen the watchdog then
  /// restarts into the same race, forever (issue #145).
  bool _activityAttached = false;

  /// Guards the exit gesture while the settings route sits on top.
  bool _settingsOpen = false;

  /// The push drawer: the kiosk content slides right in step with the pane,
  /// so the menu reads as sharing the kiosk's plane instead of floating over
  /// it. 0 = closed, 1 = fully open; dragged directly during edge swipes.
  /// Narrow on purpose — the widest thing in it is "Exit Application".
  static const _drawerWidth = 300.0;
  late final AnimationController _drawer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(_syncMenuBusy);

  void _closeDrawer() => _drawer.fling(velocity: -1);

  /// The drawer pane's focus scope (issue #377): dpad/arrow navigation puts
  /// focus here, and the scope keeps the arrows walking the menu's own
  /// entries — a directional search never leaves its nearest scope, so
  /// focus cannot wander off into the kiosk plane behind it.
  final FocusScopeNode _drawerFocus = FocusScopeNode(
    debugLabel: 'kiosk drawer',
  );

  /// Whether the drawer, when open, shows only the kiosk-allowed quick
  /// actions. Set at the moment it opens: an edge swipe while kiosk mode is
  /// locked opens it restricted (kiosk.allow_drawer); the exit gesture (and
  /// its PIN) always earns the full menu.
  bool _drawerRestricted = false;

  /// Deadline of the double-back window (discussion #312): a back press
  /// over the bare kiosk opens the menu and arms this; a press before it
  /// lapses performs the back the first one swallowed, and re-arms it, so
  /// a run of quick presses steps the history without the menu reopening
  /// between them.
  DateTime? _backArmedUntil;

  static const _backAgainWindow = Duration(seconds: 3);
  static const _backEcho = Duration(milliseconds: 200);

  /// When the last back press ran the ladder, to drop its echo.
  DateTime? _lastBackAt;

  /// One ladder for every back press — the predictive pop (the PopScope in
  /// build) and the KeyEvent path KioskLock routes here as KioskBackPressed
  /// land in the same place, so the two can never drift apart.
  void _handleBack() {
    // Android 16 with targetSdk 36 hands a key-driven back to both paths
    // at once when KioskLock swallows it (kiosk mode or the home role):
    // the predictive callback Flutter registers for the PopScope, and the
    // KeyEvent. The two land a few milliseconds apart, and ran the ladder
    // twice: the first opened the menu, the second closed it again and
    // stepped back, so a remote's back could never open the menu (issue
    // #745). No hand presses back twice this fast.
    final now = DateTime.now();
    final last = _lastBackAt;
    _lastBackAt = now;
    if (last != null && now.difference(last) < _backEcho) return;
    if (_drawer.value == 0 &&
        !c.screensaver.isActive &&
        !c.launcher.visible.value &&
        !c.intercom.rosterVisible.value &&
        !c.alarms.visible.value &&
        !c.calendar.visible.value &&
        !c.musicLibrary.visible.value &&
        c.camera.activeViewId.value == null &&
        !c.kiosk.lockdownActive &&
        (c.plugins.windows.value.isNotEmpty || c.plugins.backOverlay != null)) {
      // Windows float over the native overlays, so they close first.
      if (c.plugins.windows.value.isNotEmpty) {
        unawaited(
          c.plugins.windowEvent(c.plugins.windows.value.last.id, closed: true),
        );
      } else {
        unawaited(c.plugins.closeOverlay(c.plugins.backOverlay!));
      }
      return;
    }
    final deadline = _backArmedUntil;
    final armed = deadline != null && DateTime.now().isBefore(deadline);
    _backArmedUntil = null;
    final action = decideBack(
      drawerOpen: _drawer.value > 0,
      armed: armed,
      launcherVisible:
          c.launcher.visible.value ||
          c.intercom.rosterVisible.value ||
          c.alarms.visible.value ||
          c.calendar.visible.value ||
          c.musicLibrary.visible.value,
      overlayUp: c.browser.overlayUrl.value != null,
      cameraViewUp: c.camera.activeViewId.value != null,
      cameraFocused: c.camera.focusedCameraId.value != null,
      screensaverActive: c.screensaver.isActive,
      lockdown: c.kiosk.lockdownActive,
      locked: c.kiosk.locked,
      quickMenuAvailable: _quickMenuAvailable,
    );
    c.log.info(
      'kiosk',
      'back: ${action.name} (armed=$armed, drawer=${_drawer.value > 0})',
    );
    switch (action) {
      case BackAction.stopScreensaver:
        unawaited(c.commands.execute('stopScreensaver', const {}));
      case BackAction.closeDrawer:
        _closeDrawer();
      case BackAction.closeDrawerAndBack:
        dismissToast();
        _closeDrawer();
        unawaited(_performBack());
        _backArmedUntil = DateTime.now().add(_backAgainWindow);
      case BackAction.hideLauncher:
        // The library steps back out of an opened album first.
        if (c.musicLibrary.visible.value &&
            (c.musicLibrary.backHandler?.call() ?? false)) {
          break;
        }
        c.launcher.visible.value = false;
        c.intercom.rosterVisible.value = false;
        c.alarms.visible.value = false;
        c.calendar.visible.value = false;
        c.musicLibrary.visible.value = false;
      case BackAction.dismissOverlay:
        // A link or rotation page covers the dashboard: back uncovers it.
        c.browser.dismissOverlay();
      case BackAction.unfocusCamera:
        c.camera.focusCamera(null);
      case BackAction.hideCameraView:
        c.camera.hideView();
      case BackAction.openDrawer:
        // Mirrors the edge swipe: opening while locked earns only the
        // restricted quick menu, never the full one.
        setState(() => _drawerRestricted = c.kiosk.locked);
        _drawer.fling(velocity: 1);
        // Back is the remote's menu key (issue #745), so the arrows start
        // on the first entry the way they did when left opened the menu.
        // A touch-driven back leaves Flutter in touch highlight mode and
        // the focus draws nothing.
        _focusDrawer();
        _backArmedUntil = DateTime.now().add(_backAgainWindow);
        // No toast while the home role is held: a home screen's back has
        // no app to close and usually no history to step, so there is
        // nothing to promise — back simply means the menu there. The
        // double-back window still arms for the times history exists.
        if (!c.homeLauncher.roleHeld.value) {
          showToast(
            context,
            source: 'back',
            title: _backWouldLeaveApp
                ? l10n(context).kioskBackClose
                : l10n(context).kioskBackAgain,
            duration: _backAgainWindow,
          );
        }
      case BackAction.back:
        unawaited(_performBack());
        _backArmedUntil = DateTime.now().add(_backAgainWindow);
    }
  }

  bool get _backWouldLeaveApp => backLeavesApp(
    locked: c.kiosk.locked,
    lockdown: c.kiosk.lockdownActive,
    homeRoleHeld: c.homeLauncher.roleHeld.value,
  );

  static const _adminChannel = MethodChannel('kiosk_satellite/admin');

  /// The back the menu press swallowed: what a press over the bare kiosk
  /// did before the menu took the first one. Leaving means backgrounding
  /// the task, never finishing the Activity: on Fire OS 8 a relaunch after
  /// a finish reattaches to the cached engine with Flutter's own rendering
  /// dead — the WebView keeps drawing, so the wedge only shows when a menu
  /// or toast should appear over it. SystemNavigator.pop stays as the
  /// fallback for an Activity-less edge where backgrounding cannot land.
  Future<void> _performBack() async {
    if (_backWouldLeaveApp) {
      try {
        await _adminChannel.invokeMethod<bool>('moveTaskToBack');
      } catch (e) {
        c.log.warn('kiosk', 'moveTaskToBack failed, falling back: $e');
        await SystemNavigator.pop();
      }
    } else {
      c.browser.goBack();
    }
  }

  /// Whether the locked kiosk still offers the edge swipe: the owner opted
  /// in, and at least one row would actually show in the quick-actions
  /// menu. A menu with nothing in it is worse than no menu, and the drawer
  /// answers which rows it draws itself.
  bool get _quickMenuAvailable =>
      c.settings.get(defs.kioskAllowDrawer) &&
      KioskDrawer.visibleItems(c, restricted: true).isNotEmpty;

  /// Pull-to-refresh as the user experiences it: the Web Browsing toggle,
  /// minus the kiosk protection that switches the gesture off while the
  /// device is locked, and minus the screensaver. With Double tap to
  /// dismiss, the Home Assistant Dashboard screensaver lets touches
  /// through to the page (discussion #1069), and a pull there must not
  /// reload it.
  bool get _ptrEnabled =>
      c.settings.get(defs.pullToRefresh) &&
      !(c.kiosk.locked && c.settings.get(defs.kioskDisablePullRefresh)) &&
      !c.screensaver.isActive;

  /// The dashboard carousel as the page runs it: the setting, off while
  /// the screensaver is up for the same reason as [_ptrEnabled]. A swipe
  /// must not take the screensaver's view away.
  bool get _carouselEnabled =>
      c.settings.get(defs.haDashboardCarousel) && !c.screensaver.isActive;

  /// Push the current effective carousel state onto the live page. The
  /// sync call makes the script act on it now: build the preview strip, or
  /// tear a disabled one down instead of leaving it mounted.
  Future<void> _syncCarousel() => c.browser.runJs(
    'window.__ksCarouselEnabled = $_carouselEnabled;'
    'if (window.__ksCarouselSync) window.__ksCarouselSync();',
  );

  /// Push the current effective pull-to-refresh state onto the live WebView:
  /// the native wrapper and the JS probe both hold their own copy.
  Future<void> _syncPullToRefresh() async {
    await _pullToRefresh.setEnabled(_ptrEnabled);
    await c.browser.runJs('window.__ksPtrEnabled = $_ptrEnabled;');
  }

  void _drawerDragUpdate(DragUpdateDetails details) {
    _drawer.value += details.delta.dx / _drawerWidth;
  }

  void _drawerDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx / _drawerWidth;
    if (velocity.abs() > 1) {
      _drawer.fling(velocity: velocity.sign);
    } else {
      _drawer.fling(velocity: _drawer.value > 0.5 ? 1 : -1);
    }
  }

  /// Bumped to force a WebView rebuild for settings that are only read at
  /// creation (mixed content, SSL trust). Rebuilding re-reads initialSettings.
  int _webViewEpoch = 0;

  /// The next rebuilt WebView loads the start URL instead of picking up
  /// where the current page was (a token change, see _onSettingChanged).
  bool _rebuildFromStart = false;

  /// The proxied origin the current WebView was created with (its media
  /// rewrite script names it), and the epoch that WebView belongs to.
  String? _webViewProxyOrigin;
  int _webViewProxyEpoch = -1;

  /// Set when auto-login turns on: the seed replaces a login done by hand
  /// once, on the first page that sees this marker.
  String? _autoLoginReplace;

  /// Pull-to-refresh, Fully style. The native wrapper handles pages that fit
  /// the screen; scrollable pages never hand it the gesture (Chromium claims
  /// every vertical drag), so those report their pulls through the JS probe
  /// (see pull_to_refresh_script.dart) into [_triggerRefresh]. The spinner is
  /// ended from onLoadStop / onReceivedError — the reload's own completion —
  /// never on a timer.
  late final PullToRefreshController _pullToRefresh = PullToRefreshController(
    settings: PullToRefreshSettings(
      enabled: _ptrEnabled,
      color: const Color(0xFF488284), // brand teal on the stock spinner
    ),
    onRefresh: _triggerRefresh,
  );

  /// One refresh at a time, whichever side asked for it: the guard keeps the
  /// native gesture and the JS probe from doubling up on pages where both
  /// fire. Reset when the reload settles — and by [_refreshingFailsafe],
  /// because the reload is not guaranteed to settle: a pull racing an
  /// in-flight navigation runs the reload script in a dying document, no
  /// onLoadStop ever follows, and a guard with no way back would silently
  /// swallow every pull from then on.
  bool _refreshing = false;
  Timer? _refreshingFailsafe;

  /// Returns whether the pull was acted on — the JS probe retracts its
  /// spinner on a false reply (nothing else would ever end it, since the
  /// spinner otherwise dies with the reloading document).
  Future<bool> _triggerRefresh() async {
    c.log.info(
      'kiosk',
      'pull trigger: refreshing=$_refreshing enabled=$_ptrEnabled',
    );
    if (_refreshing || !_ptrEnabled) return false;
    _refreshing = true;
    _refreshingFailsafe?.cancel();
    _refreshingFailsafe = Timer(const Duration(seconds: 8), () {
      _refreshing = false;
    });
    // No beginRefreshing here: the native gesture already shows its spinner,
    // and the JS probe draws (and keeps) its own — awaiting the platform
    // spinner from a bridge callback is what once held the reload hostage.
    //
    // The cache-clearing pull is NOT the menu's Clear web cache: it empties
    // the HTTP cache and Cache Storage but leaves the service worker
    // registered (see pullRefreshClearScript — unregistering it mid-session
    // is what made pages reload themselves half a minute later). A plain
    // pull is just the reload.
    if (c.settings.get(defs.pullToRefreshClearCache)) {
      await InAppWebViewController.clearAllCache();
      // The wake word models are cached by URL too — a model re-published
      // on Home Assistant under the same name is invisible until its cache
      // is dropped, and a clearing pull should mean all the caches. Dropped
      // before the reload so the page's wake-word handshake re-downloads.
      await c.commands.execute('clearWakeWordModels', const {});
      await c.browser.runJs(pullRefreshClearScript);
    } else {
      await c.commands.execute('reload', const {});
    }
    return true;
  }

  Future<void> _onSettingChanged(SettingChanged e) async {
    // Lockdown flipping is the one key-capture state with no listener of
    // its own here; the sync is diffed, so the rest cost nothing.
    _syncNavCapture();
    // The theme script names the servers of the custom pages elsewhere.
    if (e.key == defs.haCustomPages.key) {
      _pageDarkChanged();
      return;
    }
    // HA kiosk mode and its hide choices are applied live: restyling the
    // page in place, with no reload and nothing lost from it.
    if (e.key == defs.haKioskMode.key ||
        e.key == defs.haKioskHideHeader.key ||
        e.key == defs.haKioskHideSidebar.key ||
        e.key == defs.screensaverDashboardKiosk.key ||
        e.key == defs.screensaverDashboardHideHeader.key ||
        e.key == defs.screensaverDashboardHideSidebar.key) {
      await _applyKioskMode();
      return;
    }
    // Mixed-content / SSL / cache / zoom are read only at WebView creation —
    // rebuild it (preserving the current URL) so the change applies without
    // a restart. The rebuild is storage-safe: localStorage is per-origin and
    // outlives the widget, so a page's saved config is not lost.
    // Zoom applies live via the viewport meta — no rebuild, no reload.
    if (e.key == defs.browserZoom.key) {
      await c.browser.runJs(_zoomJs);
      _syncContentInsets();
      return;
    }
    if (e.key == defs.uiScale.key) {
      _syncContentInsets();
      return;
    }
    // Scroll lock rides the zoom path: applied live as page CSS, no rebuild.
    if (e.key == defs.disableScrolling.key) {
      await c.browser.runJs(_scrollLockJs);
      return;
    }
    // The carousel's document-start seed is frozen at WebView creation;
    // flip the live flag so the toggle applies without a reload.
    if (e.key == defs.haDashboardCarousel.key) {
      await _syncCarousel();
      return;
    }
    // Same live-flag contract; read only on the touch path, so there is
    // no strip state to sync.
    if (e.key == defs.haCarouselOverCards.key) {
      await c.browser.runJs(
        'window.__ksCarouselOverCards = ${e.value == true};',
      );
      return;
    }
    // Haptics and the tap sound share one live-flag contract; the script
    // itself has no state to build or tear down.
    if (e.key == defs.haHaptics.key) {
      await c.browser.runJs('window.__ksHapticsEnabled = ${e.value == true};');
      return;
    }
    if (e.key == defs.haTapSound.key) {
      await c.browser.runJs('window.__ksTapSoundEnabled = ${e.value == true};');
      return;
    }
    if (e.key == defs.allowMixedContent.key ||
        e.key == defs.ignoreSslErrors.key ||
        e.key == defs.disableCache.key ||
        e.key == defs.pinchToZoom.key ||
        e.key == defs.wsFilter.key ||
        e.key == defs.disableSuspend.key ||
        e.key == defs.kioskDisableContextMenus.key) {
      setState(() => _webViewEpoch++);
      return;
    }
    // Auto-login on reloads from the start URL: the page on screen is
    // usually Home Assistant's login form, which never reads the seeded
    // session. It also signs out a login done by hand, once, since turning
    // it on asks for the token's user. Off reloads in place and the login
    // form follows.
    if (e.key == defs.haAutoLogin.key) {
      setState(() {
        _webViewEpoch++;
        if (c.settings.get(defs.haAutoLogin)) {
          _rebuildFromStart = true;
          _autoLoginReplace = '${DateTime.now().microsecondsSinceEpoch}';
        }
      });
      return;
    }
    // A new long-lived token reaches the dashboard only through the
    // auto-login seed, which runs at document start: rebuild so the page
    // reloads with the new token and signs in as its user (discussion #426).
    // Reloaded from the start URL, not the current page: whoever the new
    // token belongs to should land on the dashboard, not on a view the old
    // user was browsing, or the login form a failed token left behind.
    if (e.key == defs.haToken.key && c.settings.get(defs.haAutoLogin)) {
      setState(() {
        _webViewEpoch++;
        _rebuildFromStart = true;
      });
      return;
    }
    // Hold mode flips silently from gestures, HA and the remote admin, so
    // the screen itself says what just happened (issue #266). The drawer
    // notice carries the lasting reminder; this is only the moment's
    // feedback.
    if (e.key == defs.haHoldMode.key) {
      if (!mounted) return;
      if (e.value == true) {
        showToast(
          context,
          source: 'hold_mode',
          title: l10n(context).kioskHoldOn,
          message: l10n(context).kioskHoldNotice,
        );
      } else {
        showToast(
          context,
          source: 'hold_mode',
          title: l10n(context).kioskHoldOff,
        );
      }
      return;
    }
    // Kiosk mode swaps the drawer swipe for the exit gesture (KioskManager
    // pushes the native flags itself; this re-renders the gate — and
    // rebuilds the WebView when the master switch changes whether the
    // context-menu suppression is in force).
    if (e.key == defs.kioskEnabled.key) {
      setState(() {
        if (c.settings.get(defs.kioskDisableContextMenus)) _webViewEpoch++;
        // Leaving kiosk mode lifts the quick-actions restriction; an open
        // drawer regains its full menu in place.
        if (!c.kiosk.locked) _drawerRestricted = false;
      });
      // Locking also arms the pull-to-refresh protection (and unlocking
      // disarms it), so the effective state changes with this key too.
      await _syncPullToRefresh();
      return;
    }
    // Lockdown Mode (discussion #143): mount or drop the touch shield. On
    // enable, take back whatever a person had open on the device — drawer,
    // settings route, launcher — so nothing usable outlives the flip.
    if (e.key == defs.lockdownEnabled.key ||
        e.key == defs.lockdownBlackout.key) {
      setState(() {});
      _syncLockdownCover();
      if (e.key == defs.lockdownEnabled.key && e.value == true) {
        if (_drawer.value > 0) _closeDrawer();
        if (_settingsOpen) Navigator.of(context).popUntil((r) => r.isFirst);
        c.launcher.visible.value = false;
        c.intercom.rosterVisible.value = false;
        c.alarms.visible.value = false;
        c.calendar.visible.value = false;
        c.musicLibrary.visible.value = false;
      }
      return;
    }
    // The quick-actions toggles decide whether the locked kiosk mounts the
    // edge swipe at all; revoking the master toggle from the remote admin
    // also takes an open restricted menu away.
    if (e.key.startsWith('kiosk.allow_')) {
      setState(() {});
      if (e.key == defs.kioskAllowDrawer.key &&
          e.value != true &&
          _drawerRestricted &&
          _drawer.value > 0) {
        _closeDrawer();
      }
      return;
    }
    // Drawer menu items (issue #1194) and the Music Assistant address
    // decide which rows the drawer offers, and the drawer is built from
    // here, so a change in the remote admin shows up on the device without
    // waiting for the next rebuild.
    if (e.key == defs.uiDrawerItems.key ||
        e.key == defs.sendspinMaUrl.key ||
        e.key == defs.intercomEnabled.key ||
        e.key == defs.kioskAllowIntercom.key ||
        e.key == defs.kioskAllowAlarms.key ||
        e.key == defs.kioskAllowCalendar.key ||
        e.key == defs.kioskAllowMusicLibrary.key ||
        e.key == defs.remoteEnabled.key ||
        e.key == defs.remoteFleetDiscovery.key) {
      setState(() {});
      return;
    }
    // The secure context proxy changes the page's ORIGIN and its media
    // rewrite user script, both fixed at WebView creation — so the toggle
    // is a WebView rebuild. Await the proxy's own sync first: its listener
    // for this same event races ours, and rebuilding before the server is
    // up would map the URL onto a dead port.
    if (e.key == defs.secureProxy.key) {
      await c.proxy.sync();
      setState(() => _webViewEpoch++);
      return;
    }
    // A start URL on a new Home Assistant origin moves the proxy's upstream
    // (or starts or stops it), and the media rewrite script of the WebView
    // on screen still names the old one. Rebuild when the origin it was
    // created with is no longer the proxied one.
    if (e.key == defs.startUrl.key) {
      await c.proxy.sync();
      if (mounted && c.proxy.targetOrigin != _webViewProxyOrigin) {
        setState(() => _webViewEpoch++);
      }
      return;
    }
    // Pull-to-refresh toggles live on the existing WebView; the clear-cache
    // companion is read at pull time and needs nothing here. The kiosk
    // protection folds into the same effective state.
    if (e.key == defs.pullToRefresh.key ||
        e.key == defs.kioskDisablePullRefresh.key) {
      await _syncPullToRefresh();
      return;
    }
    // Wake word detection is negotiated with the Voice Satellite card at page
    // load (it asks whether we can run its engine natively, and we answer with
    // our own enabled setting). Reload so that handoff is re-evaluated:
    // turning it on hands detection to us, turning it off gives it back to the
    // browser engine.
    if (e.key == defs.wakeWordEnabled.key) {
      await c.browser.runJs('location.reload();');
      return;
    }
    // The satellite seed script is fixed at WebView creation, so a plain
    // reload re-runs the stale one — clearing the binding would be undone
    // at the next document start. Rebuild for fresh user scripts.
    // Where Voice Satellite runs decides whether the dashboard may boot the
    // integration's engine at all (the suppress script below), and user
    // scripts are frozen at WebView creation.
    if (e.key == defs.voiceRuntime.key) {
      setState(() => _webViewEpoch++);
      return;
    }
    if (e.key == defs.haSatelliteEntity.key) {
      setState(() => _webViewEpoch++);
      return;
    }
    // Enabling a media toggle proactively requests its OS grant (Fully-style),
    // then reloads so the page can re-request now that access is allowed.
    if (e.value == true) {
      Permission? permission;
      if (e.key == defs.webMicrophone.key) permission = Permission.microphone;
      if (e.key == defs.webCamera.key) permission = Permission.camera;
      if (e.key == defs.webGeolocation.key) permission = Permission.location;
      if (permission != null) {
        await ensureOsPermission(permission);
        await c.browser.runJs('location.reload();');
      }
    }
  }

  /// The scanner for a plugin's scanBarcode, above every route.
  Future<Map<String, Object?>> _presentScan(
    PluginScanRequest request,
    Future<String> cancel,
  ) async {
    final plugin = c.plugins.installed.value
        .where((p) => p['id'] == request.pluginId)
        .firstOrNull;
    final name = plugin?['name'] as String? ?? request.pluginId;
    final facing = request.facing ?? c.settings.get(defs.cameraDevice);
    final outcome = await Navigator.of(context, rootNavigator: true)
        .push<CodeScanOutcome>(
          MaterialPageRoute(
            builder: (context) => CodeScanner(
              title: request.title ?? l10n(context).pluginScanTitle,
              help: request.message ?? l10n(context).pluginScanHelp,
              source: l10n(context).pluginScanSource(name),
              formats: codeScanFormats(request.formats),
              facing: facing == 'back' ? CameraFacing.back : CameraFacing.front,
              timeout: request.timeout,
              cancel: cancel,
              closeOnError: true,
              screenLight: c.settings.get(defs.cameraScanScreenLight),
              onScreenLight: (on) =>
                  c.settings.set(defs.cameraScanScreenLight, on),
              lightScreen: c.screen.holdScanLight,
            ),
          ),
        );
    return (outcome ?? const CodeScanOutcome.failed('canceled')).toJson();
  }

  @override
  void initState() {
    super.initState();

    // Nothing else says a device fell back to the texture path, and a
    // report from one starts with its log (issue #302).
    if (c.settings.get(defs.legacyWebView)) {
      c.log.info('kiosk', 'legacy WebView renderer: drawing through a texture');
    }
    unawaited(_waitForActivityAttach());
    // The watchdog's step before a process restart: a fresh widget retries
    // the platform-view creation, which heals a create that raced the
    // Activity attach at boot (issue #145).
    _rebuildSub = c.bus.on<WebViewRebuildRequested>().listen((_) {
      if (mounted) {
        c.jsApi.detach();
        setState(() => _webViewEpoch++);
      }
    });
    _missingSub = c.bus.on<WebViewMissing>().listen((_) {
      if (mounted) setState(() {});
    });
    _settingsSub = c.bus.on<SettingChanged>().listen(_onSettingChanged);
    _gestureSub = c.bus.on<KioskExitGesture>().listen(_onExitGesture);
    // A plugin's barcode scan opens over whatever is showing.
    c.plugins.camera?.presenter = _presentScan;
    // Dpad and keyboard navigation (issue #377), registered on both stages
    // of the key pipeline; see _onKey for why it takes two.
    HardwareKeyboard.instance.addHandler(_onKey);
    FocusManager.instance.addEarlyKeyEventHandler(_onEarlyKey);
    // A service call, script, automation or event fired from a gesture
    // changes nothing on this screen, so the toast is the only sign the
    // gesture landed, or the only word on why it did not.
    _gestureResultSub = c.bus.on<GestureActionCompleted>().listen((e) {
      if (!mounted) return;
      // The command's error already names the call the outcome names.
      final error = e.error?.replaceFirst(RegExp(r'^.*? failed: '), '');
      final outcome = localizedGestureOutcome(context, e.action, ok: e.ok);
      showToast(
        context,
        source: 'gestures',
        title: gestureText(context, gestureActionKindTitle(e.action)),
        message: e.ok || error == null || error.isEmpty
            ? outcome
            : '$outcome: $error',
        kind: e.ok ? ToastKind.info : ToastKind.error,
        duration: Duration(seconds: e.ok ? 4 : 6),
      );
    });
    // A restart mid-lockdown (crash self-heal included) must come back with
    // the blackout cover already reported, not wait for a setting to move.
    _syncLockdownCover();
    // The Logs settings page offers the console too; it pops back to the
    // kiosk first, since the panel docks over the live page.
    _consoleReqSub = c.bus.on<WebConsoleRequested>().listen((_) {
      if (mounted) setState(() => _consoleOpen = true);
    });
    // A wake word heard while a rotation excursion covers the dashboard
    // drops the overlay at once, so the Voice Satellite interaction (which
    // lives in the always-loaded dashboard below) is instantly on screen.
    _wakeSub = c.bus.on<WakeWordDetected>().listen((_) {
      c.browser.dismissOverlay();
      c.camera.interruptForVoice();
    });
    _cameraSub = c.bus.on<CameraViewStateChanged>().listen((_) {
      if (mounted) setState(() {});
      _syncNavCapture();
    });
    // The screensaver takes the keys the moment it shows (any of them
    // dismisses it) and hands them back when it goes. The page's swipe and
    // pull gestures stand down with it.
    _saverSub = c.bus.on<ScreensaverStateChanged>().listen((_) {
      _syncNavCapture();
      unawaited(_syncPullToRefresh());
      unawaited(_syncCarousel());
    });
    _backSub = c.bus.on<KioskBackPressed>().listen((_) {
      if (!mounted || _settingsOpen) return;
      _handleBack();
    });
    // A HOME press with the kiosk as the device's home screen and already in
    // front (issue #219): what every launcher's HOME means, close what is
    // open and land on the dashboard. One sweep rather than back's one
    // layer at a time, because HOME is the "get me back" button.
    _homeSub = c.bus.on<HomeKeyPressed>().listen((_) {
      if (!mounted) return;
      if (_drawer.value > 0) _closeDrawer();
      if (_settingsOpen) Navigator.of(context).popUntil((r) => r.isFirst);
      c.launcher.visible.value = false;
      c.intercom.rosterVisible.value = false;
      c.alarms.visible.value = false;
      c.calendar.visible.value = false;
      c.musicLibrary.visible.value = false;
      if (c.browser.overlayUrl.value != null) c.browser.dismissOverlay();
      if (c.camera.activeViewId.value != null) {
        c.camera.hideView(returnToPreviousApp: false);
      }
      unawaited(c.commands.execute('stopScreensaver', const {}));
    });
    // The volume key routing follows the player and the screensaver
    // slot (issue #544); the setting rides _onSettingChanged.
    c.sendspin.nowPlaying.addListener(_syncVolumeKeys);
    c.pageState.pageDark.addListener(_pageDarkChanged);
    c.screensaver.activeView.addListener(_syncVolumeKeys);
    c.screensaver.dashboardShowing.addListener(_applyKioskMode);
    // The build and the native key routing both follow these surfaces.
    c.browser.overlayUrl.addListener(_onOverlayChanged);
    c.launcher.visible.addListener(_onOverlayChanged);
    c.intercom.rosterVisible.addListener(_onOverlayChanged);
    c.alarms.visible.addListener(_onOverlayChanged);
    c.calendar.visible.addListener(_onOverlayChanged);
    c.musicLibrary.visible.addListener(_onOverlayChanged);
    c.plugins.windows.addListener(_onOverlayChanged);
    c.plugins.installed.addListener(_onOverlayChanged);
    c.homeLauncher.roleHeld.addListener(_onOverlayChanged);
    c.plugins.contentInsets.addListener(_syncContentInsets);
    _syncContentInsets();

    // Download feedback lives in-app: the kiosk hides the status bar, so the
    // DownloadManager notification is invisible and without this a download
    // simply appears to do nothing.
    BackgroundListening.onDownloadComplete = (id, success, filename) {
      if (!mounted) return;
      final name = (filename == null || filename.isEmpty)
          ? l10n(context).kioskDownload
          : filename;
      if (success) {
        showToast(
          context,
          source: 'downloads',
          title: l10n(context).kioskDownloadComplete,
          message: name,
          kind: ToastKind.success,
          duration: const Duration(seconds: 10),
          actionLabel: l10n(context).kioskOpen,
          onAction: () => BackgroundListening.openDownload(id),
        );
      } else {
        showToast(
          context,
          source: 'downloads',
          title: l10n(context).kioskDownloadFailed,
          message: name,
          kind: ToastKind.error,
          duration: const Duration(seconds: 6),
        );
      }
    };

    if (widget.showMenuHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showToast(
          context,
          title: l10n(context).kioskTip,
          message: l10n(context).kioskMenuHint,
          duration: const Duration(seconds: 10),
        );
      });
    }
  }

  /// Open the WebView gate once the Activity is attached to the engine.
  /// Quick polls while the attach is imminent (a cold boot), slower ones
  /// for a process idling headless — there the gate staying shut is the
  /// point, since a platform view created without an Activity just dies.
  Future<void> _waitForActivityAttach() async {
    var tries = 0;
    while (mounted) {
      var attached = true;
      try {
        attached = await BackgroundListening.isActivityAttached();
      } catch (e) {
        // Fail open: a broken probe must degrade to today's behavior, not
        // hold the dashboard hostage.
        c.log.warn('kiosk', 'activity-attach probe failed: $e');
      }
      if (attached) break;
      tries++;
      await Future<void>.delayed(
        tries < 50
            ? const Duration(milliseconds: 100)
            : const Duration(seconds: 1),
      );
    }
    if (mounted) setState(() => _activityAttached = true);
  }

  /// The space plugins keep clear of their bars, in dp, as the page's CSS
  /// pixels: the Zoom level scales the page, so one CSS pixel spans that
  /// many dp. Plugins measure in their own dp, which the Scale UI factor
  /// enlarges like their overlays.
  void _syncContentInsets() {
    final zoom = c.settings.get(defs.browserZoom).toDouble();
    final dp =
        c.plugins.contentInsets.value *
        uiScaleFactor(c.settings.get(defs.uiScale));
    unawaited(c.browser.setContentInsets(zoom > 0 ? dp / zoom : dp));
  }

  /// The zoom-level setting as a viewport-meta scale, see
  /// viewport_zoom_script.dart for why not CSS zoom.
  String get _zoomJs => viewportZoomJs(
    zoom: c.settings.get(defs.browserZoom),
    pinch: c.settings.get(defs.pinchToZoom),
  );

  /// The scroll lock, as page CSS rather than the plugin's native
  /// disable-scroll flags: those swallow every touch-move at the view layer,
  /// which also starves the pull-to-refresh probe and any in-page drag (an
  /// HA slider). `touch-action` only withdraws the browser's own panning —
  /// touch events still dispatch to the page and the native gesture
  /// detectors, so pulls, taps and drags keep working. The wildcard matters:
  /// HA scrolls inner shadow-root containers, and a rule on `html` alone
  /// would not reach them. `pinch-zoom` (not `none`) so the pinch setting
  /// still composes.
  String get _scrollLockJs {
    final on = c.settings.get(defs.disableScrolling);
    return '''
      (function () {
        var st = document.getElementById('__ksScrollLock');
        if ($on && !st) {
          st = document.createElement('style');
          st.id = '__ksScrollLock';
          st.textContent = '* { touch-action: pinch-zoom !important; }';
          (document.head || document.documentElement).appendChild(st);
        } else if (!$on && st) {
          st.remove();
        }
      })();
    ''';
  }

  String get _initialUrl => c.settings.get(defs.startUrl);

  /// The kiosk went light or dark: a custom page on screen, and the next
  /// one, follow.
  void _pageDarkChanged() =>
      unawaited(c.browser.setCustomPageDark(c.pageState.pageDark.value));

  /// The JS bridge is always injected at document start. Kiosk mode rides
  /// along as a document-start script too, and is re-asserted per load in
  /// [onLoadStop] so a page that outlived a toggle catches up.
  List<UserScript> get _userScripts => [
    c.jsApi.buildUserScript(c.device.os),
    // With the proxy on, Home Assistant's absolute URLs (TTS audio,
    // announcement media) point at its own origin while the page lives on
    // loopback; Web-Audio-tapped media then plays as CORS-tainted silence.
    // The rewrite keeps everything same-origin. Frozen at WebView creation
    // like every user script — the proxy toggle rebuilds the WebView.
    if (c.proxy.running)
      UserScript(
        source: proxyMediaRewriteScript(
          targetOrigin: c.proxy.targetOrigin!,
          loopbackOrigin: c.proxy.loopbackOrigin!,
        ),
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    // "Disable cache" must also defeat the page's service worker, which
    // caches above the HTTP layer (HA always registers one).
    if (c.settings.get(defs.disableCache))
      UserScript(
        source: noCachePurgeScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    // Always injected, acted on only while the setting is on (checked in
    // _triggerRefresh) — so the toggle needs no page reload to take effect.
    // The flag stops the disc from drawing while off; it is seeded here
    // (frozen at WebView creation), corrected live in _onSettingChanged,
    // and re-asserted every load in onLoadStop for pages loaded after a
    // toggle.
    // A custom page's prefers-color-scheme answers with the kiosk's light
    // or dark (PageStateManager.pageDark), for matchMedia and its CSS. Acts
    // only on custom pages; swapped live by BrowserManager.setCustomPageDark.
    UserScript(
      groupName: BrowserManager.customPageSchemeGroup,
      source: customPageColorSchemeJs(
        dark: c.pageState.pageDark.value,
        origins: c.browser.customPageOrigins,
      ),
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    UserScript(
      source: 'window.__ksPtrEnabled = $_ptrEnabled;',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    UserScript(
      source: pullToRefreshProbeScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // Hides the freeze from the page: while the dashboard is INVISIBLE under
    // the screensaver it keeps reporting itself visible, so web apps do not
    // tear their session down over an optimization they cannot see. Always
    // injected, and only ever masking while BrowserManager says so.
    UserScript(
      source: visibilityMaskScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    UserScript(
      source:
          dashboardCameraScript +
          pauseDashboardCamerasJs(c.browser.dashboardCameraStreamsPaused),
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      forMainFrameOnly: true,
    ),
    // Kiosk mode hides Home Assistant's own header and sidebar. It has to be
    // in place before the frontend builds anything, since it catches shadow
    // roots as they are created; it acts only while its flags say so, which
    // is what lets the toggle apply without a reload.
    UserScript(
      source: kioskModeScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // The room plugins reserve for their bars. A group of its own, so
    // BrowserManager can swap it when a plugin changes it and every new
    // page starts with the current value.
    UserScript(
      groupName: BrowserManager.contentInsetsGroup,
      source: c.browser.contentInsetsSource,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // The URL Filter's rules for the dashboard, which keep Home
    // Assistant's own routing (pushState) off the blocked pages. A group of
    // its own, swapped by BrowserManager when the rules change.
    UserScript(
      groupName: BrowserManager.urlFilterGroup,
      source: c.browser.urlFilterSource(urlFilterDashboard),
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    UserScript(
      source: _kioskModeJs,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // Reports the Home Assistant socket closing, so a dashboard that is not
    // allowed to reconnect is repaired in seconds rather than at the
    // watchdog's next poll. Always injected: it is not an optimization, and
    // it has to work with the ws filter off.
    UserScript(
      source: haSocketWatchScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // Reports the moments the dashboard set can have moved (a dashboard
    // created, deleted or edited, the connection back after an outage), so
    // the dashboard view selects re-read their options then and never on
    // a timer (see dashboards_watch_script).
    UserScript(
      source: haDashboardsWatchScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // The dashboard carousel rides the same contract as the pull probe:
    // always injected, acted on only while its flag is on, so the toggle
    // needs no reload.
    UserScript(
      source:
          'window.__ksCarouselEnabled = $_carouselEnabled;'
          'window.__ksCarouselOverCards = '
          '${c.settings.get(defs.haCarouselOverCards)};',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    UserScript(
      source: dashboardCarouselScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // Haptics and the tap sound: same always-injected, flag-gated contract.
    UserScript(
      source:
          'window.__ksHapticsEnabled = '
          '${c.settings.get(defs.haHaptics)};'
          'window.__ksTapSoundEnabled = '
          '${c.settings.get(defs.haTapSound)};',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    UserScript(
      source: buttonHapticsScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // Turn off Home Assistant's "Suspend background connections" so it does
    // not deliberately drop the kiosk's socket after 5 minutes off screen.
    if (c.settings.get(defs.disableSuspend))
      UserScript(
        source: disableSuspendScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    // Filter the entity-update firehose to the current view so
    // low-powered tablets stop doing work for entities they do not show.
    if (c.settings.get(defs.wsFilter))
      UserScript(
        source: wsFilterScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    // Auto-login (ha.auto_login): hand the frontend a session built from
    // the long-lived access token, so the dashboard signs itself in
    // instead of presenting the login form. Only seeded while the page
    // has no session of its own — a login someone did by hand, or a
    // session the frontend refreshed, always wins; a session this seed
    // wrote for an earlier token is replaced. Frozen at WebView creation;
    // the toggle and a token change rebuild the WebView (_onSettingChanged).
    if (c.settings.get(defs.haAutoLogin) &&
        c.settings.get(defs.haToken).trim().isNotEmpty)
      UserScript(
        source: buildHaAutoLoginScript(
          token: c.settings.get(defs.haToken),
          replace: _autoLoginReplace,
        )!,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    // Off, the seeded session goes too, so the page asks for a login.
    if (!c.settings.get(defs.haAutoLogin))
      UserScript(
        source: haAutoLoginClearScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    // The wizard's satellite choice, handed to Voice Satellite before its
    // code runs: VS reads localStorage['vs-satellite-entity'], selects that
    // assist_satellite, hydrates its server-side profile and starts. Only
    // seeded while the key is absent — a satellite changed in the page
    // afterwards must win over a stale wizard choice.
    // Native Voice Satellite owns the satellite: the integration's engine
    // must never boot here, dashboard included, even while the integration
    // is still installed (see vs_suppress_script).
    if (c.voice.suppressPageEngine)
      UserScript(
        source: vsSuppressScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    if (!c.voice.suppressPageEngine &&
        c.settings.get(defs.haSatelliteEntity).isNotEmpty)
      UserScript(
        source:
            '''
          try {
            if (!localStorage.getItem('vs-satellite-entity')) {
              localStorage.setItem('vs-satellite-entity',
                ${jsonEncode(c.settings.get(defs.haSatelliteEntity))});
            }
          } catch (_) {}
        ''',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    // Belt to disableContextMenu's braces: the native flag stops the action
    // mode, this stops the selection ever forming (and the web contextmenu).
    if (c.kiosk.locked && c.settings.get(defs.kioskDisableContextMenus))
      UserScript(
        source: '''
          document.addEventListener('contextmenu', (e) => e.preventDefault(), true);
          const s = document.createElement('style');
          s.textContent = '* { -webkit-user-select: none !important; user-select: none !important; }';
          document.addEventListener('DOMContentLoaded', () => document.head.appendChild(s));
        ''',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
  ];

  /// Kiosk mode as the page should have it now. The Home Assistant
  /// Dashboard screensaver can hide its own choice of header and sidebar
  /// while it shows (issue #1183), whatever HA kiosk mode says.
  String get _kioskModeJs {
    final s = c.settings;
    if (c.screensaver.dashboardShowing.value &&
        s.get(defs.screensaverDashboardKiosk)) {
      return kioskModeApplyJs(
        apply: true,
        hideHeader: s.get(defs.screensaverDashboardHideHeader),
        hideSidebar: s.get(defs.screensaverDashboardHideSidebar),
      );
    }
    return kioskModeApplyJs(
      apply: s.get(defs.haKioskMode),
      hideHeader: s.get(defs.haKioskHideHeader),
      hideSidebar: s.get(defs.haKioskHideSidebar),
    );
  }

  /// Apply or tear down kiosk mode against the current page.
  Future<void> _applyKioskMode() async {
    await c.browser.runJs(_kioskModeJs);
  }

  /// Open the settings screen (One UI-style split view on wide screens).
  Future<void> _openSettings() async {
    // Hold the screensaver while settings are open. Otherwise the idle timer
    // keeps firing behind the route: it dims the backlight and, with motion
    // on, opens the camera while someone is configuring. Re-arm on return.
    await c.commands.execute('pauseScreensaver', {'paused': true});
    _settingsOpen = true;
    _syncMenuBusy();
    if (mounted) {
      // The settings route fully covers the dashboard, so its WebView can
      // stop compositing and hand the frame budget to the settings UI.
      // Report cover only once the push transition has finished (a frozen
      // view draws nothing, and the dashboard is still visible mid-slide)
      // and thaw the moment the pop starts, so the reveal is never blank.
      final route = MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(container: c),
      );
      final pushed = Navigator.of(context).push(route);
      route.animation?.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          c.browser.setCovered('settings', covered: true);
        } else if (status == AnimationStatus.reverse) {
          c.browser.setCovered('settings', covered: false);
        }
      });
      await pushed;
      // Covers pops that skip the reverse animation.
      c.browser.setCovered('settings', covered: false);
    }
    _settingsOpen = false;
    _syncMenuBusy();
    await c.commands.execute('pauseScreensaver', {'paused': false});
  }

  /// Tell the kiosk manager whether the owner is inside the menu or the
  /// settings: pauses caused from there (permission grant screens, system
  /// pickers) are legitimate, and the foreground reclaim stands down.
  void _syncMenuBusy() {
    c.kiosk.menuBusy = _settingsOpen || _drawer.value > 0;
    // However the drawer closed — key, tap, swipe, the kiosk taking the
    // screen back — focus must not stay on an entry that just left the
    // screen: the next arrow press would walk an invisible menu.
    if (_drawer.value == 0 && _drawerFocus.hasFocus) _drawerFocus.unfocus();
    _syncNavCapture();
  }

  /// Push whether Flutter wants the dpad/arrow keys right now (issue
  /// #377). While nothing here navigates, MainActivity hands them to the
  /// dashboard WebView instead, so the page keeps scrolling and its own
  /// key handling; the moment a surface of ours is up, they come here.
  /// Diffed — every caller is a state listener that fires often.
  bool? _lastNavCapture;
  void _syncNavCapture() {
    // The volume key routing rides the same state changes.
    _syncVolumeKeys();
    final capture =
        _settingsOpen ||
        !(ModalRoute.of(context)?.isCurrent ?? true) ||
        _drawer.value > 0 ||
        c.screensaver.isActive ||
        c.kiosk.lockdownActive ||
        c.launcher.visible.value ||
        c.intercom.rosterVisible.value ||
        c.alarms.visible.value ||
        c.calendar.visible.value ||
        c.musicLibrary.visible.value ||
        c.camera.activeViewId.value != null ||
        c.plugins.windows.value.isNotEmpty;
    if (capture == _lastNavCapture) return;
    _lastNavCapture = capture;
    unawaited(c.kiosk.setNavCapture(capture));
  }

  /// Push whether the hardware volume keys steer the followed media
  /// player right now (issue #544): the setting's mode against what is
  /// on screen and playing. Diffed like the nav capture.
  bool? _lastVolumeKeys;
  void _syncVolumeKeys() {
    final active = c.sendspin.volumeKeysWanted(
      viewShown: c.screensaver.nowPlayingShowing,
    );
    if (active == _lastVolumeKeys) return;
    _lastVolumeKeys = active;
    unawaited(c.kiosk.setVolumeKeys(active));
  }

  /// The dpad, arrow and select keys MainActivity routes into Flutter
  /// (issue #377), plus whatever a physical keyboard sends on its own.
  static final _navKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  static final _volumeKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.audioVolumeUp,
    LogicalKeyboardKey.audioVolumeDown,
    LogicalKeyboardKey.audioVolumeMute,
  };

  /// One decision per key event, replayed to whichever pipeline stage asks
  /// second (issue #377). The HardwareKeyboard handler sees every key even
  /// when nothing in Flutter holds focus — the state a TV box idles in, and
  /// exactly when the drawer must still open. The early FocusManager
  /// handler sees the same event object again a moment later, and its
  /// verdict is the one that actually stops the framework's shortcuts from
  /// double-acting (a HardwareKeyboard handler's result never reaches the
  /// focus system).
  KeyEvent? _decidedKey;
  bool _keyHandled = false;

  bool _onKey(KeyEvent event) {
    if (identical(event, _decidedKey)) return _keyHandled;
    _decidedKey = event;
    _keyHandled = _decideKey(event);
    return _keyHandled;
  }

  KeyEventResult _onEarlyKey(KeyEvent event) =>
      _onKey(event) ? KeyEventResult.handled : KeyEventResult.ignored;

  bool _decideKey(KeyEvent event) {
    if (event is KeyUpEvent) return false;
    final key = event.logicalKey;
    final nav = _navKeys.contains(key);
    // Under lockdown no key does anything — not even count as activity —
    // exactly as the shield keeps a touch from doing either.
    if (c.kiosk.lockdownActive) return nav;
    // A key press is activity like a touch is: it resets the idle clock
    // and dismisses a showing screensaver. Repeats from a held key are not
    // new activity, and volume stays out — nudging the volume during a
    // night screensaver should not light the room. A press that is
    // driving the menu or the settings restarts the idle clock but sends
    // no ping: the ping is delivered on the event bus a beat after the
    // press acts, so the very key that activates "Start Screensaver"
    // would race the start it commanded and dismiss it mid-flight. A
    // screensaver already showing takes the ping whatever sits open under
    // it — dismissal is the point then.
    final drivingUi =
        (_settingsOpen || _drawer.value > 0) && !c.screensaver.isActive;
    if (event is KeyDownEvent && !_volumeKeys.contains(key)) {
      if (drivingUi) {
        c.screensaver.extendIdle();
      } else {
        c.bus.publish(const ActivityDetected(source: 'key'));
      }
    }
    if (!nav) return false;
    // A focused slider answers to every arrow, vertical included, so up
    // and down could never leave its row: this handler runs ahead of the
    // slider's own shortcuts, and turns the vertical arrows back into
    // traversal. Left and right stay with the slider — adjusting is what
    // a focused slider is for. Applies wherever the slider lives; the
    // settings pages are full of them.
    final vertical = key == LogicalKeyboardKey.arrowUp
        ? TraversalDirection.up
        : key == LogicalKeyboardKey.arrowDown
        ? TraversalDirection.down
        : null;
    if (vertical != null) {
      final focus = FocusManager.instance.primaryFocus;
      if (focus?.context?.findAncestorWidgetOfExactType<Slider>() != null) {
        focus!.focusInDirection(vertical);
        return true;
      }
    }
    switch (decideNavKey(
      lockdown: false,
      screensaverActive: c.screensaver.isActive,
      nowPlayingControls: c.screensaver.nowPlayingControlsUp,
      overlayUp:
          c.launcher.visible.value ||
          c.intercom.rosterVisible.value ||
          c.alarms.visible.value ||
          c.calendar.visible.value ||
          c.musicLibrary.visible.value ||
          c.browser.overlayUrl.value != null ||
          c.camera.activeViewId.value != null,
      // Any route above this one: settings, and every dialog — the exit
      // confirm, the PIN prompt, a picker.
      routeCovered:
          _settingsOpen || !(ModalRoute.of(context)?.isCurrent ?? true),
      drawerOpen: _drawer.value > 0,
      drawerFocused: _drawerFocus.hasFocus,
    )) {
      case KeyNavAction.pass:
        return false;
      case KeyNavAction.swallow:
        return true;
      case KeyNavAction.focusDrawer:
        _focusDrawer();
        return true;
    }
  }

  /// Move focus onto the drawer's first entry, next frame — the pane must
  /// have rebuilt out of its focus-excluded closed state first.
  void _focusDrawer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _drawer.status == AnimationStatus.dismissed) return;
      _drawerFocus.requestFocus();
      // nextFocus, not a directional search: reading order starts at the
      // menu's first entry, where a directional bootstrap picked whichever
      // row its geometry liked best.
      _drawerFocus.nextFocus();
    });
  }

  /// The kiosk exit gesture: N fast taps (optionally holding the last),
  /// counted natively so they land even though the WebView swallows its
  /// pointers. PIN first when one is set; the prize is just the menu —
  /// every escape route stays behind its own confirmation.
  /// Blackout lockdown is an opaque cover over the dashboard; report it so
  /// the WebView stops compositing underneath, same as the settings route
  /// and the camera/DLNA overlays. The transparent shield must NOT freeze
  /// the page — a glanceable locked dashboard is the whole point.
  void _syncLockdownCover() {
    c.browser.setCovered(
      'lockdown',
      covered:
          c.settings.get(defs.lockdownEnabled) &&
          c.settings.get(defs.lockdownBlackout),
    );
  }

  Future<void> _onExitGesture(KioskExitGesture _) async {
    if (!mounted || _settingsOpen || _drawer.value > 0) return;
    // Under lockdown the armed gesture is lockdown's own, and the prize is
    // not the menu but the mode's end — behind the kiosk PIN, exactly as
    // the menu would be. The shields never swallow the taps: they are
    // counted natively, at the screen-level overlay when it is up and at
    // the Activity otherwise. The PIN dialog lives underneath that
    // overlay, so it lets touches through for the prompt's duration.
    if (c.kiosk.lockdownActive) {
      if (c.kiosk.pinRequired) {
        await c.kiosk.setLockShieldPassThrough(true);
        final ok = await _askPin();
        await c.kiosk.setLockShieldPassThrough(false);
        if (!ok || !mounted) return;
      }
      await c.settings.set(defs.lockdownEnabled, false);
      return;
    }
    if (c.kiosk.pinRequired) {
      final ok = await _askPin();
      if (!ok || !mounted) return;
    }
    setState(() => _drawerRestricted = false);
    _drawer.fling(velocity: 1);
  }

  Future<bool> _askPin() async {
    final controller = TextEditingController();
    var failed = false;
    final route = DialogRoute<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(kioskText(context, "Kiosk PIN")),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: kioskText(context, "PIN"),
              errorText: failed ? kioskText(context, "Wrong PIN") : null,
            ),
            onSubmitted: (v) {
              if (c.kiosk.pinMatches(v)) {
                Navigator.pop(context, true);
              } else {
                setDialogState(() => failed = true);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(kioskText(context, "Cancel")),
            ),
            FilledButton(
              onPressed: () {
                if (c.kiosk.pinMatches(controller.text)) {
                  Navigator.pop(context, true);
                } else {
                  setDialogState(() => failed = true);
                }
              },
              child: Text(kioskText(context, "Unlock")),
            ),
          ],
        ),
      ),
    );
    final ok = await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    controller.dispose();
    return ok ?? false;
  }

  @override
  void dispose() {
    BackgroundListening.onDownloadComplete = null;
    if (c.plugins.camera?.presenter == _presentScan) {
      c.plugins.camera?.presenter = null;
    }
    c.jsApi.detach();
    _refreshingFailsafe?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    FocusManager.instance.removeEarlyKeyEventHandler(_onEarlyKey);
    _drawerFocus.dispose();
    _drawer.dispose();
    _settingsSub?.cancel();
    _gestureSub?.cancel();
    _gestureResultSub?.cancel();
    _consoleReqSub?.cancel();
    _rebuildSub?.cancel();
    _missingSub?.cancel();
    _backSub?.cancel();
    _homeSub?.cancel();
    _wakeSub?.cancel();
    kioskRouteObserver.unsubscribe(this);
    _cameraSub?.cancel();
    _saverSub?.cancel();
    c.sendspin.nowPlaying.removeListener(_syncVolumeKeys);
    c.pageState.pageDark.removeListener(_pageDarkChanged);
    c.screensaver.activeView.removeListener(_syncVolumeKeys);
    c.screensaver.dashboardShowing.removeListener(_applyKioskMode);
    c.browser.overlayUrl.removeListener(_onOverlayChanged);
    c.launcher.visible.removeListener(_onOverlayChanged);
    c.intercom.rosterVisible.removeListener(_onOverlayChanged);
    c.alarms.visible.removeListener(_onOverlayChanged);
    c.calendar.visible.removeListener(_onOverlayChanged);
    c.musicLibrary.visible.removeListener(_onOverlayChanged);
    c.plugins.windows.removeListener(_onOverlayChanged);
    c.plugins.installed.removeListener(_onOverlayChanged);
    c.homeLauncher.roleHeld.removeListener(_onOverlayChanged);
    c.plugins.contentInsets.removeListener(_syncContentInsets);
    super.dispose();
  }

  void _onOverlayChanged() {
    if (mounted) setState(() {});
    _syncNavCapture();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // One physical pixel of overdraw on the kiosk plane. On displays whose
    // density is not a clean multiple of 160 (Tab S9: 340dpi, ratio 2.125)
    // the logical screen size is a repeating fraction, and converting it
    // back to physical pixels lands just under the true size (1600 becomes
    // 1599.9999...), which the engine floors: the WebView's platform view
    // ends up one pixel short and the scaffold's black shows as a hairline
    // at that edge. Oversizing by one physical pixel guarantees the floor
    // lands past the screen edge; the overhang is clipped by the window
    // (the Stack below deliberately does not clip, see clipBehavior).
    final overdraw = 1 / MediaQuery.devicePixelRatioOf(context);
    // Built once per build(), NOT once per animation tick. The
    // AnimatedBuilder below runs its builder every frame of the drawer
    // slide; the planes themselves never change during it — only their
    // positions do. Rebuilding the WebView widget (and re-reading every
    // initialSettings value) per frame would be pure waste, spent at the
    // exact moment the platform view is being moved.
    final kioskPlane = Stack(
      // Expand: the Stack takes its size from its parent, never from its
      // children — the overlays are positioned or zero-sized and would
      // collapse a child-sized Stack.
      fit: StackFit.expand,
      children: [
        // Held back until the Activity attach (the scaffold's black shows,
        // exactly what the splash was showing); see _waitForActivityAttach.
        // Exempt from the Scale UI factor: the dashboard has its own zoom
        // setting, and scaling the platform view would reflow and blur it.
        if (_activityAttached && !c.browser.webViewMissing)
          UiScaleExempt(child: _webView()),
        // Directly over the dashboard: it hides Chromium's error page, and
        // everything below in this list (an overlay page, the player) is
        // content that belongs on top of the dashboard, error or not.
        OfflineNotice(container: c),
        // Over the offline cover too: with no WebView provider there is no
        // page to wait for, and the cover would hide the only explanation.
        if (c.browser.webViewMissing) const _WebViewMissingNotice(),
        // DuraSpeed refusing the renderer: the WebView stays mounted
        // underneath, still retrying, and the notice says what to do.
        ValueListenableBuilder<bool>(
          valueListenable: c.browser.duraSpeedBlocking,
          builder: (context, blocking, _) => blocking
              ? const _WebViewMissingNotice(duraSpeed: true)
              : const SizedBox.shrink(),
        ),
        // The rotation's external pages, shown OVER the dashboard so the
        // dashboard (and the Voice Satellite session with it) never
        // unloads. A wake detection hides this instantly, revealing the
        // live dashboard underneath (see initState).
        _OverlayHost(container: c),
        PluginOverlay(plugins: c.plugins),
        SendspinPlayerOverlay(container: c),
        if (_consoleOpen)
          WebConsolePanel(
            browser: c.browser,
            onClose: () => setState(() => _consoleOpen = false),
          ),
      ],
    );
    // A horizontal drag anywhere on the drawer moves it too — swiping the
    // menu itself closed is the intuitive gesture, not just swiping the
    // kiosk. Taps and vertical scrolling inside the menu are untouched
    // (different gesture axes).
    final drawerPane = FocusScope(
      node: _drawerFocus,
      child: GestureDetector(
        onHorizontalDragUpdate: _drawerDragUpdate,
        onHorizontalDragEnd: _drawerDragEnd,
        child: KioskDrawer(
          container: c,
          onClose: _closeDrawer,
          onSettings: _openSettings,
          restricted: _drawerRestricted,
        ),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (_) =>
            c.bus.publish(const ActivityDetected(source: 'touch')),
        child: AnimatedBuilder(
          animation: _drawer,
          builder: (context, _) {
            final dx = _drawerWidth * _drawer.value;
            final open = _drawer.value > 0;
            return PopScope(
              // Back is never left to the default pop. Over the bare kiosk
              // the first press opens the menu instead (discussion #312:
              // the OS back gesture owns the left edge on gesture
              // navigation devices, so the menu swipe arrives as a back
              // press), and everything else back does — close a layer,
              // step the page's history, leave the app — runs through the
              // one ladder in _handleBack, which knows kiosk mode and the
              // home role must never background the app (issue #219): a
              // home screen never finishes on back, and letting the pop
              // through either fell to the task below (a Meta Portal's
              // still-running launcher) or had the system tear down and
              // relaunch the home Activity on every press. This is the
              // predictive-back path; devices that still deliver Back as
              // a KeyEvent are caught in KioskLock before it ever reaches
              // here, and land in the same ladder via KioskBackPressed.
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                _handleBack();
              },
              child: Stack(
                fit: StackFit.expand,
                // No clip: the default hard-edge clip is floored to whole
                // logical pixels when the engine applies it to the WebView's
                // platform view, which on fractional-ratio displays (Echo
                // Show, 1.21875) shaved the last physical pixel off the right
                // and bottom edges. Nothing here needs clipping - every child
                // either fills the screen or slides fully off it.
                clipBehavior: Clip.none,
                children: [
                  // The kiosk plane, pushed right in step with the drawer.
                  // It keeps its full size — it slides, it is never squeezed
                  // (resizing the platform view would reflow the page).
                  Positioned(
                    left: dx,
                    top: 0,
                    width: size.width + overdraw,
                    height: size.height + overdraw,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: c.screensaver.activeView,
                      child: kioskPlane,
                      builder: (context, view, child) =>
                          ValueListenableBuilder<bool>(
                            valueListenable: c.browser.renderingFrozenState,
                            child: child,
                            builder: (context, frozen, child) =>
                                ValueListenableBuilder<bool>(
                                  valueListenable: c.voice.covers,
                                  child: child,
                                  // Skip platform view compositing only after
                                  // the browser confirms it is safe to hide
                                  // the dashboard: under the two screensavers
                                  // that draw every frame, and under a voice
                                  // turn whose backdrop hides the screen.
                                  builder: (context, covers, child) => Offstage(
                                    offstage:
                                        (view == 'weather_mood' ||
                                            view == 'celestial' ||
                                            covers) &&
                                        frozen,
                                    child: child,
                                  ),
                                ),
                          ),
                    ),
                  ),
                  // The drawer plane, sliding in from the same seam. While
                  // fully closed its entries sit just offscreen, still
                  // built: without the exclusion a directional focus search
                  // (issue #377) would happily land on them. Status, not
                  // value, so the pane is focusable the instant an open
                  // begins — _focusDrawer runs before the first tick moves
                  // the value off zero.
                  Positioned(
                    left: dx - _drawerWidth,
                    top: 0,
                    bottom: 0,
                    width: _drawerWidth,
                    child: ExcludeFocus(
                      excluding: _drawer.status == AnimationStatus.dismissed,
                      child: drawerPane,
                    ),
                  ),
                  // While open, the visible slice of the kiosk closes the
                  // drawer on tap or drag — no scrim: dimming the content
                  // would put the drawer visually "above" it again.
                  if (open)
                    Positioned(
                      left: dx,
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeDrawer,
                        onHorizontalDragUpdate: _drawerDragUpdate,
                        onHorizontalDragEnd: _drawerDragEnd,
                      ),
                    ),
                  // Closed: the edge strip that swipes it open — unless
                  // kiosk mode holds the door; then only the exit gesture
                  // (and its PIN) opens the menu, or, when the owner opted
                  // into quick actions, the same swipe opens the restricted
                  // one (which mode is decided as the drag starts).
                  if (!open && (!c.kiosk.locked || _quickMenuAvailable))
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 48,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragStart: (_) {
                          if (_drawerRestricted != c.kiosk.locked) {
                            setState(() => _drawerRestricted = c.kiosk.locked);
                          }
                        },
                        onHorizontalDragUpdate: _drawerDragUpdate,
                        onHorizontalDragEnd: _drawerDragEnd,
                      ),
                    ),
                  // Over both planes (the drawer included — an outage is
                  // just as true with the menu open), and under every
                  // full-screen overlay below, which owns the display while
                  // it is up.
                  NetworkToast(container: c),
                  // Media pushed over DLNA covers both planes like the
                  // screensaver does; the screensaver stays away while it
                  // plays (playback reports activity).
                  DlnaMediaOverlay(container: c),
                  // Below the screensaver: an abandoned launcher gives way
                  // to it (the manager also closes on screensaver start).
                  AppLauncherOverlay(container: c),
                  // The intercom's Call a kiosk screen, the launcher's
                  // twin: full screen, below the screensaver, closed by
                  // the manager when a call starts.
                  IntercomRosterOverlay(container: c),
                  // The alarm list, the launcher's twin again: full
                  // screen, below the screensaver.
                  AlarmsOverlay(container: c),
                  // The family calendar, the launcher's twin as well:
                  // full screen, below the screensaver.
                  CalendarOverlay(container: c),
                  // The music library, the same kind of page: full
                  // screen, below the screensaver, so Now Playing opened
                  // from its player bar comes up over it.
                  MusicLibraryOverlay(container: c),
                  // The screensaver covers both planes — it owns the whole
                  // display, drawer open or not.
                  // Paused under the native voice overlay, which
                  // draws over it instead of dismissing it.
                  PausedUnder(
                    paused: c.screensaver.renderPaused,
                    child: ScreensaverOverlay(container: c),
                  ),
                  CameraViewOverlay(container: c),
                  // The camera preview a face wake leaves behind
                  // (discussion #371): over the screensaver, whose fade
                  // out it appears through, and answering no touch.
                  FacePreviewOverlay(motion: c.motion, settings: c.settings),
                  // The black timeout cover while a voice turn shows: the
                  // turn draws over it (issue #746). Outside a turn it
                  // sits above everything below.
                  ScreensaverBlankOverlay(container: c, underVoice: true),
                  // A turn a plugin skin draws: double tap dismisses it.
                  AssistPluginSkinTouch(container: c),
                  // Plugin overlays that asked to be on top, in the voice
                  // overlay's slot: over the screensaver, the menu and the
                  // camera views, under a notification or call card, the
                  // voice overlay itself and the lockdown shield. During a
                  // turn they are over the black cover too, so a plugin
                  // skin draws the turn there. The rest live in the kiosk
                  // plane.
                  PluginNativeOverlays(plugins: c.plugins, onTop: true),
                  // Above every overlay a notification could arrive
                  // behind (the screensaver, a camera wall, a plugin drawn
                  // on top) because a message from the house is worth
                  // covering them for, and below the lockdown shield,
                  // which is the one thing whose whole job is that nothing
                  // here answers a touch.
                  NotificationOverlay(notifications: c.notifications),
                  // The intercom's call card: over the screensaver and a
                  // camera wall like a notification, since a call coming
                  // in wakes the screen for exactly this, and under the
                  // lockdown shield, whose kiosk answers as Do not disturb.
                  IntercomCallOverlay(container: c),
                  // An announcement from Home Assistant: its own card, with
                  // the spoken text, in the same slot.
                  AnnouncementOverlay(container: c),
                  // Native Voice Satellite: the assist overlay, in the same
                  // slot, over the screensaver and the camera views.
                  AssistOverlay(container: c),
                  // The timer pills stay over the voice overlay, as Voice
                  // Satellite stacks them over its own.
                  VoiceTimerOverlay(container: c),
                  ScreensaverBlankOverlay(container: c),
                  // Lockdown Mode's touch shield: topmost, above every
                  // overlay, so nothing on screen is tappable while it
                  // holds. Transparent by default — the dashboard stays
                  // glanceable, it just stops answering — or solid black
                  // with the blackout toggle. The exit gesture still works:
                  // its taps are counted natively before Flutter sees them.
                  if (c.kiosk.lockdownActive)
                    LockdownShield(
                      blackout: c.settings.get(defs.lockdownBlackout),
                    ),
                  // An alarm on its own view: over everything, the lockdown
                  // shield included, since Stop has to answer. Its sunrise
                  // covers the screensaver and the dark panel too.
                  AlarmRingOverlay(container: c),
                  // A fleet invitation: above the shield, since answering
                  // it is an admin act the shield must not swallow.
                  FleetInviteOverlay(container: c),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// The page a (re)built WebView opens: the start URL for the first build,
  /// while nothing has loaded yet, or when the rebuild asked for it;
  /// otherwise the page that was showing.
  String _rebuildUrl() {
    final fromStart =
        _rebuildFromStart || _webViewEpoch == 0 || c.browser.currentUrl.isEmpty;
    _rebuildFromStart = false;
    return fromStart ? _initialUrl : c.browser.currentUrl;
  }

  Widget _webView() {
    // unmap-then-map settles the URL on whichever origin the CURRENT
    // proxy state calls for: a rebuild triggered by the proxy toggle
    // moves a proxied currentUrl back to the real origin (or vice
    // versa), and both calls pass everything else through untouched.
    final initialUrl = c.proxy.mapUrl(c.proxy.unmapUrl(_rebuildUrl()));
    // Recorded once per WebView, not per build: a build that keeps the
    // same WebView keeps its user scripts too.
    if (_webViewProxyEpoch != _webViewEpoch) {
      _webViewProxyEpoch = _webViewEpoch;
      _webViewProxyOrigin = c.proxy.targetOrigin;
    }
    // A custom page skips the HTTP cache from its very first load (see
    // BrowserManager.prepareLoad), as everything does with Disable cache.
    final freshLoads =
        c.settings.get(defs.disableCache) || c.browser.isCustomPage(initialUrl);
    return _buildWebView(initialUrl, freshLoads);
  }

  Widget _buildWebView(String initialUrl, bool freshLoads) => InAppWebView(
    key: ValueKey(_webViewEpoch),
    initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
    initialUserScripts: UnmodifiableListView(_userScripts),
    pullToRefreshController: _pullToRefresh,
    initialSettings: InAppWebViewSettings(
      // Hybrid composition, decided twice. Virtual display (false) freed
      // Flutter animations from syncing with the Android UI thread, but it
      // paced the WebView itself badly: a constantly-animating dashboard
      // pushes every frame through an extra texture copy, dropping frames
      // on the page and stuttering the whole UI. The kiosk *is* the
      // WebView — its scrolling wins. Flutter animates over the live view
      // only for the brief drawer slide; settings is an opaque route, so
      // the view is not even composited while it is open. The exception is
      // hardware that cannot do it: some old GPUs hand Flutter's overlay
      // buffers back in the wrong pixel format and abort the process the
      // moment the dashboard appears (issue #302), and those devices draw
      // through the texture instead.
      useHybridComposition: !c.settings.get(defs.legacyWebView),
      // The plugin maps false to LAYER_TYPE_NONE, which keeps the Activity's
      // hardware acceleration without caching the live page in another GPU
      // texture. A forced hardware layer adds work to every scrolling frame.
      hardwareAcceleration: false,
      // Required for shouldOverrideUrlLoading to be called at all: without
      // it the callback is simply never invoked, and app:// navigations
      // would fall through to Chromium as an unknown scheme.
      useShouldOverrideUrlLoading: true,
      // The plugin honors CANCEL only for the main frame. An iframe pointed
      // at ks:// or app:// (a Webpage dashboard, an iframe card) still runs
      // the action in shouldOverrideUrlLoading, but without this Chromium
      // goes on to load the link in the frame and shows
      // ERR_UNKNOWN_URL_SCHEME there (issue #1044).
      regexToCancelSubFramesLoading: r'(?i)^(ks|app):.*',
      // Long-press menus and text selection, when kiosk mode says so.
      disableContextMenu:
          c.kiosk.locked && c.settings.get(defs.kioskDisableContextMenus),
      // Pinch zoom needs both flags on Android; the on-screen +/- buttons
      // stay off regardless — a kiosk shows no browser chrome.
      supportZoom: c.settings.get(defs.pinchToZoom),
      builtInZoomControls: c.settings.get(defs.pinchToZoom),
      displayZoomControls: false,
      mediaPlaybackRequiresUserGesture: !c.settings.get(defs.webAutoplay),
      allowsInlineMediaPlayback: true,
      iframeAllow: 'camera; microphone',
      transparentBackground: true,
      geolocationEnabled: c.settings.get(defs.webGeolocation),
      javaScriptCanOpenWindowsAutomatically: c.settings.get(defs.webPopups),
      // Android: let HTTPS pages pull in HTTP subresources.
      mixedContentMode: c.settings.get(defs.allowMixedContent)
          ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW
          : MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      // Dev aid: always hit the network so an edited dashboard or
      // card bundle is never served from a stale cache. This only
      // bypasses the HTTP cache — it does NOT touch localStorage /
      // DOM storage (kept alive by domStorageEnabled, which stays
      // on), so a page's saved config survives. Nothing is cleared;
      // only "Log out" deliberately wipes storage.
      cacheEnabled: !c.settings.get(defs.disableCache),
      cacheMode: freshLoads ? CacheMode.LOAD_NO_CACHE : CacheMode.LOAD_DEFAULT,
      // Downloads (an APK update from GitHub, a camera clip): without this
      // the WebView silently ignores them.
      useOnDownloadStart: true,
      // Keeps the page running while the app is not the app on screen.
      // Named for audio, but what it does is report the window as visible to
      // Chromium whatever the Activity is doing (InAppWebView
      // .onWindowVisibilityChanged): without it Chromium suspends the page a
      // minute after the app goes behind another one, the frontend stops
      // answering Home Assistant's websocket heartbeat, and the server drops
      // the connection - taking Voice Satellite's availability and every
      // other subscription with it until someone brings the kiosk back. A
      // kiosk's page is the point of the device, not a background tab.
      allowBackgroundAudioPlaying: true,
    ),
    onReceivedServerTrustAuthRequest: (controller, challenge) async =>
        webViewServerTrust('dashboard', c.settings, challenge),
    // A dashboard button can open another Android app by navigating to
    // app://<package> (issue #44): the clock app to set an alarm, a music
    // app, whatever is installed. ks://<action> reaches the kiosk's own
    // features the same way: the app launcher, Now Playing, a camera view,
    // the screensaver (kiosk_link.dart). Everything else loads as usual.
    //
    // Only this app's own schemes are claimed. Chromium's intent:// URLs are
    // deliberately not honoured: they can carry an arbitrary component and
    // extras, and a kiosk pointed at a page is not the place to hand a web
    // document that much reach.
    shouldOverrideUrlLoading: (controller, action) async {
      final url = action.request.url;
      if (url == null) return NavigationActionPolicy.ALLOW;
      // The URL Filter (issue #989). A link leaving for an external page
      // answers to the external rules as well as the dashboard's.
      if ((url.scheme == 'http' || url.scheme == 'https') &&
          action.isForMainFrame) {
        final leaving =
            !c.browser.isDashboardOrigin(url) &&
            !c.browser.isCustomPageOrigin(url);
        final rule = c.browser.urlBlockedBy(
          url.toString(),
          leaving
              ? const {urlFilterDashboard, urlFilterExternal}
              : const {urlFilterDashboard},
        );
        if (rule != null) {
          if (mounted) showUrlBlockedToast(context, c, rule);
          return NavigationActionPolicy.CANCEL;
        }
      }
      // A link leaving the dashboard's origin must not replace the dashboard
      // page: pagehide would tear down the Voice Satellite session, and the
      // wake word and the device's HA entities die with it (issue #86). The
      // tap gets the same fullscreen page on the rotation overlay instead,
      // with the dashboard alive underneath. Subframes stay untouched, and
      // programmatic loads (the loadUrl command) never pass through here.
      // A custom page on another server is the dashboard's to show too.
      if ((url.scheme == 'http' || url.scheme == 'https') &&
          action.isForMainFrame &&
          !c.browser.isDashboardOrigin(url) &&
          !c.browser.isCustomPageOrigin(url)) {
        c.browser.showLinkOverlay(url.toString());
        return NavigationActionPolicy.CANCEL;
      }
      if (url.scheme == 'ks') {
        // Cancel whatever it names: a link that is ours by scheme must never
        // reach Chromium, which would put its error page over the dashboard.
        final action = kioskLinkAction(url.toString());
        if (action == null) {
          c.log.warn('kiosk', 'unknown kiosk link: $url');
          if (mounted) {
            showToast(
              context,
              source: 'links',
              title: l10n(context).kioskUnknownLink,
              message: url.toString(),
              kind: ToastKind.error,
            );
          }
          return NavigationActionPolicy.CANCEL;
        }
        final result = await c.gestures.runGestureAction(action);
        if (!result.ok && mounted) {
          showToast(
            context,
            source: 'links',
            title: localizedGestureAction(context, action),
            message: gestureError(context, result.error ?? 'Failed'),
            kind: ToastKind.error,
          );
        }
        return NavigationActionPolicy.CANCEL;
      }
      if (url.scheme != 'app') {
        // A link or script moving the page to or from a custom page sets
        // the cache for it before the load starts.
        if (action.isForMainFrame &&
            (url.scheme == 'http' || url.scheme == 'https')) {
          await c.browser.prepareLoad(url.toString());
        }
        return NavigationActionPolicy.ALLOW;
      }
      final package = appLinkPackage(url.toString());
      if (package == null) {
        // Ours by scheme but not a package name: cancel anyway, or Chromium
        // shows its own error page over the dashboard.
        return NavigationActionPolicy.CANCEL;
      }
      final result = await c.commands.execute('launchApp', {
        'package': package,
      });
      if (!result.ok && mounted) {
        showToast(
          context,
          source: 'links',
          title: l10n(context).kioskOpenAppFailed,
          message: launcherText(context, result.error ?? package),
          kind: ToastKind.error,
        );
      }
      return NavigationActionPolicy.CANCEL;
    },
    onWebViewCreated: (controller) {
      c.browser.attach(controller, freshLoads: freshLoads);
      c.jsApi.attach(controller);
      // Scrollable pages report their pulls here (see _pullToRefresh).
      controller.addJavaScriptHandler(
        handlerName: 'ksPullToRefresh',
        callback: (_) => _triggerRefresh(),
      );
      // The page's Home Assistant socket closed (see socket_watch_script).
      // The dashboard watchdog polls for this too; hearing it directly is
      // what turns minutes of a stranded dashboard into seconds.
      controller.addJavaScriptHandler(
        handlerName: 'ksHaSocketClosed',
        callback: (_) => c.browser.onHaSocketClosed(),
      );
      // Home Assistant tried to route to a blocked page and stayed put
      // (see urlFilterJs).
      controller.addJavaScriptHandler(
        handlerName: 'ksUrlBlocked',
        callback: (args) {
          final rule = args.length > 1 && args[1] is String
              ? args[1] as String
              : '';
          c.browser.logUrlBlocked(args.isNotEmpty ? '${args.first}' : '', rule);
          if (mounted) showUrlBlockedToast(context, c, rule);
        },
      );
      // The dashboard set may have moved (see dashboards_watch_script).
      controller.addJavaScriptHandler(
        handlerName: 'ksHaDashboardsChanged',
        callback: (args) => c.browser.onHaDashboardsChanged(
          args.isNotEmpty ? '${args.first}' : '',
        ),
      );
      // The carousel reports its drag edges so the native scrollbars
      // stay asleep during the strip animation (see carousel_script).
      controller.addJavaScriptHandler(
        handlerName: 'ksCarouselDrag',
        callback: (args) {
          final active = args.isNotEmpty && args.first == true;
          unawaited(c.browser.setDragScrollBars(hidden: active));
        },
      );
      // Touch feedback: one message per accepted tap or slider step (see
      // haptics_script). Each setting is re-checked here so a page that
      // missed a toggle's live flag still cannot buzz or click while it
      // is off; strength is read per event, so the select applies
      // instantly.
      controller.addJavaScriptHandler(
        handlerName: 'ksHaptic',
        callback: (args) {
          final tick = args.isNotEmpty && args.first == 'tick';
          if (c.settings.get(defs.haHaptics)) {
            final strength = c.settings.get(defs.haHapticsStrength);
            if (tick) {
              Haptics.tick(strength: strength);
            } else {
              Haptics.tap(strength: strength);
            }
          }
          if (c.settings.get(defs.haTapSound)) {
            final volume =
                c.settings.get(defs.haTapSoundVolume).toDouble() / 100;
            if (tick) {
              TapSound.tick(volume: volume);
            } else {
              TapSound.tap(volume: volume);
            }
          }
        },
      );
    },
    onLoadStart: (controller, url) {
      if (c.browser.isAttached(controller)) c.jsApi.onPageStarted();
    },
    onUpdateVisitedHistory: (controller, url, isReload) {
      // SPA navigations inside HA (view switches, rotation's pushState)
      // surface here and nowhere else.
      if (url != null) c.browser.onUrlChanged(url.toString());
    },
    onLoadStop: (controller, url) {
      _refreshing = false;
      _refreshingFailsafe?.cancel();
      _pullToRefresh.endRefreshing();
      // The document-start seeds of these flags are frozen at WebView
      // creation; re-assert per load so toggled settings reach pages
      // loaded later.
      c.browser.runJs('window.__ksPtrEnabled = $_ptrEnabled;');
      c.browser.runJs(
        'window.__ksCarouselEnabled = $_carouselEnabled;'
        'window.__ksCarouselOverCards = '
        '${c.settings.get(defs.haCarouselOverCards)};',
      );
      c.browser.runJs(
        'window.__ksHapticsEnabled = '
        '${c.settings.get(defs.haHaptics)};'
        'window.__ksTapSoundEnabled = '
        '${c.settings.get(defs.haTapSound)};',
      );
      if (url != null) c.browser.onPageLoaded(url.toString());
      // Re-assert kiosk mode on every navigation: the document-start script
      // carries the flags of the load that created it, and a page loaded
      // before a toggle would otherwise keep the old answer.
      _applyKioskMode();
      // The zoom-level setting, re-asserted on every navigation: the
      // rewritten viewport meta dies with each document. Pinch to zoom
      // needs the rewrite at 1x as well, the page's own meta forbids it.
      if (c.settings.get(defs.browserZoom) != 1 ||
          c.settings.get(defs.pinchToZoom)) {
        c.browser.runJs(_zoomJs);
      }
      // The scroll lock too: its style element dies with each document.
      if (c.settings.get(defs.disableScrolling)) {
        c.browser.runJs(_scrollLockJs);
      }
      // The user's pasted JavaScript, Fully Kiosk style: runs after every
      // page load. Errors surface in the web console, nowhere else.
      final inject = c.settings.get(defs.browserInjectJs);
      if (inject.trim().isNotEmpty) c.browser.runJs(inject);
    },
    onReceivedError: (controller, request, error) {
      if (request.isForMainFrame ?? true) {
        _refreshing = false;
        _refreshingFailsafe?.cancel();
        _pullToRefresh.endRefreshing();
        c.browser.onLoadError(error.description);
      }
    },
    onReceivedHttpError: (controller, request, errorResponse) {
      // Server errors only: a 4xx main document (an HA auth bounce, a 404
      // dashboard) is the page saying something, not an outage, and
      // reloading it would loop on the same answer.
      final status = errorResponse.statusCode ?? 0;
      if ((request.isForMainFrame ?? true) && status >= 500) {
        c.browser.onHttpError(status);
      }
    },
    onDownloadStarting: (controller, request) async {
      // Hand downloads to the system DownloadManager. Feedback is in-app
      // snackbars (started / done with an Open action): the kiosk hides the
      // status bar, so the DownloadManager notification is never seen.
      var name = request.suggestedFilename;
      if (name == null || name.isEmpty) {
        final segs = request.url.pathSegments.where((s) => s.isNotEmpty);
        name = segs.isEmpty ? 'download' : segs.last;
      }
      c.browser.log.info('browser', 'downloading $name (${request.url})');
      if (mounted) {
        showToast(
          context,
          source: 'downloads',
          title: l10n(context).kioskDownloading,
          message: name,
        );
      }
      await BackgroundListening.download(
        url: request.url.toString(),
        filename: name,
        userAgent: request.userAgent,
        mimeType: request.mimeType,
      );
      return null; // handled outside the WebView; nothing for it to do
    },
    onRenderProcessGone: (controller, detail) {
      if (!c.browser.isAttached(controller)) return;
      c.jsApi.detach();
      c.browser.rebuildFailedRenderer(
        'WebView renderer gone (crashed: ${detail.didCrash}, '
        'priority: ${detail.rendererPriorityAtExit})',
      );
    },
    onRenderProcessUnresponsive: (controller, url) async {
      if (!c.browser.isAttached(controller)) return null;
      if (c.browser.onRendererUnresponsive()) {
        return WebViewRenderProcessAction.TERMINATE;
      }
      return null;
    },
    onRenderProcessResponsive: (controller, url) async {
      if (c.browser.isAttached(controller)) c.browser.onRendererResponsive();
      return null;
    },
    onConsoleMessage: (controller, message) {
      c.browser.onConsoleMessage(switch (message.messageLevel) {
        ConsoleMessageLevel.ERROR => 'error',
        ConsoleMessageLevel.WARNING => 'warn',
        ConsoleMessageLevel.DEBUG => 'debug',
        ConsoleMessageLevel.TIP => 'tip',
        _ => 'log',
      }, message.message);
    },
    onPermissionRequest: (controller, request) =>
        _webPermissionResponse(c, request),
  );
}

/// Hosts the rotation's external-page overlay and keeps it ALIVE between
/// passes: hiding used to dispose the WebView, so every cycle cold-loaded the
/// page again — a visible spinner on each pass on slow tablets. Now hiding
/// just moves it offstage (loaded, not painted, not hittable) and re-showing
/// the same page is instant. The WebView is only released when the rotation
/// feature itself is off, or when a different external URL replaces it.
///
/// Link-opened overlays (issue #86) are the exception: dismissal — the close
/// button, back, a wake word — destroys the WebView outright. Nothing will
/// re-show that page, and keeping a spare renderer warm is exactly what a
/// low-RAM device cannot afford.
/// Fully-Kiosk-style WebView permissions, shared by the dashboard and the
/// overlay: a resource is granted only if its Web Content toggle is on and
/// the OS runtime grant is held (requested lazily here, never all at once at
/// launch).
Future<PermissionResponse> _webPermissionResponse(
  AppContainer c,
  PermissionRequest request,
) async {
  final granted = <PermissionResourceType>[];
  for (final resource in request.resources) {
    if (await _webResourceAllowed(c, resource)) granted.add(resource);
  }
  return PermissionResponse(
    resources: granted,
    action: granted.isEmpty
        ? PermissionResponseAction.DENY
        : PermissionResponseAction.GRANT,
  );
}

Future<bool> _webResourceAllowed(
  AppContainer c,
  PermissionResourceType resource,
) async {
  if (resource == PermissionResourceType.MICROPHONE) {
    return c.settings.get(defs.webMicrophone) &&
        await ensureOsPermission(Permission.microphone);
  }
  if (resource == PermissionResourceType.CAMERA) {
    return c.settings.get(defs.webCamera) &&
        await ensureOsPermission(Permission.camera);
  }
  if (resource == PermissionResourceType.GEOLOCATION) {
    return c.settings.get(defs.webGeolocation) &&
        await ensureOsPermission(Permission.location);
  }
  // Anything else the page asks for (e.g. protected media id) follows the
  // camera/mic decision conservatively: deny unless explicitly handled.
  return false;
}

class _OverlayHost extends StatefulWidget {
  const _OverlayHost({required this.container});

  final AppContainer container;

  @override
  State<_OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<_OverlayHost>
    with SingleTickerProviderStateMixin {
  String? _lastUrl;

  /// Whether the page being kept came from a link tap. Recorded while the
  /// overlay is up: by the time dismissal rebuilds this widget,
  /// overlayDismissible has already been reset.
  bool _linkOverlay = false;

  /// The slide: a page opened by hand rises from the bottom edge and leaves
  /// the same way, so it reads as something brought up over the dashboard
  /// rather than the dashboard being replaced between two frames.
  ///
  /// Not for the rotation, which shows nobody's page in particular on a
  /// timer and would just make the wall panel move by itself; its overlay
  /// sits at rest (value 1) and keeps today's instant swap.
  late final AnimationController _slide;

  late final Animation<Offset> _slideOffset =
      Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _slide,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

  @override
  void initState() {
    super.initState();
    // Create the ticker while mounted, even if no overlay ever opens.
    // Lazy initialization in dispose would look up a deactivated ancestor.
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      value: 1,
    )..addStatusListener(_onSlideStatus);
    widget.container.browser.overlayUrl.addListener(_onOverlayUrl);
  }

  @override
  void dispose() {
    widget.container.browser.overlayUrl.removeListener(_onOverlayUrl);
    _slide.dispose();
    super.dispose();
  }

  /// Drives the animation off the overlay state. The build below still reads
  /// the same values; this only decides which way the page is moving.
  void _onOverlayUrl() {
    final showing = widget.container.browser.overlayUrl.value != null;
    if (showing) {
      // A link page starts off the bottom edge and rises; the rotation's
      // page is simply there.
      if (widget.container.browser.overlayDismissible.value) {
        _slide.forward(from: _slide.isAnimating ? _slide.value : 0);
      } else {
        _slide.value = 1;
      }
    } else if (_linkOverlay) {
      // Already at the bottom (nothing ever slid in): drop it now rather
      // than wait for a status change that will not come.
      if (_slide.value == 0) {
        _onSlideStatus(AnimationStatus.dismissed);
      } else {
        _slide.reverse();
      }
    }
  }

  /// The exit finished: only now is the WebView released. Until then the
  /// dismissed page is still on screen — that is what is sliding.
  void _onSlideStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) return;
    if (!mounted || widget.container.browser.overlayUrl.value != null) return;
    setState(() {
      _lastUrl = null;
      _linkOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.container;
    return ValueListenableBuilder<String?>(
      valueListenable: c.browser.overlayUrl,
      builder: (context, url, _) {
        if (url != null) {
          _lastUrl = url;
          _linkOverlay = c.browser.overlayDismissible.value;
        } else if (!_linkOverlay && !c.settings.get(defs.haRotationEnabled)) {
          // The rotation feature is off: release the WebView instead of
          // keeping it warm. A dismissed link page is held a moment longer
          // — it is still on screen, sliding out (see _onSlideStatus).
          _lastUrl = null;
        }
        final kept = _lastUrl;
        if (kept == null) return const SizedBox.shrink();
        // The Music Assistant page's own idle timeout: a wall tablet whose
        // visitor queued a song and walked off belongs back on the
        // dashboard. Always mounted (with 0 seconds standing for off) so
        // the tree shape never changes underneath the live WebView; it
        // counts only while this page is the one on screen.
        final isMaPage = isMusicAssistantOrigin(
          kept,
          c.settings.get(defs.sendspinMaUrl),
        );
        return Offstage(
          // The rotation's page waits offstage between passes. A dismissed
          // link page stays on stage a moment longer: it is what the exit
          // animation is moving.
          offstage: url == null && !_linkOverlay,
          child: IgnorePointer(
            // On its way out it is scenery, not a page: a tap belongs to
            // the dashboard coming back underneath.
            ignoring: url == null,
            child: SlideTransition(
              position: _slideOffset,
              child: _IdleDismiss(
                seconds: url != null && isMaPage
                    ? c.settings.get(defs.sendspinMaAutoClose).toInt()
                    : 0,
                onIdle: () {
                  c.browser.log.info(
                    'browser',
                    'Music Assistant page idle — back to the dashboard',
                  );
                  c.browser.dismissOverlay();
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Exempt from the Scale UI factor like every WebView:
                    // an external page renders at its own scale.
                    UiScaleExempt(
                      child: _OverlayWebView(
                        url: kept,
                        key: ValueKey(kept),
                        paused: url == null,
                        container: c,
                        onRenderGone: () {
                          c.browser.log.warn(
                            'browser',
                            'overlay renderer gone — dropping the overlay',
                          );
                          c.browser.dismissOverlay();
                          setState(() => _lastUrl = null);
                        },
                      ),
                    ),
                    // A link-opened overlay has no rotation pass to move it
                    // along (issue #86): the floating close is the visible
                    // way back to the dashboard. The back button and a wake
                    // word work too — which is why the Music Assistant page
                    // can opt out of it entirely (issue #264): its
                    // full-screen "now playing" menu sits exactly under
                    // the button.
                    if (c.browser.overlayDismissible.value &&
                        !(isMaPage && c.settings.get(defs.sendspinMaHideClose)))
                      Positioned(
                        top: 12,
                        right: 12,
                        child: SafeArea(
                          child: Material(
                            color: Colors.black45,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: c.browser.dismissOverlay,
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dismisses what it wraps after [seconds] with no touch inside it, or
/// never when [seconds] is zero.
///
/// A raw [Listener] rather than a gesture recognizer: the overlay's content
/// is a platform view that claims the gestures it is given, while pointer
/// events still travel the hit-test path through here — so the page keeps
/// scrolling and tapping exactly as it did, and the timer merely watches.
class _IdleDismiss extends StatefulWidget {
  const _IdleDismiss({
    required this.seconds,
    required this.onIdle,
    required this.child,
  });

  final int seconds;
  final VoidCallback onIdle;
  final Widget child;

  @override
  State<_IdleDismiss> createState() => _IdleDismissState();
}

class _IdleDismissState extends State<_IdleDismiss> {
  Timer? _timer;

  /// When the countdown last restarted. A drag delivers pointer moves by
  /// the hundred; restarting a timer for each is waste, and one restart a
  /// second is as precise as a timeout measured in seconds needs.
  DateTime? _armedAt;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(_IdleDismiss old) {
    super.didUpdateWidget(old);
    // A page arriving or leaving, or the setting being changed from the
    // remote admin while the page is up.
    if (widget.seconds != old.seconds) _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    _armedAt = null;
    if (widget.seconds <= 0) return;
    _armedAt = DateTime.now();
    _timer = Timer(Duration(seconds: widget.seconds), widget.onIdle);
  }

  void _touched() {
    if (widget.seconds <= 0) return;
    final armed = _armedAt;
    if (armed != null &&
        DateTime.now().difference(armed) < const Duration(seconds: 1)) {
      return;
    }
    _arm();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _touched(),
    onPointerMove: (_) => _touched(),
    child: widget.child,
  );
}

/// The notice for a navigation the URL Filter stopped, naming the Block
/// rule, or saying the page is not on the allow list when [rule] is empty.
/// Nothing while Show blocked page notice is off.
void showUrlBlockedToast(BuildContext context, AppContainer c, String rule) {
  if (!c.settings.get(defs.browserUrlFilterNotice)) return;
  showToast(
    context,
    title: l10n(context).urlFilterBlocked,
    message: rule.isEmpty ? l10n(context).urlFilterNotAllowed : rule,
    kind: ToastKind.warning,
  );
}

/// A bare WebView for a rotation external page, layered over the dashboard.
///
/// Deliberately minimal: no JS bridge, no wake-word or kiosk scripts,
/// no pull-to-refresh — it only displays a page. The dashboard WebView
/// below it stays fully loaded and interactive the instant this is removed,
/// so the Voice Satellite session and the wake word never pause.
class _OverlayWebView extends StatefulWidget {
  const _OverlayWebView({
    required this.url,
    required this.paused,
    required this.container,
    this.onRenderGone,
    super.key,
  });

  final String url;

  final AppContainer container;

  /// Offstage: the page is loaded but hidden. Pausing the WebView (per-view
  /// onPause, NOT the process-wide pauseTimers) stops its JS, animations and
  /// media from burning CPU behind the dashboard for the whole gap between
  /// rotation passes — typical targets (weather pages, dashboards) animate
  /// continuously.
  final bool paused;

  /// The overlay's renderer died: the host drops the overlay (rotation puts
  /// it back on its next pass) instead of Android killing the app.
  final VoidCallback? onRenderGone;

  @override
  State<_OverlayWebView> createState() => _OverlayWebViewState();
}

class _OverlayWebViewState extends State<_OverlayWebView> {
  InAppWebViewController? _controller;

  /// One pending retry for a load the network failed (this page has no
  /// other recovery: a rotation overlay that errored used to show the
  /// error until the rotation moved on, a link overlay until dismissed).
  Timer? _retry;

  /// Live updates: the Music Assistant page's zoom level, and the URL
  /// Filter's rules for external pages.
  StreamSubscription<SettingChanged>? _settingsSub;

  /// Whether URL Filter rules covered external pages when this view was
  /// built. Only then are full loads routed through shouldOverrideUrlLoading:
  /// the plugin cancels and reissues every load it is asked about, which
  /// nothing else on this page needs.
  late final bool _filtered = widget.container.browser.urlFilter.any(
    (r) => r.appliesTo(const {urlFilterExternal}),
  );

  @override
  void initState() {
    super.initState();
    if (_isMusicAssistant) {
      widget.container.homeAssistant.dashboardDark.addListener(_darkChanged);
    }
    _settingsSub = widget.container.bus.on<SettingChanged>().listen((e) {
      final controller = _controller;
      if (controller == null) return;
      if (_isMusicAssistant && e.key == defs.sendspinMaZoom.key) {
        unawaited(_applyMaZoom(controller));
      }
      if (e.key == defs.browserUrlFilter.key) {
        unawaited(
          controller.evaluateJavascript(
            source: widget.container.browser.urlFilterSource(urlFilterExternal),
          ),
        );
      }
    });
  }

  /// The dashboard switched between light and dark with this page open.
  void _darkChanged() {
    final dark = widget.container.homeAssistant.dashboardDark.value;
    if (dark == null) return;
    unawaited(
      _controller?.evaluateJavascript(source: colorSchemeSetJs(dark: dark)),
    );
  }

  /// Music Assistant's zoom level, the dashboard's viewport scale
  /// (viewport_zoom_script.dart). Re-asserted after every load: the
  /// rewritten meta dies with each document.
  Future<void> _applyMaZoom(InAppWebViewController controller) async {
    await controller.evaluateJavascript(
      source: viewportZoomJs(
        zoom: widget.container.settings.get(defs.sendspinMaZoom),
        pinch: false,
      ),
    );
  }

  @override
  void didUpdateWidget(_OverlayWebView old) {
    super.didUpdateWidget(old);
    if (widget.paused != old.paused) {
      widget.paused ? _controller?.pause() : _controller?.resume();
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    _settingsSub?.cancel();
    widget.container.homeAssistant.dashboardDark.removeListener(_darkChanged);
    super.dispose();
  }

  void _scheduleRetry() {
    if (_retry?.isActive ?? false) return;
    _retry = Timer(const Duration(seconds: 10), () {
      if (mounted) unawaited(_controller?.reload());
    });
  }

  /// Whether this page is the Music Assistant interface: it gets its own
  /// seeding, and stays out of the external-page JavaScript injection — it
  /// is the app's own shortcut, not a site the user brought in.
  bool get _isMusicAssistant => isMusicAssistantOrigin(
    widget.url,
    widget.container.settings.get(defs.sendspinMaUrl),
  );

  /// Signing the kiosk into Music Assistant with the token it already has.
  ///
  /// The Music Assistant web interface keeps its session as a JWT in
  /// `ma_access_token`, and the long-lived token configured for lyrics is
  /// exactly such a token — so handing it over at document start opens the
  /// interface already signed in. Home Assistant's own credentials cannot
  /// stand in for this: its authorize page mints a token per client and asks
  /// for the password every time, dashboard session or not.
  ///
  /// Only for pages on the configured server, and only over a session this
  /// seeding put there itself (remembered alongside it, so a token changed
  /// in the settings replaces the stale one). A session someone signed into
  /// by hand is left alone.
  /// A Home Assistant page opened here signs in from the dashboard's own
  /// session instead of asking again (discussion #225).
  UnmodifiableListView<UserScript>? get _seedScripts {
    final own = _ownSeedScripts;
    if (!_filtered) return own;
    // The URL Filter's rules for external pages, which keep a page's
    // own routing (pushState) off the blocked addresses.
    return UnmodifiableListView([
      ...?own,
      UserScript(
        source: widget.container.browser.urlFilterSource(urlFilterExternal),
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    ]);
  }

  UnmodifiableListView<UserScript>? get _ownSeedScripts {
    final token = widget.container.settings.get(defs.sendspinMaToken).trim();
    if (_isMusicAssistant) {
      // Music Assistant's Auto theme follows the dashboard's light or dark
      // when the kiosk sets it (issue #907). Otherwise the page answers
      // from Android, as before.
      final dark = widget.container.homeAssistant.dashboardDark.value;
      return UnmodifiableListView([
        if (dark != null)
          UserScript(
            source: colorSchemeJs(dark: dark),
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
        if (token.isNotEmpty)
          UserScript(
            source:
                'try {'
                'var t = ${jsonEncode(token)};'
                'var cur = localStorage.getItem("ma_access_token");'
                'if (!cur || cur === localStorage.getItem("ks_ma_seed")) {'
                'localStorage.setItem("ma_access_token", t);'
                'localStorage.setItem("ks_ma_seed", t);'
                '}'
                '} catch (e) {}',
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
      ]);
    }
    final target = Uri.tryParse(widget.url);
    if (target == null ||
        !widget.container.browser.isHomeAssistantOrigin(target)) {
      return null;
    }
    final session = buildHaSessionScript(
      tokens: widget.container.browser.haSession,
      url: widget.url,
    );
    // A Home Assistant page opened here hides its header and sidebar the way
    // the dashboard does, per the same settings (discussion #225). Held to
    // this page's own origin, so a link onward to somewhere else is left
    // exactly as its owner built it.
    final settings = widget.container.settings;
    final sources = [
      // An excursion is not a second satellite (see vs_suppress_script).
      vsSuppressScript,
      ...externalKioskModeSources(
        origin: target.origin,
        apply: settings.get(defs.haKioskMode),
        hideHeader: settings.get(defs.haKioskHideHeader),
        hideSidebar: settings.get(defs.haKioskHideSidebar),
      ),
    ];
    return UnmodifiableListView([
      if (session != null)
        UserScript(
          source: session,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      for (final source in sources)
        UserScript(
          source: source,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialUserScripts: _seedScripts,
        initialSettings: InAppWebViewSettings(
          useHybridComposition: !widget.container.settings.get(
            defs.legacyWebView,
          ),
          // Match the dashboard's direct hardware rendering path.
          hardwareAcceleration: false,
          transparentBackground: false,
          supportZoom: false,
          // A call or camera page opened here gets the dashboard's media
          // policy (issue #700): autoplay with sound and mic/camera access
          // follow the same Web Content settings.
          mediaPlaybackRequiresUserGesture: !widget.container.settings.get(
            defs.webAutoplay,
          ),
          allowsInlineMediaPlayback: true,
          iframeAllow: 'camera; microphone',
          useShouldOverrideUrlLoading: _filtered,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
          if (widget.paused) controller.pause();
          // The page's own routing tried a blocked address and stayed
          // put (see urlFilterJs).
          controller.addJavaScriptHandler(
            handlerName: 'ksUrlBlocked',
            callback: (args) {
              final rule = args.length > 1 && args[1] is String
                  ? args[1] as String
                  : '';
              widget.container.browser.logUrlBlocked(
                args.isNotEmpty ? '${args.first}' : '',
                rule,
              );
              if (mounted) showUrlBlockedToast(context, widget.container, rule);
            },
          );
        },
        // The URL Filter's external rules, for links and scripts moving
        // this page. Called only while [_filtered].
        shouldOverrideUrlLoading: (controller, action) async {
          final url = action.request.url;
          if (url == null ||
              !action.isForMainFrame ||
              (url.scheme != 'http' && url.scheme != 'https')) {
            return NavigationActionPolicy.ALLOW;
          }
          final rule = widget.container.browser.urlBlockedBy(
            url.toString(),
            const {urlFilterExternal},
          );
          if (rule == null) return NavigationActionPolicy.ALLOW;
          if (mounted) {
            showUrlBlockedToast(context, widget.container, rule);
          }
          return NavigationActionPolicy.CANCEL;
        },
        // The user's pasted JavaScript for external pages, after every load
        // (issue #224). The Music Assistant page is the app's own shortcut
        // and is left alone.
        onLoadStop: (controller, url) async {
          if (_isMusicAssistant) {
            // The color scheme script carries the state from when this
            // view was built: a reload after a flip catches up here.
            _darkChanged();
            if (widget.container.settings.get(defs.sendspinMaZoom) != 1) {
              await _applyMaZoom(controller);
            }
            return;
          }
          // A Home Assistant page here follows the dashboard's kiosk mode;
          // re-asserted per load because this view can outlive a toggle.
          final settings = widget.container.settings;
          await controller.evaluateJavascript(
            source: kioskModeApplyJs(
              apply: settings.get(defs.haKioskMode),
              hideHeader: settings.get(defs.haKioskHideHeader),
              hideSidebar: settings.get(defs.haKioskHideSidebar),
            ),
          );
          final inject = settings.get(defs.browserInjectJsExternal);
          if (inject.trim().isEmpty) return;
          await controller.evaluateJavascript(source: inject);
        },
        // Same policy as the dashboard WebView: the pages that land here are
        // local servers with certificates of their own making (Music
        // Assistant's add-on generates one), and the address was typed by
        // the owner on their own network.
        onReceivedServerTrustAuthRequest: (controller, challenge) async =>
            webViewServerTrust(
              'page overlay',
              widget.container.settings,
              challenge,
            ),
        onReceivedError: (controller, request, error) {
          if (request.isForMainFrame ?? true) _scheduleRetry();
        },
        onReceivedHttpError: (controller, request, errorResponse) {
          final status = errorResponse.statusCode ?? 0;
          if ((request.isForMainFrame ?? true) && status >= 500) {
            _scheduleRetry();
          }
        },
        onPermissionRequest: (controller, request) =>
            _webPermissionResponse(widget.container, request),
        onRenderProcessGone: (controller, detail) =>
            widget.onRenderGone?.call(),
      ),
    );
  }
}

/// What the dashboard slot shows on a device with no WebView provider:
/// the one case where waiting, rebuilding and restarting all change
/// nothing, so the screen says what is missing instead of staying black.
/// With [duraSpeed], the provider is there but MediaTek's DuraSpeed keeps
/// refusing its renderer: the notice gives the one command that turns it
/// off and a link to the guide.
class _WebViewMissingNotice extends StatelessWidget {
  const _WebViewMissingNotice({this.duraSpeed = false});

  final bool duraSpeed;

  static const _duraSpeedDocsUrl =
      'https://kiosksatellite.com/docs/permissions/#mediatek-duraspeed';

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.web_asset_off, color: Colors.white54, size: 48),
              SizedBox(height: 16),
              Text(
                duraSpeed
                    ? strings.kioskDuraSpeedBlocking
                    : strings.kioskWebViewMissing,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              SizedBox(height: 8),
              Text(
                duraSpeed
                    ? strings.kioskDuraSpeedBlockingHelp
                    : strings.kioskWebViewMissingHelp,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              if (duraSpeed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    BrowserManager.duraSpeedCommand,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(_duraSpeedDocsUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(strings.deviceOpenGuide),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [child] live, or while [paused] as a still picture of its last
/// frame, with the live tree offstage and its tickers stopped. Impeller
/// keeps no raster cache, so a merely idle screensaver under the voice
/// overlay would still be drawn again, filters and all, every frame the
/// overlay moves; the picture costs one texture.
class PausedUnder extends StatefulWidget {
  const PausedUnder({super.key, required this.paused, required this.child});

  final ValueListenable<bool> paused;
  final Widget child;

  @override
  State<PausedUnder> createState() => _PausedUnderState();
}

class _PausedUnderState extends State<PausedUnder> {
  final _boundary = GlobalKey();
  ui.Image? _still;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    widget.paused.addListener(_changed);
  }

  @override
  void dispose() {
    widget.paused.removeListener(_changed);
    _still?.dispose();
    super.dispose();
  }

  void _changed() {
    final paused = widget.paused.value;
    if (paused == _paused || !mounted) return;
    ui.Image? still;
    if (paused) {
      // The frame on screen right now, taken before anything changes.
      final boundary =
          _boundary.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      try {
        still = boundary?.toImageSync(
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
        );
      } catch (_) {
        still = null;
      }
    }
    setState(() {
      _paused = paused;
      _still?.dispose();
      _still = still;
    });
  }

  @override
  Widget build(BuildContext context) {
    final still = _paused ? _still : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (still != null)
          IgnorePointer(
            child: RawImage(image: still, fit: BoxFit.fill),
          ),
        Offstage(
          offstage: still != null,
          child: TickerMode(
            enabled: !_paused,
            // The screensaver's root is Positioned: it needs a Stack
            // above it.
            child: RepaintBoundary(
              key: _boundary,
              child: Stack(fit: StackFit.expand, children: [widget.child]),
            ),
          ),
        ),
      ],
    );
  }
}
