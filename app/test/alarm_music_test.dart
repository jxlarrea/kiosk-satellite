import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/alarms/alarm_manager.dart';
import 'package:kiosk_satellite/managers/alarms/alarm_model.dart';
import 'package:kiosk_satellite/managers/music_library/library_model.dart';
import 'package:kiosk_satellite/managers/music_library/music_pick.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An alarm with music from the library rings with it through the music
/// commands, falls back to its tone when the music cannot play and stops
/// the music on Snooze and Stop. 2026-10-02 is a Friday.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kiosk_satellite/alarms');

  late SettingsManager settings;
  late AlarmManager alarms;
  var built = false;
  late List<String> native;
  late List<(String, Map<String, Object?>)> music;
  late DateTime now;
  var musicPlays = true;
  Completer<void>? hold;

  const pick = MusicPick(
    source: 'ma',
    item: LibraryItem(
      id: 'library://playlist/7',
      kind: LibraryKind.playlist,
      title: 'Sunday Morning',
      raw: {'item_id': '7'},
    ),
    shuffle: true,
    speaker: 'ma:kitchen',
    speakerName: 'Kitchen',
  );

  Future<void> build({
    Object? with_ = pick,
    bool ease = false,
    MusicPick? fallback,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (fallback != null) 'ks.alarms.music': jsonEncode(fallback.toJson()),
      'ks.alarms.list': jsonEncode([
        {
          'id': 'a',
          'time': '07:00',
          'days': [0, 1, 2, 3, 4, 5, 6],
          'on': true,
          'tone': 'builtin',
          'ease': ease,
          'music': ?(with_ is MusicPick ? with_.toJson() : with_),
        },
      ]),
    });
    native = [];
    music = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          native.add(call.method);
          return call.method == 'ring' ? true : null;
        });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    for (final name in [
      'bringToFront',
      'screenOn',
      'stopScreensaver',
      'alarmBrightness',
      'setStopWordArmed',
      'alarmTakeover',
      'holdScreensaver',
    ]) {
      commands.register(
        Command(
          name: name,
          description: 'stub',
          handler: (_) async => const CommandResult.ok(),
        ),
      );
    }
    for (final name in ['musicPickStart', 'musicPickStop']) {
      commands.register(
        Command(
          name: name,
          description: 'stub',
          handler: (p) async {
            music.add((name, p));
            final wait = hold;
            if (name == 'musicPickStart' && wait != null) {
              hold = null;
              await wait.future;
            }
            return name == 'musicPickStart' && !musicPlays
                ? const CommandResult.fail('the speaker did not start playing')
                : const CommandResult.ok();
          },
        ),
      );
    }
    alarms = AlarmManager(bus, commands, log, settings, clock: () => now);
    built = true;
    await alarms.init();
    await pumpEventQueue();
  }

  tearDown(() async {
    if (built) await alarms.dispose();
    built = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    musicPlays = true;
  });

  test('the pick survives the alarm list round trip', () {
    final alarm = Alarm.fromJson({
      'id': 'a',
      'time': '07:00',
      'music': pick.toJson(),
    })!;
    expect(alarm.music, pick);
    expect(alarm.music!.item!.raw, {'item_id': '7'});
    expect(Alarm.fromJson(alarm.toJson())!.music, pick);
    expect(Alarm.fromJson({'id': 'a', 'time': '07:00'})!.music, isNull);
    expect(
      Alarm.fromJson({
        'id': 'a',
        'time': '07:00',
        'music': {'source': 'spotify'},
      })!.music,
      isNull,
    );
  });

  test('it rings with the music on its speaker, not the tone', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build();
    expect(alarms.status.value.phase, AlarmPhase.ringing);
    final start = music.single;
    expect(start.$1, 'musicPickStart');
    expect(start.$2['owner'], 'alarm');
    expect(start.$2['repeat'], isTrue);
    expect(start.$2['volume'], 70);
    expect(start.$2['easeMs'], 0);
    expect((start.$2['pick'] as Map)['speaker'], 'ma:kitchen');
    expect(native, isNot(contains('ring')));
  });

  test('the music eases in when the alarm does', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build(ease: true);
    expect(music.single.$2['easeMs'], 30000);
  });

  test('the tone rings when the music cannot play', () async {
    musicPlays = false;
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build();
    expect(music.map((m) => m.$1), ['musicPickStart']);
    expect(native, contains('ring'));
    // Stop has no music left to stop.
    await alarms.stop();
    expect(music.map((m) => m.$1), ['musicPickStart']);
  });

  test('snooze and stop stop the music', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build();
    await alarms.snooze();
    expect(music.last.$1, 'musicPickStop');
    expect(music.last.$2['owner'], 'alarm');
    now = DateTime(2026, 10, 2, 7, 10, 6);
    await alarms.check();
    await pumpEventQueue();
    expect(music.where((m) => m.$1 == 'musicPickStart'), hasLength(2));
    await alarms.stop();
    expect(music.last.$1, 'musicPickStop');
  });

  test('switched on just after its time, it waits for the next', () async {
    now = DateTime(2026, 10, 2, 6, 0);
    await build();
    await alarms.setEnabled('a', false);
    now = DateTime(2026, 10, 2, 7, 2);
    await alarms.check();
    expect(await alarms.setEnabled('a', true), isTrue);
    await alarms.check();
    await pumpEventQueue();
    expect(alarms.status.value.phase, AlarmPhase.idle);
    expect(music, isEmpty);
    expect(alarms.status.value.next?.at, DateTime(2026, 10, 3, 7));
  });

  test('a stale start leaves the newer ring its music', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    // The first ring's start finishes only after a snooze and a second
    // ring: the snooze stops music, the late start never stops the second
    // ring's.
    final first = Completer<void>();
    hold = first;
    await build();
    await alarms.snooze();
    int stops() => music.where((m) => m.$1 == 'musicPickStop').length;
    expect(stops(), 1);
    now = DateTime(2026, 10, 2, 7, 10, 6);
    await alarms.check();
    await pumpEventQueue();
    expect(alarms.status.value.phase, AlarmPhase.ringing);
    expect(music.where((m) => m.$1 == 'musicPickStart'), hasLength(2));
    first.complete();
    await pumpEventQueue();
    expect(stops(), 1);
    expect(alarms.status.value.phase, AlarmPhase.ringing);
  });

  test('an alarm without its own music rings the default', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build(with_: null, fallback: pick.copyWith(speaker: 'ma:office'));
    expect(music.single.$1, 'musicPickStart');
    expect((music.single.$2['pick'] as Map)['speaker'], 'ma:office');
    expect(native, isNot(contains('ring')));
  });

  test('None rings the tone over the default', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build(with_: 'none', fallback: pick);
    expect(music, isEmpty);
    expect(native, contains('ring'));
  });

  test('None and the default survive the list round trip', () {
    final none = Alarm.fromJson({'id': 'a', 'time': '07:00', 'music': 'none'})!;
    expect(none.noMusic, isTrue);
    expect(none.toJson()['music'], 'none');
    expect(none.musicWith(pick), isNull);
    final follows = Alarm.fromJson({'id': 'a', 'time': '07:00'})!;
    expect(follows.toJson().containsKey('music'), isFalse);
    expect(follows.musicWith(pick), pick);
    final own = follows.copyWith(music: () => pick);
    expect(own.musicWith(null), pick);
  });

  test('an alarm without music rings its tone as before', () async {
    now = DateTime(2026, 10, 2, 7, 0, 5);
    await build(with_: null);
    expect(music, isEmpty);
    expect(native, contains('ring'));
  });

  test('a random pick and Shuffle only where it means something', () {
    const random = MusicPick(source: 'ma', random: RandomPick.tracks);
    expect(random.isRandom, isTrue);
    expect(random.canShuffle, isFalse);
    expect(MusicPick.fromJson(random.toJson()), random);
    const albums = MusicPick(
      source: 'sonos',
      random: RandomPick.albums,
      shuffle: true,
    );
    expect(albums.canShuffle, isTrue);
    expect(MusicPick.fromJson(albums.toJson())!.shuffle, isTrue);
    final track = MusicPick(
      source: 'ma',
      item: const LibraryItem(id: 't', kind: LibraryKind.track, title: 'T'),
      shuffle: true,
    );
    expect(track.toJson()['shuffle'], isFalse);
  });
}
