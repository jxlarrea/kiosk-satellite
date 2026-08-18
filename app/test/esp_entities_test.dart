import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/esp_entities.dart';

void main() {
  late EventBus bus;
  late CommandRegistry commands;
  late EspEntitySurface surface;
  late List<(String, Object?)> pushed;
  late List<(String, Map<String, Object?>)> executed;

  setUp(() {
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    surface = EspEntitySurface(bus, commands, log);
    pushed = [];
    executed = [];

    void stub(String name, Object? result) => commands.register(Command(
          name: name,
          description: name,
          handler: (p) async {
            executed.add((name, Map<String, Object?>.from(p)));
            return CommandResult.ok(result);
          },
        ));
    stub('getStats', {'battery': 73, 'charging': true});
    stub('getUptime', {'app': 4200, 'network': 100});
    stub('getIpAddresses', {
      'ipv4': {
        'wlan0': ['192.168.1.5']
      },
      'ipv6': {},
    });
    stub('getBrightness', 0.4);
    stub('startScreensaver', null);
    stub('stopScreensaver', null);
    stub('setBrightness', null);
    stub('reload', null);
  });

  tearDown(() => surface.detach());

  Future<void> attach() async {
    surface.attach((objectId, value) async => pushed.add((objectId, value)));
    // The initial refresh and brightness read are async fire-and-forget.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  test('descriptors carry stable object ids for every starter entity', () {
    final ids = [for (final d in surface.descriptors()) d['objectId']];
    expect(ids, [
      'screensaver',
      'screen_brightness',
      'reload',
      'battery',
      'charging',
      'uptime',
      'ip_address',
    ]);
    // Diagnostics are marked as such; controls are primary.
    final byId = {for (final d in surface.descriptors()) d['objectId']: d};
    expect(byId['battery']!['category'], 2);
    expect(byId['screensaver']!['category'], isNull);
  });

  test('attach pushes an initial snapshot from the live sources', () async {
    await attach();
    final byId = {for (final (id, value) in pushed) id: value};
    expect(byId['battery'], 73);
    expect(byId['charging'], true);
    expect(byId['uptime'], 4200);
    expect(byId['ip_address'], '192.168.1.5');
    expect(byId['screen_brightness'], 40);
    expect(byId['screensaver'], false);
  });

  test('change events stream through as state pushes', () async {
    await attach();
    pushed.clear();
    bus.publish(const ScreensaverStateChanged(active: true));
    bus.publish(const BrightnessChanged(level: 0.85));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(pushed, contains(('screensaver', true)));
    expect(pushed, contains(('screen_brightness', 85)));
  });

  test('commands map onto the same handlers MQTT uses', () async {
    await attach();
    executed.clear();
    await surface.handleCommand('screensaver', true);
    await surface.handleCommand('screensaver', false);
    await surface.handleCommand('screen_brightness', 55.0);
    await surface.handleCommand('reload', null);
    expect(executed.map((e) => e.$1).toList(),
        ['startScreensaver', 'stopScreensaver', 'setBrightness', 'reload']);
    final level =
        executed.firstWhere((e) => e.$1 == 'setBrightness').$2['level'];
    expect(level, closeTo(0.55, 1e-9));
  });

  test('detach stops event forwarding', () async {
    await attach();
    surface.detach();
    pushed.clear();
    bus.publish(const ScreensaverStateChanged(active: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(pushed, isEmpty);
  });
}
