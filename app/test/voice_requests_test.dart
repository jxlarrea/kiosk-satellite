import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/ground_control/mine.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice/ha_socket.dart';
import 'package:kiosk_satellite/managers/voice/voice_requests_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Requests from the Kiosk Satellite scripts: which kiosk answers, that
/// only an administrator token listens, and that each script's event runs
/// its feature's command and goes back as its result event.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late VoiceRequestsManager requests;
  late List<(String, Map<String, Object?>)> executed;
  VoiceRequestsManager? built;
  var now = DateTime(2026, 10, 2, 9);

  Future<void> build({
    Map<String, Object> extra = const {},
    HaSocket? socket,
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.device.name': 'Bedroom Kiosk',
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    executed = [];
    for (final name in ['alarmsVoiceRequest', 'intercomVoiceRequest']) {
      commands.register(
        Command(
          name: name,
          description: 'stub',
          handler: (p) async {
            executed.add((name, p));
            return CommandResult.ok({'ok': true, 'result': name});
          },
        ),
      );
    }
    requests = built = VoiceRequestsManager(
      bus,
      commands,
      log,
      settings,
      clock: () => now,
      socket: socket ?? _FakeSocket(admin: false),
    );
    await requests.init();
    await pumpEventQueue();
  }

  tearDown(() async {
    await built?.dispose();
    built = null;
  });

  void turn(String reason, {required bool active}) => bus.publish(
    VoiceInteractionChanged(
      active: active,
      reason: reason,
      source: InteractionSource.native,
    ),
  );

  group('who answers', () {
    test('the kiosk in a voice turn, and only while in it', () async {
      now = DateTime(2026, 10, 2, 9);
      await build();
      expect(requests.isForMe(''), isFalse);
      turn('voice', active: true);
      await pumpEventQueue();
      expect(requests.isForMe(''), isTrue);
      turn('voice', active: false);
      await pumpEventQueue();
      // A moment of grace for a runtime that reports the end first.
      expect(requests.isForMe(''), isTrue);
      now = now.add(const Duration(seconds: 10));
      expect(requests.isForMe(''), isFalse);
    });

    test('a realtime conversation answers too', () async {
      await build();
      turn('conversation', active: true);
      await pumpEventQueue();
      expect(requests.isForMe(null), isTrue);
    });

    test('a timer or an announcement is not a conversation', () async {
      await build();
      turn('timer', active: true);
      await pumpEventQueue();
      expect(requests.isForMe(''), isFalse);
    });

    test('a named kiosk answers whatever it is doing', () async {
      await build();
      expect(requests.isForMe('bedroom'), isTrue);
      expect(requests.isForMe('Bedroom Kiosk'), isTrue);
      expect(requests.isForMe('kitchen'), isFalse);
    });

    test('names in any script', () async {
      await build(extra: {'ks.device.name': 'Küche'});
      expect(requests.isForMe('küche'), isTrue);
      expect(requests.isForMe('Kinderzimmer'), isFalse);
      expect(normalizeKioskName("The Kids' Room"), 'thekidsroom');
      expect(normalizeKioskName('Спальня 2'), 'спальня2');
    });

    test('a request for another kiosk is not taken mid turn', () async {
      await build();
      bus.publish(
        const VoiceInteractionChanged(
          active: true,
          reason: 'voice',
          source: InteractionSource.page,
        ),
      );
      await pumpEventQueue();
      expect(requests.isForMe('kitchen'), isFalse);
    });
  });

  group('following requests', () {
    Future<_FakeSocket> follow({required bool admin}) async {
      final socket = _FakeSocket(admin: admin);
      await build(
        extra: {'ks.ha.url': 'http://ha.local:8123', 'ks.ha.token': 'token'},
        socket: socket,
      );
      return socket;
    }

    test('a non-admin token is never refused by Home Assistant', () async {
      final socket = await follow(admin: false);
      expect(socket.handlers, isEmpty);
      expect(socket.userChecks, 1);
    });

    test('an admin token listens for every script', () async {
      final socket = await follow(admin: true);
      expect(socket.handlers.keys, {
        'kiosk_satellite_alarm',
        'kiosk_satellite_calendar',
        'kiosk_satellite_intercom',
        'kiosk_satellite_mine',
        'kiosk_satellite_music',
      });
    });

    test('the kiosk in a voice turn runs it and answers', () async {
      final socket = await follow(admin: true);
      turn('voice', active: true);
      await pumpEventQueue();
      socket.handlers['kiosk_satellite_alarm']!({
        'data': {'id': 'r1', 'action': 'list', 'kiosk': ''},
      });
      await pumpEventQueue();
      expect(executed.single.$1, 'alarmsVoiceRequest');
      expect(executed.single.$2['voiceTurn'], isTrue);
      final fired = socket.fired.single;
      expect(fired['event_type'], 'kiosk_satellite_alarm_result');
      expect(fired['event_data'], {
        'id': 'r1',
        'ok': true,
        'result': 'alarmsVoiceRequest',
      });
    });

    test('a request in a voice turn carries who is speaking', () async {
      final socket = await follow(admin: true);
      requests.speaking = () => const Speaking(
        id: 'p1',
        name: 'Ana',
        by: 'voice',
        things: {'calendar': 'calendar.ana'},
      );
      turn('voice', active: true);
      await pumpEventQueue();
      socket.handlers['kiosk_satellite_alarm']!({
        'data': {'id': 'r1', 'action': 'list', 'kiosk': ''},
      });
      await pumpEventQueue();
      expect(executed.single.$2['speaking'], {
        'id': 'p1',
        'name': 'Ana',
        'by': 'voice',
        'things': {'calendar': 'calendar.ana'},
      });
      expect(socket.fired.single['event_data'], {
        'id': 'r1',
        'ok': true,
        'result': 'alarmsVoiceRequest',
        'speaking': 'Ana',
      });
    });

    test('outside a voice turn nobody is speaking', () async {
      final socket = await follow(admin: true);
      requests.speaking = () => const Speaking(id: 'p1', name: 'Ana');
      socket.handlers['kiosk_satellite_alarm']!({
        'data': {'id': 'r1', 'action': 'list', 'kiosk': 'Bedroom'},
      });
      await pumpEventQueue();
      expect(executed.single.$2['speaking'], isNull);
      expect(
        (socket.fired.single['event_data'] as Map).containsKey('speaking'),
        isFalse,
      );
    });

    test('a call goes by the kiosk named in caller', () async {
      final socket = await follow(admin: true);
      // Named in kiosk is the kiosk to call, never the one to answer.
      socket.handlers['kiosk_satellite_intercom']!({
        'data': {'id': 'r1', 'action': 'call', 'kiosk': 'Bedroom'},
      });
      await pumpEventQueue();
      expect(executed, isEmpty);
      expect(socket.fired, isEmpty);
      socket.handlers['kiosk_satellite_intercom']!({
        'data': {
          'id': 'r2',
          'action': 'call',
          'kiosk': 'Kitchen',
          'caller': 'Bedroom',
        },
      });
      await pumpEventQueue();
      expect(executed.single.$1, 'intercomVoiceRequest');
      expect(executed.single.$2['voiceTurn'], isFalse);
      expect(
        socket.fired.single['event_type'],
        'kiosk_satellite_intercom_result',
      );
    });
  });
}

class _FakeSocket extends HaSocket {
  _FakeSocket({required this.admin})
    : super(baseUrl: () => '', token: () => '');

  final bool admin;
  int userChecks = 0;
  final handlers = <String, void Function(Map<String, Object?>)>{};
  final fired = <Map<String, Object?>>[];

  @override
  bool get connected => true;

  @override
  Future<Object?> request(
    Map<String, Object?> command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (command['type'] == 'auth/current_user') {
      userChecks++;
      return {'id': 'u', 'is_admin': admin};
    }
    if (command['type'] == 'fire_event') fired.add(command);
    return null;
  }

  @override
  Future<Future<void> Function()> subscribe(
    Map<String, Object?> command,
    void Function(Map<String, Object?> event) onEvent, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    handlers['${command['event_type']}'] = onEvent;
    return () async {};
  }

  @override
  Future<void> close() async {}
}
