import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An announcement from Home Assistant over the screensaver (issue #1441).
///
/// The ESPHome announce action used to dismiss the screensaver like an
/// intercom call, audio only or not, and a start asked for while it played
/// was refused. The screensaver now stays up: an audio only announcement
/// changes nothing on screen, and one with a card lights the screensaver
/// enough to read it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late SettingsManager settings;
  late ScreensaverManager saver;
  late List<double> levels;

  Future<void> build([Map<String, Object> extra = const {}]) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.enabled': true,
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.timeout_seconds': 60,
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    final applied = <double>[];
    levels = applied;
    commands
      ..register(
        Command(
          name: 'setBrightness',
          description: 'recorder',
          handler: (p) async {
            applied.add((p['level']! as num).toDouble());
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'getBrightness',
          description: 'recorder',
          handler: (_) async => const CommandResult.ok(0.8),
        ),
      );
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
  }

  Future<void> hold(bool active, String reason) async {
    bus.publish(
      VoiceInteractionChanged(
        active: active,
        reason: reason,
        source: InteractionSource.command,
      ),
    );
    await pumpEventQueue();
  }

  /// The intercom's status while an announcement plays ([state] listening)
  /// or is over (idle).
  Map<String, Object?> status(String state, {bool audioOnly = false}) => {
    'state': state,
    'call': state == 'idle'
        ? null
        : {'automated': true, 'outgoing': false, 'audioOnly': audioOnly},
  };

  test('an announcement leaves the screensaver up', () async {
    await build();
    await saver.start();
    await hold(true, VoiceInteractionChanged.announcementReason);
    expect(saver.isActive, isTrue);
    expect(saver.activeView.value, 'clock');
    await hold(false, VoiceInteractionChanged.announcementReason);
    expect(saver.isActive, isTrue);
    await saver.dispose();
  });

  test('the screensaver starts while an announcement plays', () async {
    await build();
    saver.notifyActivity('touch');
    final due = saver.idleDue;
    expect(due, isNotNull);
    await hold(true, VoiceInteractionChanged.announcementReason);
    expect(saver.idleDue, due, reason: 'the idle clock runs on');
    await saver.start();
    expect(saver.isActive, isTrue);
    await saver.dispose();
  });

  test('an intercom call still dismisses the screensaver', () async {
    await build();
    await saver.start();
    await hold(true, 'intercom');
    expect(saver.isActive, isFalse);
    await saver.start();
    expect(saver.isActive, isFalse, reason: 'refused during the call');
    await saver.dispose();
  });

  test('the card lifts a dimmed screensaver until it goes', () async {
    await build({
      'ks.screensaver.brightness_enabled': true,
      'ks.screensaver.brightness_level': 0.05,
    });
    await saver.start();
    expect(levels, [0.05]);

    bus.publish(IntercomStateChanged(status('listening')));
    await pumpEventQueue();
    expect(levels.last, 0.8, reason: 'the level the session saved');
    expect(saver.activeView.value, 'clock');

    // The card stays through its last words.
    bus.publish(IntercomStateChanged(status('ended')));
    await pumpEventQueue();
    expect(levels.last, 0.8);

    bus.publish(IntercomStateChanged(status('idle')));
    await pumpEventQueue();
    expect(levels.last, 0.05, reason: 'back to the screensaver level');
    expect(saver.isActive, isTrue);
    await saver.dispose();
  });

  test('an audio only announcement leaves the brightness alone', () async {
    await build({
      'ks.screensaver.brightness_enabled': true,
      'ks.screensaver.brightness_level': 0.05,
    });
    await saver.start();
    bus.publish(IntercomStateChanged(status('listening', audioOnly: true)));
    await pumpEventQueue();
    expect(levels, [0.05]);
    await saver.dispose();
  });

  test('the card lights a blanked screensaver, which stays', () {
    fakeAsync((async) {
      build({
        'ks.screensaver.screen_off_minutes': 1,
        'ks.screensaver.screen_off_black': true,
      });
      async.flushMicrotasks();
      saver.start();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 1));
      expect(saver.activeView.value, 'blank');

      // Audio only: the screen stays dark.
      bus.publish(IntercomStateChanged(status('listening', audioOnly: true)));
      async.flushMicrotasks();
      expect(saver.activeView.value, 'blank');
      bus.publish(IntercomStateChanged(status('idle')));
      async.flushMicrotasks();

      bus.publish(IntercomStateChanged(status('listening')));
      async.flushMicrotasks();
      expect(saver.isActive, isTrue);
      expect(saver.activeView.value, 'clock');
      expect(levels.last, 0.8);
      saver.dispose();
    });
  });

  test('announcementCard reads the card off the intercom status', () {
    expect(IntercomStateChanged.announcementCard(status('listening')), isTrue);
    expect(IntercomStateChanged.announcementCard(status('ended')), isTrue);
    expect(IntercomStateChanged.announcementCard(status('idle')), isFalse);
    expect(
      IntercomStateChanged.announcementCard(
        status('listening', audioOnly: true),
      ),
      isFalse,
    );
    // An intercom broadcast coming in has the call card, not this one.
    expect(
      IntercomStateChanged.announcementCard({
        'state': 'listening',
        'call': {'automated': false, 'outgoing': false},
      }),
      isFalse,
    );
  });
}
