import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart'
    show DayForecast;
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_widgets.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/glance/glance_manager.dart';
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

  group('turning widgets off', () {
    const entries =
        '[{"position":"top_left","type":"clock","config":{}},'
        '{"position":"top_right","type":"battery","enabled":false,"config":{}}]';

    Future<SettingsManager> settingsWith(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues(initial);
      final log = Logger();
      final settings = SettingsManager(EventBus(), CommandRegistry(log), log);
      await settings.init();
      return settings;
    }

    test('a missing flag reads as on, so old entries keep showing', () {
      final widgets = decodeScreensaverWidgets(entries);
      expect(widgets.first.enabled, isTrue);
      expect(widgets.last.enabled, isFalse);
    });

    test('only an entry that is off stores the flag', () {
      final encoded = encodeScreensaverWidgets(
        decodeScreensaverWidgets(entries),
      );
      expect('"enabled"'.allMatches(encoded), hasLength(1));
      expect(decodeScreensaverWidgets(encoded).last.enabled, isFalse);
    });

    test('an entry that is off does not draw', () async {
      final settings = await settingsWith({'ks.screensaver.widgets': entries});
      expect(settings.get(defs.screensaverWidgetsEnabled), isTrue);
      expect(activeScreensaverWidgets(settings).map((w) => w.type), ['clock']);
    });

    test(
      'Enable screensaver widgets off draws none and keeps the list',
      () async {
        final settings = await settingsWith({
          'ks.screensaver.widgets': entries,
          'ks.screensaver.widgets_enabled': false,
        });
        expect(activeScreensaverWidgets(settings), isEmpty);
        expect(
          decodeScreensaverWidgets(settings.get(defs.screensaverWidgets)),
          hasLength(2),
        );
      },
    );
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
    test('nothing rides the calendar, which fills the screen', () {
      for (final type in ['clock', 'weather', 'battery', 'calendar']) {
        expect(screensaverWidgetAllowedOnMode(type, 'calendar'), isFalse);
      }
    });

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
        'high_low',
        'humidity',
        'wind',
        'visibility',
        'colored_icons',
      ]) {
        expect(defaults[key], isTrue, reason: key);
      }
      // Feels like alone starts off: the temperature line stays a single
      // reading until asked otherwise.
      expect(defaults['feels_like'], isFalse);
      expect(defaults['feels_like_only'], isFalse);
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

  group('weather forecast widget type', () {
    test('is offered, labeled, and defaulted', () {
      expect(screensaverWidgetTypes, contains('forecast'));
      expect(describeScreensaverWidgetType('forecast'), 'Weather forecast');
      final defaults = screensaverWidgetDefaults('forecast');
      expect(defaults['entity'], '');
      expect(defaults['color'], '250,250,250');
      expect(defaults['days'], 5);
      expect(forecastDayOptions, contains(defaults['days']));
      expect(defaults['today'], isTrue);
      expect(defaults['colored_icons'], isTrue);
    });

    test('rides every mode but the calendar and the camera grid', () {
      expect(screensaverWidgetAllowedOnMode('forecast', 'clock'), isTrue);
      expect(screensaverWidgetAllowedOnMode('forecast', 'immich'), isTrue);
      expect(screensaverWidgetAllowedOnMode('forecast', 'camera'), isFalse);
      expect(screensaverWidgetAllowedOnMode('forecast', 'calendar'), isFalse);
    });

    group('rows', () {
      const sunny = DayForecast(condition: 'sunny', high: 30, low: 20);
      final now = DateTime(2026, 11, 2, 22, 30);
      final daily = {
        for (var i = -1; i < 7; i++) DateTime(2026, 11, 2 + i): sunny,
      };

      test('start today and stop at the day count', () {
        final rows = forecastWidgetRows(
          daily,
          now,
          days: 3,
          includeToday: true,
        );
        expect(rows.map((r) => r.$1), [
          DateTime(2026, 11, 2),
          DateTime(2026, 11, 3),
          DateTime(2026, 11, 4),
        ]);
      });

      test('start tomorrow without today', () {
        final rows = forecastWidgetRows(
          daily,
          now,
          days: 3,
          includeToday: false,
        );
        expect(rows.first.$1, DateTime(2026, 11, 3));
        expect(rows, hasLength(3));
      });

      test('a short forecast lists only the days it has', () {
        final rows = forecastWidgetRows(
          {DateTime(2026, 11, 2): sunny, DateTime(2026, 11, 3): sunny},
          now,
          days: 7,
          includeToday: true,
        );
        expect(rows, hasLength(2));
      });

      test('come out in date order, past days dropped', () {
        final rows = forecastWidgetRows(
          {
            DateTime(2026, 11, 4): sunny,
            DateTime(2026, 11, 1): sunny,
            DateTime(2026, 11, 3): sunny,
          },
          now,
          days: 5,
          includeToday: true,
        );
        expect(rows.map((r) => r.$1), [
          DateTime(2026, 11, 3),
          DateTime(2026, 11, 4),
        ]);
      });
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
      // Always shown until a list of states narrows it down.
      expect(defaults['show_states'], '');
      // The name under the value reads by default; a corner that explains
      // itself can turn it off.
      expect(defaults['show_name'], isTrue);
      // The icon beside the value too; a text-only corner turns it off.
      expect(defaults['show_icon'], isTrue);
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

    test('visible states match the displayed or raw value', () {
      final garage = GlanceEntity(
        entityId: 'cover.garage',
        name: 'Garage',
        state: 'open',
      );
      bool visible(String states, String text) =>
          entityWidgetStateVisible({'show_states': states}, garage, text);
      // Empty always shows.
      expect(visible('', 'Open'), isTrue);
      expect(visible(' , ', 'Open'), isTrue);
      // The displayed text or the raw state, either case, any spacing.
      expect(visible('Open', 'Open'), isTrue);
      expect(visible('closed, OPEN ', 'Open'), isTrue);
      expect(visible('closed,opening', 'Open'), isFalse);
      // An attribute widget compares its attribute, not the state.
      final washer = GlanceEntity(
        entityId: 'sensor.washer',
        name: 'Washer',
        attribute: 'program',
        state: 'on',
        attributeValue: 'eco_40',
      );
      expect(
        entityWidgetStateVisible({'show_states': 'eco_40'}, washer, 'Eco 40'),
        isTrue,
      );
      expect(
        entityWidgetStateVisible({'show_states': 'on'}, washer, 'Eco 40'),
        isFalse,
      );
    });
  });

  group('per-widget scale', () {
    test('every type defaults to 0, the slider spanning -50 to 50', () {
      for (final type in screensaverWidgetTypes) {
        expect(screensaverWidgetDefaults(type)['scale'], 0, reason: type);
      }
      expect(screensaverWidgetScaleMin, -50);
      expect(screensaverWidgetScaleMax, 50);
      expect(screensaverWidgetScaleDefault, 0);
    });

    test('reads as a factor around 1', () {
      expect(screensaverWidgetScaleFactor({'scale': 0}), 1.0);
      expect(screensaverWidgetScaleFactor({'scale': 50}), 1.5);
      expect(screensaverWidgetScaleFactor({'scale': -50}), 0.5);
      expect(screensaverWidgetScaleFactor({'scale': 25}), 1.25);
      // A backup written by hand, or an entry saved before the key
      // existed, reads as the default rather than failing the widget.
      expect(screensaverWidgetScaleFactor({}), 1.0);
      expect(screensaverWidgetScaleFactor({'scale': null}), 1.0);
      expect(screensaverWidgetScaleFactor({'scale': 'huge'}), 1.0);
      expect(screensaverWidgetScaleFactor({'scale': '20'}), 1.2);
    });

    test('clamps to the slider range', () {
      expect(screensaverWidgetScaleFactor({'scale': 400}), 1.5);
      expect(screensaverWidgetScaleFactor({'scale': -90}), 0.5);
    });

    test('survives the round trip through storage', () {
      final json = encodeScreensaverWidgets([
        const ScreensaverWidget(
          position: 'top_left',
          type: 'clock',
          config: {'color': '250,250,250', 'scale': -20},
        ),
      ]);
      final back = decodeScreensaverWidgets(json);
      expect(back.single.config['scale'], -20);
      expect(screensaverWidgetScaleFactor(back.single.config), 0.8);
    });

    test('the global slider scales all widgets together', () {
      final def = defs.screensaverWidgetScale;
      expect(def.title, 'Global widget scaling');
      expect(def.defaultValue, 100);
      expect(def.min, 50);
      expect(def.max, 200);
    });
  });

  group('per-widget font', () {
    test('every type defaults both keys to Default', () {
      for (final type in screensaverWidgetTypes) {
        final d = screensaverWidgetDefaults(type);
        expect(d['font'], screensaverWidgetFontDefault, reason: type);
        expect(d['font_weight'], screensaverWidgetFontDefault, reason: type);
      }
    });

    test('the pickers offer Default plus the clock vocabulary', () {
      expect(screensaverWidgetFontOptions.first, 'default');
      expect(
        screensaverWidgetFontOptions.skip(1),
        defs.screensaverClockFont.options,
      );
      expect(
        screensaverWidgetFontWeightOptions,
        defs.screensaverClockFontWeight.options,
      );
      expect(screensaverWidgetFontWeightOptions.first, 'default');
    });

    test('Default follows the global, a pick of its own wins', () {
      expect(screensaverWidgetFontValue({}, 'rubik'), 'rubik');
      expect(screensaverWidgetFontValue({'font': 'default'}, 'inter'), 'inter');
      expect(screensaverWidgetFontValue({'font': 'lcd'}, 'inter'), 'lcd');
      // A family nobody mapped falls to the global rather than to the
      // platform default.
      expect(screensaverWidgetFontValue({'font': 'comic'}, 'nunito'), 'nunito');
      expect(screensaverWidgetFontWeightValue({}, 'bold'), 'bold');
      expect(
        screensaverWidgetFontWeightValue({'font_weight': 'default'}, 'light'),
        'light',
      );
      expect(
        screensaverWidgetFontWeightValue({'font_weight': 'black'}, 'light'),
        'black',
      );
      expect(
        screensaverWidgetFontWeightValue({'font_weight': 'heavy'}, 'default'),
        'default',
      );
    });

    test('the global rows share the clock vocabulary and sit with Widgets', () {
      final font = defs.screensaverWidgetFont;
      final weight = defs.screensaverWidgetFontWeight;
      expect(defs.allSettings, containsAll([font, weight]));
      expect(font.defaultValue, 'rubik');
      expect(font.options, defs.screensaverClockFont.options);
      expect(font.optionLabels, defs.screensaverClockFont.optionLabels);
      expect(weight.defaultValue, 'default');
      expect(weight.options, defs.screensaverClockFontWeight.options);
      expect(weight.optionLabels, defs.screensaverClockFontWeight.optionLabels);
      for (final def in [font, weight]) {
        expect(def.subpage, defs.screensaverWidgetScale.subpage);
        expect(def.section, defs.screensaverWidgetScale.section);
        expect(def.dependsOn, isNull);
      }
    });
  });

  group('vignette strength', () {
    test('is a Widgets group slider defaulting to 40 percent', () {
      final def = defs.screensaverVignetteStrength;
      expect(defs.allSettings, contains(def));
      expect(def.defaultValue, 40);
      expect(def.min, 0);
      expect(def.max, 100);
      expect(def.subpage, defs.screensaverWidgetScale.subpage);
      expect(def.section, defs.screensaverWidgetScale.section);
    });

    test('the Immich metadata overlay has a text scaling slider of its '
        'own, the global widget scaling twin', () {
      final def = defs.screensaverImmichMetadataScale;
      expect(defs.allSettings, contains(def));
      expect(def.defaultValue, 100);
      expect(def.min, defs.screensaverWidgetScale.min);
      expect(def.max, defs.screensaverWidgetScale.max);
      expect(def.step, defs.screensaverWidgetScale.step);
      expect(def.subpage, defs.screensaverImmichMetadataPosition.subpage);
      expect(def.section, defs.screensaverImmichMetadataPosition.section);
      expect(def.dependsOn, defs.screensaverImmichMetadata.key);
      // A panel correction, so it stays out of new profiles like the
      // other scales, and the profiles created before it get migrated.
      expect(defs.fleetDefaultExcluded, contains(def.key));
      // One recorded former default lacks it and the next one has it:
      // the migration step it joined by.
      final joinedAt = defs.fleetFormerDefaultExcluded.indexWhere(
        (former) => former.contains(def.key),
      );
      expect(joinedAt, greaterThan(0));
      expect(
        defs.fleetFormerDefaultExcluded[joinedAt].difference(
          defs.fleetFormerDefaultExcluded[joinedAt - 1],
        ),
        {def.key},
      );
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

    test('the default uses a lighter gradient', () {
      final colors = vignetteColors(
        defs.screensaverVignetteStrength.defaultValue,
      );
      expect(colors, [
        const Color(0x66000000),
        const Color(0x4D000000),
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
