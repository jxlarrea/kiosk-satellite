import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_link.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Bluetooth devices connected sensor (issue #281): it exists only with
/// the Bluetooth proxy on and only where Android answers, the count is the
/// state with the device names in attributes, and turning the proxy off
/// retracts it.
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

  late MqttManager mqtt;
  late EventBus bus;
  late SettingsManager settings;
  late _RecordingLink link;
  Map<String, Object?> bluetooth = const {};

  const configTopic =
      'homeassistant/sensor/ks_testdev1/bt_devices_connected/config';
  const stateTopic = 'kiosksatellite/testdev1/bt_devices_connected/state';
  const attributesTopic =
      'kiosksatellite/testdev1/bt_devices_connected/attributes';

  Future<void> build({bool proxy = true}) async {
    SharedPreferences.setMockInitialValues({
      'ks.mqtt.enabled': false,
      'ks.mqtt.host': 'broker.local',
      'ks.mqtt.device_id': 'testdev1',
      'ks.btproxy.enabled': proxy,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    commands.register(
      Command(
        name: 'getBluetoothConnections',
        description: 'stub',
        handler: (_) async => CommandResult.ok(bluetooth),
      ),
    );
    commands.register(
      Command(
        name: 'btProxyNearby',
        description: 'stub',
        handler: (_) async => CommandResult.ok(const {'count': 3}),
      ),
    );
    settings = SettingsManager(bus, commands, log);
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

  test('the count is the state and the names ride in attributes', () async {
    bluetooth = const {
      'connected': 2,
      'devices': ['Kitchen Speaker', 'Keyboard'],
      'enabled': true,
    };
    await build();
    final config = jsonDecode(link.published[configTopic]!.last) as Map;
    expect(config['entity_category'], 'diagnostic');
    expect(config['state_class'], 'measurement');
    expect(config['state_topic'], stateTopic);
    expect(link.published[stateTopic], ['2']);
    final attrs = jsonDecode(link.published[attributesTopic]!.single) as Map;
    expect(attrs['devices'], ['Kitchen Speaker', 'Keyboard']);
  });

  test('nothing connected still reports a count, not unknown', () async {
    bluetooth = const {'connected': 0, 'devices': <String>[], 'enabled': true};
    await build();
    expect(link.published[stateTopic], ['0']);
  });

  test('an unchanged count publishes once despite the poll', () async {
    bluetooth = const {
      'connected': 1,
      'devices': ['Kitchen Speaker'],
      'enabled': true,
    };
    await build();
    expect(link.published[stateTopic]!.length, 1);
  });

  test('the sensor rides the proxy switch', () async {
    bluetooth = const {
      'connected': 1,
      'devices': ['Kitchen Speaker'],
      'enabled': true,
    };
    await build(proxy: false);
    // Retracted rather than absent: a config from a build that had the
    // proxy on must not linger as a dead entity.
    expect(link.published[configTopic], ['']);
    expect(link.published.containsKey(stateTopic), isFalse);

    link.published.clear();
    await settings.set(defs.btproxyEnabled, true);
    await pumpEventQueue();
    expect(jsonDecode(link.published[configTopic]!.last), isA<Map>());
    expect(link.published[stateTopic], ['1']);
  });

  test('a link coming up publishes without waiting for the poll', () async {
    bluetooth = const {'connected': 0, 'devices': <String>[], 'enabled': true};
    await build();
    expect(link.published[stateTopic], ['0']);

    // Home Assistant connects to a lock through the proxy: the link is
    // gone again long before the next minute tick.
    bluetooth = const {
      'connected': 1,
      'devices': ['Yale Lock'],
      'enabled': true,
    };
    bus.publish(const BluetoothLinksChanged());
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await pumpEventQueue();
    expect(link.published[stateTopic], ['0', '1']);
    final attrs = jsonDecode(link.published[attributesTopic]!.last) as Map;
    expect(attrs['devices'], ['Yale Lock']);
  });

  test('a device Android will not answer for gets no sensor', () async {
    // No adapter, or no Nearby devices grant on Android 12+.
    bluetooth = const {};
    await build();
    expect(link.published[configTopic], ['']);
    expect(link.published.containsKey(stateTopic), isFalse);
  });
}
