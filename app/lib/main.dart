import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_container.dart';
import 'core/app_identity.dart';
import 'core/app_locales.dart';
import 'core/certificate_log.dart';
import 'core/error_log.dart';
import 'core/events.dart';
import 'core/frame_watchdog.dart';
import 'core/headless.dart';
import 'core/ha_http_overrides.dart';
import 'core/user_authorities.dart';
import 'managers/kiosk/kiosk_manager.dart'
    show hidesNavigationBar, hidesStatusBar;
import 'managers/settings/definitions.dart' as defs;
import 'managers/settings/settings_manager.dart';
import 'managers/wake_word/pryon/pryon_catalog.dart';
import 'ui/key_nav.dart';
import 'ui/kiosk_screen.dart';
import 'ui/resized_image.dart';
import 'ui/ui_scale.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';
import 'ui/toast.dart';
import 'package:kiosk_satellite/core/lifecycle.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The engine's decoded-image cache defaults to 100MB — a quarter of a
  // low-RAM device's whole app budget, sitting alongside the Chromium
  // WebView that IS the product. This app's Flutter UI is chrome around
  // that WebView plus one screensaver slide at a time (slides evict
  // themselves as they leave); 32MB is generous for all of it.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 32 << 20;

  // Before any image decodes: whether resized images must be scaled on the
  // CPU instead of by Impeller's OpenGL ES blit.
  await GpuResize.init();

  // Before the container: managers read it while they start.
  await Headless.detect();

  final container = AppContainer();
  // Self-signed certificates are the norm for LAN Home Assistant servers;
  // accept them for the configured HA host (and only that host) across
  // every HTTP and websocket client in the app. This has to come before
  // init: managers open Home Assistant sockets while they start, and
  // dart:io builds its one shared WebSocket client on the first connect.
  // A client born before the overrides keeps strict verification for the
  // whole run (issue #775). The policy reads settings only at handshake
  // time, after settings.init.
  CertificateLog.attach(container.log);
  HttpOverrides.global = HaHttpOverrides(container.settings);
  // Private CAs the user installed on the device, for the same reason
  // before init: every connection from here on should trust them.
  await trustUserAuthorities();
  // Before init: the settings it serves hide Amazon's wake word engine
  // unless an Echo image's service answered.
  await PryonCatalog.init(container.log);
  await container.init();
  // Framework and uncaught Dart errors into the app log, where reports
  // and the watchdog's restart note can see them.
  installErrorLog(
    container.log,
    onMissingWebView: () => container.browser.markWebViewMissing(
      'the WebView creation threw MissingWebViewPackageException',
    ),
    onBrokenWebView: () => container.browser.markWebViewBroken(
      'the WebView provider threw InvocationTargetException while starting',
    ),
  );

  // The app names itself on the wire from here on: the device manager has
  // resolved the version and the OS by now, and the overrides hand the
  // string to every client the process creates. The shared WebSocket
  // client may already exist from init, so it is told directly.
  AppIdentity.configure(
    version: container.device.appVersion,
    osVersion: container.device.osVersion,
  );
  WebSocket.userAgent = AppIdentity.userAgent;

  // A device without a screen has no UI to build and no frames to watch
  // for. The managers, the service and the remote admin are the app.
  if (Headless.active) {
    container.log.info('app', 'running headless: no screen on this device');
    return;
  }

  // Media permissions are NOT requested here. They are gated by the Web
  // Content toggles and the OS grant is requested lazily (see KioskScreen),
  // so we never prompt for camera/mic the user hasn't enabled.

  // Kiosk devices run fullscreen; system bars come back with a swipe and
  // hide again. That promise breaks the moment the WebView — a platform
  // view — takes input focus (a tap, the keyboard): Android drops the
  // window's immersive flags and, set only once, they would stay lost. So
  // hiding is re-asserted whenever the system reports the bars visible.
  //
  // The mode depends on kiosk mode. Sticky immersive gives the friendly
  // behavior — but its transient bars are a system override: no callback
  // fires and re-hide requests are ignored, so the peek is always the
  // system's three seconds. Locked down, that is too long a window; plain
  // immersive makes a revealed bar an ordinary one, which notifies us and
  // obeys the fast re-hide (KioskLock's ticker backstops it besides).
  // Sticky in BOTH states — plain immersive turned out to paint One UI's
  // "swipe for status bar" hint pill on every touch, which is worse than
  // what it fixed. Sticky draws no hint; its transient bar is dismissed
  // early by KioskLock's hide() ticker while kiosk mode holds.
  //
  // With Hide status bar or Hide navigation bar off (and no kiosk mode)
  // that bar stays up instead; see applySystemBars.
  Future<void> applyImmersion() => applySystemBars(container.settings);
  // Deliberately NOT awaited: this platform call can hang forever when the
  // process is restarted by the OS mid permission flow (the engine comes up
  // without an attached window), and awaiting it here stalled main() before
  // runApp — the launch splash forever, with the Dart isolate alive
  // underneath. Immersion needs no ordering: the callback below and
  // KioskLock re-assert it continuously.
  unawaited(applyImmersion());
  container.bus.on<SettingChanged>().listen((e) {
    if (e.key == defs.kioskEnabled.key ||
        e.key == defs.lockdownEnabled.key ||
        e.key == defs.screenHideStatusBar.key ||
        e.key == defs.screenHideNavigationBar.key) {
      applyImmersion();
    }
  });
  // A screensaver dismissal reveals the dashboard WebView with no focus
  // change or resume to re-assert the mode, and on some Android 12 ROMs
  // the gesture bar stayed up over the dashboard afterwards (issue #728).
  container.bus.on<ScreensaverStateChanged>().listen((e) {
    if (!e.active) applyImmersion();
  });
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    if (!systemOverlaysAreVisible) return;
    if (!hidesStatusBar(container.settings) &&
        !hidesNavigationBar(container.settings)) {
      return;
    }
    final locked = container.settings.get(defs.kioskEnabled);
    await Future<void>.delayed(
      locked ? const Duration(milliseconds: 400) : const Duration(seconds: 3),
    );
    await applyImmersion();
  });

  // Armed BEFORE runApp: the watchdog is the recovery for "the UI never
  // came up", so it must not depend on the UI coming up.
  FrameWatchdog(container).start();
  runApp(KioskSatelliteApp(container: container));
}

