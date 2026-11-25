import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/ground_control/ground_control_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Ground Control person's Home Assistant picture, for the camera
/// preview's name card: from the person entity they are linked to, read
/// with the kiosk's token and looked up once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the linked person entity gives the picture, and nothing without a '
      'link', () async {
    // The test binding answers every HTTP request with 400. This one talks
    // to a stand-in Home Assistant.
    final mocked = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = mocked);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final seen = <String>[];
    server.listen((request) async {
      seen.add('${request.uri.path} ${request.headers.value('authorization')}');
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'entity_id': 'person.ana',
          'attributes': {'entity_picture': '/api/image/serve/ana/512x512'},
        }),
      );
      await request.response.close();
    });
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    await settings.set(defs.haUrl, 'http://127.0.0.1:${server.port}/');
    await settings.set(defs.haToken, 'tok');
    final gc = GroundControlManager(bus, commands, log, settings);
    gc.people = [
      {
        'id': 'ana',
        'name': 'Ana',
        'things': {'person': 'person.ana'},
      },
      {'id': 'leo', 'name': 'Leo', 'things': <String, Object?>{}},
    ];
    final base = 'http://127.0.0.1:${server.port}';
    expect(await gc.pictureOf('ana'), '$base/api/image/serve/ana/512x512');
    expect(await gc.pictureOf('ana'), '$base/api/image/serve/ana/512x512');
    expect(await gc.pictureOf('leo'), isNull);
    expect(seen, ['/api/states/person.ana Bearer tok']);
  });
}
