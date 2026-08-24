import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_link.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real-MAC identity in MQTT discovery (issue #252): with the setting on
/// and an adopted address stored, the device block carries a connections
/// entry so Home Assistant merges this device with the ESPHome device and
/// with the router integrations' entries; without it, no connections key.
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
  late _RecordingLink link;

  Future<void> build({required Map<String, Object> extraPrefs}) async {
    SharedPreferences.setMockInitialValues({
      'ks.mqtt.enabled': false,
      'ks.mqtt.host': 'broker.local',
      'ks.mqtt.device_id': 'testdev1',
      ...extraPrefs,
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    commands.register(Command(
      name: 'getDeviceInfo',
      description: 'stub',
      handler: (_) async => CommandResult.ok(const {
        'model': 'samsung SM-X700',
        'appVersion': '2026.8.65',
      }),
    ));
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

  Map deviceBlock() {
    final configs = link.published.entries
        .firstWhere((e) => e.key.endsWith('/config'))
        .value;
    return (jsonDecode(configs.last) as Map)['device'] as Map;
  }

  test('an adopted address lands in the device block, lowercase', () async {
    await build(extraPrefs: {
      'ks.esphome.real_mac': true,
      'ks.internal.esphome_adopted_mac': '80:30:49:CD:D6:5F',
    });
    expect(deviceBlock()['connections'], [
      ['mac', '80:30:49:cd:d6:5f'],
    ]);
  });

  test('a typed address lands in the device block when nothing was read',
      () async {
    // No adoption stored and no platform channel in tests: the typed
    // address (issue #300) is what the device block carries.
    await build(extraPrefs: {
      'ks.esphome.real_mac': true,
      'ks.esphome.mac_override': '80:30:49:CD:D6:5F',
    });
    expect(deviceBlock()['connections'], [
      ['mac', '80:30:49:cd:d6:5f'],
    ]);
  });

  test('with the setting off the device block has no connections', () async {
    await build(extraPrefs: {
      'ks.internal.esphome_adopted_mac': '80:30:49:CD:D6:5F',
    });
    expect(deviceBlock().containsKey('connections'), isFalse);
  });
}
