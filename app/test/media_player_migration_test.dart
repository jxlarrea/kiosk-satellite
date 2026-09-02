import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Player to control pick from before the Media Player page: a Music
/// Assistant player id under sendspin.ma_player. It carries over into the
/// one pick key with its source, so an update never drops a followed
/// player.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsManager> boot(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final log = Logger();
    final settings = SettingsManager(EventBus(), CommandRegistry(log), log);
    await settings.init();
    return settings;
  }

  test(
    'a Music Assistant pick under the old key becomes the new pick',
    () async {
      final settings = await boot({
        'ks.sendspin.ma_player': 'up0fe23db0',
        'ks.sendspin.ma_player_name': 'Sonos Office',
      });
      expect(settings.get(defs.sendspinPlayer), 'ma:up0fe23db0');
      expect(settings.get(defs.sendspinPlayerName), 'Sonos Office');
      expect(settings.get(defs.sendspinPlayerSource), 'ma');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('ks.sendspin.ma_player'), isFalse);
      expect(prefs.containsKey('ks.sendspin.ma_player_name'), isFalse);
    },
  );

  test('an empty old pick leaves this device as the source', () async {
    final settings = await boot({'ks.sendspin.ma_player': ''});
    expect(settings.get(defs.sendspinPlayer), '');
    expect(settings.get(defs.sendspinPlayerSource), '');
  });

  test('a pick stored before the source existed names its source', () async {
    final settings = await boot({
      'ks.sendspin.player': 'ha:media_player.office_sonos_office',
    });
    expect(settings.get(defs.sendspinPlayerSource), 'ha');
    final sonos = await boot({'ks.sendspin.player': 'sonos:RINCON_1'});
    expect(sonos.get(defs.sendspinPlayerSource), 'sonos');
  });

  test('an existing source is left alone', () async {
    final settings = await boot({
      'ks.sendspin.player': 'ma:abc',
      'ks.sendspin.player_source': 'ma',
    });
    expect(settings.get(defs.sendspinPlayerSource), 'ma');
    expect(settings.get(defs.sendspinPlayer), 'ma:abc');
  });
}
