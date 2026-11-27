import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/companion/companion_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice/assist_view.dart';
import 'package:kiosk_satellite/managers/voice/companion_voice.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Settings of one kiosk, in memory: the two kiosks of a test would share
/// the mocked preferences otherwise.
class _Settings extends SettingsManager {
  _Settings(super.bus, super.commands, super.log);

  final values = <String, Object?>{};

  @override
  T get<T>(defs.SettingDef<T> def) =>
      values.containsKey(def.key) ? values[def.key] as T : def.defaultValue;

  @override
  Future<void> set<T>(defs.SettingDef<T> def, T value, {String? source}) async {
    final previous = get(def);
    values[def.key] = value;
    bus.publish(SettingChanged(key: def.key, value: value, previous: previous));
  }
}

class _Voice implements CompanionVoice {
  @override
  bool nativeRuntime = true;
  bool companion = false;

  @override
  bool get companionScreen => companion;

  @override
  final ValueNotifier<AssistView> view = ValueNotifier(AssistView.hidden);
  @override
  final ValueNotifier<double> level = ValueNotifier(0);
  @override
  final ValueNotifier<double> dockCountdown = ValueNotifier(1);
  @override
  ({double elapsed, double duration})? playback;

  final shown = <AssistView>[];
  final levels = <double>[];
  int dismissed = 0;
  int held = 0;

  @override
  void Function()? companionDismiss;
  @override
  void Function({bool silence})? companionHold;

  @override
  void dismiss() {
    if (companion) {
      companionDismiss?.call();
    } else {
      dismissed++;
    }
  }

  @override
  void holdResults({bool silence = false}) {
    if (companion) {
      companionHold?.call(silence: silence);
    } else {
      held++;
    }
  }

  @override
  void showCompanion(AssistView next) => shown.add(next);

  @override
  void companionTick({
    double? level,
    double? countdown,
    ({double elapsed, double duration})? playback,
  }) {
    if (level != null) levels.add(level);
  }
}

/// A WebSocket in memory: one end of a [StreamChannelController].
class _Ws with StreamChannelMixin<dynamic> implements WebSocketChannel {
  _Ws(this._channel) : sink = _Sink(_channel.sink);

  final StreamChannel<dynamic> _channel;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  final WebSocketSink sink;

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}

class _Sink implements WebSocketSink {
  _Sink(this._sink);

  final StreamSink<dynamic> _sink;

  @override
  void add(dynamic data) => _sink.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _sink.addError(error, stackTrace);
  @override
  Future<void> addStream(Stream<dynamic> stream) => _sink.addStream(stream);
  @override
  Future<void> get done => _sink.done;
  @override
  Future<void> close([int? closeCode, String? closeReason]) => _sink.close();
}

/// One kiosk: its bus, commands, settings, voice and companion manager.
class _Kiosk {
  _Kiosk(this.id, this.name);

  final String id;
  final String name;
  final bus = EventBus();
  final log = Logger();
  late final commands = CommandRegistry(log).as('test');
  late final _Settings settings = _Settings(bus, commands, log);
  final voice = _Voice();
  late final CompanionManager companion;
  late final List<_Kiosk> network;

  Map<String, Object?> get directoryEntry => {
    'id': id,
    'name': name,
    'address': id,
    'port': 2324,
  };

  Future<void> start(
    http.Client Function() client,
    WebSocketChannel Function(Uri uri) socket,
  ) async {
    settings.values[defs.voiceRuntime.key] = 'native';
    settings.values[defs.voiceEnabled.key] = true;
    commands.register(
      Command(
        name: 'fleet',
        description: '',
        handler: (_) async => CommandResult.ok({
          'enabled': true,
          'devices': [
            for (final k in network) {...k.directoryEntry, 'self': k == this},
          ],
        }),
      ),
    );
    companion = CompanionManager(
      bus,
      commands,
      log,
      settings,
      voice,
      clientFactory: client,
      socketFactory: socket,
    );
    await companion.init();
  }

  Future<void> companionMode(bool on) async {
    voice.companion = on;
    await settings.set(defs.voiceCompanionMode, on);
  }
}

