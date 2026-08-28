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

/// Adaptive brightness (issue #343) in the screen manager: the ceiling is
/// the bright-room level (Maximum brightness, or the screensaver's own
/// slider), the panel gets it times the factor the room's light sets, the
/// screensaver deals in ceilings and everything else in the panel.
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
  late List<BrightnessChanged> published;
  late bool present;
  late double? lux;
  late EventBus bus;
  late SettingsManager settings;
  late CommandRegistry commands;
  late ScreenManager screen;

  /// Let a write's platform round trip and the bus delivery after it run.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

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
    commands = CommandRegistry(log);
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
    bus.on<BrightnessChanged>().listen(published.add);
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
    await settle();
  }

  Future<double?> ceiling() async =>
      (await commands.execute('getBrightness', const {'ceiling': true})).data
          as double?;
  Future<double?> panelLevel() async =>
      (await commands.execute('getBrightness', const {})).data as double?;

  /// Adaptive on with Minimum 20% and Maximum 80%: a floor of 0.25.
  const on = {
    'ks.screen.adaptive_brightness': true,
    'ks.screen.adaptive_min_brightness': 0.2,
    'ks.screen.adaptive_max_brightness': 0.8,
    'ks.screen.adaptive_dark_lux': 5,
    'ks.screen.adaptive_bright_lux': 500,
  };

  tearDown(() => screen.dispose());

  test('a session starting in the dark lands at Maximum brightness dimmed '
      'to Minimum, and Default brightness stands down', () async {
    await build({
      ...on,
      'ks.screen.set_brightness_on_launch': true,
      'ks.screen.default_brightness': 0.5,
    });
    expect(writes, [closeTo(0.2, 0.001)]);
    expect(await ceiling(), 0.8);
    expect(await panelLevel(), closeTo(0.2, 0.001));
    // The mirrors hear the panel; the event carries both.
    expect(published.single.level, 0.8);
    expect(published.single.panel, closeTo(0.2, 0.001));
  });

  test('the room brightening lifts the panel toward Maximum, with no '
      'setting moving, and the mirrors hear each step', () async {
    await build(on);
    published.clear();
    bus.publish(const LightLevelChanged(lux: 500));
    await settle();
    expect(writes.last, closeTo(0.8, 0.001));
    expect(published.single.panel, closeTo(0.8, 0.001));
    expect(await ceiling(), 0.8);
  });

  test('a step the eye cannot see is not written', () async {
    await build(on);
    // 5 -> 5.5 lx moves the factor by a hair.
    bus.publish(const LightLevelChanged(lux: 5.5));
    await settle();
    expect(writes, hasLength(1));
  });

  test('the screensaver sets a ceiling and reads back what it set, in any '
      'light', () async {
    await build(on);
    await commands.execute('setBrightness', {'level': 0.2, 'ceiling': true});
    await settle();
    expect(writes.last, closeTo(0.05, 0.001));
    expect(await ceiling(), 0.2);
    bus.publish(const LightLevelChanged(lux: 500));
    await settle();
    expect(writes.last, closeTo(0.2, 0.001));
    expect(await ceiling(), 0.2);
  });

  test('a panel-level write (Home Assistant) lands as asked and the curve '
      'scales it from there', () async {
    await build(on);
    await commands.execute('setBrightness', {'level': 0.3});
    await settle();
    expect(writes.last, closeTo(0.3, 0.001));
    expect(await panelLevel(), closeTo(0.3, 0.001));
    // 0.3 at the floor is a ceiling of 1.0 (clamped), so a bright room
    // lifts it all the way.
    bus.publish(const LightLevelChanged(lux: 500));
    await settle();
    expect(writes.last, closeTo(1.0, 0.001));
  });

  test('Maximum brightness moving re-anchors the ceiling at once', () async {
    await build(on);
    await settings.set(defs.adaptiveMaxBrightness, 0.4);
    await settle();
    expect(writes.last, closeTo(0.2, 0.001));
    expect(await ceiling(), 0.4);
  });

  test('turning the switch off goes back to Default brightness where it is '
      'set, else to the ceiling undimmed', () async {
    await build({
      ...on,
      'ks.screen.set_brightness_on_launch': true,
      'ks.screen.default_brightness': 0.6,
    });
    await settings.set(defs.adaptiveBrightness, false);
    await settle();
    expect(writes.last, closeTo(0.6, 0.001));

    await build(on);
    await settings.set(defs.adaptiveBrightness, false);
    await settle();
    expect(writes.last, closeTo(0.8, 0.001));
    expect(await panelLevel(), closeTo(0.8, 0.001));
  });

  test('turning it on writes Maximum brightness dimmed for the room', () async {
    await build({
      'ks.screen.adaptive_min_brightness': 0.2,
      'ks.screen.adaptive_max_brightness': 0.8,
    }, startPanel: 0.7);
    await settings.set(defs.adaptiveBrightness, true);
    await settle();
    expect(writes.last, closeTo(0.2, 0.001));
    expect(await ceiling(), 0.8);
  });

  test("the observer's echo of this app's own write is not a new ceiling; "
      'a change made elsewhere is', () async {
    await build(on, startLux: 500);
    published.clear();
    await observe(0.8);
    expect(published, isEmpty);
    // Quick settings moved the panel to 50% with the factor at 1.
    await observe(0.5);
    expect(published.single.panel, 0.5);
    expect(await ceiling(), 0.5);
    // At the floor now: the external value is undone by the factor.
    bus.publish(const LightLevelChanged(lux: 5));
    await settle();
    expect(writes.last, closeTo(0.125, 0.001));
    await observe(0.05);
    expect(await ceiling(), closeTo(0.2, 0.001));
  });

  test('without adaptive brightness ceiling and panel are one number, and '
      'Default brightness works as before', () async {
    await build({
      'ks.screen.set_brightness_on_launch': true,
      'ks.screen.default_brightness': 0.6,
    });
    expect(writes, [0.6]);
    await observe(0.3);
    expect(published.last.level, 0.3);
    expect(published.last.panel, 0.3);
    expect(await ceiling(), 0.3);
    expect(await panelLevel(), 0.3);
  });

  test('without a light sensor the switch does nothing', () async {
    await build({
      ...on,
      'ks.screen.set_brightness_on_launch': true,
      'ks.screen.default_brightness': 0.6,
    }, sensor: false);
    expect(writes, [0.6]);
    bus.publish(const LightLevelChanged(lux: 500));
    await settle();
    expect(writes, hasLength(1));
  });

  test(
    'an adaptive step right after another write waits out the gap',
    () async {
      await build(on, gap: const Duration(milliseconds: 60));
      await commands.execute('setBrightness', {'level': 0.8, 'ceiling': true});
      bus.publish(const LightLevelChanged(lux: 500));
      await settle();
      expect(writes, hasLength(2));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(writes, hasLength(3));
      expect(writes.last, closeTo(0.8, 0.001));
    },
  );
}
