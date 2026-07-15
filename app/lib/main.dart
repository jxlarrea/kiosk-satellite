import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_container.dart';
import 'managers/settings/definitions.dart' as defs;
import 'ui/kiosk_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = AppContainer();
  await container.init();

  // Kiosk devices run fullscreen; system bars come back with a swipe.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(KioskSatelliteApp(container: container));
}

class KioskSatelliteApp extends StatelessWidget {
  const KioskSatelliteApp({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    final configured = container.settings.get(defs.startUrl).isNotEmpty;
    return MaterialApp(
      title: 'Kiosk Satellite',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: configured
          ? KioskScreen(container: container)
          : SetupScreen(container: container),
    );
  }
}
