import 'dart:async';

import '../../core/events.dart';
import '../../core/manager.dart';
import '../ground_control/mine.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'ha_socket.dart';
import 'voice_turns.dart';

/// Requests from the Kiosk Satellite scripts in Home Assistant (blueprints
/// in this repository): alarms, intercom calls, the calendar and music by
/// voice. A script
/// exposed to Assist works with any LLM conversation agent, in any
/// language, but never learns which satellite heard the request. So it
/// fires an event, every kiosk hears it over its own Home Assistant
/// socket, and the one being asked runs it through its feature's command
/// and answers with the result event, which the script hands back to the
/// LLM.
///
/// The kiosk being asked is the one named in the request, or else the one
/// in a voice turn right now: the tool runs while the conversation is
/// still going, so that is the kiosk that heard it. Nothing here needs an
/// ESPHome entity, so a request never restarts the ESPHome server.
class VoiceRequestsManager extends Manager {
  VoiceRequestsManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    DateTime Function()? clock,
    HaSocket? socket,
  }) : _turns = VoiceTurns(bus, clock: clock),
       _socket =
           socket ??
           HaSocket(
             baseUrl: () => _settings.get(defs.haUrl),
             token: () => _settings.get(defs.haToken),
           );

  /// Each script's event, the command that runs it and the field that
  /// names the kiosk being asked. The result goes back as the event's
  /// name with `_result` after it.
  static const routes = <String, ({String command, String kiosk})>{
    'kiosk_satellite_alarm': (command: 'alarmsVoiceRequest', kiosk: 'kiosk'),
    'kiosk_satellite_calendar': (
      command: 'calendarVoiceRequest',
      kiosk: 'kiosk',
    ),
    'kiosk_satellite_music': (
      command: 'musicLibraryVoiceRequest',
      kiosk: 'kiosk',
    ),
    // "My" list, calendar, playlist or person: who is speaking and what
    // they own, from Ground Control (kiosk_satellite_mine).
    'kiosk_satellite_mine': (command: 'groundControlMine', kiosk: 'kiosk'),
    // The kiosk named in `kiosk` is the one to call, so the one placing
    // the call goes by `caller`.
    'kiosk_satellite_intercom': (
      command: 'intercomVoiceRequest',
      kiosk: 'caller',
    ),
  };

  /// Who is speaking in this kiosk's voice turn, set by the app container
  /// from Ground Control. Each request in a voice turn carries it as
  /// `speaking`, so the calendar and music can tell what "my" means, and
  /// each answer names the person.
  Speaking? Function()? speaking;

  final SettingsManager _settings;
  final VoiceTurns _turns;
  final HaSocket _socket;

  final _subs = <StreamSubscription<Object?>>[];
  Timer? _watch;
  final _unsubscribe = <Future<void> Function()>[];
  int _subscribedOn = -1;
  bool _subscribing = false;

  /// The token's user is not an administrator. Home Assistant refuses
  /// custom events to them and logs every refusal, so nothing is asked
  /// again until the address or token changes.
  bool _notAdmin = false;

  @override
  String get name => 'voice_requests';

  @override
  Future<void> init() async {
    _turns.start();
    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        if (e.key == defs.haUrl.key || e.key == defs.haToken.key) {
          unawaited(_resubscribe());
        }
      }),
    );
    // The socket does not reconnect on its own: look again now and then.
    _watch = Timer.periodic(const Duration(seconds: 30), (_) => _follow());
    unawaited(_follow());
  }

  @override
  Future<void> dispose() async {
    _watch?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await _turns.dispose();
    await _socket.close();
  }

  /// Named in the request's [named] field, or, with no name, in a voice
  /// turn.
  bool isForMe(Object? named) {
    final asked = normalizeKioskName('${named ?? ''}');
    if (asked.isEmpty) return _turns.activeOrRecent;
    for (final own in [
      _settings.get(defs.deviceName),
      _settings.get(defs.esphomeNodeName),
    ]) {
      final name = normalizeKioskName(own);
      if (name.isNotEmpty && (name.contains(asked) || asked.contains(name))) {
        return true;
      }
    }
    return false;
  }

  bool get _configured =>
      _settings.get(defs.haUrl).trim().isNotEmpty &&
      _settings.get(defs.haToken).isNotEmpty;

  Future<void> _resubscribe() async {
    _unsubscribe.clear();
    _subscribedOn = -1;
    _notAdmin = false;
    await _socket.close();
    await _follow();
  }

  Future<void> _follow() async {
    if (_subscribing || _notAdmin || !_configured) return;
    if (_unsubscribe.isNotEmpty &&
        _socket.connected &&
        _socket.connections == _subscribedOn) {
      return;
    }
    _subscribing = true;
    try {
      // Any user may ask who it is, so this check leaves no error in the
      // Home Assistant log.
      final user = await _socket.request({'type': 'auth/current_user'});
      if (user is Map && user['is_admin'] != true) {
        _notAdmin = true;
        log.info(
          name,
          'voice alarms, calls, calendar and music need an administrator '
          'token, not listening',
        );
        await _socket.close();
        return;
      }
      _unsubscribe.clear();
      for (final event in routes.keys) {
        _unsubscribe.add(
          await _socket.subscribe({
            'type': 'subscribe_events',
            'event_type': event,
          }, (e) => unawaited(_onRequest(event, e['data']))),
        );
      }
      _subscribedOn = _socket.connections;
      log.debug(name, 'listening for voice requests');
    } catch (e) {
      _unsubscribe.clear();
      log.debug(name, 'voice requests not followed: $e');
    } finally {
      _subscribing = false;
    }
  }

  Future<void> _onRequest(String event, Object? raw) async {
    final route = routes[event];
    if (route == null || raw is! Map) return;
    final data = raw.cast<String, Object?>();
    final named = '${data[route.kiosk] ?? ''}'.trim();
    if (!isForMe(named)) return;
    // Only this kiosk's own voice turn has a speaker: a kiosk asked by
    // name while idle knows nobody.
    final who = _turns.activeOrRecent ? speaking?.call() : null;
    final r = await commands.execute(route.command, {
      ...data,
      // Picked for the conversation it is in, not by name: a call waits
      // for the answer to be spoken.
      'voiceTurn': named.isEmpty,
      'speaking': who?.toJson(),
    });
    final result = {
      ...(r.ok && r.data is Map
          ? (r.data! as Map).cast<String, Object?>()
          : <String, Object?>{'ok': false, 'error': r.error ?? 'failed'}),
      'speaking': ?who?.name,
    };
    log.info(
      name,
      '$event ${data['action'] ?? data['thing']}: '
      '${result['ok'] == true ? result['result'] ?? result['status'] : result['error']}',
    );
    try {
      await _socket.request({
        'type': 'fire_event',
        'event_type': '${event}_result',
        'event_data': {'id': data['id'], ...result},
      });
    } catch (e) {
      log.warn(name, 'could not answer the $event request: $e');
    }
  }
}

/// A kiosk's name as a request compares it: lower case, letters and
/// digits only, so "the kids' room" finds "Kids Room" in any script.
String normalizeKioskName(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');
