import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_widgets.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
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
      for (final key in ['location', 'forecast', 'humidity', 'wind',
          'visibility']) {
        expect(defaults[key], isTrue, reason: key);
      }
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

    test('re-migration replaces the old clock widget, not other corners',
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
    });
  });
}