/// The routes before the password of each kiosk, the way the remote
/// manager hands them to its commands.
Future<http.Response> _route(List<_Kiosk> network, http.Request request) async {
  final kiosk = network.firstWhere((k) => k.id == request.url.host);
  final path = request.url.path.substring(1);
  Future<http.Response> json(int code, Object? body) async =>
      http.Response(jsonEncode(body), code);
  if (path == 'api/fleet/identity') {
    return json(200, {'id': kiosk.id, 'name': kiosk.name});
  }
  if (path == 'api/companion/identity') {
    final r = await kiosk.commands.execute('companionIdentity', const {});
    return json(200, r.data);
  }
  if (path == 'api/companion/invite') {
    final body = jsonDecode(request.body) as Map<String, Object?>;
    // The sender's real address, as the remote manager puts it.
    final from = network.firstWhere((k) => k.id == (body['from'] as Map)['id']);
    final r = await kiosk.commands.execute('companionInviteReceived', {
      ...body,
      'address': from.id,
    });
    return json(r.ok ? 200 : 400, r.toJson());
  }
  if (path.startsWith('api/companion/invite/')) {
    final r = await kiosk.commands.execute('companionInvitePoll', {
      'nonce': path.substring('api/companion/invite/'.length),
    });
    return json(200, r.data);
  }
  if (path == 'api/companion/leave' || path == 'api/companion/left') {
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final r = await kiosk.commands.execute(
      path.endsWith('left') ? 'companionLeft' : 'companionLeave',
      body,
    );
    return json(r.ok ? 200 : 404, r.toJson());
  }
  return json(404, {'error': 'not found'});
}

