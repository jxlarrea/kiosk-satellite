import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/ground_control/ground_control_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The esphome.kiosk_satellite_speaker event: each voice Voice Match
/// places goes to Home Assistant with the person, the score and how.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late GroundControlManager gc;
  late List<HaEventRequested> fired;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/ground_control'),
          (_) async => null,
        );
    SharedPreferences.setMockInitialValues({});
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    gc = GroundControlManager(bus, commands, log, settings);
    await gc.init();
    gc.people = const [
      {
        'id': 'x1',
        'name': 'Xavier',
        'things': {'person': 'person.xavier'},
      },
      {'id': 'a1', 'name': 'Ana', 'things': <String, String>{}},
    ];
    fired = [];
    bus.on<HaEventRequested>().listen(fired.add);
  });

  tearDown(() => gc.dispose());

  test('a recognized voice, with its Home Assistant person', () async {
    bus.publish(
      const VoiceSpeakerChanged('Xavier', id: 'x1', by: 'voice', score: 0.71),
    );
    bus.publish(const VoiceSpeakerChanged('Ana', id: 'a1', by: 'only_person'));
    await pumpEventQueue();
    expect(
      [for (final e in fired) e.name],
      ['kiosk_satellite_speaker', 'kiosk_satellite_speaker'],
    );
    expect(fired[0].data, {
      'event_type': 'recognized',
      'name': 'Xavier',
      'person': 'person.xavier',
      'score': 0.71,
      'by': 'voice',
    });
    expect(fired[1].data, {
      'event_type': 'recognized',
      'name': 'Ana',
      'person': '',
      'score': null,
      'by': 'only_person',
    });
  });

  test('a voice nobody enrolled has no name', () async {
    bus.publish(const VoiceSpeakerChanged('', score: 0.21));
    await pumpEventQueue();
    expect(fired.single.data, {
      'event_type': 'unknown',
      'name': '',
      'person': '',
      'score': 0.21,
      'by': '',
    });
  });

  test('a new turn clearing the speaker fires nothing', () async {
    bus.publish(const VoiceSpeakerChanged(''));
    await pumpEventQueue();
    expect(fired, isEmpty);
  });
}
