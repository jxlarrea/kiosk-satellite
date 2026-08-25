import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/core/permissions.dart';
import 'package:kiosk_satellite/managers/gestures/gesture_mappings.dart';
import 'package:kiosk_satellite/managers/gestures/gestures_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clap_synth.dart';

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
      final triggers = nativeGestureTriggers(
        decodeGestureMappings(
          '[{"id":"g1","trigger":{"type":"corner_taps","corner":"tl",'
          '"taps":3},"action":{"type":"menu"}},'
          '{"id":"g2","trigger":{"type":"finger_hold","fingers":2,'
          '"holdMs":1500},"action":{"type":"menu"}},'
          '{"id":"g3","trigger":{"type":"corner_sequence",'
          '"sequence":["tl","tr","bl"]},"action":{"type":"menu"}}]',
        ),
      );
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
        describeGestureTrigger({
          'type': 'corner_taps',
          'corner': 'tl',
          'taps': 3,
        }),
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
      expect(
        describeGestureAction({'type': 'app_launcher'}),
        'Open the app launcher',
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
        'showAppLauncher',
        'launchApp',
        'openUri',
        'openSystemSettings',
        'haCallService',
        'haFireEvent',
      ]) {
        commands.register(
          Command(
            name: name,
            description: 'test stub',
            handler: (p) async {
              executed.add((name, p));
              return const CommandResult.ok();
            },
          ),
        );
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

    test('sendspin_player leaves the show_player setting alone', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"finger_hold","fingers":2,'
        '"holdMs":1000},"action":{"type":"sendspin_player"}}]',
      );
      // The reveal goes through the card override (issue #257): a player
      // configured not to pop up on its own can still be summoned for the
      // session, without the setting changing underneath its owner.
      await settings.set(defs.sendspinShowPlayer, false);
      await fire('g1');
      expect(settings.get(defs.sendspinShowPlayer), isFalse);
    });

    test('sendspin_player publishes the reveal, which is what actually '
        'brings back a flung-away card', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"finger_hold","fingers":2,'
        '"holdMs":1000},"action":{"type":"sendspin_player"}}]',
      );
      // The card hidden by a fling (or the paused-hide timer) is the
      // override state, and only this event reaches the overlay that
      // owns it (and the manager's queue recovery behind it).
      var revealed = 0;
      bus.on<SendspinShowPlayerRequested>().listen((_) => revealed++);
      await fire('g1');
      await pumpEventQueue();
      expect(revealed, 1, reason: 'the overlay un-dismisses on this event');
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
      // toggle: performed again, the same gesture closes the view it opened.
      expect(executed[0].$2, {'viewId': 'v1', 'toggle': true});
      expect(executed[1].$1, 'hideCameraView');
    });

    test('screensaver_stop action stops the screensaver', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"claps","claps":2},'
        '"action":{"type":"screensaver_stop"}}]',
      );
      await fire('g1');
      expect(executed.single.$1, 'stopScreensaver');
    });

    test('app_launcher opens the launcher overlay (issue #318)', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"corner_taps","corner":"br",'
        '"taps":3},"action":{"type":"app_launcher"}}]',
      );
      await fire('g1');
      // Open only, through the launcher's own command so its gates (master
      // switch, whitelist) apply; the drawer's Allowed Action does not.
      expect(executed.single.$1, 'showAppLauncher');
    });

    test('hold_mode toggles the setting each time (issue #266)', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"claps","claps":3},'
        '"action":{"type":"hold_mode"}}]',
      );
      // The same gesture pins and, performed again, releases: the setting
      // IS the live state every other surface (HA switch, remote admin,
      // drawer notice) observes.
      await fire('g1');
      expect(settings.get(defs.haHoldMode), isTrue);
      await fire('g1');
      expect(settings.get(defs.haHoldMode), isFalse);
    });
  });

  group('clapTargets', () {
    test('collects clap counts and ignores everything else', () {
      final mappings = decodeGestureMappings(
        '[{"id":"g1","trigger":{"type":"claps","claps":2},'
        '"action":{"type":"screensaver"}},'
        '{"id":"g2","trigger":{"type":"claps","claps":4},'
        '"action":{"type":"screensaver"}},'
        '{"id":"g3","trigger":{"type":"corner_taps","corner":"tl","taps":3},'
        '"action":{"type":"screensaver"}}]',
      );
      expect(clapTargets(mappings), {2, 4});
      // Claps are acoustic: the native touch engine never sees them.
      expect(nativeGestureTriggers(mappings).map((t) => t['id']), ['g3']);
    });
  });

  group('clap gestures', () {
    const clapMapping =
        '[{"id":"c1","trigger":{"type":"claps","claps":2},'
        '"action":{"type":"navigate","path":"lovelace/0"}}]';

    late EventBus bus;
    late SettingsManager settings;
    late GesturesManager gestures;
    late List<(String, Map<String, Object?>)> executed;
    late StreamController<Uint8List> mic;
    late int permissionAsks;

    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    Future<void> build(
      String mappingsJson, {
      PermissionOutcome outcome = PermissionOutcome.granted,
    }) async {
      SharedPreferences.setMockInitialValues({
        'ks.${defs.gestureMappings.key}': mappingsJson,
      });
      bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      executed = [];
      commands.register(
        Command(
          name: 'haNavigate',
          description: 'test stub',
          handler: (p) async {
            executed.add(('haNavigate', p));
            return const CommandResult.ok();
          },
        ),
      );
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      mic = StreamController<Uint8List>.broadcast();
      permissionAsks = 0;
      gestures = GesturesManager(
        bus,
        commands,
        log,
        settings,
        micStream: () => mic.stream,
        micPermission: () async {
          permissionAsks++;
          return outcome;
        },
      );
      await gestures.init();
      await settle();
    }

    /// Push a synthetic scene through the mic stream in 80 ms chunks.
    Future<void> hear(List<double> samples) async {
      final bytes = pcmOf(samples);
      const chunk = 2560;
      for (var i = 0; i < bytes.length; i += chunk) {
        mic.add(Uint8List.sublistView(bytes, i, min(i + chunk, bytes.length)));
      }
      await settle();
    }

    test('two claps run the mapped action', () async {
      await build(clapMapping);
      expect(mic.hasListener, isTrue, reason: 'a claps mapping opens the mic');
      await hear(clapScene(2, Random(20)));
      expect(executed.single.$1, 'haNavigate');
      expect(executed.single.$2, {'path': 'lovelace/0'});
    });

    test('no clap mappings never opens the mic', () async {
      await build(
        '[{"id":"g1","trigger":{"type":"corner_taps","corner":"tl",'
        '"taps":3},"action":{"type":"navigate","path":"lovelace/0"}}]',
      );
      expect(mic.hasListener, isFalse);
      expect(permissionAsks, 0);
    });

    test('claps during a voice turn are ignored', () async {
      await build(clapMapping);
      bus.publish(const WakeWordStateChanged(active: false, listening: false));
      await settle();
      await hear(clapScene(2, Random(21)));
      expect(executed, isEmpty, reason: 'that was someone talking to VS');
      bus.publish(const WakeWordStateChanged(active: true, listening: true));
      await settle();
      await hear(clapScene(2, Random(22)));
      expect(executed, hasLength(1));
    });

    test('muting the satellite closes the capture, unmuting reopens', () async {
      await build(clapMapping);
      bus.publish(
        const WakeWordStateChanged(active: true, listening: false, muted: true),
      );
      await settle();
      expect(mic.hasListener, isFalse, reason: 'muted means not listening');
      bus.publish(const WakeWordStateChanged(active: true, listening: true));
      await settle();
      expect(mic.hasListener, isTrue);
    });

    test('lockdown closes the capture', () async {
      await build(clapMapping);
      await settings.set(defs.lockdownEnabled, true);
      await settle();
      expect(mic.hasListener, isFalse);
      await settings.set(defs.lockdownEnabled, false);
      await settle();
      expect(mic.hasListener, isTrue);
    });

    test('kiosk Disable Gestures covers claps too', () async {
      await build(clapMapping);
      await settings.set(defs.kioskEnabled, true);
      await settings.set(defs.kioskDisableGestures, true);
      await settle();
      expect(mic.hasListener, isFalse);
    });

    test('a declined microphone stays closed and is not re-nagged', () async {
      await build(clapMapping, outcome: PermissionOutcome.declined);
      expect(mic.hasListener, isFalse);
      expect(permissionAsks, 1);
      // An unrelated wake state change must not re-prompt...
      bus.publish(const WakeWordStateChanged(active: true, listening: true));
      await settle();
      expect(permissionAsks, 1);
      // ...but editing the mappings is the user re-engaging: ask again.
      await settings.setFromJson(defs.gestureMappings.key, clapMapping);
      await settle();
      expect(permissionAsks, 2);
    });

    test('a capture error retries instead of going deaf', () async {
      await build(clapMapping);
      mic.addError(StateError('audioserver died'));
      await settle();
      expect(mic.hasListener, isFalse);
      // The retry timer is 30 s; call the sync directly by nudging a gate.
      await settings.setFromJson(defs.gestureMappings.key, clapMapping);
      await settle();
      expect(mic.hasListener, isTrue);
    });
  });
}
