import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';
import 'package:kiosk_satellite/managers/sendspin/sendspin_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Sendspin server announces nothing on connect about a queue that is
/// not playing, so after an app restart a paused Music Assistant queue is
/// invisible to the app and the "Show the Sendspin player" gesture had
/// nothing to reveal (issue #178). These cover the recovery: the reveal
/// asks Music Assistant for the player's active queue and surfaces a
/// paused card from the answer.
class _FakeApi extends MusicAssistantApi {
  _FakeApi(this.track) : super(baseUrl: 'ma.local', token: 't');

  final Map<String, Object?>? track;
  int calls = 0;

  @override
  Future<Map<String, Object?>?> fetchActiveQueueTrack({
    required String playerId,
  }) async {
    calls++;
    return track;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kiosk_satellite/sendspin');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late EventBus bus;
  late SendspinManager sendspin;
  late SettingsManager settings;
  late _FakeApi api;

  Future<void> build(Map<String, Object?>? track) async {
    SharedPreferences.setMockInitialValues({
      'ks.${defs.sendspinEnabled.key}': true,
      'ks.${defs.sendspinClientId.key}': 'abc123',
      'ks.${defs.sendspinMaUrl.key}': 'ma.local',
      'ks.${defs.sendspinMaToken.key}': 'token',
    });
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    sendspin = SendspinManager(bus, commands, log, settings);
    api = _FakeApi(track);
    sendspin.apiFactory = ({required baseUrl, required token}) => api;
    await sendspin.init();
    // Let the queued _start transition finish so _running is true.
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() async {
    await sendspin.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> reveal() async {
    bus.publish(const SendspinShowPlayerRequested());
    // The recovery awaits the API; two turns settle it.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('the reveal recovers a paused queue as a paused card', () async {
    await build({
      'state': 'paused',
      'title': 'First Time',
      'artist': 'Lucy Dacus',
      'album': 'Home Video',
      'durationMs': 254000,
      'positionMs': 12000,
    });
    expect(sendspin.nowPlaying.value, isNull);

    await reveal();

    final now = sendspin.nowPlaying.value;
    expect(now, isNotNull);
    expect(now!['playing'], isFalse);
    expect(now['title'], 'First Time');
    expect(now['artist'], 'Lucy Dacus');
    expect(now['positionMs'], 12000);
    // The queue's transport state is bookkeeping, not card content.
    expect(now.containsKey('state'), isFalse);
  });

  test('no queue in Music Assistant leaves nothing on screen', () async {
    await build(null);

    await reveal();

    expect(sendspin.nowPlaying.value, isNull);
    expect(api.calls, 1);
  });

  test('a playing queue is left to its own metadata', () async {
    await build({'state': 'playing', 'title': 'First Time'});

    await reveal();

    expect(sendspin.nowPlaying.value, isNull);
  });

  test('a card already on screen asks Music Assistant nothing', () async {
    await build({'state': 'paused', 'title': 'First Time'});
    await reveal();
    expect(api.calls, 1);

    await reveal();

    // The second reveal is the overlay's own business (un-dismissing);
    // no new lookup happens while a card exists.
    expect(api.calls, 1);
  });

  test('cardShown follows the override over the show_player setting', () async {
    await build({'state': 'paused', 'title': 'First Time'});
    // Nothing on screen yet: hidden whatever the setting says.
    expect(sendspin.cardShown, isFalse);

    await reveal();
    // A card with the default setting (show_player on) and no override.
    expect(sendspin.cardShown, isTrue);

    // The kiosk menu's Hide: override false wins over the setting.
    sendspin.cardOverride.value = false;
    expect(sendspin.cardShown, isFalse);

    // An explicit reveal wins over a switched-off setting (issue #257).
    await settings.set(defs.sendspinShowPlayer, false);
    sendspin.cardOverride.value = true;
    expect(sendspin.cardShown, isTrue);
    sendspin.cardOverride.value = null;
    expect(sendspin.cardShown, isFalse);
  });
}
