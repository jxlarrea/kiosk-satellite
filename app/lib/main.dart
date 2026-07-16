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

  // Kiosk devices run fullscreen; system bars come back with a swipe.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(KioskSatelliteApp(container: container));
}

class KioskSatelliteApp extends StatefulWidget {
  const KioskSatelliteApp({super.key, required this.container});

  final AppContainer container;

  @override
  State<KioskSatelliteApp> createState() => _KioskSatelliteAppState();
}

class _KioskSatelliteAppState extends State<KioskSatelliteApp> {
  StreamSubscription<SettingChanged>? _sub;

  @override
  void initState() {
    super.initState();
    // The theme setting applies live, including when flipped from the remote
    // admin — the whole point of changing it from another room is seeing it.
    _sub = widget.container.bus
        .on<SettingChanged>()
        .listen((e) => e.key == defs.uiTheme.key ? setState(() {}) : null);
  }

  @override
  void dispose() {
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
