import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_link.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The broker packet cap (issue #207): an MQTT 5 broker that advertised a
/// Maximum Packet Size answers an oversize publish by dropping the whole
/// connection, so a camera frame bigger than the cap must be skipped with
/// a log line rather than sent.
class _CappedLink extends MqttLink {
  _CappedLink(this.cap);

  final int? cap;
  final binaryPublishes = <String, List<int>>{};

  bool _connected = false;

  @override
  String get protocolName => 'MQTT 5';

  @override
  bool get connected => _connected;

  @override
  int? get brokerMaximumPacketSize => cap;

  @override
  Stream<MqttInbound> get messages => const Stream.empty();

  @override
  Future<MqttLinkError?> connect(MqttLinkConfig config) async {
    _connected = true;
    return null;
  }

  @override
  void disconnect() => _connected = false;

  @override
  void publishBytes(String topic, List<int> bytes, {required bool retain}) {
    binaryPublishes[topic] = bytes;
  }

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
  late EventBus bus;
  late _CappedLink link;

  Future<void> build(int? cap) async {
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
    link = _CappedLink(cap);
    mqtt.linkFactory = ({required legacy}) => link;
    await mqtt.connectForTest();
  }

  tearDown(() async => mqtt.dispose());

  const topic = 'kiosksatellite/testdev1/camera_snapshot/image';

  test('a frame over the advertised cap is skipped, not sent', () async {
    await build(1024);
    bus.publish(CameraSnapshotTaken(jpeg: Uint8List(2048)));
    await pumpEventQueue();
    expect(link.binaryPublishes, isNot(contains(topic)));
  });

  test('a frame under the cap goes out', () async {
    await build(1024);
    bus.publish(CameraSnapshotTaken(jpeg: Uint8List(512)));
    await pumpEventQueue();
    expect(link.binaryPublishes[topic], hasLength(512));
  });

  test('no advertised cap means no gate', () async {
    await build(null);
    bus.publish(CameraSnapshotTaken(jpeg: Uint8List(5 * 1024 * 1024)));
    await pumpEventQueue();
    expect(link.binaryPublishes[topic], hasLength(5 * 1024 * 1024));
  });
}
