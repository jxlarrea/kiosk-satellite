import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_link.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Device > Hardware sensors (issue #213): the Device identity sensor
/// carries the model with Android version and build in attributes, the IP
/// sensors put the primary address in the state with the rest (keyed by
/// interface) in attributes, and the uptime pair publishes seconds with an
/// unknown network uptime while offline.
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
  Map<String, Object?> ips = const {'ipv4': {}, 'ipv6': {}};
  Map<String, Object?> uptime = const {'app': 4321, 'network': null};

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.mqtt.enabled': false,
      'ks.mqtt.host': 'broker.local',
      'ks.mqtt.device_id': 'testdev1',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    commands.register(Command(
      name: 'getDeviceInfo',
      description: 'stub',
      handler: (_) async => CommandResult.ok(const {
        'model': 'samsung SM-X700',
        'osVersion': 'Android 13',
        'appVersion': '2026.8.40',
      }),
    ));
    commands.register(Command(
      name: 'getDeviceDetails',
      description: 'stub',
      handler: (_) async =>
          CommandResult.ok(const {'androidBuild': 'TP1A.220624.014'}),
    ));
    commands.register(Command(
      name: 'getIpAddresses',
      description: 'stub',
      handler: (_) async => CommandResult.ok(ips),
    ));
    commands.register(Command(
      name: 'getUptime',
      description: 'stub',
      handler: (_) async => CommandResult.ok(uptime),
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

  test('discovery announces the five diagnostic sensors', () async {
    await build();
    for (final objectId in [
      'device_info',
      'ipv4_address',
      'ipv6_address',
      'app_uptime',
      'network_uptime',
    ]) {
      final configs =
          link.published['homeassistant/sensor/ks_testdev1/$objectId/config'];
      expect(configs, isNotNull, reason: objectId);
      final config = jsonDecode(configs!.single) as Map;
      expect(config['entity_category'], 'diagnostic', reason: objectId);
    }
    final uptimeConfig = jsonDecode(link
        .published['homeassistant/sensor/ks_testdev1/app_uptime/config']!
        .single) as Map;
    expect(uptimeConfig['device_class'], 'duration');
    expect(uptimeConfig['unit_of_measurement'], 's');
  });

  test('the Device sensor carries the model with version and build', () async {
    await build();
    expect(link.published['kiosksatellite/testdev1/device_info/state'],
        ['samsung SM-X700']);
    final attrs = jsonDecode(link
        .published['kiosksatellite/testdev1/device_info/attributes']!
        .single) as Map;
    expect(attrs['android_version'], 'Android 13');
    expect(attrs['build'], 'TP1A.220624.014');
  });

  test('the first IPv4 address is the state, the rest ride in attributes',
      () async {
    ips = const {
      'ipv4': {
        'wlan0': ['192.168.1.50'],
        'eth0': ['10.0.3.2'],
      },
      'ipv6': {},
    };
    await build();
    expect(link.published['kiosksatellite/testdev1/ipv4_address/state'],
        ['192.168.1.50']);
    final attrs = jsonDecode(link
        .published['kiosksatellite/testdev1/ipv4_address/attributes']!
        .single) as Map;
    expect(attrs['other_addresses'], ['10.0.3.2']);
    expect((attrs['interfaces'] as Map)['eth0'], ['10.0.3.2']);
  });

  test('IPv6 prefers a global address over the link-local one', () async {
    ips = const {
      'ipv4': {},
      'ipv6': {
        'wlan0': ['fe80::1234', '2001:db8::50'],
      },
    };
    await build();
    expect(link.published['kiosksatellite/testdev1/ipv6_address/state'],
        ['2001:db8::50']);
    final attrs = jsonDecode(link
        .published['kiosksatellite/testdev1/ipv6_address/attributes']!
        .single) as Map;
    expect(attrs['other_addresses'], ['fe80::1234']);
  });

  test('no address at all publishes an empty (unknown) state', () async {
    ips = const {'ipv4': {}, 'ipv6': {}};
    await build();
    expect(
        link.published['kiosksatellite/testdev1/ipv4_address/state'], ['']);
    expect(
        link.published['kiosksatellite/testdev1/ipv6_address/state'], ['']);
  });

  test('uptime publishes seconds, network unknown while offline', () async {
    uptime = const {'app': 4321, 'network': null};
    await build();
    expect(link.published['kiosksatellite/testdev1/app_uptime/state'],
        ['4321']);
    expect(link.published['kiosksatellite/testdev1/network_uptime/state'],
        ['']);
  });

  test('a live network publishes its uptime', () async {
    uptime = const {'app': 4321, 'network': 99};
    await build();
    expect(link.published['kiosksatellite/testdev1/network_uptime/state'],
        ['99']);
  });
}
