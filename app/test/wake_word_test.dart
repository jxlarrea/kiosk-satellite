import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The wake-word handoff protocol (docs/js-api.md): detection stops the
/// native engine before the event is published; the page resumes listening
/// via setWakeWordActive(true).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late SettingsManager settings;
  late WakeWordManager wakeWord;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'ks.wake_word.enabled': true,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    wakeWord = WakeWordManager(bus, commands, log, settings);
    await wakeWord.init();
  });

  tearDown(() async {
    await wakeWord.dispose();
    await bus.dispose();
  });

  test('listens on init when enabled', () {
    expect(wakeWord.listening, isTrue);
  });

  test('detection releases the mic before publishing, page resume re-arms',
      () async {
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
    // Mic released before the page hears about the detection.
    expect(listeningAtDetection, isFalse);
    expect(wakeWord.listening, isFalse);

    // Page finished its voice session and resumes us.
    final resume =
        await commands.execute('setWakeWordActive', const {'active': true});
    expect(resume.ok, isTrue);
    expect(wakeWord.listening, isTrue);
  });

  test('getWakeWordState reflects suspension', () async {
    await commands.execute('setWakeWordActive', const {'active': false});
    final state = await commands.execute('getWakeWordState', const {});
    expect(state.ok, isTrue);
    final data = state.data as Map<String, Object?>;
    expect(data['active'], isFalse);
    expect(data['listening'], isFalse);
  });

  test('disabling the setting stops listening', () async {
    await settings.setFromJson('wake_word.enabled', false);
    await Future<void>.delayed(Duration.zero);
    expect(wakeWord.listening, isFalse);
  });
}
