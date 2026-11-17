import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/music_library/music_library_manager.dart';
import 'package:kiosk_satellite/managers/music_library/music_requests.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Play my playlist": the music script sends mine, and the kiosk plays
/// the playlist Ground Control has for the person speaking.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MusicRequests requests;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'ks.device.name': 'Kitchen'});
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    requests = MusicRequests(
      settings,
      MusicLibraryManager(bus, commands, log, settings),
      commands,
    );
  });

  test('nobody recognized: ask whose playlist', () async {
    final r = await requests.handle({'action': 'play', 'query': 'mine'});
    expect(r['ok'], isFalse);
    expect(r['error'], contains('nobody was recognized'));
  });

  test('a speaker without a playlist says so', () async {
    final r = await requests.handle({
      'action': 'play',
      'query': 'my playlist',
      'speaking': {'name': 'Leo', 'things': <String, String>{}},
    });
    expect(r['error'], 'Leo has no playlist');
  });
}
