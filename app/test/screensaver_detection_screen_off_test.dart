import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late List<String> screenCalls;
  late List<FaceDismissedScreensaver> previews;

  Future<void> build(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'black',
      ...initial,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    final calls = <String>[];
    screenCalls = calls;
    for (final name in ['screenOn', 'screenOff']) {
      commands.register(
        Command(
          name: name,
          description: 'Record screen power requests',
          handler: (_) async {
            calls.add(name);
            bus.publish(
              ScreenStateChanged(on: name == 'screenOn', source: 'app'),
            );
            return const CommandResult.ok();
          },
        ),
      );
    }
    previews = [];
    bus.on<FaceDismissedScreensaver>().listen(previews.add);
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
  }

  for (final (kind, event, onlyWhenOff) in [
    (
      'motion',
      const MotionDetected(),
      defs.screensaverDismissOnMotionScreenOffOnly,
    ),
    ('face', const FaceDetected(), defs.screensaverDismissOnFaceScreenOffOnly),
    (
      'proximity',
      const ProximityDetected(),
      defs.screensaverDismissOnProximityScreenOffOnly,
    ),
    (
      'person',
      const PersonDetected(),
      defs.screensaverDismissOnPersonScreenOffOnly,
    ),
  ]) {
    final dismissKey = 'ks.screensaver.dismiss_on_$kind';
    final onlyKey = 'ks.${onlyWhenOff.key}';

    test(
      '$kind leaves visible screensavers and the countdown alone then wakes',
      () {
        fakeAsync((async) {
          build({
            dismissKey: true,
            onlyKey: true,
            'ks.screensaver.timeout_seconds': 60,
            'ks.screensaver.screen_off_minutes': 5,
          });
          async.flushMicrotasks();
          async.elapse(const Duration(minutes: 1));
          expect(saver.isActive, isTrue);
          for (var minute = 0; minute < 5; minute++) {
            bus.publish(event);
            async.flushMicrotasks();
            expect(saver.isActive, isTrue);
            expect(screenCalls, isEmpty);
            expect(previews, isEmpty);
            async.elapse(const Duration(minutes: 1));
          }
          expect(screenCalls, ['screenOff']);
          expect(saver.isActive, isTrue);

          bus.publish(event);
          async.flushMicrotasks();
          expect(saver.isActive, isFalse);
          expect(screenCalls, ['screenOff', 'screenOn']);
          expect(previews, hasLength(kind == 'face' ? 1 : 0));
        });
      },
    );

    test('$kind defaults to dismissing a visible screensaver', () async {
      await build({dismissKey: true});
      expect(settings.get(onlyWhenOff), isFalse);
      await saver.start();
      bus.publish(event);
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
      expect(screenCalls, ['screenOn']);
      await saver.dispose();
    });

    test('$kind restriction still allows touch dismissal', () async {
      await build({dismissKey: true, onlyKey: true});
      await saver.start();
      bus.publish(const ActivityDetected(source: 'touch'));
      await pumpEventQueue();
      expect(saver.isActive, isFalse);
      await saver.dispose();
    });

    test(
      '$kind restriction follows screen power changes during a session',
      () async {
        await build({dismissKey: true, onlyKey: true});
        await saver.start();
        bus.publish(const ScreenStateChanged(on: false));
        bus.publish(const ScreenStateChanged(on: true, source: 'app'));
        bus.publish(event);
        await pumpEventQueue();
        expect(saver.isActive, isTrue);

        await settings.set(onlyWhenOff, false);
        bus.publish(event);
        await pumpEventQueue();
        expect(saver.isActive, isFalse);
        await saver.dispose();
      },
    );

    for (final scheduleEnabled in [false, true]) {
      test(
        '$kind respects a schedule detection override of $scheduleEnabled',
        () async {
          await build({
            dismissKey: !scheduleEnabled,
            onlyKey: true,
            'ks.screensaver.schedule_enabled': true,
            'ks.screensaver.schedule':
                '[{"at":"00:00","mode":"black","$kind":$scheduleEnabled}]',
          });
          await saver.start();
          bus.publish(event);
          await pumpEventQueue();
          expect(saver.isActive, isTrue);
          bus.publish(const ScreenStateChanged(on: false));
          bus.publish(event);
          await pumpEventQueue();
          expect(saver.isActive, !scheduleEnabled);
          expect(screenCalls, scheduleEnabled ? ['screenOn'] : isEmpty);
          await saver.dispose();
        },
      );
    }

    test('$kind restriction does not change postponing before a session', () {
      fakeAsync((async) {
        build({
          dismissKey: true,
          onlyKey: true,
          'ks.screensaver.postpone_on_$kind': true,
          'ks.screensaver.timeout_seconds': 60,
        });
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 40));
        bus.publish(event);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 40));
        expect(saver.isActive, isFalse);
        async.elapse(const Duration(seconds: 20));
        expect(saver.isActive, isTrue);
      });
    });

    test(
      '$kind toggle is persisted and exposed through the settings schema',
      () async {
        await build({});
        expect(settings.visible(onlyWhenOff), isFalse);
        await settings.setFromJson('screensaver.dismiss_on_$kind', true);
        expect(settings.visible(onlyWhenOff), isTrue);
        await settings.setFromJson(onlyWhenOff.key, true);
        expect(
          settings.describe().firstWhere(
            (row) => row['key'] == onlyWhenOff.key,
          ),
          containsPair('value', true),
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(onlyKey), isTrue);
        await saver.dispose();
      },
    );
  }
}
