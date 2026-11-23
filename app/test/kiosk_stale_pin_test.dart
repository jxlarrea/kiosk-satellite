import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/kiosk/kiosk_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A pin left over from a process that closed (issue #1565). The native
/// side ends it as the process starts. What is testable here is the note
/// in the app log: asked on the first apply an Activity answers, logged
/// once and not asked again.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const lockChannel = MethodChannel('kiosk_satellite/kiosk_lock');
  const note = 'ended a pin left over from before the app restarted';

  late Logger log;
  late CommandRegistry commands;
  late KioskManager kiosk;
  late List<String> lockCalls;

  /// What the mock native side answers to endedStalePin, one per ask. Null
  /// is a call no Activity was there to take.
  late List<bool?> answers;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    lockCalls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, (
      call,
    ) async {
      lockCalls.add(call.method);
      if (call.method != 'endedStalePin') return null;
      if (answers.isEmpty) throw MissingPluginException();
      final answer = answers.removeAt(0);
      if (answer == null) throw MissingPluginException();
      return answer;
    });
    kiosk = KioskManager(bus, commands, log, settings);
    kiosk.pushFlags = true;
    await kiosk.init();
  }

  /// One apply. On a host init makes none of its own, and re-arming after
  /// an install is a plain apply.
  Future<void> apply() => commands.execute('resumeKioskAfterInstall', const {});

  tearDown(() async {
    await kiosk.dispose();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(lockChannel, null);
  });

  int asks() => lockCalls.where((m) => m == 'endedStalePin').length;
  int notes() => log.recent.where((e) => e.message == note).length;

  test('an ended pin is logged once and not asked about again', () async {
    answers = [true];
    await build();
    await apply();
    expect(asks(), 1);
    expect(notes(), 1);

    await apply();
    expect(lockCalls.where((m) => m == 'apply').length, 2);
    expect(asks(), 1);
    expect(notes(), 1);
  });

  test('nothing is logged when no pin was ended', () async {
    answers = [false];
    await build();
    await apply();
    await apply();
    expect(asks(), 1);
    expect(notes(), 0);
  });

  test('an apply no Activity answered asks again on the next one', () async {
    answers = [null, true];
    await build();
    await apply();
    expect(asks(), 1);
    expect(notes(), 0);

    await apply();
    expect(asks(), 2);
    expect(notes(), 1);
  });
}
