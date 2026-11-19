import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/bt_proxy_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/voice/voice_manager.dart';
import 'package:kiosk_satellite/managers/wake_word/wake_word_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The vs_pause_timer family of actions: a timer picked by its id goes to
/// Home Assistant's timer intents by its name, else by each way its
/// starting duration may have been split.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The fake Home Assistant below is a real local server.
  setUpAll(() => HttpOverrides.global = null);

  test('a named timer goes by its name alone', () {
    expect(VoiceManager.timerSlots('Pasta', 600), [
      {'name': 'Pasta'},
    ]);
  });

  test('an unnamed timer tries each split of its duration', () {
    expect(VoiceManager.timerSlots('', 600), [
      {'start_minutes': 10},
      {'start_seconds': 600},
    ]);
    expect(VoiceManager.timerSlots('', 90), [
      {'start_minutes': 1, 'start_seconds': 30},
      {'start_seconds': 90},
    ]);
    expect(VoiceManager.timerSlots('', 5400), [
      {'start_hours': 1, 'start_minutes': 30},
      {'start_minutes': 90},
      {'start_seconds': 5400},
    ]);
  });

  group('controlTimer', () {
    late HttpServer server;
    late Directory support;
    late BtProxyManager esphome;
    late VoiceManager voice;
    late SettingsManager settings;
    late CommandRegistry commands;
    final requests = <Map<String, Object?>>[];

    /// What the fake Home Assistant answers an intent with: null for done,
    /// else the error it speaks.
    late String? Function(Map<String, Object?> data) answer;

    setUp(() async {
      requests.clear();
      answer = (_) => null;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final body = jsonDecode(await utf8.decodeStream(request)) as Map;
        requests.add(body.cast<String, Object?>());
        final error = answer((body['data'] as Map).cast<String, Object?>());
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'response_type': error == null ? 'action_done' : 'error',
              'speech': {
                'plain': {'speech': error ?? 'Done'},
              },
            }),
          );
        await request.response.close();
      });
      support = await Directory.systemTemp.createTemp('ks_timer_control');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => support.path,
          );
      SharedPreferences.setMockInitialValues({});
      final bus = EventBus();
      final log = Logger();
      commands = CommandRegistry(log);
      settings = SettingsManager(bus, commands, log);
      await settings.init();
      await settings.set(defs.haUrl, 'http://127.0.0.1:${server.port}');
      await settings.set(defs.haToken, 'token');
      esphome = BtProxyManager(bus, commands, log, settings);
      voice = VoiceManager(
        bus,
        commands,
        log,
        settings,
        esphome,
        WakeWordManager(bus, commands, log, settings),
      );
      await voice.init();
    });

    tearDown(() async {
      await voice.dispose();
      await server.close(force: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      await support.delete(recursive: true);
    });

    void start(
      String id, {
      String name = '',
      int total = 600,
      bool active = true,
    }) => esphome.onVoice!('timer', {
      'type': 0,
      'id': id,
      'name': name,
      'totalSeconds': total,
      'secondsLeft': total,
      'isActive': active,
    });

    test('finds a 90 second timer by the split it was asked with', () async {
      start('t1', total: 90);
      answer = (data) =>
          data['start_seconds'] == 90 && !data.containsKey('start_minutes')
          ? null
          : 'Timer not found';
      expect(await voice.controlTimer('t1', 'cancel'), isNull);
      expect(
        [for (final r in requests) r['data']],
        [
          {'start_minutes': 1, 'start_seconds': 30},
          {'start_seconds': 90},
        ],
      );
      expect(requests.last['name'], 'HassCancelTimer');
    });

    test('adds time to a named timer', () async {
      start('t1', name: 'pasta');
      expect(
        await voice.controlTimer('t1', 'add', minutes: 5, seconds: 0),
        isNull,
      );
      expect(requests.single['name'], 'HassIncreaseTimer');
      expect(requests.single['data'], {'name': 'pasta', 'minutes': 5});
    });

    test('a change needs a duration', () async {
      start('t1');
      expect(await voice.controlTimer('t1', 'remove'), isNotNull);
      expect(requests, isEmpty);
    });

    test('pausing a paused timer changes nothing', () async {
      start('t1', active: false);
      expect(await voice.controlTimer('t1', 'pause'), isNull);
      expect(requests, isEmpty);
    });

    test('an empty id picks the only timer and refuses several', () async {
      start('t1', name: 'pasta');
      expect(await voice.controlTimer('', 'pause'), isNull);
      expect(requests.single['data'], {'name': 'pasta'});
      start('t2', name: 'rice');
      expect(await voice.controlTimer('', 'pause'), contains('timer_id'));
      expect(requests, hasLength(1));
    });

    void finish(String id, {String name = ''}) => esphome.onVoice!('timer', {
      'type': 3,
      'id': id,
      'name': name,
      'totalSeconds': 600,
      'secondsLeft': 0,
      'isActive': false,
    });

    test('Enable timers off drops the timers and takes no new ones', () async {
      // Issue #1508. Until the ESPHome server restarts, Home Assistant
      // still sends events for the timers it holds.
      start('t1', name: 'pasta');
      start('t2', name: 'tea');
      finish('t2', name: 'tea');
      expect(voice.timerList(), hasLength(2));
      await settings.set(defs.timersEnabled, false);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(voice.timerList(), isEmpty);
      // The running one is cancelled in Home Assistant, which would keep
      // it. The finished one is gone from there already.
      expect([for (final r in requests) r['name']], ['HassCancelTimer']);
      expect(requests.single['data'], {'name': 'pasta'});
      requests.clear();
      start('t3', name: 'eggs');
      expect(voice.timerList(), isEmpty);
      final started = await commands.execute('voiceStartTimer', {'minutes': 5});
      expect(started.ok, isFalse);
      expect(requests, isEmpty);
    });

    test('cancelling a ringing timer silences it', () async {
      start('t1', name: 'pasta');
      finish('t1', name: 'pasta');
      expect(await voice.controlTimer('t1', 'cancel'), isNull);
      expect(voice.timerList(), isEmpty);
      expect(requests, isEmpty);
    });

    test('an empty id silences the only ringing timer', () async {
      start('t1');
      finish('t1');
      expect(await voice.controlTimer('', 'cancel'), isNull);
      expect(voice.timerList(), isEmpty);
    });

    test('silences one ringing timer and leaves the other', () async {
      start('t1', name: 'pasta');
      start('t2', name: 'rice');
      finish('t1', name: 'pasta');
      finish('t2', name: 'rice');
      expect(await voice.controlTimer('', 'cancel'), contains('timer_id'));
      expect(await voice.controlTimer('t1', 'cancel'), isNull);
      expect([for (final t in voice.timerList()) t['timer_id']], ['t2']);
    });

    test('a ringing timer only takes a cancel', () async {
      start('t1');
      finish('t1');
      expect(await voice.controlTimer('t1', 'pause'), isNotNull);
      expect(voice.timerList(), hasLength(1));
    });

    test('an empty id with no timer says so', () async {
      expect(await voice.controlTimer('', 'cancel'), contains('no timer'));
      expect(requests, isEmpty);
    });

    test('an unknown id is refused', () async {
      expect(await voice.controlTimer('nope', 'cancel'), isNotNull);
      expect(requests, isEmpty);
    });

    test('says when twins keep Home Assistant from telling', () async {
      start('t1');
      start('t2');
      answer = (_) => 'Multiple timers matched';
      expect(
        await voice.controlTimer('t1', 'cancel'),
        contains('same name or duration'),
      );
    });
  });
}
