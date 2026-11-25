import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/ground_control/ground_control_manager.dart';
import 'package:kiosk_satellite/managers/js_api/js_api_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who Face Recognition sees at the kiosk, as plugins with the
/// face.recognition capability and Home Assistant and custom pages read
/// it through the JS API.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late GroundControlManager gc;
  late List<FaceRecognitionChanged> changes;
  late List<FaceArrivalReported> arrivals;

  const ana = FaceInViewChanged(
    id: 'a1',
    name: 'Ana',
    score: 0.8,
    color: '#3366ff',
    people: [(id: 'a1', name: 'Ana'), (id: 'l1', name: 'Leo')],
    colors: {'a1': '#3366ff', 'l1': '#ff9900'},
  );

  Future<void> on({bool presence = false}) async {
    await settings.set(defs.groundControlEnabled, true);
    await settings.set(defs.cameraEnabled, true);
    await settings.set(defs.visionMatchEnabled, true);
    await settings.set(defs.visionMatchPresenceSensors, presence);
  }

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/ground_control'),
          (_) async => null,
        );
    SharedPreferences.setMockInitialValues({});
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    gc = GroundControlManager(bus, commands, log, settings);
    await gc.init();
    gc.people = const [
      {
        'id': 'a1',
        'name': 'Ana',
        'things': {'person': 'person.ana'},
      },
      {'id': 'l1', 'name': 'Leo', 'things': <String, String>{}},
    ];
    changes = [];
    arrivals = [];
    bus.on<FaceRecognitionChanged>().listen(changes.add);
    bus.on<FaceArrivalReported>().listen(arrivals.add);
  });

  tearDown(() => gc.dispose());

  test('off, nobody is reported even with a face in view', () async {
    bus.publish(ana);
    await pumpEventQueue();
    expect(gc.faceRecognitionState(), {
      'enabled': false,
      'name': '',
      'person': '',
      'color': null,
      'people': <Object?>[],
      'present': null,
      'looking': null,
    });
  });

  test('the person at the kiosk and everyone in view, with their Home '
      'Assistant person and never the Ground Control id', () async {
    await on();
    bus.publish(ana);
    await pumpEventQueue();
    final state = gc.faceRecognitionState();
    expect(state, {
      'enabled': true,
      'name': 'Ana',
      'person': 'person.ana',
      'color': '#3366ff',
      'people': [
        {'name': 'Ana', 'person': 'person.ana', 'color': '#3366ff'},
        {'name': 'Leo', 'person': '', 'color': '#ff9900'},
      ],
      'present': null,
      'looking': null,
    });
    expect(changes.last.state, state);
    final result = await commands.execute('faceRecognitionState', const {});
    expect(result.data, state);
  });

  test('presence and looking come with Presence sensors on', () async {
    await on(presence: true);
    expect(gc.faceRecognitionState()['present'], isFalse);
    bus.publish(const VisionPresenceChanged(present: true, looking: true));
    await pumpEventQueue();
    expect(gc.faceRecognitionState()['present'], isTrue);
    expect(gc.faceRecognitionState()['looking'], isTrue);
  });

  test('a change is published once', () async {
    await on();
    await pumpEventQueue();
    changes.clear();
    bus.publish(ana);
    bus.publish(ana);
    await pumpEventQueue();
    expect(changes, hasLength(1));
  });

  test('arrivals and leaves carry the Home Assistant person', () async {
    bus.publish(const FaceArrived(id: 'a1', name: 'Ana'));
    bus.publish(const FaceLeft(id: 'l1', name: 'Leo'));
    await pumpEventQueue();
    expect(
      [for (final a in arrivals) a.toJson()],
      [
        {'event': 'arrived', 'name': 'Ana', 'person': 'person.ana'},
        {'event': 'left', 'name': 'Leo', 'person': ''},
      ],
    );
  });

  group('JS API', () {
    late JsApiManager api;

    setUp(() async {
      await on();
      bus.publish(ana);
      await pumpEventQueue();
      api = JsApiManager(bus, commands, Logger(), '1.0.0')
        ..faceRecognitionOrigins = () => {
          'http://homeassistant.local:8123',
          'https://pages.example.com',
        };
    });

    Future<Object?> read(String? origin) =>
        api.handleCall(['getFaceRecognition'], origin: origin);

    test('Home Assistant and custom pages read who is at the kiosk', () async {
      expect(
        (await read('http://homeassistant.local:8123') as Map)['name'],
        'Ana',
      );
      expect((await read('https://pages.example.com') as Map)['name'], 'Ana');
    });

    test('any other site and frames inside a page read nothing', () async {
      expect(await read('https://elsewhere.example.com'), isNull);
      expect(await read('http://homeassistant.local:8124'), isNull);
      expect(await read('file:///sdcard/page.html'), isNull);
      expect(await read(null), isNull);
    });

    test('without a source of origins no page reads it', () async {
      api.faceRecognitionOrigins = null;
      expect(await read('http://homeassistant.local:8123'), isNull);
    });
  });
}
