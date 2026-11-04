import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/music_library/music_library_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MusicLibraryManager> library(
    Future<Uint8List?> Function(String url)? playerArtwork,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    return MusicLibraryManager(
      bus,
      commands,
      log,
      settings,
      playerArtwork: playerArtwork,
    );
  }

  test('a cover the player holds loads through the player', () async {
    final asked = <String>[];
    final cover = Uint8List.fromList([1, 2, 3]);
    final lib = await library((url) async {
      asked.add(url);
      return cover;
    });
    for (final url in [
      'sendspin-artwork:mw2i5p27-2',
      'mediasession:com.spotify.music',
      'airplay:7',
    ]) {
      expect(await lib.loadArt(url), cover);
    }
    expect(asked, [
      'sendspin-artwork:mw2i5p27-2',
      'mediasession:com.spotify.music',
      'airplay:7',
    ]);
  });

  test('without a player loader such a cover stays empty', () async {
    final lib = await library(null);
    expect(await lib.loadArt('sendspin-artwork:mw2i5p27-2'), isNull);
  });

  test('inline logos never reach the player', () async {
    var asked = false;
    final lib = await library((url) async {
      asked = true;
      return null;
    });
    final bytes = await lib.loadArt('data:image/png;base64,AAEC');
    expect(bytes, Uint8List.fromList([0, 1, 2]));
    expect(asked, isFalse);
  });
}
