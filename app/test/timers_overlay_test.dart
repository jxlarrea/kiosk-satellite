import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/voice_timers/voice_timer_manager.dart';
import 'package:kiosk_satellite/ui/timers_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppContainer c;
  late List<VoiceTimerAction> actions;
  late StreamSubscription<VoiceTimerAction> subscription;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = AppContainer();
    actions = [];
    await c.settings.init();
    await c.voiceTimers.init();
    for (final name in [
      'voiceChime',
      'voiceStopSpeech',
      'voiceSpeakerDone',
      'screenOn',
      'bringToFront',
    ]) {
      c.commands.register(
        Command(
          name: name,
          description: '',
          handler: (_) async => const CommandResult.ok({'id': 'sound'}),
        ),
      );
    }
    subscription = c.bus.on<VoiceTimerAction>().listen(actions.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await c.voiceTimers.dispose();
    await c.settings.dispose();
    await c.bus.dispose();
  });

  Map<String, Object?> timer(
    String id,
    int seconds, {
    bool active = true,
    String? name,
    int? duration,
  }) => {
    'id': id,
    'name': name ?? 'Timer $id',
    'totalSeconds': seconds,
    'startedAt': DateTime.now().millisecondsSinceEpoch,
    'isActive': active,
    'duration': duration ?? seconds,
  };
  Future<CommandResult> snapshot(List<Object?> timers) => c.commands.execute(
    'setVoiceTimers',
    {'entityId': 'native', 'timers': timers},
  );
  Future<CommandResult> alert(List<Object?> timers) => c.commands.execute(
    'setVoiceTimerAlert',
    {'entityId': 'native', 'timers': timers, 'muted': true},
  );
  Widget app() => MaterialApp(
    localizationsDelegates: UiStrings.localizationsDelegates,
    supportedLocales: UiStrings.supportedLocales,
    home: Scaffold(
      body: Stack(children: [TimersOverlay(container: c)]),
    ),
  );
  Future<void> size(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  String heroTime(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('timers-hero-time'))).data!;

  test('the view writes hours, minutes and seconds', () {
    expect(voiceTimerClock(0), '00:00:00');
    expect(voiceTimerClock(252), '00:04:12');
    expect(voiceTimerClock(4350), '01:12:30');
    expect(voiceTimerClock(360000), '100:00:00');
  });

  test('progress runs against the whole length, added time included', () {
    final t = VoiceTimer.parse({
      ...timer('one', 300, duration: 600),
      'startedAt': 100000,
    })!;
    final at = DateTime.fromMillisecondsSinceEpoch(100000);
    expect(t.progress(at), closeTo(.5, .001));
    expect(
      t.progress(at.add(const Duration(seconds: 150))),
      closeTo(.25, .001),
    );
    expect(t.progress(at.add(const Duration(hours: 1))), 0);
  });

  testWidgets(
    'a timer starting opens the view, the last one ending closes it',
    (tester) async {
      await tester.pumpWidget(app());
      expect(c.voiceTimers.visible.value, isFalse);
      await snapshot([timer('one', 600)]);
      await tester.pump();
      expect(c.voiceTimers.visible.value, isTrue);
      expect(find.text('TIMERS'), findsOneWidget);
      expect(heroTime(tester), '00:10:00');
      await snapshot([]);
      await tester.pump(const Duration(seconds: 3));
      expect(c.voiceTimers.visible.value, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('with the pills on the view stays shut until it is opened', (
    tester,
  ) async {
    await c.settings.set(defs.voiceTimerPills, true);
    await tester.pumpWidget(app());
    await snapshot([timer('one', 600)]);
    await tester.pump();
    expect(c.voiceTimers.visible.value, isFalse);
    await c.commands.execute('openTimers', const {});
    await tester.pump();
    expect(heroTime(tester), '00:10:00');
    // Opened by hand, it stays once the timers are gone.
    await snapshot([]);
    await tester.pump(const Duration(seconds: 3));
    expect(c.voiceTimers.visible.value, isTrue);
    expect(find.text('No timers'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timers-close')));
    await tester.pump();
    expect(c.voiceTimers.visible.value, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the timer that ends first is the large one', (tester) async {
    await size(tester, const Size(1280, 800));
    await tester.pumpWidget(app());
    await snapshot([
      timer('bread', 4350, name: 'Bread'),
      timer('pasta', 252, name: 'Pasta'),
      timer('tea', 120, active: false, name: 'Tea'),
      timer('laundry', 1665, name: 'Laundry'),
    ]);
    await tester.pump();
    expect(heroTime(tester), '00:04:12');
    // The others by when they end, the paused one last.
    final cards = tester
        .widgetList(
          find.byWidgetPredicate((w) => '${w.key}'.contains('timer-card-')),
        )
        .map((w) => '${w.key}')
        .toList();
    expect(cards, [contains('laundry'), contains('bread'), contains('tea')]);
    expect(find.text('Paused'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('timers-hero-pause')));
    await tester.tap(find.byKey(const ValueKey('timers-hero-cancel')));
    expect(actions.map((a) => '${a.id}:${a.action}'), [
      'pasta:pause',
      'pasta:cancel',
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  for (final (label, screen) in const [
    ('a tablet', Size(1280, 800)),
    ('an Echo Show 5', Size(787, 393)),
    ('a phone', Size(390, 844)),
    ('a small phone', Size(320, 568)),
  ]) {
    testWidgets('more than three timers scroll on $label', (tester) async {
      await size(tester, screen);
      await tester.pumpWidget(app());
      await snapshot([
        for (var i = 0; i < 7; i++)
          timer('$i', 300 + i * 600, name: 'A rather long timer name $i'),
      ]);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(heroTime(tester), '00:05:00');
      final list = find.byKey(const ValueKey('timers-list'));
      expect(list, findsOneWidget);
      final last = find.byKey(const ValueKey('timer-card-6'));
      expect(last, findsNothing);
      await tester.dragUntilVisible(
        last,
        list,
        screen.width >= 600 && screen.height >= 500
            ? const Offset(-200, 0)
            : const Offset(0, -120),
      );
      expect(last, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('one timer fills $label', (tester) async {
      await size(tester, screen);
      await tester.pumpWidget(app());
      await snapshot([timer('one', 4350, name: 'Bread')]);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(heroTime(tester), '01:12:30');
      expect(find.byKey(const ValueKey('timers-list')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('a finished timer takes the top with Dismiss', (tester) async {
    await size(tester, const Size(1280, 800));
    await tester.pumpWidget(app());
    await snapshot([timer('bread', 4350, name: 'Bread')]);
    await alert([timer('pasta', 0, name: 'Pasta')]);
    await tester.pump();
    expect(heroTime(tester), '00:00:00');
    expect(find.text("Time's up"), findsOneWidget);
    expect(find.byKey(const ValueKey('timers-hero-pause')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('timers-dismiss')));
    await tester.pump();
    expect(actions.single.action, 'dismiss');
    expect(c.voiceTimers.alerts.value, isEmpty);
    expect(heroTime(tester), '01:12:30');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a shared timer names the kiosk it comes from', (tester) async {
    await size(tester, const Size(1280, 800));
    await tester.pumpWidget(app());
    final shared = VoiceTimer.parse(timer('t1', 600, name: 'Laundry'))!;
    c.voiceTimers.setShared(
      'bedroom',
      name: 'Bedroom',
      timers: [shared],
      alerts: const [],
    );
    await tester.pump();
    expect(c.voiceTimers.visible.value, isTrue);
    expect(find.text('Bedroom'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('timers-hero-pause')));
    expect(actions.single.entityId, 'shared:bedroom');
    expect(actions.single.id, 't1');
    c.voiceTimers.setShared(
      'bedroom',
      name: 'Bedroom',
      timers: const [],
      alerts: const [],
    );
    await tester.pump(const Duration(seconds: 3));
    expect(c.voiceTimers.visible.value, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the digits change on the timer\'s own second', (tester) async {
    await tester.pumpWidget(app());
    // 600 s, started 400 ms ago: the next second falls in 600 ms.
    await snapshot([
      {
        ...timer('one', 600),
        'startedAt': DateTime.now().millisecondsSinceEpoch - 400,
      },
    ]);
    await tester.pump();
    expect(find.byKey(const ValueKey('timers-hero-time')), findsOneWidget);
    await snapshot([]);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
  });
}
