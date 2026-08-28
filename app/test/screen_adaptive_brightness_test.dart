import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screen/screen_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// Adaptive brightness (issue #343) in the screen manager: the level every
/// caller deals in is the ceiling, the panel gets it times the factor the
/// room's light sets, and every mirror hears the ceiling.
class _NoopWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kiosk_satellite/brightness');

  /// The fake panel and the fake light sensor.
  late double panel;
  late List<double> writes;
  late List<double> published;
  late bool present;
  late double? lux;
  late EventBus bus;
  late SettingsManager settings;
  late ScreenManager screen;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> build(
    Map<String, Object> initial, {
    bool sensor = true,
    double? startLux = 5,
    double startPanel = 0.5,
    Duration gap = Duration.zero,
  }) async {
    panel = startPanel;
    writes = [];
    published = [];
    present = sensor;
    lux = startLux;
    wakelockPlusPlatformInstance = _NoopWakelock();
    SharedPreferences.setMockInitialValues(initial);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'get':
              return panel;
            case 'set':
              final level = (call.arguments as Map)['level'] as double;
              panel = level;
              writes.add(level);
              return true;
            default:
              return null;
          }
        });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    // The device manager's probe, as the screen manager sees it.
    commands.register(
      Command(
        name: 'getLightLevel',
        description: 'fake',
        handler: (_) async =>
            CommandResult.ok({'present': present, 'lux': lux}),
      ),
    );
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    bus.on<BrightnessChanged>().listen((e) => published.add(e.level));
    screen = ScreenManager(bus, commands, log, settings, adaptiveWriteGap: gap);
    await screen.init();
    // The bus delivers on a microtask: let init's publishes land.
    await settle();
  }

  /// The native observer reporting a system value that moved the panel.
  Future<void> observe(double level) async {
    panel = level;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('brightnessChanged', level),
          ),
          (_) {},
        );
  }

  const on = {
    'ks.screen.adaptive_brightness': true,
    'ks.screen.adaptive_dim_floor': 0.2,
    'ks.screen.adaptive_dark_lux': 5,
    'ks.screen.adaptive_bright_lux': 500,
  };

  tearDown(() => screen.dispose());

  test('the default brightness of a session starting in the dark lands '
      'dimmed, and every mirror hears the ceiling', () async {
    await build({
      ...on,
      'ks.screen.set_brightness_on_launch': true,
      'ks.screen.default_brightness': 0.8,
    });
    expect(writes, [closeTo(0.16, 0.001)]);
    expect(published, [0.8]);
    expect(await screen.getBrightness(), 0.8);
  });

  test('the room brightening lifts the panel toward the ceiling, with no '
      'setting moving and nothing published', () async {
    await build({
      ...on,
      'ks.screen.set_brightness_on_launch': true,
      'ks.screen.default_brightness': 0.8,
    });
    published.clear();
    bus.publish(const LightLevelChanged(lux: 500));
    await settle();
    expect(writes.last, closeTo(0.8, 0.001));
    expect(published, isEmpty);
    expect(await screen.getBrightness(), 0.8);
  });

  test('a step the eye cannot see is not written', () async {
    await build({
      ...on,
      'ks.screen.set_brightness_on_launch': true,
      'ks.screen.default_brightness': 0.8,
    });
    // 5 -> 5.5 lx moves the factor by a hair.
    bus.publish(const LightLevelChanged(lux: 5.5));
    await settle();
    expect(writes, hasLength(1));
  });

  test('the screensaver setting its level gets it scaled, and reads back '
      'what it set', () async {
    await build(on);
    expect(await screen.setBrightness(0.2), isTrue);
    await settle();
    expect(writes, [closeTo(0.04, 0.001)]);
    expect(published, [0.2]);
    expect(await screen.getBrightness(), 0.2);
  });

  test(
    'turning adaptive brightness off shows the ceiling as is again',
    () async {
      await build(on);
      await screen.setBrightness(0.6);
      await settings.set(defs.adaptiveBrightness, false);
      await settle();
      expect(writes.last, closeTo(0.6, 0.001));
      expect(await screen.getBrightness(), 0.6);
    },
  );

  test(
    'turning it on takes the panel as the ceiling and dims at once',
    () async {
      await build({}, startPanel: 0.7);
      await settings.set(defs.adaptiveBrightness, true);
      await settings.set(defs.adaptiveDimFloor, 0.2);
      await settle();
      expect(writes.last, closeTo(0.14, 0.001));
      expect(await screen.getBrightness(), 0.7);
    },
  );

  test('a session starting under a panel the last one dimmed undoes the '
      'dimming to find the ceiling', () async {
    // Last night's session left 0.14 on the panel (0.7 at the floor).
    await build(on, startPanel: 0.14);
    expect(await screen.getBrightness(), closeTo(0.7, 0.001));
  });

  test("the observer's echo of this app's own write is not a new ceiling; "
      'a change made elsewhere is', () async {
    await build(on, startLux: 500);
    await screen.setBrightness(0.8);
    await settle();
    published.clear();
    await observe(0.8);
    await settle();
    expect(published, isEmpty);
    // Quick settings moved the panel to 50% with the factor at 1.
    await observe(0.5);
    await settle();
    expect(published, [0.5]);
    expect(await screen.getBrightness(), 0.5);
    // At the floor now: the external value is undone by the factor.
    bus.publish(const LightLevelChanged(lux: 5));
    await settle();
    expect(writes.last, closeTo(0.1, 0.001));
    await observe(0.05);
    expect(await screen.getBrightness(), closeTo(0.25, 0.001));
  });

  test('without adaptive brightness the observer reports the panel as '
      'before', () async {
    await build({});
    await observe(0.3);
    await settle();
    expect(published, [0.3]);
    expect(await screen.getBrightness(), 0.3);
  });

  test('without a light sensor the switch does nothing', () async {
    await build({
      ...on,
      'ks.screen.set_brightness_on_launch': true,
      'ks.screen.default_brightness': 0.8,
    }, sensor: false);
    expect(writes, [0.8]);
    bus.publish(const LightLevelChanged(lux: 500));
    await settle();
    expect(writes, hasLength(1));
  });

  test(
    'an adaptive step right after another write waits out the gap',
    () async {
      await build(on, gap: const Duration(milliseconds: 60));
      await screen.setBrightness(0.8);
      bus.publish(const LightLevelChanged(lux: 500));
      await settle();
      expect(writes, hasLength(1));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(writes, hasLength(2));
      expect(writes.last, closeTo(0.8, 0.001));
    },
  );
}
