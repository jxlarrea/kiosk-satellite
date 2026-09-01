import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_widgets.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeScreensaverWidgets', () {
    test('parses a well-formed list', () {
      final widgets = decodeScreensaverWidgets(
        '[{"position":"top_right","type":"clock",'
        '"config":{"color":"10,20,30","h24":true,"date":true}}]',
      );
      expect(widgets, hasLength(1));
      expect(widgets.single.position, 'top_right');
      expect(widgets.single.type, 'clock');
      expect(widgets.single.config['color'], '10,20,30');
      expect(widgets.single.config['h24'], isTrue);
      expect(widgets.single.config['date'], isTrue);
    });

    test('drops malformed entries, keeps the valid ones', () {
      final widgets = decodeScreensaverWidgets(
        '[{"position":"middle","type":"clock"},'
        '{"position":"top_left","type":"weather_vane"},'
        '{"type":"clock"},"junk",'
        '{"position":"bottom_left","type":"clock"}]',
      );
      expect(widgets, hasLength(1));
      expect(widgets.single.position, 'bottom_left');
    });

    test('one widget per corner: the first claimant wins', () {
      final widgets = decodeScreensaverWidgets(
        '[{"position":"top_left","type":"clock","config":{"h24":true}},'
        '{"position":"top_left","type":"clock","config":{"h24":false}}]',
      );
      expect(widgets, hasLength(1));
      expect(widgets.single.config['h24'], isTrue);
    });

    test('a missing config reads as the type defaults', () {
      final widgets = decodeScreensaverWidgets(
        '[{"position":"top_right","type":"clock"}]',
      );
      expect(widgets.single.config['color'], '250,250,250');
      expect(widgets.single.config['h24'], isFalse);
    });

    test('garbage input is an empty list', () {
      expect(decodeScreensaverWidgets('not json'), isEmpty);
      expect(decodeScreensaverWidgets('{"position":"top_left"}'), isEmpty);
      expect(decodeScreensaverWidgets('[]'), isEmpty);
    });
  });

  group('encodeScreensaverWidgets', () {
    test('stores in corner order, top-left to bottom-right', () {
      final encoded = encodeScreensaverWidgets([
        const ScreensaverWidget(
          position: 'bottom_right',
          type: 'clock',
          config: {},
        ),
        const ScreensaverWidget(
          position: 'top_left',
          type: 'clock',
          config: {},
        ),
      ]);
      final decoded = decodeScreensaverWidgets(encoded);
      expect(decoded.first.position, 'top_left');
      expect(decoded.last.position, 'bottom_right');
    });
  });

  group('screensaverWidgetAllowedOnMode', () {
    test('the clock stays off Clock and the camera grid', () {
      expect(screensaverWidgetAllowedOnMode('clock', 'clock'), isFalse);
      expect(screensaverWidgetAllowedOnMode('clock', 'camera'), isFalse);
      expect(screensaverWidgetAllowedOnMode('clock', 'black'), isTrue);
      expect(screensaverWidgetAllowedOnMode('clock', 'immich'), isTrue);
    });

    test('the weather widget rides the Clock mode, but not the grid', () {
      expect(screensaverWidgetAllowedOnMode('weather', 'clock'), isTrue);
      expect(screensaverWidgetAllowedOnMode('weather', 'camera'), isFalse);
      expect(screensaverWidgetAllowedOnMode('weather', 'gallery'), isTrue);
    });
  });

  group('weather widget type', () {
    test('is offered, labeled, and defaulted', () {
      expect(screensaverWidgetTypes, contains('weather'));
      expect(describeScreensaverWidgetType('weather'), 'Weather');
      final defaults = screensaverWidgetDefaults('weather');
      expect(defaults['entity'], '');
      expect(defaults['label'], '');
      expect(defaults['color'], '250,250,250');
      // Every line defaults on; the entity's own readings gate them too.
      for (final key in [
        'location',
        'forecast',
        'humidity',
        'wind',
        'visibility',
      ]) {
        expect(defaults[key], isTrue, reason: key);
      }
      // Feels like alone starts off: the temperature line stays a single
      // reading until asked otherwise.
      expect(defaults['feels_like'], isFalse);
    });

    test('decodes alongside a clock, one corner each', () {
      final widgets = decodeScreensaverWidgets(
        '[{"position":"top_left","type":"clock"},'
        '{"position":"bottom_right","type":"weather",'
        '"config":{"entity":"weather.home","humidity":false}}]',
      );
      expect(widgets, hasLength(2));
      expect(widgets.last.type, 'weather');
      expect(widgets.last.config['entity'], 'weather.home');
      expect(widgets.last.config['humidity'], isFalse);
    });
  });

  group('battery widget type', () {
    test('is offered, labeled, and defaulted', () {
      expect(screensaverWidgetTypes, contains('battery'));
      expect(describeScreensaverWidgetType('battery'), 'Battery');
      final defaults = screensaverWidgetDefaults('battery');
      expect(defaults['color'], '250,250,250');
      // The percentage reads by default; hiding until the charge is low is
      // the opt-in, since a widget nobody sees is a widget nobody adds.
      expect(defaults['percent'], isTrue);
      expect(defaults['low'], isFalse);
    });

    test('rides every mode but the camera grid', () {
      expect(screensaverWidgetAllowedOnMode('battery', 'clock'), isTrue);
      expect(screensaverWidgetAllowedOnMode('battery', 'immich'), isTrue);
      expect(screensaverWidgetAllowedOnMode('battery', 'camera'), isFalse);
    });

    test('only when low: hidden until the charge is low and off the cable', () {
      // Off by default: the widget is there to be read.
      expect(
        batteryWidgetVisible(lowOnly: false, level: 90, charging: false),
        isTrue,
      );
      expect(
        batteryWidgetVisible(lowOnly: true, level: 90, charging: false),
        isFalse,
      );
      expect(
        batteryWidgetVisible(
          lowOnly: true,
          level: lowBatteryLevel,
          charging: false,
        ),
        isTrue,
      );
      // On the cable it is already being dealt with.
      expect(
        batteryWidgetVisible(lowOnly: true, level: 5, charging: true),
        isFalse,
      );
    });

    test('a device without a battery draws nothing in either mode', () {
      // A mains-powered box (issue #367): no charge to show, and a bolt
      // burning in the corner forever would only say it is plugged in.
      expect(
        batteryWidgetVisible(lowOnly: false, level: null, charging: true),
        isFalse,
      );
      expect(
        batteryWidgetVisible(lowOnly: false, level: null, charging: false),
        isFalse,
      );
      expect(
        batteryWidgetVisible(lowOnly: true, level: null, charging: false),
        isFalse,
      );
      // A real 0% is a flat battery, not a missing one.
      expect(
        batteryWidgetVisible(lowOnly: true, level: 0, charging: false),
        isTrue,
      );
    });

    test('decodes with its own config', () {
      final widgets = decodeScreensaverWidgets(
        '[{"position":"bottom_left","type":"battery",'
        '"config":{"color":"250,250,250","percent":false,"low":true}}]',
      );
      expect(widgets.single.type, 'battery');
      expect(widgets.single.config['percent'], isFalse);
      expect(widgets.single.config['low'], isTrue);
    });
  });

  group('entity widget type', () {
    test('is offered, labeled, and defaulted', () {
      expect(screensaverWidgetTypes, contains('entity'));
      expect(describeScreensaverWidgetType('entity'), 'Entity');
      final defaults = screensaverWidgetDefaults('entity');
      expect(defaults['entity'], '');
      expect(defaults['name'], '');
      expect(defaults['label'], '');
      // The state by default; an attribute is the opt-in, as on the row.
      expect(defaults['attribute'], '');
      // The name under the value reads by default; a corner that explains
      // itself can turn it off.
      expect(defaults['show_name'], isTrue);
      expect(defaults['color'], '250,250,250');
    });

    test('rides every mode but the camera grid', () {
      expect(screensaverWidgetAllowedOnMode('entity', 'clock'), isTrue);
      expect(screensaverWidgetAllowedOnMode('entity', 'immich'), isTrue);
      expect(screensaverWidgetAllowedOnMode('entity', 'black'), isTrue);
      expect(screensaverWidgetAllowedOnMode('entity', 'camera'), isFalse);
    });

    test('decodes with its own config', () {
      final widgets = decodeScreensaverWidgets(
        '[{"position":"top_right","type":"entity",'
        '"config":{"entity":"sensor.bedroom_temperature",'
        '"name":"Bedroom Temperature","label":"Bedroom",'
        '"attribute":"","color":"250,250,250"}}]',
      );
      expect(widgets.single.type, 'entity');
      expect(widgets.single.config['entity'], 'sensor.bedroom_temperature');
      expect(widgets.single.config['label'], 'Bedroom');
    });

    test('its config reads as the row model', () {
      final entity = entityWidgetEntity({
        'entity': 'sensor.bedroom_temperature',
        'name': 'Bedroom Temperature',
        'label': 'Bedroom',
        'attribute': 'humidity',
      });
      expect(entity.entityId, 'sensor.bedroom_temperature');
      expect(entity.name, 'Bedroom Temperature');
      expect(entity.customName, 'Bedroom');
      expect(entity.displayName, 'Bedroom');
      expect(entity.attribute, 'humidity');
      // Nothing live yet: the widget draws nothing until a reading lands.
      expect(entity.state, isNull);
    });

    test('an empty label and attribute mean the Home Assistant name and '
        'the state', () {
      final entity = entityWidgetEntity({
        'entity': ' sensor.outside ',
        'name': 'Outside',
        'label': '  ',
        'attribute': '',
      });
      expect(entity.entityId, 'sensor.outside');
      expect(entity.customName, isNull);
      expect(entity.displayName, 'Outside');
      expect(entity.attribute, isNull);
    });
  });

  group('vignette strength', () {
    test('is a Widgets group slider defaulting to the pre-slider look', () {
      final def = defs.screensaverVignetteStrength;
      expect(defs.allSettings, contains(def));
      expect(def.defaultValue, 80);
      expect(def.min, 0);
      expect(def.max, 100);
      expect(def.subpage, defs.screensaverWidgetScale.subpage);
      expect(def.section, defs.screensaverWidgetScale.section);
    });

    test('the Immich metadata overlay has a twin slider of its own', () {
      final def = defs.screensaverImmichVignetteStrength;
      expect(defs.allSettings, contains(def));
      expect(def.key, isNot(defs.screensaverVignetteStrength.key));
      expect(def.defaultValue, defs.screensaverVignetteStrength.defaultValue);
      expect(def.min, defs.screensaverVignetteStrength.min);
      expect(def.max, defs.screensaverVignetteStrength.max);
      expect(def.subpage, defs.screensaverImmichMetadataPosition.subpage);
      expect(def.section, defs.screensaverImmichMetadataPosition.section);
      expect(def.dependsOn, defs.screensaverImmichMetadata.key);
    });

    test('the default reproduces the original gradient', () {
      final colors = vignetteColors(
        defs.screensaverVignetteStrength.defaultValue,
      );
      expect(colors, [
        const Color(0xCC000000),
        const Color(0x99000000),
        const Color(0x00000000),
      ]);
    });

    test('scales with the slider and clamps out-of-range values', () {
      expect(vignetteColors(100).first.a, 1.0);
      expect(vignetteColors(50).first, const Color(0x80000000));
      expect(vignetteColors(50)[1], const Color(0x60000000));
      expect(vignetteColors(0).first, const Color(0x00000000));
      expect(vignetteColors(250), vignetteColors(100));
      expect(vignetteColors(-5), vignetteColors(0));
    });
  });

  group('legacy small clock migration', () {
    Future<SettingsManager> boot(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
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

    test('an enabled small clock becomes a clock widget', () async {
      final settings = await boot({
        'ks.screensaver.mini_clock': true,
        'ks.screensaver.mini_clock_position': 'bottom_left',
        'ks.screensaver.mini_clock_color': '1,2,3',
        'ks.screensaver.mini_clock_24h': true,
        'ks.screensaver.mini_clock_date': true,
        // The 24h carry-over (issue #116) already ran; keep it out of the way.
        'ks.internal.screensaver.mini_clock_24h.migrated': '1',
      });
      final widgets = decodeScreensaverWidgets(
        settings.get(defs.screensaverWidgets),
      );
      expect(widgets, hasLength(1));
      expect(widgets.single.type, 'clock');
      expect(widgets.single.position, 'bottom_left');
      expect(widgets.single.config['color'], '1,2,3');
      expect(widgets.single.config['h24'], isTrue);
      expect(widgets.single.config['date'], isTrue);
      // The old switch is off, so the migration never runs twice.
      expect(settings.get(defs.screensaverMiniClock), isFalse);
    });

    test('a disabled small clock migrates nothing', () async {
      final settings = await boot({
        'ks.screensaver.mini_clock_position': 'bottom_left',
        'ks.internal.screensaver.mini_clock_24h.migrated': '1',
      });
      expect(settings.get(defs.screensaverWidgets), '[]');
      expect(settings.get(defs.screensaverMiniClock), isFalse);
    });

    test(
      're-migration replaces the old clock widget, not other corners',
      () async {
        final settings = await boot({
          'ks.screensaver.mini_clock': true,
          'ks.screensaver.mini_clock_position': 'top_right',
          'ks.screensaver.widgets':
              '[{"position":"top_left","type":"clock","config":{"h24":true}}]',
          'ks.internal.screensaver.mini_clock_24h.migrated': '1',
        });
        final widgets = decodeScreensaverWidgets(
          settings.get(defs.screensaverWidgets),
        );
        // The stale clock entry is dropped rather than left to fight the
        // migrated one; a future non-clock widget would be kept.
        expect(widgets, hasLength(1));
        expect(widgets.single.position, 'top_right');
        expect(widgets.single.config['h24'], isFalse);
      },
    );
  });
}
