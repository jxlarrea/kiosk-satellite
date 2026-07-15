import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The wake-word contract (docs/js-api.md): config is pushed by the Voice
/// Satellite card (setWakeWordConfig), detection releases the mic before the
/// event is published, and the page resumes listening via
/// setWakeWordActive(true).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late WakeWordManager wakeWord;

  const vsConfig = {
    'engine': 'microWakeWord',
    'models': [
      {
        'id': 'okay_nabu',
        'wakeWord': 'Okay Nabu',
        'manifestUrl': 'http://ha.local:8123/voice_satellite/models/okay_nabu.json',
      },
    ],
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    wakeWord = WakeWordManager(bus, commands, log, settings);
    await wakeWord.init();
  });

  tearDown(() async {
    await wakeWord.dispose();
    await bus.dispose();
  });

  test('unconfigured until Voice Satellite pushes a config', () async {
    expect(wakeWord.available, isFalse);
    final state = await commands.execute('getWakeWordState', const {});
    expect((state.data as Map)['engine'], isNull);
  });

  test('rejects malformed configs', () async {
    final result = await commands
        .execute('setWakeWordConfig', const {'engine': 'bogus', 'models': []});
    expect(result.ok, isFalse);
  });

  test('accepts a VS config and reports native availability honestly',
      () async {
    final result = await commands.execute('setWakeWordConfig', vsConfig);
    expect(result.ok, isTrue);
    // microWakeWord now has a native TFLite runner, so we take the handoff.
    expect((result.data as Map)['available'], isTrue);

    final state = await commands.execute('getWakeWordState', const {});
    final data = state.data as Map<String, Object?>;
    expect(data['engine'], 'microWakeWord');
    expect((data['models'] as List), hasLength(1));
  });

  test('detection releases the mic before publishing, page resume re-arms',
      () async {
    await commands.execute('setWakeWordConfig', vsConfig);

    final detections = <WakeWordDetected>[];
    var listeningAtDetection = true;
    bus.on<WakeWordDetected>().listen((e) {
      detections.add(e);
      listeningAtDetection = wakeWord.listening;
    });

    final result = await commands.execute('simulateWakeWord', const {});
    expect(result.ok, isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(detections, hasLength(1));
    expect(detections.single.model, 'okay_nabu');
    expect(detections.single.phrase, 'Okay Nabu');
    // Mic released before the page hears about the detection.
    expect(listeningAtDetection, isFalse);

    // Detection suspends listening until the page resumes us.
    var state = await commands.execute('getWakeWordState', const {});
    expect((state.data as Map)['active'], isFalse);

    await commands.execute('setWakeWordActive', const {'active': true});
    state = await commands.execute('getWakeWordState', const {});
    expect((state.data as Map)['active'], isTrue);
  });
}