/// Hide the system bars, or show the ones whose Hide status bar or Hide
/// navigation bar setting is off while neither kiosk mode nor lockdown is on
/// (issues #1076 and #1102). Manual with the shown overlays rather than
/// edgeToEdge: the latter would make Flutter undo the edge-to-edge window
/// MainActivity sets up itself. Manual drops the sticky flag for a bar it
/// hides, so SystemBars.kt sets the swipe behavior on the window itself. The
/// native side pads the content by the visible bars (CutoutLayout), so the
/// dashboard sits between them.
Future<void> applySystemBars(SettingsManager settings) {
  final status = hidesStatusBar(settings);
  final navigation = hidesNavigationBar(settings);
  if (status && navigation) {
    return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  return SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      if (!status) SystemUiOverlay.top,
      if (!navigation) SystemUiOverlay.bottom,
    ],
  );
}

class KioskSatelliteApp extends StatefulWidget {
  const KioskSatelliteApp({super.key, required this.container});

  final AppContainer container;

  @override
  State<KioskSatelliteApp> createState() => _KioskSatelliteAppState();
}

class _KioskSatelliteAppState extends State<KioskSatelliteApp>
    with WidgetsBindingObserver {
  StreamSubscription<SettingChanged>? _sub;
  StreamSubscription<WakeWordDetected>? _wakeSub;
  StreamSubscription<VoiceInteractionChanged>? _voiceSub;

  /// When the Activity last went to the background (screen off, app switch).
  /// A resume after more than a few seconds of this may thaw the WebView with
  /// a half-open HA socket, so we nudge it to reconnect (see BrowserManager).
  DateTime? _backgroundedAt;
  static const _reconnectAfterBackground = Duration(seconds: 5);

  /// The reconnect nudge is DEFERRED, not fired on the resume itself, because a
  /// wake word heard from the background brings the app forward — the resume
  /// arrives BEFORE [WakeWordDetected] is published (wake_word_manager awaits
  /// bringToFront first). Cycling the socket in the middle of that turn makes
  /// Home Assistant reject Voice Satellite's pipeline as a duplicate wake-up.
  /// So we wait, and cancel if a wake or voice turn shows up meanwhile: that
  /// resume was wake-driven, the app was never frozen, and the socket is fine.
  Timer? _nudgeTimer;
  bool _voiceActive = false;
  DateTime? _lastWakeAt;
  static const _nudgeDelay = Duration(seconds: 3);
  static const _wakeGuard = Duration(seconds: 8);

  /// While backgrounded, poke the HA websocket so Chromium's hidden-tab timer
  /// throttling does not starve its keepalive and let the server drop it. Only
  /// runs when the process is kept alive (background listening's foreground
  /// service); otherwise a frozen isolate never fires it. Best-effort: the
  /// wake path's ensureHaConnected is the guarantee if the socket dies anyway.
  Timer? _keepAliveTimer;
  static const _keepAliveEvery = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Read on every toast, so a change from the remote applies to the next.
    toastShown = (source) => !defs
        .decodeToastsHidden(widget.container.settings.get(defs.uiToastsHidden))
        .contains(source);
    // Interface settings apply immediately, including remote changes.
    _sub = widget.container.bus.on<SettingChanged>().listen(
      (e) =>
          e.key == defs.uiTheme.key ||
              e.key == defs.uiScale.key ||
              e.key == defs.uiLanguage.key ||
              e.key == defs.screenHideStatusBar.key ||
              e.key == defs.screenHideNavigationBar.key ||
              e.key == defs.kioskEnabled.key ||
              e.key == defs.lockdownEnabled.key
          ? setState(() {})
          : null,
    );
    // A wake-driven resume must never cycle the socket: record the wake and
    // drop any pending nudge the resume it caused had scheduled.
    _wakeSub = widget.container.bus.on<WakeWordDetected>().listen((_) {
      _lastWakeAt = DateTime.now();
      _nudgeTimer?.cancel();
    });
    _voiceSub = widget.container.bus.on<VoiceInteractionChanged>().listen((e) {
      _voiceActive = e.active;
      if (e.active) _nudgeTimer?.cancel();
    });
  }

  final _returned = ReturnWatch();

  @override
  void didChangeLocales(List<Locale>? locales) {
    // Refresh glyph selection without changing the saved interface language.
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final returned = _returned.returned(state);
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      _nudgeTimer?.cancel();
      // Keep the socket warm while hidden (see _keepAliveTimer).
      _keepAliveTimer?.cancel();
      _keepAliveTimer = Timer.periodic(
        _keepAliveEvery,
        (_) => widget.container.browser.pingHaConnection(),
      );
      return;
    }
    if (returned) {
      // Coming back from an OS screen (permission grants, app settings) is
      // another way the window returns without its immersive flags.
      applySystemBars(widget.container.settings);
      _keepAliveTimer?.cancel();
      final since = _backgroundedAt;
      _backgroundedAt = null;
      // Only after a real background spell: a long freeze is what leaves the
      // HA socket half-open. Skip brief inactive flickers (dialogs, the
      // drawer) so a healthy connection is never needlessly cycled. Deferred
      // (see _nudgeTimer): if a wake word caused this resume, the wake/voice
      // events land within the delay and cancel it.
      if (since != null &&
          DateTime.now().difference(since) >= _reconnectAfterBackground) {
        _nudgeTimer?.cancel();
        _nudgeTimer = Timer(_nudgeDelay, _maybeNudge);
      }
    }
  }

  void _maybeNudge() {
    // A wake word that brought us forward means Voice Satellite is starting an
    // interaction on the live HA socket; cycling it now makes the server see a
    // duplicate wake-up. Background listening also keeps the app unfrozen, so
    // the socket is not the zombie the nudge exists to fix. Only recover when
    // this resume was NOT wake-driven.
    if (_voiceActive) return;
    final wake = _lastWakeAt;
    if (wake != null && DateTime.now().difference(wake) < _wakeGuard) return;
    // Verified first: a socket that answers a ping is left alone, so a
    // routine wake (the screen-off feature wakes several times a day) does
    // not cost a connection flash and every camera card's stream; only a
    // socket that fails the round trip gets the cycle.
    widget.container.browser.nudgeHaSocketIfDead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _wakeSub?.cancel();
    _voiceSub?.cancel();
    _nudgeTimer?.cancel();
    _keepAliveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final container = widget.container;
    final configured = container.settings.get(defs.startUrl).isNotEmpty;
    final barsShown =
        !hidesStatusBar(container.settings) ||
        !hidesNavigationBar(container.settings);
    final uiLocale = appLocaleForLanguage(
      container.settings.get(defs.uiLanguage),
    );
    return MaterialApp(
      title: 'Kiosk Satellite',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: appLocalizationsForUiLocale(uiLocale),
      supportedLocales: appSupportedLocales,
      locale: appRenderingLocale(
        uiLocale,
        WidgetsBinding.instance.platformDispatcher.locales,
      ),
      theme: buildTheme(Brightness.light, barsShown: barsShown),
      darkTheme: buildTheme(Brightness.dark, barsShown: barsShown),
      themeMode: switch (container.settings.get(defs.uiTheme)) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      // Above the Navigator, so every route — settings, its subpages, the
      // pickers — walks dpad/arrow focus under the same policy (issue
      // #377): reading order, and the page header scrolled back into view
      // when focus reaches a page's first row. The Scale UI factor sits at
      // the same altitude for the same reason: every route, dialog and
      // overlay scales, with the WebViews opting back out (UiScaleExempt).
      builder: (context, child) => UiScaler(
        scale: uiScaleFactor(container.settings.get(defs.uiScale)),
        child: FocusTraversalGroup(policy: KsTraversalPolicy(), child: child!),
      ),
      navigatorObservers: [kioskRouteObserver],
      home: configured
          ? KioskScreen(container: container)
          : SetupScreen(container: container),
    );
  }
}
