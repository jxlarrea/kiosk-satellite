import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/core/photo_exif.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/photo_metadata.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #268: which lines the Immich metadata overlay carries, and the
/// weather condition in Home Assistant's own language.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsManager> build(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final log = Logger();
    final bus = EventBus();
    final settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
    return settings;
  }

  group('Immich metadata lines', () {
    test(
      'every line is on out of the box: the overlay reads as it did',
      () async {
        final settings = await build({'ks.screensaver.immich_metadata': true});
        expect(immichMetadataVisible(settings), isTrue);
        for (final field in immichMetadataFields.keys) {
          expect(immichMetadataFieldOn(settings, field), isTrue, reason: field);
        }
      },
    );

    test('a line turned off leaves the others alone', () async {
      final settings = await build({
        'ks.screensaver.immich_metadata': true,
        'ks.screensaver.immich_metadata_album': false,
      });
      expect(immichMetadataFieldOn(settings, 'album'), isFalse);
      expect(immichMetadataFieldOn(settings, 'date'), isTrue);
      expect(immichMetadataFieldOn(settings, 'settings'), isTrue);
      expect(immichMetadataFieldOn(settings, 'location'), isTrue);
      expect(immichMetadataVisible(settings), isTrue);
    });

    test('the camera model and its exposure answer to one toggle', () async {
      final settings = await build({
        'ks.screensaver.immich_metadata': true,
        'ks.screensaver.immich_metadata_camera': false,
      });
      expect(immichMetadataFieldOn(settings, 'camera'), isFalse);
      expect(immichMetadataFieldOn(settings, 'settings'), isFalse);
      expect(immichMetadataFieldOn(settings, 'date'), isTrue);
    });

    test('the overlay stands down with every line off', () async {
      final settings = await build({
        'ks.screensaver.immich_metadata': true,
        'ks.screensaver.immich_metadata_album': false,
        'ks.screensaver.immich_metadata_date': false,
        'ks.screensaver.immich_metadata_camera': false,
        'ks.screensaver.immich_metadata_location': false,
      });
      expect(immichMetadataVisible(settings), isFalse);
    });

    test('the master toggle still wins over the lines', () async {
      final settings = await build(const {});
      expect(immichMetadataVisible(settings), isFalse);
      expect(immichMetadataFieldOn(settings, 'date'), isFalse);
    });
  });

  group('immichMetadataCorner', () {
    test('the configured corner, out of the box the bottom left', () async {
      final settings = await build({'ks.screensaver.immich_metadata': true});
      expect(immichMetadataCorner(settings), 'bottom_left');
    });

    test(
      'a widget in the corner pushes the panel to the next free one',
      () async {
        final settings = await build({
          'ks.screensaver.immich_metadata': true,
          'ks.screensaver.widgets':
              '[{"position":"bottom_left","type":"battery","config":{}}]',
        });
        expect(immichMetadataCorner(settings), 'top_left');
      },
    );

    test('a widget that is off leaves its corner to the panel', () async {
      final settings = await build({
        'ks.screensaver.immich_metadata': true,
        'ks.screensaver.widgets':
            '[{"position":"bottom_left","type":"battery","enabled":false,'
            '"config":{}}]',
      });
      expect(immichMetadataCorner(settings), 'bottom_left');
    });

    test('Enable screensaver widgets off frees every corner', () async {
      final settings = await build({
        'ks.screensaver.immich_metadata': true,
        'ks.screensaver.widgets_enabled': false,
        'ks.screensaver.widgets':
            '[{"position":"bottom_left","type":"battery","config":{}}]',
      });
      expect(immichMetadataCorner(settings), 'bottom_left');
    });

    test('nothing to say means no corner: the row need not narrow', () async {
      final settings = await build(const {});
      expect(immichMetadataCorner(settings), isNull);
      final linesOff = await build({
        'ks.screensaver.immich_metadata': true,
        'ks.screensaver.immich_metadata_album': false,
        'ks.screensaver.immich_metadata_date': false,
        'ks.screensaver.immich_metadata_camera': false,
        'ks.screensaver.immich_metadata_location': false,
      });
      expect(immichMetadataCorner(linesOff), isNull);
    });

    test('a fully claimed screen stands the panel down', () async {
      final settings = await build({
        'ks.screensaver.immich_metadata': true,
        'ks.screensaver.widgets':
            '[{"position":"top_left","type":"clock","config":{}},'
            '{"position":"top_right","type":"weather","config":{}},'
            '{"position":"bottom_left","type":"battery","config":{}},'
            '{"position":"bottom_right","type":"clock","config":{}}]',
      });
      expect(immichMetadataCorner(settings), isNull);
    });
  });

  // Issue #953: the same panel over Home Assistant Media and Local Media,
  // each on its own settings, read from the photo's EXIF.
  group('EXIF metadata modes', () {
    test('each mode follows its own switches', () async {
      final settings = await build({
        'ks.screensaver.media_metadata': true,
        'ks.screensaver.local_metadata': true,
        'ks.screensaver.local_metadata_camera': false,
      });
      expect(photoMetadataVisible(settings, 'media'), isTrue);
      expect(photoMetadataFieldOn(settings, 'media', 'settings'), isTrue);
      expect(photoMetadataFieldOn(settings, 'local', 'camera'), isFalse);
      expect(photoMetadataFieldOn(settings, 'local', 'settings'), isFalse);
      expect(photoMetadataFieldOn(settings, 'local', 'date'), isTrue);
      expect(photoMetadataVisible(settings, 'immich'), isFalse);
    });

    test('no album or location line without a server to name them', () {
      for (final mode in ['media', 'local']) {
        expect(
          photoMetadataDefs[mode]!.fields.keys,
          unorderedEquals(['date', 'camera', 'settings']),
          reason: mode,
        );
      }
    });

    test('off by default, and the Photo Gallery has no panel', () async {
      final settings = await build(const {});
      expect(photoMetadataVisible(settings, 'media'), isFalse);
      expect(photoMetadataVisible(settings, 'local'), isFalse);
      expect(photoMetadataDefs.containsKey('gallery'), isFalse);
      expect(photoMetadataCorner(settings, 'gallery'), isNull);
    });

    test('a widget in the corner pushes the panel along', () async {
      final settings = await build({
        'ks.screensaver.media_metadata': true,
        'ks.screensaver.media_metadata_position': 'bottom_right',
        'ks.screensaver.widgets':
            '[{"position":"bottom_right","type":"battery","config":{}}]',
      });
      expect(photoMetadataCorner(settings, 'media'), 'top_left');
    });

    test('the lines read like Immich\'s', () {
      final details = photoExifDetails(
        PhotoExif(
          taken: DateTime(2025, 3, 29, 14, 22),
          make: 'Canon',
          model: 'Canon EOS R5',
          focalLength: 35,
          fNumber: 1.8,
          iso: 400,
        ),
      );
      expect(details['date'], 'March 29, 2025');
      expect(details['camera'], 'Canon EOS R5');
      expect(details['settings'], '35mm  f/1.8  ISO 400');
      expect(photoCameraLine('Google', 'Pixel 8 Pro'), 'Google Pixel 8 Pro');
      expect(photoExifDetails(null), isEmpty);
      expect(photoExifDetails(const PhotoExif(make: 'Google')), isEmpty);
    });
  });

  group('parseStateTranslations', () {
    Object? result(Map<String, Object?> resources) => {'resources': resources};

    test('the domain\'s own states come back keyed by bare state', () {
      final states = parseStateTranslations(
        result({
          'component.weather.entity_component._.state.fog': 'Nebbia',
          'component.weather.entity_component._.state.sunny': 'Sereno',
          'component.weather.entity_component._.name': 'Meteo',
        }),
        'weather',
      );
      expect(states, {'fog': 'Nebbia', 'sunny': 'Sereno'});
    });

    test('device-class states and other domains are left out', () {
      final states = parseStateTranslations(
        result({
          'component.weather.entity_component._.state.rainy': 'Piovoso',
          'component.weather.entity_component.humidity.state.rainy': 'Umido',
          'component.sensor.entity_component._.state.rainy': 'Pioggia',
        }),
        'weather',
      );
      expect(states, {'rainy': 'Piovoso'});
    });

    test('an answer that carries nothing usable reads as empty', () {
      expect(parseStateTranslations(null, 'weather'), isEmpty);
      expect(parseStateTranslations(const {}, 'weather'), isEmpty);
      expect(
        parseStateTranslations(
          result({'component.weather.entity_component._.state.fog': 42}),
          'weather',
        ),
        isEmpty,
      );
    });
  });
}
