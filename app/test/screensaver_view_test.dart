import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screensaver's overlay announcements (ScreensaverViewChanged): the
/// browser's rendering freeze keys off them, and Dim must read as
/// "dashboard uncovered" or the freeze blanks the screen (issue #82).
/// Registry commands (setBrightness, keepScreenAwake, ...) are absent here
/// and fail soft, which is all these tests need.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late ScreensaverManager saver;
  late List<String?> views;

  Future<void> build(
    String mode, {
    Map<String, Object> extra = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.mode': mode,
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
    views = [];
    bus.on<ScreensaverViewChanged>().listen((e) => views.add(e.view));
  }

  test('dim runs with no overlay: the dashboard stays the display', () async {
    await build('dim');
    await saver.start();
    await pumpEventQueue();
    expect(saver.activeView.value, isNull);
    expect(views, [null]);
  });

  test('black covers the dashboard and uncovers it on stop', () async {
    await build('black');
    await saver.start();
    await pumpEventQueue();
    expect(saver.activeView.value, 'black');
    expect(views, ['black']);
    await saver.stop();
    await pumpEventQueue();
    expect(saver.activeView.value, isNull);
    expect(views, ['black', null]);
  });

  test('a content mode announces its own view', () async {
    await build('clock');
    await saver.start();
    await pumpEventQueue();
    expect(views, ['clock']);
  });

  // The Immich screensaver claims both bottom corners while a pair of
  // portrait photos shares the screen, so the corner widgets there stand
  // down instead of landing on the two metadata panels.
  test('claimed corners start empty and are released on stop', () async {
    await build('immich');
    expect(saver.claimedCorners.value, isEmpty);
    await saver.start();
    saver.claimedCorners.value = const {'bottom_left', 'bottom_right'};
    await saver.stop();
    await pumpEventQueue();
    expect(saver.claimedCorners.value, isEmpty);
  });

  // The website screensaver's double-tap option (discussion #248): single
  // taps fall through to the page, only a second tap inside the window
  // dismisses. The chain lives in the manager because one physical tap
  // reports twice — the kiosk screen's raw pointer Listener and the
  // WebView's JS bridge both land in notifyActivity — and the two paths
  // must share one count.
  group('slide navigation', () {
    test('no slideshow up: the buttons are a no-op', () async {
      await build('clock');
      await saver.start();
      await pumpEventQueue();
      expect(await saver.stepSlide(1), isFalse);
      expect(await saver.stepSlide(-1), isFalse);
    });

    test('a mounted slideshow is stepped, forward and back', () async {
      await build('local');
      await saver.start();
      await pumpEventQueue();
      final steps = <int>[];
      Future<void> navigator(int direction) async => steps.add(direction);
      saver.attachSlides(navigator);
      expect(await saver.stepSlide(1), isTrue);
      expect(await saver.stepSlide(-1), isTrue);
      expect(await saver.stepSlide(0), isFalse);
      expect(steps, [1, -1]);
    });

    test('the registry commands answer whether anything stepped', () async {
      await build('local');
      // The commands register in init(), which the other cases skip.
      await saver.init();
      await saver.start();
      await pumpEventQueue();
      final commands = saver.commands;
      expect(
        (await commands.execute('nextScreensaverSlide', const {})).data,
        isFalse,
      );
      final steps = <int>[];
      saver.attachSlides((d) async => steps.add(d));
      expect(
        (await commands.execute('nextScreensaverSlide', const {})).data,
        isTrue,
      );
      expect(
        (await commands.execute('previousScreensaverSlide', const {})).data,
        isTrue,
      );
      expect(steps, [1, -1]);
    });

    test('an unmounted slideshow stands down, and stop clears it', () async {
      await build('local');
      await saver.start();
      await pumpEventQueue();
      final steps = <int>[];
      Future<void> mine(int direction) async => steps.add(direction);
      Future<void> other(int direction) async => steps.add(direction * 10);
      saver.attachSlides(mine);
      // Detaching someone else's navigator leaves the live one in place.
      saver.detachSlides(other);
      expect(await saver.stepSlide(1), isTrue);
      saver.detachSlides(mine);
      expect(await saver.stepSlide(1), isFalse);
      expect(steps, [1]);

      saver.attachSlides(mine);
      await saver.stop();
      await pumpEventQueue();
      expect(await saver.stepSlide(1), isFalse);
      // Between screensavers nothing steps even with a stale navigator.
      saver.attachSlides(mine);
      expect(await saver.stepSlide(1), isFalse);
      expect(steps, [1]);
    });
  });

  group('double tap to dismiss', () {
    var now = DateTime(2026, 8, 19, 12);

    Future<void> buildDoubleTap() async {
      await build(
        'website',
        extra: {'ks.screensaver.website_double_tap': true},
      );
      now = DateTime(2026, 8, 19, 12);
      saver.clock = () => now;
      await saver.start();
      await pumpEventQueue();
      expect(saver.activeView.value, 'website');
    }

    test('a single tap leaves the screensaver up', () async {
      await buildDoubleTap();
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.activeView.value, 'website');
    });

    test('a second tap inside the window dismisses', () async {
      await buildDoubleTap();
      saver.notifyActivity('touch');
      now = now.add(const Duration(milliseconds: 300));
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.activeView.value, isNull);
    });

    test('the JS bridge echo of a tap does not count', () async {
      // The WebView reports the same physical taps the raw Listener
      // already delivered, under its own source name; counting both
      // would turn every single tap into a double.
      await buildDoubleTap();
      saver.notifyActivity('touch');
      now = now.add(const Duration(milliseconds: 200));
      saver.notifyActivity('touch_page');
      await pumpEventQueue();
      expect(saver.activeView.value, 'website');
    });

    test('a second finger landing at once is not a second tap', () async {
      // A pinch is two pointer downs a few milliseconds apart; the
      // debounce keeps it from reading as a double tap.
      await buildDoubleTap();
      saver.notifyActivity('touch');
      now = now.add(const Duration(milliseconds: 40));
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.activeView.value, 'website');
      // The chain the first finger opened still completes normally.
      now = now.add(const Duration(milliseconds: 260));
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.activeView.value, isNull);
    });

    test('the bridge alone still dismisses when the gate is off', () async {
      await build('website');
      await saver.start();
      await pumpEventQueue();
      saver.notifyActivity('touch_page');
      await pumpEventQueue();
      expect(saver.activeView.value, isNull);
    });

    test('a slow second tap starts a new chain instead', () async {
      await buildDoubleTap();
      saver.notifyActivity('touch');
      now = now.add(const Duration(seconds: 2));
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.activeView.value, 'website');
      // ...which a prompt follow-up completes.
      now = now.add(const Duration(milliseconds: 300));
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.activeView.value, isNull);
    });

    test('motion and voice still dismiss on the first report', () async {
      await buildDoubleTap();
      saver.notifyActivity('motion');
      await pumpEventQueue();
      expect(saver.activeView.value, isNull);
    });

    test('other modes keep single-tap dismissal', () async {
      await build('black', extra: {'ks.screensaver.website_double_tap': true});
      await saver.start();
      await pumpEventQueue();
      saver.notifyActivity('touch');
      await pumpEventQueue();
      expect(saver.activeView.value, isNull);
    });

    test('the toggle lives in the Website group, off by default', () {
      // Schema-driven surfaces (device, remote, search) all render from
      // the definition, so the gating is the feature's whole visibility.
      expect(defs.screensaverWebsiteDoubleTap.defaultValue, isFalse);
      expect(defs.screensaverWebsiteDoubleTap.section, 'Website screensaver');
      expect(defs.screensaverWebsiteDoubleTap.dependsOn, 'screensaver.mode');
      expect(defs.screensaverWebsiteDoubleTap.dependsOnValue, 'website');
    });
  });

  // The Clock screensaver's Night mode (issue #391): at or below the
  // threshold the digits take the night color, and they only give it back
  // a quarter above it, so a reading hovering on the line cannot flicker
  // the face.
  group('night mode', () {
    bool active(double? lux, {bool previous = false, bool enabled = true}) =>
        clockNightActive(
          previous: previous,
          enabled: enabled,
          lux: lux,
          threshold: 5,
        );

    test('a dark room turns the color on, at or below the threshold', () {
      expect(active(2), isTrue);
      expect(active(5), isTrue);
      expect(active(5, previous: true), isTrue);
    });

    test('a lit room turns it off', () {
      expect(active(50), isFalse);
      expect(active(50, previous: true), isFalse);
    });

    test('the band just above the threshold holds the last decision', () {
      expect(active(6), isFalse);
      expect(active(6, previous: true), isTrue);
      // A quarter above the threshold always releases.
      expect(active(6.3, previous: true), isFalse);
    });

    test('disabled or sensorless never claims the dark', () {
      expect(active(2, enabled: false), isFalse);
      expect(active(null), isFalse);
      expect(active(null, previous: true), isFalse);
    });

    test('the group lives on the Clock page, gated and off by default', () {
      // Schema-driven surfaces (device, remote, search) all render from
      // the definitions; the remote's syncGatedRows needs the gate and
      // its rows in one card, so all three share the section.
      expect(defs.screensaverClockNight.defaultValue, isFalse);
      expect(defs.screensaverClockNight.dependsOn, 'screensaver.mode');
      expect(defs.screensaverClockNight.dependsOnValue, 'clock');
      for (final def in [
        defs.screensaverClockNightLux,
        defs.screensaverClockNightColor,
        defs.screensaverClockNightBgColor,
      ]) {
        expect(def.section, defs.screensaverClockNight.section);
        expect(def.subpage, defs.screensaverClockNight.subpage);
        expect(def.dependsOn, defs.screensaverClockNight.key);
      }
      // Both UIs draw a color picker off the suffix alone.
      expect(defs.screensaverClockNightColor.key, endsWith('_color'));
      expect(defs.screensaverClockNightBgColor.key, endsWith('_color'));
      expect(defs.screensaverClockNightBgColor.defaultValue, '0,0,0');
      expect(defs.screensaverClockNightLux.defaultValue, 5);
      expect(defs.screensaverClockNightLux.min, 1);
      expect(defs.screensaverClockNightLux.max, 100);
    });
  });
}