void main() {
  late _Kiosk dot;
  late _Kiosk panel;
  late List<_Kiosk> network;

  /// What a stream refusal looks like to the connecting side.
  WebSocketChannel Function(Uri uri) socketsTo(List<_Kiosk> network) => (uri) {
    final active = network.firstWhere((k) => k.id == uri.host);
    final controller = StreamChannelController<dynamic>();
    final id = uri.queryParameters['id'] ?? '';
    final verified = active.commands.execute('companionStreamVerify', {
      'id': id,
      'nonce': uri.queryParameters['nonce'] ?? '',
      'address': id,
    });
    final client = _Ws(controller.foreign);
    final ready = verified.then((r) {
      if (!r.ok) throw WebSocketChannelException('HTTP 403');
      active.commands.execute('companionAttach', {
        'id': id,
        'channel': _Ws(controller.local),
      });
    });
    return _ReadyWs(client, ready);
  };

  setUp(() async {
    dot = _Kiosk('dot', 'KS Echo Dot');
    panel = _Kiosk('panel', 'Kitchen panel');
    network = [dot, panel];
    for (final k in network) {
      k.network = network;
    }
    http.Client client() => MockClient((request) => _route(network, request));
    await dot.start(client, socketsTo(network));
    await panel.start(client, socketsTo(network));
  });

  tearDown(() async {
    await dot.companion.dispose();
    await panel.companion.dispose();
  });

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> pair() async {
    await panel.companionMode(true);
    final invited = await dot.commands.execute('companionInvite', {
      'id': 'panel',
    });
    expect(invited.ok, isTrue, reason: invited.error);
    expect(panel.companion.pendingInvite, isNotNull);
    final accepted = await panel.commands.execute('companionAccept', const {});
    expect(accepted.ok, isTrue, reason: accepted.error);
    await settle();
  }

  test('an assist view survives the wire', () {
    const view = AssistView(
      phase: AssistPhase.speaking,
      earlier: [
        AssistTurn(command: 'lights on', tools: ['Turn on'], answer: 'Done'),
      ],
      command: 'what is the weather',
      answer: 'Sunny',
      streaming: true,
      tools: ['Get weather forecast'],
      results: [
        AssistResult('weather', {'forecast': <Object>[]}),
      ],
      docked: true,
      lingering: true,
      assistant: 2,
      speaker: 'Ana',
      speakerColor: '#ff0000',
    );
    final back = AssistView.fromJson(jsonDecode(jsonEncode(view.toJson())));
    expect(back.phase, AssistPhase.speaking);
    expect(back.earlier.single.tools, ['Turn on']);
    expect(back.earlier.single.answer, 'Done');
    expect(back.command, 'what is the weather');
    expect(back.answer, 'Sunny');
    expect(back.streaming, isTrue);
    expect(back.results.single.kind, 'weather');
    expect(back.docked, isTrue);
    expect(back.lingering, isTrue);
    expect(back.assistant, 2);
    expect(back.speaker, 'Ana');
    expect(back.speakerColor, '#ff0000');
    expect(AssistView.fromJson('junk').visible, isFalse);
    expect(AssistView.fromJson({'phase': 'nope'}).visible, isFalse);
  });

  test('companion screen mode turns the satellite off', () async {
    expect(panel.settings.voiceSatelliteOn, isTrue);
    await panel.companionMode(true);
    expect(panel.settings.voiceSatelliteOn, isFalse);
    expect(panel.settings.companionScreen, isTrue);
  });

  test('a kiosk not in companion screen mode refuses the invitation', () async {
    final r = await dot.commands.execute('companionInvite', {'id': 'panel'});
    expect(r.ok, isFalse);
    expect(r.error, 'Companion screen mode is off there');
    expect(dot.companion.screens, isEmpty);
  });

  test(
    'the candidates say which kiosks are in companion screen mode',
    () async {
      await panel.companionMode(true);
      final r = await dot.commands.execute('companionCandidates', const {});
      final list = (r.data as List).cast<Map<String, Object?>>();
      expect(list.single['id'], 'panel');
      expect(list.single['companion'], isTrue);
      expect(list.single['supported'], isTrue);
    },
  );

  test('an accepted invitation streams the overlay to the companion', () async {
    await pair();
    expect(dot.companion.screens.single.status, 'accepted');
    expect(panel.companion.companionOf?['id'], 'dot');
    expect(
      panel.companion.describe()['of'],
      containsPair('state', 'connected'),
    );
    expect(dot.companion.describe()['screens'], [
      containsPair('connected', true),
    ]);

    dot.voice.view.value = const AssistView(
      phase: AssistPhase.listening,
      command: 'turn on the lights',
    );
    await settle();
    expect(panel.voice.shown.last.phase, AssistPhase.listening);
    expect(panel.voice.shown.last.command, 'turn on the lights');

    // The bar's level follows while the session is up.
    dot.voice.level.value = 0.5;
    await Future<void>.delayed(CompanionManager.tickEvery * 3);
    await settle();
    expect(panel.voice.levels, contains(0.5));

    // A dismissal on the companion screen ends the session on the Dot.
    panel.voice.dismiss();
    await settle();
    expect(dot.voice.dismissed, 1);
    panel.voice.holdResults();
    await settle();
    expect(dot.voice.held, 1);
  });

  test('a declined invitation reads declined on the active kiosk', () async {
    await panel.companionMode(true);
    await dot.commands.execute('companionInvite', {'id': 'panel'});
    await panel.commands.execute('companionDecline', const {});
    final poll = await panel.commands.execute('companionInvitePoll', {
      'nonce': dot.companion.screens.single.nonce,
    });
    expect((poll.data as Map)['status'], 'declined');
  });

  test('a stream with the wrong nonce is refused', () async {
    await pair();
    final r = await dot.commands.execute('companionStreamVerify', {
      'id': 'panel',
      'nonce': 'not the nonce',
      'address': 'panel',
    });
    expect(r.ok, isFalse);
  });

  test('removing the companion screen makes it forget the kiosk', () async {
    await pair();
    final r = await dot.commands.execute('companionRemove', {'id': 'panel'});
    expect(r.ok, isTrue);
    await settle();
    expect(dot.companion.screens, isEmpty);
    expect(panel.companion.companionOf, isNull);
    expect(panel.voice.shown.last.visible, isFalse);
  });

  test('stopping on the companion screen marks it left', () async {
    await pair();
    final r = await panel.commands.execute('companionStop', const {});
    expect(r.ok, isTrue);
    await settle();
    expect(panel.companion.companionOf, isNull);
    expect(dot.companion.screens.single.status, 'left');
  });

  test('turning companion screen mode off drops the link', () async {
    await pair();
    await panel.companionMode(false);
    await settle();
    expect(panel.companion.describe()['of'], containsPair('state', 'idle'));
    expect(dot.companion.describe()['screens'], [
      containsPair('connected', false),
    ]);
  });
}

/// A channel whose [ready] waits on the other end's verdict.
class _ReadyWs with StreamChannelMixin<dynamic> implements WebSocketChannel {
  _ReadyWs(this._inner, this.ready);

  final _Ws _inner;

  @override
  final Future<void> ready;

  @override
  Stream<dynamic> get stream => _inner.stream;
  @override
  WebSocketSink get sink => _inner.sink;
  @override
  String? get protocol => null;
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
}
