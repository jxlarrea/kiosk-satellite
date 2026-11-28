import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/screen/adaptive_light_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The light adaptive brightness follows (issue #911): the device sensor
/// by default, a Home Assistant entity in its place with the switch on.
/// Home Assistant is left unconfigured, so no socket opens; the entity's
/// states are fed in as the subscription would deliver them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late CommandRegistry commands;
  late AdaptiveLightManager light;
  late List<AdaptiveLightChanged> published;
  late List<RoomLightChanged> room;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  Future<void> build(
    Map<String, Object> prefs, {
    bool sensor = true,
    double? sensorLux = 30,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    commands.register(
      Command(
        name: 'getLightLevel',
        description: 'fake',
        handler: (_) async => CommandResult.ok({
          'present': sensor,
          'lux': sensor ? sensorLux : null,
          'live': false,
        }),
      ),
    );
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    published = [];
    bus.on<AdaptiveLightChanged>().listen(published.add);
    room = [];
    bus.on<RoomLightChanged>().listen(room.add);
    light = AdaptiveLightManager(
      bus,
      commands,
      log,
      settings,
      HomeAssistantManager(bus, commands, log, settings),
    );
    await light.init();
    await settle();
  }

  Future<Map> probe() async =>
      (await commands.execute('getAdaptiveLight', const {})).data as Map;

  Future<Map> roomProbe() async =>
      (await commands.execute('getRoomLight', const {})).data as Map;

  tearDown(() => light.dispose());

  test('the device sensor is the source by default', () async {
    await build({'ks.screen.adaptive_brightness': true});
    expect(await probe(), {
      'source': 'sensor',
      'entity': '',
      'lux': 30.0,
      'live': false,
    });
    bus.publish(const LightLevelChanged(lux: 80));
    await settle();
    expect(published.last.source, 'sensor');
    expect(published.last.lux, 80);
    expect(published.last.live, isTrue);
  });

  test('a device without a sensor reports none', () async {
    await build({'ks.screen.adaptive_brightness': true}, sensor: false);
    expect((await probe())['source'], 'none');
    expect((await probe())['lux'], isNull);
  });

  test('the entity takes over from the sensor, and the sensor no longer '
      'moves the reading', () async {
    await build({
      'ks.screen.adaptive_brightness': true,
      'ks.screen.adaptive_use_entity': true,
      'ks.screen.adaptive_light_entity': 'sensor.hallway_illuminance',
    });
    expect((await probe())['source'], 'entity');
    expect((await probe())['lux'], isNull);
    light.applyEntityState('sensor.hallway_illuminance', '12.5');
    await settle();
    expect(published.last.source, 'entity');
    expect(published.last.lux, 12.5);
    final count = published.length;
    bus.publish(const LightLevelChanged(lux: 400));
    await settle();
    expect(published, hasLength(count));
    expect((await probe())['lux'], 12.5);
  });

  test('a state that is not a light level keeps the last reading', () async {
    await build({
      'ks.screen.adaptive_brightness': true,
      'ks.screen.adaptive_use_entity': true,
      'ks.screen.adaptive_light_entity': 'sensor.hallway_illuminance',
    });
    light.applyEntityState('sensor.hallway_illuminance', '20');
    light.applyEntityState('sensor.hallway_illuminance', 'unavailable');
    light.applyEntityState('sensor.other', '900');
    await settle();
    expect((await probe())['lux'], 20.0);
  });

  test(
    'the last entity reading survives a restart, for that entity only',
    () async {
      await build({
        'ks.screen.adaptive_brightness': true,
        'ks.screen.adaptive_use_entity': true,
        'ks.screen.adaptive_light_entity': 'sensor.hallway_illuminance',
      });
      light.applyEntityState('sensor.hallway_illuminance', '7');
      await settle();
      final saved = settings.internal('adaptive_entity_last_lux');
      await light.dispose();
      await build({
        'ks.screen.adaptive_brightness': true,
        'ks.screen.adaptive_use_entity': true,
        'ks.screen.adaptive_light_entity': 'sensor.hallway_illuminance',
        'ks.internal.adaptive_entity_last_lux': saved,
      });
      expect(await probe(), containsPair('lux', 7.0));
      expect(await probe(), containsPair('live', false));
      await settings.set(defs.adaptiveLightEntity, 'sensor.porch_illuminance');
      await settle();
      expect((await probe())['lux'], isNull);
      expect(published.last.lux, isNull);
    },
  );

  test('turning the entity switch off goes back to the sensor', () async {
    await build({
      'ks.screen.adaptive_brightness': true,
      'ks.screen.adaptive_use_entity': true,
      'ks.screen.adaptive_light_entity': 'sensor.hallway_illuminance',
    });
    await settings.set(defs.adaptiveUseEntity, false);
    await settle();
    expect(published.last.source, 'sensor');
    expect(published.last.lux, 30);
  });

  group('room light (issue #1636)', () {
    const entityPrefs = {
      'ks.screen.adaptive_brightness': true,
      'ks.screen.adaptive_use_entity': true,
      'ks.screen.adaptive_light_entity': 'sensor.hallway_illuminance',
    };

    test('the device sensor by default', () async {
      await build({});
      expect(await roomProbe(), {
        'present': true,
        'lux': 30.0,
        'live': false,
        'source': 'sensor',
      });
      bus.publish(const LightLevelChanged(lux: 80));
      await settle();
      expect(room.last.source, 'sensor');
      expect(room.last.lux, 80);
    });

    test('the entity adaptive brightness follows takes over, and the '
        'sensor no longer moves it', () async {
      await build(entityPrefs);
      expect(await roomProbe(), containsPair('source', 'entity'));
      light.applyEntityState('sensor.hallway_illuminance', '3');
      await settle();
      expect(room.last.source, 'entity');
      expect(room.last.lux, 3);
      final count = room.length;
      bus.publish(const LightLevelChanged(lux: 400));
      await settle();
      expect(room, hasLength(count));
      expect((await roomProbe())['lux'], 3.0);
    });

    test('the entity stands in on a device without a sensor', () async {
      await build(entityPrefs, sensor: false);
      light.applyEntityState('sensor.hallway_illuminance', '4');
      await settle();
      expect(await roomProbe(), containsPair('present', true));
      expect(await roomProbe(), containsPair('lux', 4.0));
    });

    test('a repeated entity state is not announced again', () async {
      await build(entityPrefs);
      light.applyEntityState('sensor.hallway_illuminance', '5');
      await settle();
      final count = room.length;
      // The subscription dropped and reopened with the same reading.
      light.seedEntity(lux: 5);
      light.applyEntityState('sensor.hallway_illuminance', '5');
      await settle();
      expect(room, hasLength(count));
    });

    test('the entity switch on with adaptive brightness off leaves the '
        'device sensor', () async {
      await build({...entityPrefs, 'ks.screen.adaptive_brightness': false});
      expect(await roomProbe(), containsPair('source', 'sensor'));
      expect(await roomProbe(), containsPair('lux', 30.0));
    });

    test('no entity picked leaves the device sensor', () async {
      await build({...entityPrefs, 'ks.screen.adaptive_light_entity': ''});
      expect(await roomProbe(), containsPair('source', 'sensor'));
    });

    test('turning adaptive brightness off announces the sensor', () async {
      await build(entityPrefs);
      light.applyEntityState('sensor.hallway_illuminance', '2');
      await settle();
      await settings.set(defs.adaptiveBrightness, false);
      await settle();
      expect(room.last.source, 'sensor');
      expect(room.last.lux, 30);
    });
  });
}
