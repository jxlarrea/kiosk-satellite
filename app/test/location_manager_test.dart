import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/location/location_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The GPS position for Home Assistant (issue #363). The native bridge
/// answers `support` (a receiver, or why not), `last` (the receiver's last
/// known fix) and streams fixes at the asked interval; the manager watches
/// the receiver only while Report location is on under an entity-serving
/// ESPHome server, keeps the switch off where there is no receiver, and
/// relays each fix as an event while keeping the last one across runs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const noReceiver = {
    'supported': false,
    'hint': 'Not available on this device: it has no GPS receiver.',
  };
  const receiver = {'supported': true};
  const fix = {
    'latitude': 45.5019,
    'longitude': -73.5674,
    'time': 1756500000000,
    'accuracy': 8.0,
    'altitude': 31.0,
    'speed': 0.5,
    'provider': 'gps',
  };

  var listens = 0;
  var cancels = 0;
  Object? listenArgs;
  Map<String, Object?>? nativeSupport;
  Map<String, Object?>? nativeLast;
  MockStreamHandlerEventSink? sink;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/location'),
          (call) async => switch (call.method) {
            'support' => nativeSupport,
            'last' => nativeLast,
            _ => null,
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('kiosk_satellite/location_stream'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              listens++;
              listenArgs = arguments;
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
  late LocationManager location;
  late List<LocationChanged> events;

  Future<void> build(Map<String, Object> initial) async {
    listens = 0;
    cancels = 0;
    listenArgs = null;
    sink = null;
    nativeLast = null;
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    events = [];
    bus.on<LocationChanged>().listen(events.add);
    location = LocationManager(
      bus,
      commands,
      log,
      settings,
      retryInterval: const Duration(milliseconds: 40),
    );
    addTearDown(location.dispose);
    await location.init();
  }

  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  const on = {
    'ks.esphome.enabled': true,
    'ks.esphome.entities': true,
    'ks.location.enabled': true,
  };

  test('no receiver: the switch is kept off and both surfaces get the '
      'reason', () async {
    nativeSupport = noReceiver;
    await build(on);
    await pump();
    expect(settings.get(defs.locationEnabled), isFalse);
    expect(location.locationKnownUnsupported, isTrue);
    expect(location.locationHint, noReceiver['hint']);
    expect(
      log.recent
          .where((e) => e.level == LogLevel.warn && e.tag == 'location')
          .map((e) => e.message),
      contains(
        'Report location kept off: not available on this device: it has '
        'no GPS receiver.',
      ),
    );
    final res = await commands.execute('getLocationSupport', const {});
    expect(res.data, noReceiver);
    expect(listens, 0);

    // A later write (the remote API, an import) is undone the same way.
    await settings.set(defs.locationEnabled, true);
    await pump();
    expect(settings.get(defs.locationEnabled), isFalse);
    expect(listens, 0);
  });

  test('a receiver: fixes flow at the asked interval, each one an event, '
      'the last kept across runs', () async {
    nativeSupport = receiver;
    await build({...on, 'ks.location.interval': 30});
    await pump();
    expect(settings.get(defs.locationEnabled), isTrue);
    expect(listens, 1);
    expect(listenArgs, {'intervalMs': 30000});
    expect(location.streaming, isTrue);

    sink!.success(fix);
    await pump();
    expect(events, hasLength(1));
    expect(events.single.latitude, 45.5019);
    expect(events.single.longitude, -73.5674);
    expect(events.single.accuracy, 8.0);
    expect(events.single.altitude, 31.0);
    expect(events.single.speed, 0.5);
    expect(
      events.single.time,
      DateTime.fromMillisecondsSinceEpoch(1756500000000, isUtc: true),
    );
    final status = await commands.execute('getLocation', const {});
    final data = status.data as Map;
    expect(data['enabled'], isTrue);
    expect(data['streaming'], isTrue);
    expect((data['fix'] as Map)['latitude'], 45.5019);

    // The fix outlives the process: the next run reads it before the
    // receiver has said anything.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('ks.internal.esphome_last_location'),
      contains('45.5019'),
    );
    expect(settings.internal('esphome_last_location'), contains('-73.5674'));
  });

  test('the receiver is only watched while everything above it is on, '
      'and a new interval re-asks', () async {
    nativeSupport = receiver;
    await build(on);
    await pump();
    expect(listens, 1);

    await settings.set(defs.locationInterval, 120);
    await pump();
    expect(cancels, 1);
    expect(listens, 2);
    expect(listenArgs, {'intervalMs': 120000});

    await settings.set(defs.esphomeEntities, false);
    await pump();
    expect(cancels, 2);
    expect(location.streaming, isFalse);
    expect(location.enabled, isFalse);

    await settings.set(defs.esphomeEntities, true);
    await pump();
    expect(listens, 3);

    await settings.set(defs.locationEnabled, false);
    await pump();
    expect(cancels, 3);
    expect(listens, 3);
  });

  test("the receiver's last known fix seeds the sensors before the first "
      'fresh one', () async {
    nativeSupport = receiver;
    await build(on);
    nativeLast = fix;
    // init already started the stream with no seed; a restart re-asks.
    await settings.set(defs.locationInterval, 20);
    await pump();
    expect(events, hasLength(1));
    expect(location.last?.latitude, 45.5019);
  });

  test('a refused stream says why and tries again', () async {
    nativeSupport = receiver;
    await build(on);
    await pump();
    expect(listens, 1);
    sink!.error(
      code: 'denied',
      message: 'location permission not granted',
      details: null,
    );
    await pump();
    expect(location.streaming, isFalse);
    expect(location.error, 'Location permission not granted.');
    final status = await commands.execute('getLocation', const {});
    expect((status.data as Map)['error'], 'Location permission not granted.');
    // The retry lands on its own; a grant on the permission row can also
    // nudge it at once.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(listens, greaterThanOrEqualTo(2));
    location.sync();
    await pump();
    expect(location.streaming, isTrue);
  });

  test('no answer counts as a receiver, never switching the feature off '
      'on a guess', () async {
    nativeSupport = null;
    await build(on);
    await pump();
    expect(settings.get(defs.locationEnabled), isTrue);
    expect(location.locationKnownUnsupported, isFalse);
    expect(listens, 1);
  });
}
