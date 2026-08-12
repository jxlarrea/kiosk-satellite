import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_link.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Foreground app sensor (issue #192): discovery announces it, the
/// state is the package name with the human label in attributes,
/// publishes dedupe on the package, and an unknowable foreground reads
/// unknown rather than a stale name.
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
    // The real links fire this from the client's connected hook; the
    // bring-up (discovery, initial states) rides on it.
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
  Map<String, Object?> foreground = const {'package': null, 'label': null};

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
      name: 'foregroundApp',
      description: 'stub',
      handler: (_) async => CommandResult.ok(foreground),
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

  test('discovery announces a diagnostic sensor with attributes', () async {
    foreground = const {'package': 'com.wallpanel', 'label': 'WallPanel'};
    await build();
    final configs = link
        .published['homeassistant/sensor/ks_testdev1/foreground_app/config'];
    expect(configs, isNotNull);
    final config = jsonDecode(configs!.single) as Map;
    expect(config['entity_category'], 'diagnostic');
    expect(config['state_topic'],
        'kiosksatellite/testdev1/foreground_app/state');
    expect(config['json_attributes_topic'],
        'kiosksatellite/testdev1/foreground_app/attributes');
  });

  test('the package is the state and the label rides in attributes',
      () async {
    foreground = const {'package': 'com.wallpanel', 'label': 'WallPanel'};
    await build();
    expect(link.published['kiosksatellite/testdev1/foreground_app/state'],
        ['com.wallpanel']);
    final attrs = jsonDecode(link
        .published['kiosksatellite/testdev1/foreground_app/attributes']!
        .single) as Map;
    expect(attrs['label'], 'WallPanel');
  });

  test('an unchanged foreground publishes once despite the poll', () async {
    foreground = const {'package': 'com.wallpanel', 'label': 'WallPanel'};
    // connectForTest runs the initial publish and the first stats poll;
    // the dedupe must collapse them into a single state publish.
    await build();
    expect(
        link.published['kiosksatellite/testdev1/foreground_app/state']!.length,
        1);
  });

  test('an unknowable foreground reads unknown with a null label',
      () async {
    foreground = const {'package': null, 'label': null};
    await build();
    expect(link.published['kiosksatellite/testdev1/foreground_app/state'],
        ['unknown']);
    final attrs = jsonDecode(link
        .published['kiosksatellite/testdev1/foreground_app/attributes']!
        .single) as Map;
    expect(attrs['label'], isNull);
  });
}
