import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/dlna/dlna_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;
  late DlnaManager dlna;

  // The manager is never init()ed: these tests poke the transport
  // notifiers directly, the same surface the SOAP handlers drive, and
  // init would bind real sockets.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    dlna = DlnaManager(bus, commands, log, settings);
  });

  DlnaMedia media(String kind) =>
      DlnaMedia(uri: 'http://x/y', kind: kind, metadata: '');

  test('audio covers the screen while the setting is off', () {
    dlna.media.value = media('audio');
    dlna.transportState.value = 'PLAYING';
    expect(dlna.audioInBackground, isFalse);
    expect(dlna.coversScreen, isTrue);
  });

  test('audio stays off screen with the setting on', () async {
    await settings.set(defs.dlnaAudioBackground, true);
    dlna.media.value = media('audio');
    dlna.transportState.value = 'PLAYING';
    expect(dlna.audioInBackground, isTrue);
    expect(dlna.coversScreen, isFalse);
  });

  test('video and images still take the screen with the setting on',
      () async {
    await settings.set(defs.dlnaAudioBackground, true);
    for (final kind in ['video', 'image', 'auto']) {
      dlna.media.value = media(kind);
      dlna.transportState.value = 'PLAYING';
      expect(dlna.audioInBackground, isFalse, reason: kind);
      expect(dlna.coversScreen, isTrue, reason: kind);
    }
  });

  test('queued background audio shows no loading screen', () async {
    await settings.set(defs.dlnaAudioBackground, true);
    dlna.media.value = media('audio');
    dlna.transportState.value = 'STOPPED';
    dlna.pending.value = true;
    expect(dlna.coversScreen, isFalse);
  });
}
