import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_link.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Last interaction sensor over MQTT (issue #241): announced as a
/// timestamp sensor, stamped by touches and spoken turns, and left alone
/// by motion, announcements and media playback.
class _RecordingLink extends MqttLink {
  final published = <String, List<String>>{};

  bool _connected = false;

  @override
  String get protocolName => 'MQTT 5';

  @override
  bool get connected => _connected;

  @override
  Stream<MqttInbound> get messages => const Stream.empty();

  @override
  Future<MqttLinkError?> connect(MqttLinkConfig config) async {
    _connected = true;
    onConnected?.call();
    return null;
  }

  @override
  void disconnect() => _connected = false;

  @override
  void publishBytes(String topic, List<int> bytes, {required bool retain}) {}

  @override
  void publishString(String topic, String payload, {required bool retain}) {
    published.putIfAbsent(topic, () => []).add(payload);
  }

  @override
  void publishEmpty(String topic) {}

  @override
  void subscribe(String topic) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late MqttManager mqtt;
  late _RecordingLink link;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.mqtt.enabled': false,
      'ks.mqtt.host': 'broker.local',
      'ks.mqtt.device_id': 'testdev1',
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    mqtt = MqttManager(bus, commands, log, settings);
    await mqtt.init();
    link = _RecordingLink();
    mqtt.linkFactory = ({required legacy}) => link;
    await mqtt.connectForTest();
    // The bring-up runs 500ms after the onConnected hook (the reconnect
    // debounce); wait it out in real time, then let the queue drain.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await pumpEventQueue();
  }

  tearDown(() async => mqtt.dispose());

  test('discovery announces a timestamp sensor without a value yet', () async {
    await build();
    final config = link
        .published['homeassistant/sensor/ks_testdev1/last_interaction/config'];
    expect(config, isNotNull);
    final parsed = jsonDecode(config!.last) as Map<String, Object?>;
    expect(parsed['device_class'], 'timestamp');
    expect(
      parsed['state_topic'],
      'kiosksatellite/testdev1/last_interaction/state',
    );
    // Unknown until someone actually interacts; the broker's retained copy
    // covers restarts.
    expect(
      link.published['kiosksatellite/testdev1/last_interaction/state'],
      isNull,
    );
  });

  test(
    'touches and spoken turns stamp the sensor, ambient noise does not',
    () async {
      await build();
      bus.publish(const MotionDetected());
      bus.publish(const ActivityDetected(source: 'motion'));
      bus.publish(const ActivityDetected(source: 'remote'));
      bus.publish(
        const VoiceInteractionChanged(active: true, reason: 'announcement'),
      );
      await pumpEventQueue();
      const topic = 'kiosksatellite/testdev1/last_interaction/state';
      expect(link.published[topic], isNull);
      bus.publish(const ActivityDetected(source: 'touch'));
      await pumpEventQueue();
      expect(link.published[topic], hasLength(1));
      expect(DateTime.parse(link.published[topic]!.single), isA<DateTime>());
      // A second touch inside the minute rides the trailing throttle instead
      // of publishing again right away.
      bus.publish(const ActivityDetected(source: 'touch'));
      await pumpEventQueue();
      expect(link.published[topic], hasLength(1));
    },
  );

  test('a wake word stamps the sensor', () async {
    await build();
    bus.publish(const WakeWordDetected(model: 'ok_nova', phrase: 'ok nova'));
    await pumpEventQueue();
    expect(
      link.published['kiosksatellite/testdev1/last_interaction/state'],
      hasLength(1),
    );
  });

  test('a power button wake stamps the sensor, the app\'s own wakes do not '
      '(issue #348)', () async {
    await build();
    const topic = 'kiosksatellite/testdev1/last_interaction/state';
    // The wake word, motion or an automation lighting the panel is not a
    // person at the device; nor is the panel going dark, or a wake the
    // probe takes back.
    bus.publish(const ScreenStateChanged(on: true, source: 'app'));
    bus.publish(const ScreenStateChanged(on: false, source: 'system'));
    bus.publish(const ScreenStateChanged(on: true, source: 'probe'));
    await pumpEventQueue();
    expect(link.published[topic], isNull);
    // The OS reporting a wake this app did not ask for: the power button.
    bus.publish(const ScreenStateChanged(on: true, source: 'system'));
    await pumpEventQueue();
    expect(link.published[topic], hasLength(1));
    expect(DateTime.parse(link.published[topic]!.single), isA<DateTime>());
  });
}
