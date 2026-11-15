import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/audio/adaptive_volume_curve.dart';
import 'package:kiosk_satellite/managers/audio/adaptive_volume_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adaptive volume (issue #1450): the curve, and the manager that follows
/// the room's noise windows and hands each volume its share.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the curve', () {
    const curve = AdaptiveVolumeCurve([
      VolumePoint(-58, 0.4, 0.6, 0.8),
      VolumePoint(-50, 0.55, 0.7, 0.85),
      VolumePoint(-41, 0.75, 0.86, 0.96),
      VolumePoint(-30, 1, 1, 1),
    ]);

    test('the default is stored as the setting ships it', () {
      expect(
        AdaptiveVolumeCurve.defaults.encode(),
        AdaptiveVolumeCurve.defaultJson,
      );
      expect(
        defs.adaptiveVolumeCurve.defaultValue,
        AdaptiveVolumeCurve.defaultJson,
      );
      expect(
        AdaptiveVolumeCurve.check(AdaptiveVolumeCurve.defaultJson),
        isNull,
      );
    });

    test('a stored curve reads back', () {
      final read = AdaptiveVolumeCurve.parse(curve.encode());
      expect(read.points, curve.points);
    });

    test('each volume holds below the first point and above the last', () {
      expect(curve.levelAt(VolumeChannel.assistant, -90), 0.4);
      expect(curve.levelAt(VolumeChannel.media, -58), 0.6);
      expect(curve.levelAt(VolumeChannel.intercom, -30), 1);
      expect(curve.levelAt(VolumeChannel.assistant, -5), 1);
    });

    test('between two points a volume moves in a straight line', () {
      expect(curve.levelAt(VolumeChannel.assistant, -54), closeTo(0.475, 1e-9));
      expect(curve.levelAt(VolumeChannel.media, -45.5), closeTo(0.78, 1e-9));
      expect(curve.levelAt(VolumeChannel.intercom, -35.5), closeTo(0.98, 1e-9));
    });

    test('a point is bounded by its neighbors', () {
      final b = curve.bounds(1);
      expect(b.noiseLo, -57);
      expect(b.noiseHi, -42);
      expect(b.levelLo[VolumeChannel.assistant], 0.4);
      expect(b.levelHi[VolumeChannel.assistant], 0.75);
      expect(b.levelLo[VolumeChannel.media], 0.6);
      expect(b.levelHi[VolumeChannel.media], 0.86);
      final first = curve.bounds(0);
      expect(first.noiseLo, AdaptiveVolumeCurve.minNoise);
      expect(first.levelLo[VolumeChannel.intercom], 0);
      final last = curve.bounds(3);
      expect(last.noiseHi, AdaptiveVolumeCurve.maxNoise);
      expect(last.levelHi[VolumeChannel.assistant], 1);
    });

    test('a point dragged past a neighbor stops at it', () {
      final moved = curve.clamp(1, const VolumePoint(-20, 0.9, 0.2, 0.9));
      expect(moved.noise, -42);
      expect(moved.assistant, 0.75);
      expect(moved.media, 0.6);
      expect(moved.intercom, 0.9);
    });

    test('a curve that is not one is refused', () {
      String? check(String json) => AdaptiveVolumeCurve.check(json);
      expect(check('nonsense'), isNotNull);
      expect(check('[[-60,50,50,50]]'), isNotNull);
      expect(
        check('[[-60,50,50],[-50,60,60,60],[-40,70,70,70],[-30,80,80,80]]'),
        isNotNull,
      );
      // Noise levels that do not rise.
      expect(
        check('[[-60,50,50,50],[-60,60,60,60],[-40,70,70,70],[-30,80,80,80]]'),
        'Room noise levels must rise from one point to the next',
      );
      // A volume that falls.
      expect(
        check('[[-60,50,50,50],[-50,60,40,60],[-40,70,70,70],[-30,80,80,80]]'),
        'Volumes must not fall from one point to the next',
      );
      expect(
        check('[[-60,50,50,50],[-50,60,60,60],[-40,70,70,70],[-30,80,80,120]]'),
        'Enter volumes from 0 to 100',
      );
      expect(
        check('[[-120,50,50,50],[-50,60,60,60],[-40,70,70,70],[-30,80,80,80]]'),
        'Enter room noise levels from -96 to 0 dBFS',
      );
      // A value that is not a curve reads as the default one.
      expect(
        AdaptiveVolumeCurve.parse('nonsense').points,
        AdaptiveVolumeCurve.defaults.points,
      );
    });
  });

  group('the manager', () {
    late EventBus bus;
    late SettingsManager settings;
    late CommandRegistry commands;
    late AdaptiveVolumeManager manager;
    late List<AdaptiveVolumeChanged> events;
    late DateTime now;

    Future<void> build({bool enabled = true}) async {
      SharedPreferences.setMockInitialValues({});
      bus = EventBus();
      final log = Logger();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      await settings.set(defs.adaptiveVolume, enabled);
      // A straight line from 50% at -60 dBFS to 100% at -30.
      await settings.set(
        defs.adaptiveVolumeCurve,
        '[[-60,50,50,50],[-50,67,67,67],[-40,83,83,83],[-30,100,100,100]]',
      );
      events = [];
      bus.on<AdaptiveVolumeChanged>().listen(events.add);
      now = DateTime.utc(2026, 11, 14, 12);
      manager = AdaptiveVolumeManager(
        bus,
        commands,
        log,
        settings,
        now: () => now,
      );
      await manager.init();
      await pumpEventQueue();
    }

    /// One clean window of room noise, five seconds after the last.
    Future<void> window(
      double db, {
      Duration after = const Duration(seconds: 5),
    }) async {
      now = now.add(after);
      bus.publish(NoiseWindowMeasured(db));
      await pumpEventQueue();
    }

    tearDown(() async {
      await manager.dispose();
      await settings.dispose();
    });

    test('with no reading every volume plays at its slider', () async {
      await build();
      expect(manager.noise, isNull);
      expect(events.single.noise, isNull);
      expect(events.single.assistant, 1);
      expect(events.single.media, 1);
      expect(events.single.intercom, 1);
    });

    test('the first window sets the room and the assistant follows', () async {
      await build();
      await window(-60);
      expect(manager.noise, -60);
      expect(events.last.assistant, 0.5);
      // Media and the intercom do not follow the room until switched on.
      expect(events.last.media, 1);
      expect(events.last.intercom, 1);
    });

    test('a volume follows once its switch is on', () async {
      await build();
      await window(-60);
      await settings.set(defs.adaptiveVolumeMedia, true);
      await pumpEventQueue();
      expect(events.last.media, 0.5);
      // The intercom also needs the intercom itself.
      await settings.set(defs.adaptiveVolumeIntercom, true);
      await pumpEventQueue();
      expect(events.last.intercom, 1);
      await settings.set(defs.intercomEnabled, true);
      await pumpEventQueue();
      expect(events.last.intercom, 0.5);
    });

    test('off, the room is still followed and nothing is turned', () async {
      await build(enabled: false);
      await window(-60);
      expect(manager.noise, -60);
      expect(events.last.noise, -60);
      expect(events.last.assistant, 1);
      await settings.set(defs.adaptiveVolume, true);
      await pumpEventQueue();
      expect(events.last.assistant, 0.5);
    });

    test('one loud window changes nothing, two raise the room', () async {
      await build();
      await window(-60);
      await window(-30);
      expect(manager.noise, -60);
      // The quieter of the two: both were at least that loud.
      await window(-40);
      expect(manager.noise, -40);
      expect(events.last.assistant, 0.83);
      // And it keeps rising with every louder window after that.
      await window(-35);
      expect(manager.noise, -40);
      await window(-34);
      expect(manager.noise, -35);
    });

    test('a slammed door between quiet windows is ignored', () async {
      await build();
      await window(-60);
      await window(-25);
      await window(-60);
      await window(-25);
      await window(-60);
      expect(manager.noise, -60);
    });

    test('the room falls one dB per window', () async {
      await build();
      await window(-40);
      await window(-60);
      expect(manager.noise, -41);
      await window(-60);
      expect(manager.noise, -42);
      // Never below what was measured.
      await window(-42.4);
      expect(manager.noise, -42.4);
    });

    test('a silenced capture is not a quiet room', () async {
      await build();
      await window(-45);
      // Digital silence: Android zeroed the capture behind another app.
      await window(-96);
      await window(-96, after: const Duration(minutes: 5));
      expect(manager.noise, -45);
      // The quietest a real microphone reads still counts.
      await window(-80);
      expect(manager.noise, -80);
    });

    test('after a long gap a quieter window is taken as it is', () async {
      await build();
      await window(-35);
      await window(-58, after: const Duration(minutes: 40));
      expect(manager.noise, -58);
      // A louder one still waits for a second.
      await window(-30, after: const Duration(minutes: 40));
      expect(manager.noise, -58);
      await window(-30);
      expect(manager.noise, -30);
    });

    test('a louder window from before a long gap does not count', () async {
      await build();
      await window(-60);
      await window(-30);
      await window(-32, after: const Duration(minutes: 5));
      expect(manager.noise, -60);
    });

    test('getAdaptiveVolume reports the room and the shares', () async {
      await build();
      await window(-45);
      final data =
          (await commands.execute('getAdaptiveVolume', const {})).data as Map;
      expect(data['enabled'], true);
      expect(data['noise'], -45);
      expect(data['assistant'], closeTo(0.75, 1e-9));
      expect(data['media'], 1);
      expect(data['intercom'], 1);
    });

    test('a new curve moves the shares at once', () async {
      await build();
      await window(-60);
      await settings.set(
        defs.adaptiveVolumeCurve,
        '[[-60,20,20,20],[-50,67,67,67],[-40,83,83,83],[-30,100,100,100]]',
      );
      await pumpEventQueue();
      expect(events.last.assistant, 0.2);
    });

    test('a curve that is not one is refused by the setting', () async {
      await build();
      expect(
        settings.validate(defs.adaptiveVolumeCurve, '[[-60,50,50,50]]'),
        isNotNull,
      );
    });
  });
}
