import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/fleet/fleet_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The kiosk switcher's discovery: the native bridge announces this device
/// and streams the kiosks it hears; the manager runs it only while the
/// remote admin serves and Find other kiosks is on, answers the `fleet`
/// command with this device first and the rest by name, and publishes a
/// change as an event the remote admin page hears.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  var listens = 0;
  var cancels = 0;
  MockStreamHandlerEventSink? sink;
  Map<String, Object?> snapshot = {'self': null, 'peers': const []};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/fleet'),
          (call) async {
            calls.add(call);
            return switch (call.method) {
              'snapshot' => snapshot,
              _ => null,
            };
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('kiosk_satellite/fleet_stream'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              listens++;
              sink = events;
            },
            onCancel: (arguments) {
              cancels++;
              sink = null;
            },
          ),
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late Logger log;
  late SettingsManager settings;
  late FleetManager fleet;
  late List<FleetChanged> events;

  Future<void> build(Map<String, Object> initial) async {
    calls.clear();
    listens = 0;
    cancels = 0;
    sink = null;
    snapshot = {'self': null, 'peers': const []};
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    events = [];
    bus.on<FleetChanged>().listen(events.add);
    fleet = FleetManager(bus, commands, log, settings);
    addTearDown(fleet.dispose);
    await fleet.init();
  }

  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  const serving = {
    'ks.remote.enabled': true,
    'ks.remote.password': 'secret',
    'ks.remote.port': 2324,
    'ks.device.name': 'Living Room',
  };

  const self = {
    'id': 'aaaa',
    'name': 'Living Room',
    'version': '2026.9.18',
    'address': '192.168.1.30',
    'port': 2324,
  };

  test('announces with the device name and admin port while serving', () async {
    await build(serving);
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments, {'name': 'Living Room', 'port': 2324});
    expect(listens, 1);
    expect(fleet.running, isTrue);
  });

  test('stays off without remote management or a password', () async {
    await build({'ks.remote.enabled': true, 'ks.remote.port': 2324});
    expect(calls.where((c) => c.method == 'start'), isEmpty);
    expect(fleet.running, isFalse);

    await build({'ks.remote.password': 'secret'});
    expect(calls.where((c) => c.method == 'start'), isEmpty);
  });

  test('the switch stops and restarts it', () async {
    await build(serving);
    await settings.set(defs.remoteFleetDiscovery, false);
    await pump();
    expect(calls.last.method, 'stop');
    expect(cancels, 1);
    expect(fleet.running, isFalse);

    await settings.set(defs.remoteFleetDiscovery, true);
    await pump();
    expect(calls.last.method, 'start');
    expect(fleet.running, isTrue);
  });

  test('a rename goes out at once', () async {
    await build(serving);
    calls.clear();
    await settings.set(defs.deviceName, 'Kitchen');
    await pump();
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments, {'name': 'Kitchen', 'port': 2324});
    // Still the one stream: a restart is a re-announce, not a new listen.
    expect(listens, 1);
  });

  test('lists this device first and the others by name', () async {
    await build(serving);
    // The command re-reads the native snapshot, so it holds the same.
    snapshot = {
      'self': self,
      'peers': [
        {
          'id': 'cccc',
          'name': 'kitchen',
          'version': '2026.9.17',
          'address': '192.168.1.70',
          'port': 2324,
        },
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    };
    sink!.success(snapshot);
    await pump();

    final r = await commands.execute('fleet', const {});
    expect(r.ok, isTrue);
    final data = r.data as Map;
    expect(data['enabled'], isTrue);
    final devices = (data['devices'] as List).cast<Map>();
    expect(devices.map((d) => d['name']), [
      'Living Room',
      'Bedroom',
      'kitchen',
    ]);
    expect(devices.first['self'], isTrue);
    expect(devices[1]['self'], isFalse);
    expect(devices[1]['url'], 'http://192.168.1.71:2324');
    expect(devices[2]['version'], '2026.9.17');
  });

  test('publishes a change as an event the remote page hears', () async {
    await build(serving);
    sink!.success({
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    });
    await pump();
    expect(events, hasLength(1));
    expect(events.single.wireName, 'fleet');
    final listed = events.single.toJson()['devices'] as List;
    expect(listed, hasLength(2));

    // The same list again is not a change.
    sink!.success({
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    });
    await pump();
    expect(events, hasLength(1));

    // A peer gone is.
    sink!.success({'self': self, 'peers': const []});
    await pump();
    expect(events, hasLength(2));
    expect((events.last.toJson()['devices'] as List), hasLength(1));
  });

  test('the fleet command reads the native snapshot while running', () async {
    await build(serving);
    snapshot = {
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    };
    final r = await commands.execute('fleet', const {});
    final devices = (r.data as Map)['devices'] as List;
    expect(devices, hasLength(2));
    expect(calls.last.method, 'snapshot');
  });

  test('the remote admin switching off empties the list', () async {
    await build(serving);
    sink!.success({
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    });
    await pump();
    await settings.set(defs.remoteEnabled, false);
    await pump();
    expect(fleet.running, isFalse);
    final r = await commands.execute('fleet', const {});
    expect((r.data as Map)['enabled'], isFalse);
    expect((r.data as Map)['devices'], isEmpty);
    expect(events.last.toJson()['devices'], isEmpty);
  });
}
