import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_link.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The protocol ladder: MQTT 5 first (its will delay is what keeps a
/// napping radio from flapping availability), 3.1.1 once for brokers that
/// never learned 5, remembered for the rest of the run.
class _FakeLink extends MqttLink {
  _FakeLink(this.name, this.error);

  final String name;
  final MqttLinkError? error;
  int connects = 0;

  @override
  String get protocolName => name;

  bool _connected = false;

  @override
  bool get connected => _connected;

  @override
  Stream<MqttInbound> get messages => const Stream.empty();

  @override
  Future<MqttLinkError?> connect(MqttLinkConfig config) async {
    connects++;
    _connected = error == null;
    return error;
  }

  @override
  void disconnect() => _connected = false;

  @override
  void publishBytes(String topic, List<int> bytes, {required bool retain}) {}

  @override
  void publishString(String topic, String payload, {required bool retain}) {}

  @override
  void publishEmpty(String topic) {}

  @override
  void subscribe(String topic) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MqttManager mqtt;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.mqtt.enabled': false,
      'ks.mqtt.host': 'broker.local',
      'ks.mqtt.device_id': 'testdev1',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    mqtt = MqttManager(bus, commands, log, settings);
    await mqtt.init();
  }

  tearDown(() async => mqtt.dispose());

  test('a broker that refuses 5 gets one 3.1.1 try, then stays there',
      () async {
    await build();
    final v5 = _FakeLink(
      'MQTT 5',
      const MqttLinkError('The broker does not accept MQTT 5.',
          retryable: false),
    );
    final v311 = _FakeLink('MQTT 3.1.1', null);
    mqtt.linkFactory = ({required legacy}) => legacy ? v311 : v5;

    await mqtt.connectForTest();
    expect(v5.connects, 1);
    expect(v311.connects, 1);
    expect(v311.connected, isTrue);

    // The next connect skips the doomed 5 attempt entirely.
    v311.disconnect();
    await mqtt.connectForTest();
    expect(v5.connects, 1);
    expect(v311.connects, 2);
  });

  test('a 5-capable broker never sees a 3.1.1 attempt', () async {
    await build();
    final v5 = _FakeLink('MQTT 5', null);
    final v311 = _FakeLink('MQTT 3.1.1', null);
    mqtt.linkFactory = ({required legacy}) => legacy ? v311 : v5;

    await mqtt.connectForTest();

    expect(v5.connected, isTrue);
    expect(v311.connects, 0);
  });

  test('an unreachable broker fails both rungs and stays disconnected',
      () async {
    await build();
    final v5 = _FakeLink('MQTT 5',
        const MqttLinkError('Could not reach broker.local:1883.', retryable: true));
    final v311 = _FakeLink('MQTT 3.1.1',
        const MqttLinkError('Could not reach broker.local:1883.', retryable: true));
    mqtt.linkFactory = ({required legacy}) => legacy ? v311 : v5;

    await mqtt.connectForTest();

    expect(v5.connected, isFalse);
    expect(v311.connected, isFalse);
  });
}
