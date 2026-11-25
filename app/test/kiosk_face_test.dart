import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/kiosk/kiosk_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kiosk Mode and Lockdown Mode > Ground Control Vision Match: Skip the PIN
/// for the chosen people recognized at the kiosk, and Lock and unlock with
/// faces.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const faceRecognition = {
    'ks.camera.enabled': true,
    'ks.ground_control.enabled': true,
    'ks.vision_match.enabled': true,
    'ks.vision_match.face_detection': true,
    'ks.vision_match.face_recognition': true,
  };
  const chosenAna = '[{"id":"ana","name":"Ana"}]';

  late EventBus bus;
  late SettingsManager settings;
  late KioskManager kiosk;

  /// Builds the managers inside [async], so the bus listeners' timers run
  /// on fake time.
  void build(FakeAsync async, Map<String, Object> extra) {
    SharedPreferences.setMockInitialValues({...faceRecognition, ...extra});
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    commands.register(
      Command(
        name: 'bringToFront',
        description: 'test stub',
        handler: (_) async => const CommandResult.ok(true),
      ),
    );
    settings = SettingsManager(bus, commands, log);
    settings.init();
    async.flushMicrotasks();
    kiosk = KioskManager(bus, commands, log, settings);
    kiosk.init();
    async.flushMicrotasks();
  }

  void see(FakeAsync async, List<({String id, String name})> people) {
    bus.publish(
      FaceInViewChanged(
        id: people.isEmpty ? null : people.first.id,
        name: people.isEmpty ? '' : people.first.name,
        people: people,
      ),
    );
    async.flushMicrotasks();
  }

  const ana = (id: 'ana', name: 'Ana');
  const leo = (id: 'leo', name: 'Leo');

  group('Skip the PIN for', () {
    test('Nobody, the default, never skips it', () {
      fakeAsync((async) {
        build(async, {'ks.kiosk.enabled': true});
        see(async, [ana]);
        expect(kiosk.faceSkipsPin(lockdown: false), isFalse);
      });
    });

    test('Chosen people skips it only for a chosen person in view', () {
      fakeAsync((async) {
        build(async, {
          'ks.kiosk.enabled': true,
          'ks.kiosk.face_skip_pin': 'people',
          'ks.kiosk.face_people': chosenAna,
        });
        final skipped = <FacePinSkipped>[];
        bus.on<FacePinSkipped>().listen(skipped.add);
        expect(kiosk.faceSkipsPin(lockdown: false), isFalse);
        see(async, [leo]);
        expect(kiosk.faceSkipsPin(lockdown: false), isFalse);
        see(async, [leo, ana]);
        expect(kiosk.faceSkipsPin(lockdown: false), isTrue);
        async.flushMicrotasks();
        expect(skipped.single.name, 'Ana');
        expect(skipped.single.lockdown, isFalse);
        // The lockdown exit has its own setting.
        expect(kiosk.faceSkipsPin(lockdown: true), isFalse);
      });
    });

    test('with nobody chosen, anyone recognized skips it', () {
      fakeAsync((async) {
        build(async, {'ks.lockdown.face_skip_pin': 'people'});
        see(async, [leo]);
        expect(kiosk.faceSkipsPin(lockdown: true), isTrue);
      });
    });

    test('without Face Recognition the setting is hidden and does nothing', () {
      fakeAsync((async) {
        build(async, {
          'ks.kiosk.enabled': true,
          'ks.vision_match.face_recognition': false,
          'ks.kiosk.face_skip_pin': 'people',
        });
        see(async, [ana]);
        expect(kiosk.faceSkipsPin(lockdown: false), isFalse);
      });
    });
  });

  group('Lock and unlock with faces', () {
    Map<String, Object> auto() => {
      'ks.lockdown.face_skip_pin': 'people',
      'ks.lockdown.face_people': chosenAna,
      'ks.lockdown.face_auto': true,
    };

    test('locks 10 s after nobody chosen is in view and unlocks when a '
        'chosen person arrives', () {
      fakeAsync((async) {
        build(async, auto());
        see(async, []);
        async.elapse(const Duration(seconds: 9));
        expect(settings.get(defs.lockdownEnabled), isFalse);
        async.elapse(const Duration(seconds: 2));
        expect(settings.get(defs.lockdownEnabled), isTrue);
        // Someone not chosen keeps it locked.
        see(async, [leo]);
        expect(settings.get(defs.lockdownEnabled), isTrue);
        see(async, [leo, ana]);
        expect(settings.get(defs.lockdownEnabled), isFalse);
        // Ana leaves: locked again 10 s later.
        see(async, [leo]);
        async.elapse(const Duration(seconds: 5));
        expect(settings.get(defs.lockdownEnabled), isFalse);
        async.elapse(const Duration(seconds: 6));
        expect(settings.get(defs.lockdownEnabled), isTrue);
      });
    });

    test('a lock from Home Assistant holds while a chosen person stays', () {
      fakeAsync((async) {
        build(async, auto());
        see(async, [ana]);
        settings.set(defs.lockdownEnabled, true);
        async.flushMicrotasks();
        see(async, [ana]);
        async.elapse(const Duration(seconds: 30));
        expect(settings.get(defs.lockdownEnabled), isTrue);
      });
    });

    test('off by default', () {
      fakeAsync((async) {
        build(async, {
          'ks.lockdown.face_skip_pin': 'people',
          'ks.lockdown.face_people': chosenAna,
        });
        see(async, []);
        async.elapse(const Duration(seconds: 30));
        expect(settings.get(defs.lockdownEnabled), isFalse);
        expect(defs.lockdownFaceAuto.defaultValue, isFalse);
      });
    });
  });
}
