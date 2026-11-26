import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/ground_control/client_key.dart';
import 'package:kiosk_satellite/managers/ground_control/ground_control_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The control connection proves it is Kiosk Satellite: it signs Ground
/// Control's challenge, waits for approval and hands the ticket to the
/// voice turns. A fake Ground Control checks the signature as the real one
/// does (ground_control/clients.py).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final seed = List<int>.generate(32, (i) => i);
  late HttpServer server;
  late List<Map<String, Object?>> received;
  late StreamController<String> toKiosk;
  late SimplePublicKey public;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/ground_control'),
          (_) async => null,
        );
    SharedPreferences.setMockInitialValues({});
    public = await (await Ed25519().newKeyPairFromSeed(
      seed,
    )).extractPublicKey();
    received = [];
    toKiosk = StreamController<String>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final ws = await WebSocketTransformer.upgrade(req);
      ws.add(jsonEncode({'type': 'challenge', 'nonce': 'n0nce'}));
      toKiosk.stream.listen(ws.add);
      ws.listen((m) => received.add((jsonDecode(m as String) as Map).cast()));
    });
  });

  tearDown(() async {
    // Nobody listens when no kiosk connected: closing would wait forever.
    unawaited(toKiosk.close());
    await server.close(force: true);
  });

  Future<(GroundControlManager, List<GroundControlServiceChanged>)> start({
    ClientKey? key,
    String deviceName = '',
    String fleetId = '',
  }) async {
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    await settings.set(defs.voiceEnabled, true);
    await settings.set(defs.voiceMatchEnabled, true);
    await settings.set(defs.groundControlEnabled, true);
    await settings.set(defs.deviceName, deviceName);
    await settings.set(defs.fleetId, fleetId);
    await settings.set(
      defs.groundControlAddress,
      'http://127.0.0.1:${server.port}',
    );
    final published = <GroundControlServiceChanged>[];
    bus.on<GroundControlServiceChanged>().listen(published.add);
    final gc = GroundControlManager(
      bus,
      commands,
      log,
      settings,
      clientKey: () async => key,
    );
    addTearDown(gc.dispose);
    await gc.init();
    return (gc, published);
  }

  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(done(), isTrue);
  }

  test(
    'signs the challenge and waits for approval before the ticket',
    () async {
      final (gc, published) = await start(key: ClientKey('test', seed));
      await until(() => received.isNotEmpty);
      final hello = received.single;
      expect(hello['type'], 'hello');
      final proof = (hello['proof'] as Map).cast<String, Object?>();
      expect(proof['key'], 'test');
      final ok = await Ed25519().verify(
        utf8.encode('${ClientKey.protocol}\nn0nce\n${hello['device_id']}'),
        signature: Signature(
          base64Decode('${proof['sig']}'),
          publicKey: public,
        ),
      );
      expect(ok, isTrue);
      expect((hello['features'] as Map)['trimming'], isTrue);
      expect((hello['features'] as Map)['isolation'], isTrue);
      expect((hello['features'] as Map)['wake_word_aligner'], isTrue);

      toKiosk.add(jsonEncode({'type': 'pending'}));
      await until(() => gc.status == 'pending');
      expect(published.where((e) => e.baseUrl != null), isEmpty);

      toKiosk.add(jsonEncode({'type': 'ticket', 'ticket': 't1'}));
      toKiosk.add(
        jsonEncode({
          'type': 'people',
          'people': <Object>[],
          'install': 'docker',
          'arch': 'amd64',
          'cuda': '12.9',
          'on_gpu': true,
        }),
      );
      await until(() => gc.status == 'connected');
      expect(gc.describe()['install'], {
        'install': 'docker',
        'arch': 'amd64',
        'cuda': '12.9',
        'onGpu': true,
      });
      expect(published.last.ticket, 't1');
      expect(published.last.baseUrl, 'http://127.0.0.1:${server.port}');

      // A Ground Control that doesn't say leaves nothing from the last one.
      toKiosk.add(jsonEncode({'type': 'people', 'people': <Object>[]}));
      await until(() => (gc.describe()['install'] as Map).isEmpty);

      // Declined later: the voice turns stop using it.
      toKiosk.add(jsonEncode({'type': 'declined'}));
      await until(() => gc.status == 'declined');
      expect(published.last.baseUrl, isNull);
      expect(gc.ticket, isNull);
    },
  );

  test('goes by a name made from the device id without a name (#15)', () async {
    // Ground Control turns away a hello without a device id.
    final (gc, _) = await start(
      key: ClientKey('test', seed),
      fleetId: '9F3c0aD41E7b2A6c',
    );
    await until(() => received.isNotEmpty);
    expect(received.single['device_id'], 'kiosk-satellite-7b2a6c');
    expect(gc.deviceId, 'kiosk-satellite-7b2a6c');
  });

  test('goes by its device name when it has one', () async {
    await start(
      key: ClientKey('test', seed),
      deviceName: 'Kitchen Tablet',
      fleetId: '9f3c0ad41e7b2a6c',
    );
    await until(() => received.isNotEmpty);
    expect(received.single['device_id'], 'ks-kitchen-tablet');
  });

  test('the Ground Control id falls back in order', () {
    expect(defs.groundControlDeviceId('Hall', 'Kitchen', 'abc123def'), 'hall');
    expect(
      defs.groundControlDeviceId('', 'Kitchen', 'abc123def'),
      'ks-kitchen',
    );
    expect(
      defs.groundControlDeviceId('', '', 'abc123def'),
      'kiosk-satellite-123def',
    );
    expect(
      defs.groundControlDeviceId('', '\u{1F600}', 'abc'),
      'kiosk-satellite-abc',
    );
    expect(defs.groundControlDeviceId('', '', ''), '');
  });

  test('signs exactly what Ground Control checks', () async {
    // The signature ground_control/clients.py makes with the same seed.
    final proof = await ClientKey('test', seed).proof('n0nce', 'k1');
    expect(
      proof['sig'],
      'jQPzt3mFi0Q0MgUPoBnnkoyEk5bahS/CWcMp81v9pTkc3WLWARQmOK1WU5Ru2Bf5GHpAB29bakImehGA/z9oAg==',
    );
  });

  test('a build without the key says so', () async {
    final (gc, _) = await start();
    await until(() => received.isNotEmpty);
    expect(received.single.containsKey('proof'), isFalse);
    toKiosk.add(jsonEncode({'type': 'error', 'code': 'not_kiosk_satellite'}));
    await until(() => gc.status == 'unsigned');
  });
}
