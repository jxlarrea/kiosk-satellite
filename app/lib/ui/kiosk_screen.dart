import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/permissions.dart';

import '../app_container.dart';
import 'screensaver_view.dart';
import '../core/events.dart';
import '../managers/browser/carousel_script.dart';
import '../managers/browser/disable_suspend_script.dart';
import '../managers/browser/ha_session_script.dart';
import '../managers/browser/haptics_script.dart';
import '../managers/device/haptics.dart';
import '../managers/device/tap_sound.dart';
import '../managers/browser/no_cache_script.dart';
import '../managers/browser/pull_to_refresh_script.dart';
import '../managers/browser/socket_watch_script.dart';
import '../managers/browser/visibility_mask_script.dart';
import '../managers/browser/ws_filter_script.dart';
import '../managers/kiosk/app_link.dart';
import '../managers/wake_word/background_listening.dart';
import '../managers/proxy/media_rewrite_script.dart';
import '../managers/sendspin/music_assistant_api.dart';
import '../managers/home_assistant/kiosk_mode.dart';
import '../managers/settings/definitions.dart' as defs;
import 'app_launcher_overlay.dart';
import 'lockdown_shield.dart';
import 'offline_notice.dart';
import 'dlna_media_overlay.dart';
import 'camera_view_overlay.dart';
import 'kiosk_drawer.dart';
import 'sendspin_player_overlay.dart';
import 'settings_screen.dart';
import 'web_console_panel.dart';

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
    with SingleTickerProviderStateMixin {
  AppContainer get c => widget.container;

  bool _consoleOpen = false;
  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<KioskExitGesture>? _gestureSub;
  StreamSubscription<WebConsoleRequested>? _consoleReqSub;
  StreamSubscription<KioskBackPressed>? _backSub;
  StreamSubscription<WakeWordDetected>? _wakeSub;
  StreamSubscription<CameraViewStateChanged>? _cameraSub;
  StreamSubscription<WebViewRebuildRequested>? _rebuildSub;

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

  /// Whether the drawer, when open, shows only the kiosk-allowed quick
  /// actions. Set at the moment it opens: an edge swipe while kiosk mode is
  /// locked opens it restricted (kiosk.allow_drawer); the exit gesture (and
  /// its PIN) always earns the full menu.
  bool _drawerRestricted = false;

  /// Whether the locked kiosk still offers the edge swipe: the owner opted
  /// in, and at least one allowed action would actually show — a menu with
  /// nothing in it is worse than no menu.
  bool get _quickMenuAvailable {
    if (!c.settings.get(defs.kioskAllowDrawer)) return false;
    final hasCameras =
        c.camera.config.defaultView?.cameraIds.isNotEmpty ?? false;
    return c.settings.get(defs.kioskAllowDashboard) ||
        c.settings.get(defs.kioskAllowScreensaver) ||
        c.settings.get(defs.kioskAllowTheme) ||
        (c.settings.get(defs.kioskAllowCamera) && hasCameras);
  }

  /// Pull-to-refresh as the user experiences it: the Web Browsing toggle,
  /// minus the kiosk protection that switches the gesture off while the
  /// device is locked.
  bool get _ptrEnabled =>
      c.settings.get(defs.pullToRefresh) &&
      !(c.kiosk.locked && c.settings.get(defs.kioskDisablePullRefresh));

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

  /// Consecutive renderer-unresponsive callbacks; two in a row means a
  /// wedged renderer, not a transient stall, and earns a terminate.
  int _unresponsiveStrikes = 0;

  /// Pull-to-refresh, Fully style. The native wrapper handles pages that fit
  /// the screen; scrollable pages never hand it the gesture (Chromium claims
  /// every vertical drag), so those report their pulls through the JS probe
  /// (see pull_to_refresh_script.dart) into [_triggerRefresh]. The spinner is
  /// ended from onLoadStop / onReceivedError — the reload's own completion —
  /// never on a timer.
  late final PullToRefreshController _pullToRefresh = PullToRefreshController(
    settings: PullToRefreshSettings(
      enabled: _ptrEnabled,
      color: const Color(0xFF749C6F), // brand sage on the stock spinner
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
    // HA kiosk mode and its hide choices are applied live: restyling the
    // page in place, with no reload and nothing lost from it.
    if (e.key == defs.haKioskMode.key ||
        e.key == defs.haKioskHideHeader.key ||
        e.key == defs.haKioskHideSidebar.key) {
      await _applyKioskMode();
      return;
    }
    // Mixed-content / SSL / cache / zoom are read only at WebView creation —
    // rebuild it (preserving the current URL) so the change applies without
    // a restart. The rebuild is storage-safe: localStorage is per-origin and
    // outlives the widget, so a page's saved config is not lost.
    // Zoom applies live via CSS — no rebuild, no reload. CSS zoom, not
    // the WebView's initial-scale: responsive pages (Home Assistant
    // included) declare a viewport meta that overrides initial-scale,
    // while CSS zoom rescales the layout regardless.
    if (e.key == defs.browserZoom.key) {
      await c.browser.runJs(_zoomJs);
      return;
    }
    // Scroll lock rides the zoom path: applied live as page CSS, no rebuild.
    if (e.key == defs.disableScrolling.key) {
      await c.browser.runJs(_scrollLockJs);
      return;
    }
    // The carousel's document-start seed is frozen at WebView creation;
    // flip the live flag so the toggle applies without a reload. The sync
    // call makes the script act on it now: build the preview strip, or
    // tear a disabled one down instead of leaving it mounted.
    if (e.key == defs.haDashboardCarousel.key) {
      await c.browser.runJs(
        'window.__ksCarouselEnabled = ${e.value == true};'
        'if (window.__ksCarouselSync) window.__ksCarouselSync();',
      );
      return;
    }
    // Haptics and the tap sound share one live-flag contract; the script
    // itself has no state to build or tear down.
    if (e.key == defs.haHaptics.key) {
      await c.browser.runJs(
        'window.__ksHapticsEnabled = ${e.value == true};',
      );
      return;
    }
    if (e.key == defs.haTapSound.key) {
      await c.browser.runJs(
        'window.__ksTapSoundEnabled = ${e.value == true};',
      );
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
    // The Music Assistant shortcut and the address it opens both decide
    // whether the drawer offers the entry at all, and the drawer is built
    // from here — so a flip in the remote admin shows up on the device
    // without waiting for the next rebuild.
    if (e.key == defs.sendspinMaShortcut.key ||
        e.key == defs.sendspinMaUrl.key) {
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
    // Voice Satellite reads getScreensaverSuppressed once per page load, so
    // anything that changes the answer re-negotiates with a reload. The
    // screensaver toggle only matters while suppression is on.
    if (e.key == defs.vsSuppressScreensaver.key ||
        (e.key == defs.screensaverEnabled.key &&
            c.settings.get(defs.vsSuppressScreensaver))) {
      await c.browser.runJs('location.reload();');
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

  @override
  void initState() {
    super.initState();

    unawaited(_waitForActivityAttach());
    // The watchdog's step before a process restart: a fresh widget retries
    // the platform-view creation, which heals a create that raced the
    // Activity attach at boot (issue #145).
    _rebuildSub = c.bus.on<WebViewRebuildRequested>().listen((_) {
      if (mounted) setState(() => _webViewEpoch++);
    });
    _settingsSub = c.bus.on<SettingChanged>().listen(_onSettingChanged);
    _gestureSub = c.bus.on<KioskExitGesture>().listen(_onExitGesture);
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
    });
    _backSub = c.bus.on<KioskBackPressed>().listen((_) {
      if (!mounted || _settingsOpen) return;
      if (_drawer.value > 0) {
        _closeDrawer();
      } else if (c.launcher.visible.value) {
        c.launcher.visible.value = false;
      } else if (c.browser.overlayUrl.value != null) {
        // A link or rotation page covers the dashboard: back uncovers it.
        c.browser.dismissOverlay();
      } else if (c.camera.activeViewId.value != null) {
        if (c.camera.focusedCameraId.value != null) {
          c.camera.focusCamera(null);
        } else {
          c.camera.hideView();
        }
      } else {
        c.browser.goBack();
      }
    });
    // canPop below depends on the overlay's presence.
    c.browser.overlayUrl.addListener(_onOverlayChanged);
    c.launcher.visible.addListener(_onOverlayChanged);

    // Download feedback lives in-app: the kiosk hides the status bar, so the
    // DownloadManager notification is invisible and without this a download
    // simply appears to do nothing.
    BackgroundListening.onDownloadComplete = (id, success, filename) {
      if (!mounted) return;
      final name = (filename == null || filename.isEmpty)
          ? 'Download'
          : filename;
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? SnackBar(
                content: Text('$name downloaded'),
                duration: const Duration(seconds: 10),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () => BackgroundListening.openDownload(id),
                ),
              )
            : SnackBar(
                content: Text('$name failed to download'),
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
              ),
      );
    };

    if (widget.showMenuHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip: swipe from the left edge to open the menu'),
            duration: Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
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

  /// The zoom-level setting as a CSS zoom on the document root. Idempotent
  /// and reversible: 1x clears the property entirely.
  String get _zoomJs {
    final zoom = c.settings.get(defs.browserZoom);
    return zoom == 1
        ? "document.documentElement.style.zoom = '';"
        : "document.documentElement.style.zoom = '$zoom';";
  }

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
    // Kiosk mode hides Home Assistant's own header and sidebar. It has to be
    // in place before the frontend builds anything, since it catches shadow
    // roots as they are created; it acts only while its flags say so, which
    // is what lets the toggle apply without a reload.
    UserScript(
      source: kioskModeScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    UserScript(
      source: kioskModeApplyJs(
        apply: c.settings.get(defs.haKioskMode),
        hideHeader: c.settings.get(defs.haKioskHideHeader),
        hideSidebar: c.settings.get(defs.haKioskHideSidebar),
      ),
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
    // The dashboard carousel rides the same contract as the pull probe:
    // always injected, acted on only while its flag is on, so the toggle
    // needs no reload.
    UserScript(
      source:
          'window.__ksCarouselEnabled = '
          '${c.settings.get(defs.haDashboardCarousel)};',
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
    // The wizard's satellite choice, handed to Voice Satellite before its
    // code runs: VS reads localStorage['vs-satellite-entity'], selects that
    // assist_satellite, hydrates its server-side profile and starts. Only
    // seeded while the key is absent — a satellite changed in the page
    // afterwards must win over a stale wizard choice.
    if (c.settings.get(defs.haSatelliteEntity).isNotEmpty)
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

  /// Apply or tear down kiosk mode against the current page.
  Future<void> _applyKioskMode() async {
    await c.browser.runJs(
      kioskModeApplyJs(
        apply: c.settings.get(defs.haKioskMode),
        hideHeader: c.settings.get(defs.haKioskHideHeader),
        hideSidebar: c.settings.get(defs.haKioskHideSidebar),
      ),
    );
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
  }

  /// Whether a WebView permission request may be granted: its Web Content
  /// toggle must be on and the OS runtime grant must be held (requested
  /// lazily here — never all-at-once at launch).
  Future<bool> _resourceAllowed(PermissionResourceType resource) async {
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
      covered: c.settings.get(defs.lockdownEnabled) &&
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kiosk PIN'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'PIN',
              errorText: failed ? 'Wrong PIN' : null,
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
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (c.kiosk.pinMatches(controller.text)) {
                  Navigator.pop(context, true);
                } else {
                  setDialogState(() => failed = true);
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return ok ?? false;
  }

  @override
  void dispose() {
    BackgroundListening.onDownloadComplete = null;
    _refreshingFailsafe?.cancel();
    _drawer.dispose();
    _settingsSub?.cancel();
    _gestureSub?.cancel();
    _consoleReqSub?.cancel();
    _rebuildSub?.cancel();
    _backSub?.cancel();
    _wakeSub?.cancel();
    _cameraSub?.cancel();
    c.browser.overlayUrl.removeListener(_onOverlayChanged);
    c.launcher.visible.removeListener(_onOverlayChanged);
    super.dispose();
  }

  void _onOverlayChanged() {
    if (mounted) setState(() {});
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
        if (_activityAttached) _webView(),
        // Directly over the dashboard: it hides Chromium's error page, and
        // everything below in this list (an overlay page, the player) is
        // content that belongs on top of the dashboard, error or not.
        OfflineNotice(container: c),
        // The rotation's external pages, shown OVER the dashboard so the
        // dashboard (and the Voice Satellite session with it) never
        // unloads. A wake detection hides this instantly, revealing the
        // live dashboard underneath (see initState).
        _OverlayHost(container: c),
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
    final drawerPane = GestureDetector(
      onHorizontalDragUpdate: _drawerDragUpdate,
      onHorizontalDragEnd: _drawerDragEnd,
      child: KioskDrawer(
        container: c,
        onClose: _closeDrawer,
        onSettings: _openSettings,
        restricted: _drawerRestricted,
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
              // System back closes the drawer first. A closed kiosk keeps
              // the default behavior — except in kiosk mode, where back must
              // never background the app: it steps the page's history
              // instead. This is the predictive-back path; devices that
              // still deliver Back as a KeyEvent are caught in KioskLock
              // before it ever reaches here, and land in the same handling
              // via KioskBackPressed.
              canPop:
                  !open &&
                  !c.kiosk.locked &&
                  !c.kiosk.lockdownActive &&
                  c.browser.overlayUrl.value == null &&
                  !c.launcher.visible.value &&
                  c.camera.activeViewId.value == null,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                if (open) {
                  _closeDrawer();
                } else if (c.launcher.visible.value) {
                  c.launcher.visible.value = false;
                } else if (c.browser.overlayUrl.value != null) {
                  // A link or rotation page covers the dashboard: back
                  // uncovers it.
                  c.browser.dismissOverlay();
                } else if (c.camera.activeViewId.value != null) {
                  if (c.camera.focusedCameraId.value != null) {
                    c.camera.focusCamera(null);
                  } else {
                    c.camera.hideView();
                  }
                } else {
                  c.browser.goBack();
                }
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
                    child: kioskPlane,
                  ),
                  // The drawer plane, sliding in from the same seam.
                  Positioned(
                    left: dx - _drawerWidth,
                    top: 0,
                    bottom: 0,
                    width: _drawerWidth,
                    child: drawerPane,
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
                  // The screensaver covers both planes — it owns the whole
                  // display, drawer open or not.
                  ScreensaverOverlay(container: c),
                  CameraViewOverlay(container: c),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _webView() => InAppWebView(
    key: ValueKey(_webViewEpoch),
    initialUrlRequest: URLRequest(
      // unmap-then-map settles the URL on whichever origin the CURRENT
      // proxy state calls for: a rebuild triggered by the proxy toggle
      // moves a proxied currentUrl back to the real origin (or vice
      // versa), and both calls pass everything else through untouched.
      url: WebUri(
        c.proxy.mapUrl(
          c.proxy.unmapUrl(
            _webViewEpoch == 0 || c.browser.currentUrl.isEmpty
                ? _initialUrl
                : c.browser.currentUrl,
          ),
        ),
      ),
    ),
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
      // the view is not even composited while it is open.
      useHybridComposition: true,
      // Required for shouldOverrideUrlLoading to be called at all: without
      // it the callback is simply never invoked, and app:// navigations
      // would fall through to Chromium as an unknown scheme.
      useShouldOverrideUrlLoading: true,
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
      cacheMode: c.settings.get(defs.disableCache)
          ? CacheMode.LOAD_NO_CACHE
          : CacheMode.LOAD_DEFAULT,
      // Downloads (an APK update from GitHub, a camera clip): without this
      // the WebView silently ignores them.
      useOnDownloadStart: true,
    ),
    onReceivedServerTrustAuthRequest: (controller, challenge) async {
      // Accept untrusted/self-signed certs only when the user opted
      // in (e.g. a local HA instance without proper SSL). Otherwise
      // fall through to the platform's default validation.
      if (c.settings.get(defs.ignoreSslErrors)) {
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.PROCEED,
        );
      }
      return ServerTrustAuthResponse(
        action: ServerTrustAuthResponseAction.CANCEL,
      );
    },
    // A dashboard button can open another Android app by navigating to
    // app://<package> (issue #44): the clock app to set an alarm, a music
    // app, whatever is installed. Everything else loads as usual.
    //
    // Only this app's own scheme is claimed. Chromium's intent:// URLs are
    // deliberately not honoured: they can carry an arbitrary component and
    // extras, and a kiosk pointed at a page is not the place to hand a web
    // document that much reach.
    shouldOverrideUrlLoading: (controller, action) async {
      final url = action.request.url;
      if (url == null) return NavigationActionPolicy.ALLOW;
      // A link leaving the dashboard's origin must not replace the dashboard
      // page: pagehide would tear down the Voice Satellite session, and the
      // wake word and the device's HA entities die with it (issue #86). The
      // tap gets the same fullscreen page on the rotation overlay instead,
      // with the dashboard alive underneath. Subframes stay untouched, and
      // programmatic loads (the loadUrl command) never pass through here.
      if ((url.scheme == 'http' || url.scheme == 'https') &&
          action.isForMainFrame &&
          !c.browser.isDashboardOrigin(url)) {
        c.browser.showLinkOverlay(url.toString());
        return NavigationActionPolicy.CANCEL;
      }
      if (url.scheme != 'app') {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Could not open $package'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return NavigationActionPolicy.CANCEL;
    },
    onWebViewCreated: (controller) {
      c.browser.attach(controller);
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
        'window.__ksCarouselEnabled = '
        '${c.settings.get(defs.haDashboardCarousel)};',
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
      // The zoom-level setting, as CSS zoom on every navigation.
      if (c.settings.get(defs.browserZoom) != 1) c.browser.runJs(_zoomJs);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $name'),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
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
      // The WebView's renderer process died — OOM on low-RAM panels (NSPanel
      // Pro, Echo Show), GPU faults, classically right at screensaver wake
      // when the surface recomposites. Handling this callback is what stops
      // Android from killing the WHOLE APP in response; rebuild the WebView
      // in place instead, which reloads the current page, and the kiosk
      // carries on.
      c.browser.log.warn(
        'browser',
        'WebView renderer gone (crashed: ${detail.didCrash}) — rebuilding '
            'the WebView',
      );
      _unresponsiveStrikes = 0;
      if (mounted) setState(() => _webViewEpoch++);
    },
    onRenderProcessUnresponsive: (controller, url) async {
      // The renderer HUNG rather than died — the other way a memory-starved
      // device loses the dashboard (the renderer thrashes, stalls, and
      // Chromium waits for us to act; unhandled, the page sits white
      // forever while the rest of the app runs on). One strike is grace
      // for a transient stall; on the second, terminate the renderer,
      // which fires onRenderProcessGone above and rebuilds the WebView.
      _unresponsiveStrikes++;
      c.browser.log.warn(
        'browser',
        'WebView renderer unresponsive '
            '(strike $_unresponsiveStrikes) at $url',
      );
      if (_unresponsiveStrikes >= 2) {
        _unresponsiveStrikes = 0;
        return WebViewRenderProcessAction.TERMINATE;
      }
      return null;
    },
    onRenderProcessResponsive: (controller, url) async {
      if (_unresponsiveStrikes > 0) {
        c.browser.log.info('browser', 'WebView renderer responsive again');
      }
      _unresponsiveStrikes = 0;
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
    onPermissionRequest: (controller, request) async {
      // Fully-Kiosk-style: grant a resource only if its Web Content
      // toggle is on, ensuring the OS runtime grant lazily.
      final granted = <PermissionResourceType>[];
      for (final resource in request.resources) {
        if (await _resourceAllowed(resource)) granted.add(resource);
      }
      return PermissionResponse(
        resources: granted,
        action: granted.isEmpty
            ? PermissionResponseAction.DENY
            : PermissionResponseAction.GRANT,
      );
    },
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
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
    value: 1,
  )..addStatusListener(_onSlideStatus);

  late final Animation<Offset> _slideOffset = Tween(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _slide,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ));

  @override
  void initState() {
    super.initState();
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
                seconds:
                    url != null &&
                        isMusicAssistantOrigin(
                          kept,
                          c.settings.get(defs.sendspinMaUrl),
                        )
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
                    _OverlayWebView(
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
                    // A link-opened overlay has no rotation pass to move it
                    // along (issue #86): the floating close is the visible
                    // way back to the dashboard. The back button and a wake
                    // word work too.
                    if (c.browser.overlayDismissible.value)
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
    final token = widget.container.settings.get(defs.sendspinMaToken).trim();
    if (_isMusicAssistant) {
      if (token.isEmpty) return null;
      return UnmodifiableListView([
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
    final kiosk = externalKioskModeSources(
      origin: target.origin,
      apply: settings.get(defs.haKioskMode),
      hideHeader: settings.get(defs.haKioskHideHeader),
      hideSidebar: settings.get(defs.haKioskHideSidebar),
    );
    if (session == null && kiosk.isEmpty) return null;
    return UnmodifiableListView([
      if (session != null)
        UserScript(
          source: session,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      for (final source in kiosk)
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
          useHybridComposition: true,
          transparentBackground: false,
          supportZoom: false,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
          if (widget.paused) controller.pause();
        },
        // The user's pasted JavaScript for external pages, after every load
        // (issue #224). The Music Assistant page is the app's own shortcut
        // and is left alone.
        onLoadStop: (controller, url) async {
          if (_isMusicAssistant) return;
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
        onReceivedServerTrustAuthRequest: (controller, challenge) async {
          if (widget.container.settings.get(defs.ignoreSslErrors)) {
            return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.PROCEED,
            );
          }
          return ServerTrustAuthResponse(
            action: ServerTrustAuthResponseAction.CANCEL,
          );
        },
        onReceivedError: (controller, request, error) {
          if (request.isForMainFrame ?? true) _scheduleRetry();
        },
        onReceivedHttpError: (controller, request, errorResponse) {
          final status = errorResponse.statusCode ?? 0;
          if ((request.isForMainFrame ?? true) && status >= 500) {
            _scheduleRetry();
          }
        },
        onRenderProcessGone: (controller, detail) =>
            widget.onRenderGone?.call(),
      ),
    );
  }
}
