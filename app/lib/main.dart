import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_container.dart';
import 'managers/settings/definitions.dart' as defs;
import 'ui/kiosk_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = AppContainer();
  await container.init();

  // The WebView's getUserMedia (Voice Satellite mic, camera dashboards) only
  // works if the app itself holds the OS runtime grant — otherwise Chromium
  // reports "Could not start audio source". Request before the first load.
  await _requestMediaPermissions(container);

  // Kiosk devices run fullscreen; system bars come back with a swipe.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(KioskSatelliteApp(container: container));
}

Future<void> _requestMediaPermissions(AppContainer container) async {
  try {
    final statuses = await [Permission.microphone, Permission.camera].request();
    container.log.info('permissions',
        'mic=${statuses[Permission.microphone]}, camera=${statuses[Permission.camera]}');
  } catch (e) {
    container.log.warn('permissions', 'request failed: $e');
  }
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
