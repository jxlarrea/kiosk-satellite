import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_container.dart';
import 'core/events.dart';
import 'core/frame_watchdog.dart';
import 'core/ha_http_overrides.dart';
import 'managers/settings/definitions.dart' as defs;
import 'ui/kiosk_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = AppContainer();
  await container.init();

  // Self-signed certificates are the norm for LAN Home Assistant servers;
  // accept them for the configured HA host (and only that host) across
  // every HTTP and websocket client in the app.
  HttpOverrides.global = HaHttpOverrides(container.settings);

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
  Future<void> applyImmersion() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Deliberately NOT awaited: this platform call can hang forever when the
  // process is restarted by the OS mid permission flow (the engine comes up
  // without an attached window), and awaiting it here stalled main() before
  // runApp — the launch splash forever, with the Dart isolate alive
  // underneath. Immersion needs no ordering: the callback below and
  // KioskLock re-assert it continuously.
  unawaited(applyImmersion());
  container.bus.on<SettingChanged>().listen((e) {
    if (e.key == defs.kioskEnabled.key) applyImmersion();
  });
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    if (!systemOverlaysAreVisible) return;
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
    // The theme setting applies live, including when flipped from the remote
    // admin — the whole point of changing it from another room is seeing it.
    _sub = widget.container.bus
        .on<SettingChanged>()
        .listen((e) => e.key == defs.uiTheme.key ? setState(() {}) : null);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
    if (state == AppLifecycleState.resumed) {
      // Coming back from an OS screen (permission grants, app settings) is
      // another way the window returns without its immersive flags.
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
    widget.container.browser.reconnectHaSocket();
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
    return MaterialApp(
      title: 'Kiosk Satellite',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (container.settings.get(defs.uiTheme)) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      home: configured
          ? KioskScreen(container: container)
          : SetupScreen(container: container),
    );
  }
}
