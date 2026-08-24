import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/js_api/js_api_manager.dart';

/// The window.kioskSatellite bridge. Assistant loudness belongs to the app
/// (issue #294): Voice Satellite scales every sound it delegates by its own
/// HA media_player entity volume, which stacked under the Assistant volume
/// fader turned "everything at 100%" into near-silence. The bridge drops the
/// page's volume opinion so delegated sounds play at the Assistant volume
/// alone; the remote API keeps the explicit parameter.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommandRegistry commands;
  late JsApiManager api;
  late Map<String, Object?> seen;

  Future<void> build() async {
    final log = Logger();
    commands = CommandRegistry(log);
    api = JsApiManager(EventBus(), commands, log, '1.0.0');
    await api.init();
    seen = {};
    for (final name in ['playSound', 'setSoundVolume', 'setBrightness']) {
      commands.register(
        Command(
          name: name,
          description: 'test stub',
          handler: (p) async {
            seen = Map.of(p);
            return const CommandResult.ok(true);
          },
        ),
      );
    }
  }

  test('a page playSound loses its volume opinion, keeps the rest', () async {
    await build();
    await api.handleCall([
      'playSound',
      {'url': 'http://x/done.mp3', 'volume': 0.028, 'cache': true},
    ]);
    expect(seen, isNot(contains('volume')));
    expect(seen['url'], 'http://x/done.mp3');
    expect(seen['cache'], true);
  });

  test('a page setSoundVolume loses its volume opinion too', () async {
    await build();
    await api.handleCall([
      'setSoundVolume',
      {'id': 'snd1', 'volume': 0.028},
    ]);
    expect(seen, isNot(contains('volume')));
    expect(seen['id'], 'snd1');
  });

  test('other methods pass their params through untouched', () async {
    await build();
    await api.handleCall([
      'setBrightness',
      {'level': 0.5},
    ]);
    expect(seen['level'], 0.5);
  });

  test(
    'the command itself still honors an explicit volume (remote API)',
    () async {
      await build();
      await commands.execute('playSound', {'url': 'http://x', 'volume': 0.5});
      expect(seen['volume'], 0.5);
    },
  );
}
