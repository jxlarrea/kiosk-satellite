import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_container.dart';
import 'core/events.dart';
import 'managers/settings/definitions.dart' as defs;
import 'ui/kiosk_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = AppContainer();
  await container.init();

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
  await applyImmersion();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The theme setting applies live, including when flipped from the remote
    // admin — the whole point of changing it from another room is seeing it.
    _sub = widget.container.bus
        .on<SettingChanged>()
        .listen((e) => e.key == defs.uiTheme.key ? setState(() {}) : null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from an OS screen (permission grants, app settings) is
    // another way the window returns without its immersive flags.
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
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
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
      home: configured
          ? KioskScreen(container: container)
          : SetupScreen(container: container),
    );
  }
}
