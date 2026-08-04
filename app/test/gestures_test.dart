import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/gestures/gesture_mappings.dart';
import 'package:kiosk_satellite/managers/gestures/gestures_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeGestureMappings', () {
    test('parses well-formed mappings', () {
      final mappings = decodeGestureMappings(
        '[{"id":"g1","trigger":{"type":"corner_taps","corner":"tl",'
        '"taps":3},"action":{"type":"screen_off"}}]',
      );
      expect(mappings, hasLength(1));
      expect(mappings.single.id, 'g1');
      expect(mappings.single.triggerType, 'corner_taps');
      expect(mappings.single.actionType, 'screen_off');
    });

    test('drops malformed entries, keeps the valid ones', () {
      final mappings = decodeGestureMappings(
        '[{"id":"g1","trigger":{"type":"corner_hold","corner":"br",'
        '"holdMs":2000},"action":{"type":"menu"}},'
        '{"trigger":{"type":"corner_taps"},"action":{"type":"menu"}},'
        '{"id":"g3","action":{"type":"menu"}},'
        '{"id":"","trigger":{},"action":{}},'
        '"junk"]',
      );
      expect(mappings, hasLength(1));
      expect(mappings.single.id, 'g1');
    });

    test('garbage input is an empty list', () {
      expect(decodeGestureMappings('not json'), isEmpty);
      expect(decodeGestureMappings('{"id":"g1"}'), isEmpty);
      expect(decodeGestureMappings('[]'), isEmpty);
    });
  });

  group('nativeGestureTriggers', () {
    test('flattens id and trigger fields, skipping absent ones', () {
      final triggers = nativeGestureTriggers(decodeGestureMappings(
        '[{"id":"g1","trigger":{"type":"corner_taps","corner":"tl",'
        '"taps":3},"action":{"type":"menu"}},'
        '{"id":"g2","trigger":{"type":"finger_hold","fingers":2,'
        '"holdMs":1500},"action":{"type":"menu"}},'
        '{"id":"g3","trigger":{"type":"corner_sequence",'
        '"sequence":["tl","tr","bl"]},"action":{"type":"menu"}}]',
      ));
      expect(triggers, [
        {'id': 'g1', 'type': 'corner_taps', 'corner': 'tl', 'taps': 3},
        {'id': 'g2', 'type': 'finger_hold', 'fingers': 2, 'holdMs': 1500},
        {
          'id': 'g3',
          'type': 'corner_sequence',
          'sequence': ['tl', 'tr', 'bl'],
        },
      ]);
    });
  });

  group('describe helpers', () {
    test('trigger labels', () {
      expect(
        describeGestureTrigger({'type': 'corner_taps', 'corner': 'tl', 'taps': 3}),
        '3 taps in the top-left corner',
      );
      expect(
        describeGestureTrigger({
          'type': 'corner_hold',
          'corner': 'br',
          'holdMs': 1500,
        }),
        'Hold the bottom-right corner for 1.5s',
      );
      expect(
        describeGestureTrigger({
          'type': 'finger_taps',
          'fingers': 3,
          'taps': 2,
        }),
        '3-finger double tap',
      );
      expect(
        describeGestureTrigger({
          'type': 'corner_sequence',
          'sequence': ['tl', 'tr'],
        }),
        'Corner sequence: TL > TR',
      );
    });

    test('action labels', () {
      expect(
        describeGestureAction({'type': 'navigate', 'path': 'lovelace/0'}),
        'Go to lovelace/0',
      );
      expect(
        describeGestureAction({
          'type': 'ha_service',
          'domain': 'light',
          'service': 'turn_on',
        }),
        'Call light.turn_on',
      );
      expect(
        describeGestureAction({
          'type': 'ha_script',
          'entityId': 'script.morning',
        }),
        'Run script.morning',
      );
      expect(
        describeGestureAction({
          'type': 'ha_automation',
          'entityId': 'automation.lights_off',
        }),
        'Trigger automation.lights_off',
      );
      expect(
        describeGestureAction({'type': 'screensaver'}),
        'Start the screensaver',
      );
    });
  });

  group('GesturesManager', () {
    late EventBus bus;
    late CommandRegistry commands;
    late SettingsManager settings;
    late GesturesManager gestures;
    late List<(String, Map<String, Object?>)> executed;

    Future<void> build(String mappingsJson) async {
      SharedPreferences.setMockInitialValues({
        'ks.${defs.gestureMappings.key}': mappingsJson,
      });
      bus = EventBus();
      final log = Logger();
      commands = CommandRegistry(log);
      executed = [];
      for (final name in [
        'haNavigate',
        'showLinkPage',
        'startScreensaver',
        'stopScreensaver',
        'screenOff',
        'showCameraView',
        'hideCameraView',
        'launchApp',
        'openUri',
        'openSystemSettings',
        'haCallService',
        'haFireEvent',
      ]) {
        commands.register(Command(
          name: name,
          description: 'test stub',
          handler: (p) async {
            executed.add((name, p));
            return const CommandResult.ok();
          },
        ));
      }
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      gestures = GesturesManager(bus, commands, log, settings);
      await gestures.init();
    }

    Future<void> fire(String id) async {
      bus.publish(GestureDetected(id: id));
      await Future<void>.delayed(Duration.zero);
    }

    test('a detected gesture runs its mapped command', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"corner_taps","corner":"tl",'
        '"taps":3},"action":{"type":"navigate","path":"lovelace/0"}}]',
      );
      await fire('g1');
      expect(executed, hasLength(1));
      expect(executed.single.$1, 'haNavigate');
      expect(executed.single.$2, {'path': 'lovelace/0'});
    });

    test('an unknown id runs nothing', () async {
      await build('[]');
      await fire('missing');
      expect(executed, isEmpty);
    });

    test('script and automation actions call the right services', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"finger_taps","fingers":3,"taps":1},'
        '"action":{"type":"ha_script","entityId":"script.morning"}},'
        '{"id":"g2","trigger":{"type":"corner_hold","corner":"bl",'
        '"holdMs":1500},"action":{"type":"ha_automation",'
        '"entityId":"automation.lights_off"}}]',
      );
      await fire('g1');
      await fire('g2');
      expect(executed[0].$1, 'haCallService');
      expect(executed[0].$2, {
        'domain': 'script',
        'service': 'turn_on',
        'entity_id': 'script.morning',
      });
      expect(executed[1].$2, {
        'domain': 'automation',
        'service': 'trigger',
        'entity_id': 'automation.lights_off',
      });
    });

    test('ha_service forwards entity and data only when present', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"corner_taps","corner":"tr",'
        '"taps":2},"action":{"type":"ha_service","domain":"light",'
        '"service":"turn_on","entityId":"light.kitchen",'
        '"data":{"brightness_pct":60}}},'
        '{"id":"g2","trigger":{"type":"corner_taps","corner":"bl",'
        '"taps":2},"action":{"type":"ha_service","domain":"scene",'
        '"service":"turn_on"}}]',
      );
      await fire('g1');
      await fire('g2');
      expect(executed[0].$1, 'haCallService');
      expect(executed[0].$2, {
        'domain': 'light',
        'service': 'turn_on',
        'entity_id': 'light.kitchen',
        'data': {'brightness_pct': 60},
      });
      expect(executed[1].$2, {'domain': 'scene', 'service': 'turn_on'});
    });

    test('screensaver action starts the screensaver', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"corner_taps","corner":"br",'
        '"taps":3},"action":{"type":"screensaver"}}]',
      );
      await fire('g1');
      expect(executed.single.$1, 'startScreensaver');
    });

    test('sendspin_player turns the show_player setting on', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"finger_hold","fingers":2,'
        '"holdMs":1000},"action":{"type":"sendspin_player"}}]',
      );
      await settings.set(defs.sendspinShowPlayer, false);
      await fire('g1');
      expect(settings.get(defs.sendspinShowPlayer), isTrue);
      // Show only: firing again never hides it.
      await fire('g1');
      expect(settings.get(defs.sendspinShowPlayer), isTrue);
    });

    test('camera_view show and hide pick the right command', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"corner_taps","corner":"tl",'
        '"taps":2},"action":{"type":"camera_view","mode":"show",'
        '"viewId":"v1","viewName":"Front"}},'
        '{"id":"g2","trigger":{"type":"corner_taps","corner":"tr",'
        '"taps":2},"action":{"type":"camera_view","mode":"hide"}}]',
      );
      await fire('g1');
      await fire('g2');
      expect(executed[0].$1, 'showCameraView');
      expect(executed[0].$2, {'viewId': 'v1'});
      expect(executed[1].$1, 'hideCameraView');
    });
  });
}
