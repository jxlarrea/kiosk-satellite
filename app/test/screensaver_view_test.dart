import 'package:flutter_test/flutter_test.dart';
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

  Future<void> build(String mode, {Map<String, Object> extra = const {}}) async {
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
      await build(
        'black',
        extra: {'ks.screensaver.website_double_tap': true},
      );
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
}
