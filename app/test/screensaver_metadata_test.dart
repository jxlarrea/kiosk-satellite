import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
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
