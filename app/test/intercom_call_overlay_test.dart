import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/ui/intercom_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [
    const Size(320, 480),
    const Size(360, 640),
    const Size(640, 360),
    const Size(240, 427),
    const Size(1280, 800),
  ]) {
    for (final broadcast in [false, true]) {
      testWidgets('push to talk and hangup stay reachable at $size '
          '(broadcast: $broadcast)', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final container = AppContainer();
        await container.settings.init();
        addTearDown(container.settings.dispose);
        final commands = <(String, Map<String, Object?>)>[];
        for (final name in ['intercomTalk', 'intercomHangup']) {
          container.commands.register(
            Command(
              name: name,
              description: 'Record overlay actions',
              handler: (params) async {
                commands.add((name, Map.of(params)));
                return const CommandResult.ok();
              },
            ),
          );
        }
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: IntercomCallOverlay(container: container)),
          ),
        );
        container.bus.publish(
          IntercomStateChanged({
            'state': broadcast ? 'broadcasting' : 'in_call',
            'talkMode': 'ptt',
            'micGranted': true,
            'call': {
              'kind': broadcast ? 'broadcast' : 'call',
              'outgoing': true,
              'peer': {
                'id': 'kitchen',
                'name': 'Kitchen and dining room kiosk',
              },
              'since': DateTime.now().millisecondsSinceEpoch,
              'targets': [
                for (var i = 0; i < 12; i++)
                  {
                    'name': 'Kitchen and dining room kiosk $i',
                    'status': 'listening',
                  },
              ],
            },
          }),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        final talk = find.text('Hold to talk');
        final end = find.byIcon(broadcast ? Icons.close : Icons.call_end);
        final endButton = find.ancestor(
          of: end,
          matching: find.byType(InkWell),
        );
        final screen = Offset.zero & size;
        expect(screen.contains(tester.getRect(endButton).topLeft), isTrue);
        expect(screen.contains(tester.getRect(endButton).bottomRight), isTrue);
        expect(end.hitTestable(), findsOneWidget);
        final talkButton = find.ancestor(
          of: talk,
          matching: find.byType(AnimatedContainer),
        );
        // End sits under the pill, except on a short screen where it sits
        // beside it.
        final talkRect = tester.getRect(talkButton);
        final endRect = tester.getRect(endButton);
        if (size.height < 480) {
          expect(endRect.left, greaterThan(talkRect.right));
          expect(endRect.center.dy, closeTo(talkRect.center.dy, 3));
        } else {
          expect(endRect.top, greaterThan(talkRect.bottom));
          expect((endRect.center.dx - talkRect.center.dx).abs(), lessThan(1));
        }
        final press = await tester.startGesture(tester.getCenter(talk));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(commands.last.$1, 'intercomTalk');
        expect(commands.last.$2, {'on': true});
        expect(end.hitTestable(), findsOneWidget);
        await press.up();
        await tester.pump();
        expect(commands.last.$1, 'intercomTalk');
        expect(commands.last.$2, {'on': false});
        await tester.tap(end);
        await tester.pump();
        expect(commands.last.$1, 'intercomHangup');
        expect(commands.last.$2, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  group('a call with a picture', () {
    Map<String, Object?> status({
      String state = 'in_call',
      bool camera = true,
      bool cameraReady = true,
      bool stalled = false,
    }) => {
      'state': state,
      'talkMode': 'handsfree',
      'micGranted': true,
      'cameraReady': cameraReady,
      'call': {
        'kind': 'call',
        'peer': {'name': 'Kitchen'},
        'since': DateTime.now().millisecondsSinceEpoch,
        'video': {
          'peer': true,
          'camera': camera,
          'farCamera': true,
          'farShown': true,
          'farStalled': stalled,
          'farTexture': 1,
          'selfTexture': camera ? 2 : null,
          'farWidth': 640,
          'farHeight': 480,
          'selfWidth': 480,
          'selfHeight': 640,
        },
      },
    };

    Future<AppContainer> show(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final container = AppContainer();
      await container.settings.init();
      addTearDown(container.settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IntercomCallOverlay(container: container)),
        ),
      );
      return container;
    }

    double detailsOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first)
        .opacity;

    testWidgets('the details leave after 3 seconds and come back on a tap', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(IntercomStateChanged(status(state: 'calling')));
      await tester.pump();
      container.bus.publish(IntercomStateChanged(status()));
      await tester.pump();
      expect(detailsOpacity(tester), 1);
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      expect(detailsOpacity(tester), 0);
      expect(find.text('End'), findsOneWidget);
      expect(find.byType(Texture), findsNWidgets(2));
      await tester.tapAt(const Offset(640, 300));
      await tester.pump();
      expect(detailsOpacity(tester), 1);
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      expect(detailsOpacity(tester), 0);
      await tester.pumpWidget(const SizedBox());
    });

    double controlsOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text('End'),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    testWidgets('the controls leave with the details', (tester) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(IntercomStateChanged(status()));
      await tester.pump();
      expect(controlsOpacity(tester), 1);
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      expect(controlsOpacity(tester), 0);
      await tester.tapAt(const Offset(640, 300));
      await tester.pump();
      expect(controlsOpacity(tester), 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a tap on a hidden End only brings the controls back', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      final hangups = <String>[];
      container.commands.register(
        Command(
          name: 'intercomHangup',
          description: 'stub',
          handler: (_) async {
            hangups.add('end');
            return const CommandResult.ok();
          },
        ),
      );
      container.bus.publish(IntercomStateChanged(status()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      final end = tester.getCenter(find.byIcon(Icons.call_end));
      await tester.tapAt(end);
      await tester.pump();
      expect(hangups, isEmpty);
      expect(controlsOpacity(tester), 1);
      await tester.tapAt(end);
      await tester.pump();
      expect(hangups, ['end']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('holding to talk keeps the controls up', (tester) async {
      final container = await show(tester, const Size(1280, 800));
      container.commands.register(
        Command(
          name: 'intercomTalk',
          description: 'stub',
          handler: (_) async => const CommandResult.ok(),
        ),
      );
      container.bus.publish(
        IntercomStateChanged(status()..['talkMode'] = 'ptt'),
      );
      await tester.pump();
      final hold = await tester.startGesture(
        tester.getCenter(find.text('Hold to talk')),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(controlsOpacity(tester), 1);
      await hold.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      expect(controlsOpacity(tester), 0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ringing and calling keep the controls up', (tester) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(
        IntercomStateChanged(status(state: 'ringing', camera: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      final decline = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Decline'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(decline.opacity, 1);
      await tester.pumpWidget(const SizedBox());
    });

    for (final brightness in Brightness.values) {
      testWidgets('the picture sits on black in $brightness', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final container = AppContainer();
        await container.settings.init();
        addTearDown(container.settings.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(body: IntercomCallOverlay(container: container)),
          ),
        );
        container.bus.publish(IntercomStateChanged(status()));
        await tester.pump();
        final ground = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(IntercomCallOverlay),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final box = ground.decoration as BoxDecoration;
        expect(box.color, Colors.black);
        expect(box.gradient, isNull);
        final behind = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.byType(Texture).first,
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(behind.color, Colors.black);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('placing a call shows this kiosk, even if a picture arrives', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(IntercomStateChanged(status(state: 'calling')));
      await tester.pump();
      final textures = tester
          .widgetList<Texture>(find.byType(Texture))
          .map((t) => t.textureId);
      expect(textures, [2]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the self view keeps the shape of a tall picture', (
      tester,
    ) async {
      final container = await show(tester, const Size(390, 844));
      container.bus.publish(IntercomStateChanged(status()));
      await tester.pump();
      final self = find.byWidgetPredicate(
        (w) => w is Texture && w.textureId == 2,
      );
      expect(tester.getSize(self).aspectRatio, closeTo(480 / 640, 0.01));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ringing keeps the name up and offers both answers', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(
        IntercomStateChanged(status(state: 'ringing', camera: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      expect(detailsOpacity(tester), 1);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Voice only'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    Map<String, Object?> switchable() => status()..['canSwitchCamera'] = true;

    testWidgets('Switch camera comes and goes with the details', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      final taps = <String>[];
      container.commands.register(
        Command(
          name: 'intercomSwitchCamera',
          description: 'stub',
          handler: (_) async {
            taps.add('switch');
            return const CommandResult.ok();
          },
        ),
      );
      container.bus.publish(IntercomStateChanged(switchable()));
      await tester.pump();
      final button = find.text('Switch camera');
      expect(button, findsOneWidget);
      final name = tester.getRect(find.text('Kitchen'));
      expect(tester.getRect(button).top, greaterThan(name.bottom));
      await tester.tap(button);
      await tester.pump();
      expect(taps, ['switch']);
      await tester.pump(const Duration(seconds: 4));
      expect(detailsOpacity(tester), 0);
      // Hidden, a tap on the same spot only brings the details back.
      await tester.tapAt(tester.getCenter(button));
      await tester.pump();
      expect(taps, ['switch']);
      expect(detailsOpacity(tester), 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Switch camera needs two cameras and the camera on', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(IntercomStateChanged(status()));
      await tester.pump();
      expect(find.text('Switch camera'), findsNothing);
      container.bus.publish(
        IntercomStateChanged(status(camera: false)..['canSwitchCamera'] = true),
      );
      await tester.pump();
      expect(find.text('Switch camera'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    for (final size in const [
      Size(640, 360),
      Size(787, 393),
      Size(844, 390),
      Size(390, 844),
      Size(960, 480),
    ]) {
      testWidgets('Switch camera clears the controls at $size', (tester) async {
        final container = await show(tester, size);
        final s = switchable()..['talkMode'] = 'ptt';
        container.bus.publish(IntercomStateChanged(s));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final pill = tester.getRect(find.text('Switch camera'));
        final talk = tester.getRect(find.text('Hold to talk'));
        expect(pill.bottom, lessThanOrEqualTo(talk.top));
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('the countdown says when the camera will turn on', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      Map<String, Object?> counting({required bool withCamera}) {
        final s = status(state: 'ringing', camera: false);
        s['autoAnswerCamera'] = withCamera;
        (s['call'] as Map)['autoAnswerAt'] = DateTime.now()
            .add(const Duration(seconds: 3))
            .millisecondsSinceEpoch;
        return s;
      }

      container.bus.publish(IntercomStateChanged(counting(withCamera: true)));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Camera on in'), findsOneWidget);
      container.bus.publish(IntercomStateChanged(counting(withCamera: false)));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Camera on in'), findsNothing);
      expect(find.textContaining('Answers in'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a kiosk without a camera answers with one button', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(
        IntercomStateChanged(
          status(state: 'ringing', camera: false, cameraReady: false),
        ),
      );
      await tester.pump();
      expect(find.text('Answer'), findsOneWidget);
      expect(find.text('Video'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with the camera off the corner says so', (tester) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(IntercomStateChanged(status(camera: false)));
      await tester.pump();
      expect(find.text('Your camera is off'), findsOneWidget);
      expect(find.text('Camera off'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a picture that stopped says it is reconnecting', (
      tester,
    ) async {
      final container = await show(tester, const Size(1280, 800));
      container.bus.publish(IntercomStateChanged(status(stalled: true)));
      await tester.pump();
      expect(find.text('Video reconnecting…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    for (final size in const [
      Size(787, 393),
      Size(960, 600),
      Size(390, 844),
      Size(844, 390),
    ]) {
      testWidgets('the controls fit at $size', (tester) async {
        final container = await show(tester, size);
        container.bus.publish(IntercomStateChanged(status()));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final end = tester.getRect(find.text('End'));
        expect(end.bottom, lessThanOrEqualTo(size.height));
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
