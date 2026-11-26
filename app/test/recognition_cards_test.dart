import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/managers/ground_control/recognition_cards.dart';
import 'package:kiosk_satellite/managers/motion/motion_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/recognition_card_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vision Match > Recognition cards: the arrival card, the action card and
/// when each shows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const faceRecognition = {
    'ks.camera.enabled': true,
    'ks.ground_control.enabled': true,
    'ks.vision_match.enabled': true,
    'ks.vision_match.face_detection': true,
    'ks.vision_match.face_recognition': true,
  };

  late EventBus bus;
  late SettingsManager settings;
  late RecognitionCards cards;

  void build(FakeAsync async, [Map<String, Object> extra = const {}]) {
    SharedPreferences.setMockInitialValues({...faceRecognition, ...extra});
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    settings.init();
    async.flushMicrotasks();
    cards = RecognitionCards(bus, commands, log, settings);
    cards.init();
    async.flushMicrotasks();
  }

  void see(FakeAsync async, List<({String id, String name})> people) {
    bus.publish(
      FaceInViewChanged(
        id: people.isEmpty ? null : people.first.id,
        name: people.isEmpty ? '' : people.first.name,
        color: people.isEmpty ? null : '#56814F',
        people: people,
        colors: {for (final p in people) p.id: '#56814F'},
      ),
    );
    async.flushMicrotasks();
  }

  void pass(FakeAsync async, Duration d) => async.elapse(d);

  const ana = (id: 'ana', name: 'Ana');
  const leo = (id: 'leo', name: 'Leo');

  test('an arrival card shows for 4 s, and again only after a minute '
      'away', () {
    fakeAsync((async) {
      build(async);
      see(async, [ana]);
      expect(cards.card.value?.name, 'Ana');
      expect(cards.card.value?.arrival, isTrue);
      expect(cards.card.value?.action, isNull);
      pass(async, const Duration(seconds: 5));
      expect(cards.card.value, isNull);

      // Away for 20 s: no card on the way back.
      see(async, []);
      pass(async, const Duration(seconds: 20));
      see(async, [ana]);
      expect(cards.card.value, isNull);

      // Away for a minute: the card shows again.
      see(async, []);
      pass(async, const Duration(seconds: 61));
      see(async, [ana]);
      expect(cards.card.value?.name, 'Ana');
    });
  });

  test('says who arrives and leaves, on the same rule, with the cards '
      'off too', () {
    fakeAsync((async) {
      build(async, {'ks.vision_match.show_arrivals': false});
      final arrived = <String>[];
      final left = <String>[];
      bus.on<FaceArrived>().listen((e) => arrived.add(e.name));
      bus.on<FaceLeft>().listen((e) => left.add(e.name));
      see(async, [ana]);
      expect(arrived, ['Ana']);
      expect(cards.card.value, isNull);
      // Out of view for 30 s and back: still here.
      see(async, []);
      pass(async, const Duration(seconds: 30));
      see(async, [ana]);
      see(async, []);
      pass(async, const Duration(seconds: 59));
      expect(left, isEmpty);
      pass(async, const Duration(seconds: 2));
      expect(left, ['Ana']);
      see(async, [ana]);
      expect(arrived, ['Ana', 'Ana']);
    });
  });

  test('someone else in view does not get a card until they are at the '
      'kiosk', () {
    fakeAsync((async) {
      build(async);
      see(async, [ana, leo]);
      expect(cards.card.value?.id, 'ana');
      pass(async, const Duration(seconds: 5));
      see(async, [leo, ana]);
      expect(cards.card.value?.id, 'leo');
    });
  });

  test('an action while the arrival card is up shows on it', () {
    fakeAsync((async) {
      build(async);
      see(async, [ana]);
      bus.publish(
        const FacePinSkipped(lockdown: false, name: 'Ana', id: 'ana'),
      );
      async.flushMicrotasks();
      final card = cards.card.value!;
      expect(card.arrival, isTrue);
      expect(card.action, FaceAction.pinSkipped);
      expect(card.color, '#56814F');
      pass(async, const Duration(seconds: 2));
      expect(cards.card.value, isNotNull);
      pass(async, const Duration(seconds: 2));
      expect(cards.card.value, isNull);
    });
  });

  test('an action on its own gets the small card', () {
    fakeAsync((async) {
      build(async);
      see(async, [ana]);
      pass(async, const Duration(seconds: 5));
      bus.publish(
        const FaceLockdownChanged(locked: false, name: 'Ana', id: 'ana'),
      );
      async.flushMicrotasks();
      expect(cards.card.value?.arrival, isFalse);
      expect(cards.card.value?.action, FaceAction.lockdownOff);
      // Lockdown Mode turned back on shows nothing.
      pass(async, const Duration(seconds: 4));
      bus.publish(const FaceLockdownChanged(locked: true));
      async.flushMicrotasks();
      expect(cards.card.value, isNull);
    });
  });

  test('a voice confirmed by a face shows the action card', () {
    fakeAsync((async) {
      build(async);
      bus.publish(
        const VoiceSpeakerChanged(
          'Leo',
          id: 'leo',
          color: '#7A5BA6',
          by: 'face',
        ),
      );
      async.flushMicrotasks();
      expect(cards.card.value?.action, FaceAction.voiceConfirmed);
      expect(cards.card.value?.color, '#7A5BA6');
      // A voice named by the voice alone shows nothing.
      pass(async, const Duration(seconds: 4));
      bus.publish(const VoiceSpeakerChanged('Leo', id: 'leo', by: 'voice'));
      async.flushMicrotasks();
      expect(cards.card.value, isNull);
    });
  });

  test('the calendar put forward for a face shows the action card', () {
    fakeAsync((async) {
      build(async, {'ks.vision_match.show_arrivals': false});
      see(async, [ana]);
      bus.publish(const FaceCalendarFocused(id: 'ana', name: 'Ana'));
      async.flushMicrotasks();
      expect(cards.card.value?.action, FaceAction.calendarFocused);
      expect(cards.card.value?.name, 'Ana');
      expect(cards.card.value?.color, '#56814F');
      pass(async, RecognitionCards.actionSpan);
      expect(cards.card.value, isNull);
    });
  });

  test('both cards can be turned off', () {
    fakeAsync((async) {
      build(async, {
        'ks.vision_match.show_arrivals': false,
        'ks.vision_match.show_actions': false,
      });
      see(async, [ana]);
      expect(cards.card.value, isNull);
      bus.publish(
        const FacePinSkipped(lockdown: false, name: 'Ana', id: 'ana'),
      );
      async.flushMicrotasks();
      expect(cards.card.value, isNull);
    });
  });

  test('without Face Recognition nothing shows', () {
    fakeAsync((async) {
      build(async, {'ks.vision_match.face_recognition': false});
      see(async, [ana]);
      expect(cards.card.value, isNull);
    });
  });

  group('the overlay', () {
    late RecognitionCards cards;
    late MotionManager motion;

    Future<void> pumpOverlay(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({...faceRecognition});
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      motion = MotionManager(bus, commands, log, settings);
      cards = RecognitionCards(bus, commands, log, settings);
      await cards.init();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: UiStrings.localizationsDelegates,
          supportedLocales: UiStrings.supportedLocales,
          home: Stack(
            children: [
              const SizedBox.expand(),
              RecognitionCardOverlay(
                cards: cards,
                motion: motion,
                settings: settings,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('draws the arrival card and the action card', (tester) async {
      await pumpOverlay(tester);
      cards.card.value = const RecognitionCard(
        id: 'ana',
        name: 'Ana',
        arrival: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Recognized'), findsOneWidget);

      cards.card.value = const RecognitionCard(
        id: 'ana',
        name: 'Ana',
        action: FaceAction.pinSkipped,
      );
      await tester.pumpAndSettle();
      expect(find.text('PIN skipped'), findsOneWidget);
      // The small card has no name, only the picture.
      expect(find.text('Ana'), findsNothing);
    });
  });
}
