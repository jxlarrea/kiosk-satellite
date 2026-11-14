import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/voice_timers/voice_timer_manager.dart';
import 'package:kiosk_satellite/ui/voice_timer_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppContainer c;
  late List<String> sounds;
  Completer<CommandResult>? pendingSound;
  late List<VoiceTimerAction> actions;
  late StreamSubscription<VoiceTimerAction> subscription;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = AppContainer();
    sounds = [];
    pendingSound = null;
    actions = [];
    await c.settings.init();
    // These tests are about the pills, which are opt in.
    await c.settings.set(defs.voiceTimerPills, true);
    await c.voiceTimers.init();
    c.commands.register(
      Command(
        name: 'voiceChime',
        description: '',
        handler: (_) async {
          if (pendingSound != null) return pendingSound!.future;
          sounds.add('play');
          return CommandResult.ok({'id': 'sound${sounds.length}'});
        },
      ),
    );
    c.commands.register(
      Command(
        name: 'voiceSpeak',
        description: '',
        handler: (p) async {
          sounds.add('speak:${p['url']}');
          return CommandResult.ok({'id': 'sound${sounds.length}'});
        },
      ),
    );
    c.commands.register(
      Command(
        name: 'voiceStopSpeech',
        description: '',
        handler: (p) async {
          sounds.add('stop:${p['id']}');
          return const CommandResult.ok();
        },
      ),
    );
    subscription = c.bus.on<VoiceTimerAction>().listen(actions.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await c.voiceTimers.dispose();
    await c.settings.dispose();
    await c.bus.dispose();
  });

  Map<String, Object?> timer(String id, {bool active = true, String? name}) => {
    'id': id,
    'name': name ?? 'Pasta $id',
    'totalSeconds': 125,
    'startedAt': DateTime.now().millisecondsSinceEpoch,
    'isActive': active,
  };
  Future<CommandResult> snapshot(List<Object?> timers) => c.commands.execute(
    'setVoiceTimers',
    {'entityId': 'assist_satellite.kitchen', 'timers': timers},
  );
  Future<CommandResult> alert(
    List<Object?> timers, {
    bool muted = false,
    bool hidden = false,
    String? speech,
  }) => c.commands.execute('setVoiceTimerAlert', {
    'entityId': 'assist_satellite.kitchen',
    'timers': timers,
    'muted': muted,
    'hidden': hidden,
    'speech': ?speech,
  });
  Widget app({Locale? locale}) => MaterialApp(
    locale: locale,
    localizationsDelegates: UiStrings.localizationsDelegates,
    supportedLocales: UiStrings.supportedLocales,
    home: Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF222D3D))),
          Positioned.fill(child: VoiceTimerOverlay(container: c)),
        ],
      ),
    ),
  );

  test('countdown uses elapsed time and preserves paused time', () {
    final start = DateTime.fromMillisecondsSinceEpoch(100000);
    final running = VoiceTimer.parse({...timer('one'), 'startedAt': 100000})!;
    final paused = VoiceTimer.parse({
      ...timer('two', active: false),
      'startedAt': 100000,
    })!;
    expect(running.remaining(start.add(const Duration(seconds: 12))), 113);
    expect(paused.remaining(start.add(const Duration(hours: 1))), 125);
    expect(running.remaining(start.subtract(const Duration(seconds: 12))), 125);
    expect(running.remaining(start.add(const Duration(hours: 1))), 0);
    expect(voiceTimerTime(3661), '1:01:01');
  });

  test(
    'rejects malformed snapshots without losing the previous timers',
    () async {
      expect((await snapshot([timer('one'), timer('two')])).ok, true);
      expect((await snapshot([timer('one'), timer('one')])).ok, false);
      expect(
        (await snapshot([
          {'id': 'bad'},
        ])).ok,
        false,
      );
      expect(c.voiceTimers.timers.value.length, 2);
      c.bus.publish(const VoiceTimersCleared());
      await Future<void>.delayed(Duration.zero);
      expect(c.voiceTimers.timers.value, isEmpty);
    },
  );

  testWidgets(
    'single tap pauses, paused tap resumes and double tap only cancels',
    (tester) async {
      await snapshot([timer('one'), timer('two', active: false)]);
      await tester.pumpWidget(app());
      final first = find.byKey(const ValueKey('voice-timer-one'));
      final second = find.byKey(const ValueKey('voice-timer-two'));
      await tester.tap(first);
      await tester.pump(const Duration(milliseconds: 350));
      expect(actions.map((e) => e.action), ['pause']);
      await tester.tap(second);
      await tester.pump(const Duration(milliseconds: 350));
      expect(actions.last.action, 'resume');
      actions.clear();
      await tester.tap(first);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(first);
      await tester.pump(const Duration(milliseconds: 350));
      expect(actions.map((e) => e.action), ['cancel']);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'drag saves position without a timer action and survives remount',
    (tester) async {
      await snapshot([timer('one')]);
      await tester.pumpWidget(app());
      final pill = find.byKey(const ValueKey('voice-timer-one'));
      await tester.drag(pill, const Offset(150, 170));
      await tester.pump(const Duration(milliseconds: 350));
      expect(actions, isEmpty);
      expect(c.settings.get(defs.voiceTimerPosition), isNot('0.5,0.08'));
      final position = tester.getTopLeft(pill);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      expect((tester.getTopLeft(pill) - position).distance, lessThan(.1));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('many named timers stay accessible on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await snapshot([
      for (var i = 0; i < 12; i++)
        timer('$i', name: 'A very long timer name $i'),
    ]);
    await tester.pumpWidget(app());
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('local alert repeats, honors mute and stops on dismissal', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await alert([timer('done')]);
    await tester.pump();
    expect(sounds, ['play']);
    expect(find.text('Timer finished'), findsOneWidget);
    c.bus.publish(const SoundEnded(id: 'sound1'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(sounds.where((s) => s == 'play').length, 2);
    await alert([timer('done')], muted: true);
    await tester.pump(const Duration(seconds: 3));
    expect(sounds.where((s) => s == 'play').length, 2);
    await alert([timer('done')]);
    await tester.pump();
    expect(sounds.where((s) => s == 'play').length, 3);
    await tester.tap(find.byKey(const ValueKey('voice-timer-done')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(actions.last.action, 'dismiss');
    expect(c.voiceTimers.alerts.value, isEmpty);
    expect(sounds.last, startsWith('stop:'));
    await tester.pump(const Duration(seconds: 6));
    expect(sounds.where((s) => s == 'play').length, 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a hidden alert rings without a pill', (tester) async {
    await tester.pumpWidget(app());
    await alert([timer('done')], hidden: true);
    await tester.pump();
    expect(sounds, ['play']);
    expect(c.voiceTimers.alerts.value, hasLength(1));
    expect(find.text('Timer finished'), findsNothing);
    await alert([]);
    await tester.pump();
    expect(c.voiceTimers.alertHidden.value, isFalse);
    expect(sounds.last, 'stop:sound1');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a spoken phrase follows every second chime', (tester) async {
    await alert([timer('done')]);
    await tester.pump();
    // The phrase arrives once Home Assistant made it, mid ring.
    await alert([timer('done')], speech: 'http://ha/tts.mp3');
    for (var i = 1; i <= 5; i++) {
      c.bus.publish(SoundEnded(id: 'sound$i'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
    }
    expect(sounds, [
      'play',
      'play',
      'speak:http://ha/tts.mp3',
      'play',
      'play',
      'speak:http://ha/tts.mp3',
    ]);
    await alert([]);
    await tester.pump(const Duration(seconds: 6));
    expect(sounds.last, 'stop:sound6');
  });

  testWidgets('Spanish timer labels and controls use the imported catalog', (
    tester,
  ) async {
    await snapshot([timer('one', name: '')]);
    await tester.pumpWidget(app(locale: const Locale('es')));
    expect(find.text('Temporizador'), findsOneWidget);
    expect(
      find.byTooltip(
        'Toca para pausar. Toca dos veces para cancelar. Arrastra para mover.',
      ),
      findsOneWidget,
    );
    await alert([timer('done', name: 'Pasta')], muted: true);
    await tester.pump();
    expect(find.text('Finalizado'), findsOneWidget);
    expect(
      find.byTooltip('Toca para cerrar la alerta del temporizador.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await alert([]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dismissal during sound startup stops the late sound', (
    tester,
  ) async {
    final started = Completer<CommandResult>();
    pendingSound = started;
    await alert([timer('done')]);
    await alert([]);
    started.complete(const CommandResult.ok({'id': 'late'}));
    await tester.pump();
    expect(sounds, ['stop:late']);
  });

  testWidgets('long timer sounds do not overlap and can be dismissed', (
    tester,
  ) async {
    await alert([timer('long')]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(sounds, ['play']);
    c.bus.publish(const SoundEnded(id: 'unrelated'));
    await tester.pump(const Duration(seconds: 3));
    expect(sounds, ['play']);
    c.bus.publish(const SoundEnded(id: 'sound1'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(sounds, ['play', 'play']);
    await alert([]);
    await tester.pump(const Duration(seconds: 9));
    expect(sounds, ['play', 'play', 'stop:sound2']);
  });

  testWidgets('completion before the command response releases playback', (
    tester,
  ) async {
    final result = Completer<CommandResult>();
    pendingSound = result;
    await alert([timer('early')]);
    c.bus.publish(const SoundEnded(id: 'early'));
    await tester.pump();
    result.complete(const CommandResult.ok({'id': 'early'}));
    await tester.pump();
    pendingSound = null;
    await tester.pump(const Duration(seconds: 3));
    expect(sounds, ['play']);
    await alert([]);
  });
}
