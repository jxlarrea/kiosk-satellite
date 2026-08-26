import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/camera/models.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Camera Streams screensaver's rotation settings: the ordered view
/// list, its dwell, and the carry-over from the single-view setting the
/// mode had before it rotated.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeCameraViewIds', () {
    test('keeps strings in order, each once', () {
      expect(decodeCameraViewIds('["b","a","b","c"]'), ['b', 'a', 'c']);
    });

    test('drops what is not a view id', () {
      expect(decodeCameraViewIds('["a", 1, null, "", {"id":"x"}]'), ['a']);
    });

    test('anything unreadable is an empty rotation', () {
      expect(decodeCameraViewIds(''), isEmpty);
      expect(decodeCameraViewIds('not json'), isEmpty);
      expect(decodeCameraViewIds('{"a":1}'), isEmpty);
    });

    test('round-trips through the encoder', () {
      expect(decodeCameraViewIds(encodeCameraViewIds(['x', 'y'])), ['x', 'y']);
    });
  });

  group('definitions', () {
    test('the mode is named Camera Streams', () {
      expect(defs.screensaverMode.optionLabels!['camera'], 'Camera Streams');
    });

    test('the page rows gate on the mode and share the page', () {
      for (final def in [
        defs.screensaverCameraViews,
        defs.screensaverCameraViewSeconds,
        defs.screensaverCameraMute,
      ]) {
        expect(def.dependsOn, defs.screensaverMode.key, reason: def.key);
        expect(def.dependsOnValue, 'camera', reason: def.key);
        expect(def.subpage, 'Camera Streams screensaver', reason: def.key);
        expect(def.section, 'Camera Streams screensaver', reason: def.key);
      }
      expect(defs.subpageHints['Camera Streams screensaver'], isNotNull);
      // Silent unless someone asks otherwise: the screensaver talks to an
      // empty room.
      expect(defs.screensaverCameraMute.defaultValue, isTrue);
      // The old single-view keys draw no row anywhere; they only exist so
      // old backups still import.
      expect(defs.screensaverCameraView.hidden, isTrue);
      expect(defs.screensaverCameraView.section, isNull);
      expect(defs.screensaverCameraViewName.hidden, isTrue);
    });

    test('the dwell has a floor', () async {
      expect(defs.validateCameraViewSeconds(4), isNotNull);
      expect(defs.validateCameraViewSeconds(5), isNull);
      expect(defs.validateCameraViewSeconds(30), isNull);
      expect(defs.validateCameraViewSeconds('30'), isNotNull);

      SharedPreferences.setMockInitialValues({});
      final bus = EventBus();
      final log = Logger();
      final settings = SettingsManager(bus, CommandRegistry(log), log);
      await settings.init();
      expect(
        await settings.setFromJson(defs.screensaverCameraViewSeconds.key, 2),
        isFalse,
      );
      expect(settings.get(defs.screensaverCameraViewSeconds), 30);
      expect(
        await settings.setFromJson(defs.screensaverCameraViewSeconds.key, 10),
        isTrue,
      );
      expect(settings.get(defs.screensaverCameraViewSeconds), 10);
    });
  });

  group('single-view carry-over', () {
    Future<SettingsManager> boot(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues(initial);
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      final saver = ScreensaverManager(bus, commands, log, settings);
      await saver.init();
      await saver.dispose();
      return settings;
    }

    test('the old view becomes the rotation and the old keys clear', () async {
      final settings = await boot({
        'ks.screensaver.mode': 'camera',
        'ks.screensaver.camera_view': 'v1',
        'ks.screensaver.camera_view_name': 'Front door',
      });
      expect(settings.get(defs.screensaverCameraViews), '["v1"]');
      expect(settings.get(defs.screensaverCameraView), '');
      expect(settings.get(defs.screensaverCameraViewName), '');
    });

    test('an old backup restores the screensaver it describes', () async {
      // The old key was the one view the screensaver showed, so it replaces
      // whatever list a newer build had, rather than joining it.
      final settings = await boot({
        'ks.screensaver.camera_views': '["a","b"]',
        'ks.screensaver.camera_view': 'v1',
      });
      expect(settings.get(defs.screensaverCameraViews), '["v1"]');
      expect(settings.get(defs.screensaverCameraView), '');
    });

    test('nothing to carry over leaves the list alone', () async {
      final settings = await boot({'ks.screensaver.camera_views': '["a"]'});
      expect(settings.get(defs.screensaverCameraViews), '["a"]');
    });

    test('an old backup imported later migrates too', () async {
      SharedPreferences.setMockInitialValues({});
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      final saver = ScreensaverManager(bus, commands, log, settings);
      await saver.init();
      await settings.setFromJson(defs.screensaverCameraView.key, 'v9');
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      expect(settings.get(defs.screensaverCameraViews), '["v9"]');
      expect(settings.get(defs.screensaverCameraView), '');
      await saver.dispose();
    });
  });
}
