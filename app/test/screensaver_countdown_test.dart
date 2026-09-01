import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The idle clock's due moment (issue #406): announced whenever it moves,
/// null whenever nothing counts down, and readable through a command so the
/// ESPHome surface can seed its sensor at server start.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late ScreensaverManager saver;
  late List<DateTime?> announced;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
    announced = [];
    bus.on<ScreensaverCountdownChanged>().listen((e) => announced.add(e.due));
  }

  test('the due moment follows the clock: armed at init, moved by a touch, '
      'cleared when it fires', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.timeout_seconds': 30,
      });
      async.flushMicrotasks();
      final start = DateTime(2026, 9, 1, 12);
      var now = start;
      saver.clock = () => now;
      saver.init();
      async.flushMicrotasks();
      expect(saver.idleDue, start.add(const Duration(seconds: 30)));
      expect(announced, [start.add(const Duration(seconds: 30))]);

      now = start.add(const Duration(seconds: 10));
      async.elapse(const Duration(seconds: 10));
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.idleDue, start.add(const Duration(seconds: 40)));
      expect(announced.last, start.add(const Duration(seconds: 40)));

      final due = commands.execute('getScreensaverDue', const {});
      async.flushMicrotasks();
      var read = '';
      due.then((r) => read = '${r.data}');
      async.flushMicrotasks();
      expect(
        read,
        start.add(const Duration(seconds: 40)).toUtc().toIso8601String(),
      );

      now = start.add(const Duration(seconds: 40));
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
      expect(saver.idleDue, isNull);
      expect(announced.last, isNull);
    });
  });

  test('a hold clears the moment and its release brings a fresh one', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.timeout_seconds': 30,
      });
      async.flushMicrotasks();
      saver.init();
      async.flushMicrotasks();
      expect(saver.idleDue, isNotNull);

      bus.publish(
        const CameraViewStateChanged(viewId: 'front', viewName: 'Front'),
      );
      async.flushMicrotasks();
      expect(saver.idleDue, isNull);
      expect(announced.last, isNull);

      bus.publish(const CameraViewStateChanged(viewId: null, viewName: null));
      async.flushMicrotasks();
      expect(saver.idleDue, isNotNull);
      expect(announced.last, saver.idleDue);

      // A voice turn holds the clock until the turn ends.
      bus.publish(
        const WakeWordDetected(model: 'okay_nabu', phrase: 'okay nabu'),
      );
      async.flushMicrotasks();
      expect(saver.idleDue, isNull);
      bus.publish(const WakeWordStateChanged(active: true, listening: true));
      async.flushMicrotasks();
      expect(saver.idleDue, isNotNull);
    });
  });

  test('a settings change moves the moment, the session\'s own saved '
      'brightness write does not', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.timeout_seconds': 30,
      });
      async.flushMicrotasks();
      saver.init();
      async.flushMicrotasks();
      final armed = saver.idleDue;
      announced.clear();
      bus.publish(
        const SettingChanged(key: 'screensaver.saved_brightness', value: 0.4),
      );
      async.flushMicrotasks();
      expect(saver.idleDue, armed);
      expect(announced, isEmpty);
      async.elapse(const Duration(seconds: 5));
      bus.publish(
        const SettingChanged(key: 'screensaver.timeout_seconds', value: 60),
      );
      async.flushMicrotasks();
      expect(saver.idleDue, isNot(armed));
      expect(announced, hasLength(1));
    });
  });

  test('a disabled screensaver or a zero timeout never announces a moment', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.enabled': false,
        'ks.screensaver.timeout_seconds': 30,
      });
      async.flushMicrotasks();
      saver.init();
      async.flushMicrotasks();
      saver.notifyActivity('touch');
      async.flushMicrotasks();
      expect(saver.idleDue, isNull);
      expect(announced, isEmpty);
      var read = 'unset';
      commands
          .execute('getScreensaverDue', const {})
          .then((r) => read = '${r.data}');
      async.flushMicrotasks();
      expect(read, 'null');
    });
  });
}
