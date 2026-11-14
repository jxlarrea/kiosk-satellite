import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/bt_proxy_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice/voice_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Timer and alarm events for Home Assistant's bus (issue #765): how their
/// fields go out over the ESPHome API, and the timer events Home
/// Assistant's own timer messages turn into.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('strings stay data, everything else goes out as a literal', () {
    final fields = haEventFields({
      'event_type': 'finished',
      'name': '{{ states("sun.sun") }}',
      'total_seconds': 300,
      'is_active': false,
      'enabled': true,
      'days': ['mon', 'tue'],
      'gone': null,
    });
    expect(fields.data, {
      'event_type': 'finished',
      'name': '{{ states("sun.sun") }}',
    });
    expect(fields.typed, {
      'total_seconds': '300',
      'is_active': 'False',
      'enabled': 'True',
      'days': '["mon","tue"]',
      'gone': 'None',
    });
  });

  test('every timer message from Home Assistant fires one event', () async {
    final support = await Directory.systemTemp.createTemp('ks_ha_events');
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      await support.delete(recursive: true);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => support.path,
        );
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    final esphome = BtProxyManager(bus, commands, log, settings);
    final voice = VoiceManager(
      bus,
      commands,
      log,
      settings,
      esphome,
      WakeWordManager(bus, commands, log, settings),
    );
    await voice.init();
    final events = <HaEventRequested>[];
    bus.on<HaEventRequested>().listen(events.add);
    final lists = <List<Map<String, Object?>>>[];
    bus.on<VoiceTimersChanged>().listen((e) => lists.add(e.timers));

    void timer(int type, {int left = 300, bool active = true}) =>
        esphome.onVoice!('timer', {
          'type': type,
          'id': 't1',
          'name': 'pizza',
          'totalSeconds': type == 1 ? 360 : 300,
          'secondsLeft': left,
          'isActive': active,
        });

    timer(0);
    timer(1, left: 200, active: false);
    timer(3, left: 0);
    voice.dismiss();
    await pumpEventQueue();

    expect(events.map((e) => e.name).toSet(), {'kiosk_satellite_timer'});
    expect(
      [for (final e in events) e.data['event_type']],
      ['started', 'updated', 'finished', 'dismissed'],
    );
    expect(events[1].data, {
      'event_type': 'updated',
      'timer_id': 't1',
      'name': 'pizza',
      // The duration it was started with, as the Voice Satellite event
      // reported it, not Home Assistant's grown total.
      'total_seconds': 300,
      'seconds_left': 200,
      'is_active': false,
    });
    expect(events[3].data['name'], 'pizza');
    expect(events[3].data['total_seconds'], 300);

    // The vs_list_timers list after each change: running, paused,
    // ringing, then gone once the alert is dismissed.
    expect(lists, hasLength(4));
    expect(lists[0].single['is_active'], isTrue);
    expect(lists[0].single['ends_at'], isA<String>());
    expect(lists[1].single, {
      'timer_id': 't1',
      'name': 'pizza',
      'total_seconds': 300,
      'duration_seconds': 360,
      'seconds_left': 200,
      'is_active': false,
      'ends_at': null,
      'finished': false,
    });
    expect(lists[2].single['finished'], isTrue);
    expect(lists[2].single['total_seconds'], 300);
    expect(lists[3], isEmpty);
    expect(voice.timerList(), isEmpty);
    await voice.dispose();
  });
}
