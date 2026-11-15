import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/js_api/js_api_manager.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart';
import 'package:kiosk_satellite/managers/navigation/compass_layout.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/alarms_overlay.dart';
import 'package:kiosk_satellite/ui/calendar_overlay.dart';
import 'package:kiosk_satellite/ui/compass/compass_controller.dart';
import 'package:kiosk_satellite/ui/kiosk_drawer.dart';
import 'package:kiosk_satellite/ui/kiosk_screen.dart';
import 'package:kiosk_satellite/ui/sendspin_player_overlay.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:kiosk_satellite/ui/timers_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The view in the Compass center has no close button: closing it lands on
// the center, which opens it again (issue #1452).
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: appSupportedLocales,
    home: Scaffold(body: Stack(children: [child])),
  );

  final close = find.byTooltip('Close');

  test('the controller names the center while it is on screen', () async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    final compass = CompassController(c)..start();
    addTearDown(() async {
      compass.dispose();
      await c.settings.dispose();
      await c.bus.dispose();
      await c.log.dispose();
    });
    Future<void> set(String key, String value) async {
      await c.settings.setFromJson(key, value);
      await Future<void>.delayed(Duration.zero);
    }

    // Classic has no center.
    expect(c.compassCenter.value, '');
    await set(
      defs.navCompassLayout.key,
      jsonEncode({
        'center': {'kind': 'alarms'},
        'right': [
          {'kind': 'calendar'},
        ],
        'left': [
          {'kind': 'menu'},
        ],
      }),
    );
    expect(c.compassCenter.value, '');

    await set(defs.navStyle.key, 'compass');
    expect(c.compassCenter.value, 'alarms');
    expect(c.alarms.compassView.value, isTrue);

    // On a side the view closes to the center, so it keeps its button.
    compass.current.value = const CompassSlot(CompassArm.right);
    expect(c.calendar.compassView.value, isTrue);
    expect(c.compassCenter.value, '');
    compass.current.value = CompassSlot.center;
    expect(c.compassCenter.value, 'alarms');

    // Another center takes the place of the first.
    await set(
      defs.navCompassLayout.key,
      jsonEncode({
        'center': {'kind': 'calendar'},
        'right': [
          {'kind': 'alarms'},
        ],
      }),
    );
    expect(c.compassCenter.value, 'calendar');

    await set(defs.navStyle.key, 'classic');
    expect(c.compassCenter.value, '');
  });

  // The close button on a side goes to the center as back does: the center
  // opens before the side view closes, so nothing flashes between them.
  test('a side view closes to the center, the center first', () async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    final order = <String>[];
    void stand(String name, ValueNotifier<bool> page, bool up) {
      c.commands.register(
        Command(
          name: name,
          description: name,
          handler: (_) async {
            page.value = up;
            return const CommandResult.ok();
          },
        ),
      );
    }

    stand('openAlarms', c.alarms.visible, true);
    stand('hideAlarms', c.alarms.visible, false);
    stand('openCalendar', c.calendar.visible, true);
    stand('hideCalendar', c.calendar.visible, false);
    void watch(String name, ValueNotifier<bool> page) => page.addListener(
      () => order.add('$name ${page.value ? 'up' : 'down'}'),
    );
    watch('alarms', c.alarms.visible);
    watch('calendar', c.calendar.visible);
    final compass = CompassController(c)..start();
    addTearDown(() async {
      compass.dispose();
      await c.settings.dispose();
      await c.bus.dispose();
      await c.log.dispose();
    });
    await c.settings.setFromJson(
      defs.navCompassLayout.key,
      jsonEncode({
        'center': {'kind': 'alarms'},
        'up': [
          {'kind': 'calendar'},
        ],
        'left': [
          {'kind': 'menu'},
        ],
      }),
    );
    // Classic leaves the close to the view.
    expect(compass.closeToCenter('calendar'), isFalse);
    await c.settings.setFromJson(defs.navStyle.key, 'compass');
    await Future<void>.delayed(Duration.zero);

    const up = CompassSlot(CompassArm.up);
    await compass.show(up);
    expect(c.calendar.visible.value, isTrue);
    expect(c.alarms.visible.value, isFalse);

    // Not the view in hand, or the center itself: the view closes itself.
    expect(compass.closeToCenter('alarms'), isFalse);

    // Another page up with it is left to uncover.
    c.voiceTimers.visible.value = true;
    expect(compass.closeToCenter('calendar'), isFalse);
    c.voiceTimers.visible.value = false;

    order.clear();
    expect(compass.closeToCenter('calendar'), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(order, ['alarms up', 'calendar down']);
    expect(compass.current.value, CompassSlot.center);
    expect(compass.closeToCenter('alarms'), isFalse);
  });

  // Close overlays from Home Assistant under Compass: the floating page
  // goes and the kiosk lands on the center, which stays up.
  test('close overlays keeps the center and drops the rest', () async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    void stand(String name, ValueNotifier<bool> page, bool up) {
      c.commands.register(
        Command(
          name: name,
          description: name,
          handler: (_) async {
            page.value = up;
            return const CommandResult.ok();
          },
        ),
      );
    }

    stand('openAlarms', c.alarms.visible, true);
    stand('hideAlarms', c.alarms.visible, false);
    stand('openCalendar', c.calendar.visible, true);
    stand('hideCalendar', c.calendar.visible, false);
    var downs = 0;
    c.alarms.visible.addListener(() {
      if (!c.alarms.visible.value) downs++;
    });
    final compass = CompassController(c)..start();
    addTearDown(() async {
      compass.dispose();
      await c.settings.dispose();
      await c.bus.dispose();
      await c.log.dispose();
    });
    await c.settings.setFromJson(
      defs.navCompassLayout.key,
      jsonEncode({
        'center': {'kind': 'alarms'},
        'up': [
          {'kind': 'calendar'},
        ],
        'left': [
          {'kind': 'menu'},
        ],
      }),
    );
    expect(await c.compassCloseOverlays!(), isFalse);
    await c.settings.setFromJson(defs.navStyle.key, 'compass');
    await Future<void>.delayed(Duration.zero);
    await compass.show(const CompassSlot(CompassArm.up));
    c.browser.showLinkOverlay('https://example.com');
    expect(c.browser.overlayUrl.value, isNotNull);

    expect(await c.compassCloseOverlays!(), isTrue);
    expect(c.browser.overlayUrl.value, isNull);
    expect(compass.current.value, CompassSlot.center);
    expect(c.alarms.visible.value, isTrue);
    expect(c.calendar.visible.value, isFalse);

    // At the center already: the center never closes.
    downs = 0;
    expect(await c.compassCloseOverlays!(), isTrue);
    expect(c.alarms.visible.value, isTrue);
    expect(downs, 0);
  });

  // Classic starts on the dashboard: the views Compass held open close
  // with it, and a page the layout does not hold stays.
  test('switching to Classic closes the views of the layout', () async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    void stand(String name, ValueNotifier<bool> page, bool up) {
      c.commands.register(
        Command(
          name: name,
          description: name,
          handler: (_) async {
            page.value = up;
            return const CommandResult.ok();
          },
        ),
      );
    }

    stand('openAlarms', c.alarms.visible, true);
    stand('hideAlarms', c.alarms.visible, false);
    stand('openCalendar', c.calendar.visible, true);
    stand('hideCalendar', c.calendar.visible, false);
    stand('hideTimers', c.voiceTimers.visible, false);
    final compass = CompassController(c)..start();
    addTearDown(() async {
      compass.dispose();
      await c.settings.dispose();
      await c.bus.dispose();
      await c.log.dispose();
    });
    await c.settings.setFromJson(
      defs.navCompassLayout.key,
      jsonEncode({
        'center': {'kind': 'alarms'},
        'up': [
          {'kind': 'calendar'},
        ],
        'left': [
          {'kind': 'menu'},
        ],
      }),
    );
    await c.settings.setFromJson(defs.navStyle.key, 'compass');
    await Future<void>.delayed(Duration.zero);
    await compass.show(CompassSlot.center);
    expect(c.alarms.visible.value, isTrue);
    // Timers are not in this layout: opened by a voice timer, say.
    c.voiceTimers.visible.value = true;

    await c.settings.setFromJson(defs.navStyle.key, 'classic');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.alarms.visible.value, isFalse);
    expect(c.calendar.visible.value, isFalse);
    expect(c.voiceTimers.visible.value, isTrue);
  });

  testWidgets('the timers view drops its button at the center', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await tester.runAsync(() async {
      await c.settings.init();
      await c.voiceTimers.init();
    });
    await tester.pumpWidget(app(TimersOverlay(container: c)));
    c.voiceTimers.visible.value = true;
    await tester.pump();
    const key = ValueKey('timers-close');
    expect(find.byKey(key), findsOneWidget);

    c.compassCenter.value = 'timers';
    await tester.pump();
    expect(find.byKey(key), findsNothing);
    expect(find.text('No timers'), findsOneWidget);

    // Another view in the center leaves this one its button.
    c.compassCenter.value = 'alarms';
    await tester.pump();
    expect(find.byKey(key), findsOneWidget);
    await tester.tap(find.byKey(key));
    await tester.pump();
    expect(c.voiceTimers.visible.value, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the alarm list drops its button at the center', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await tester.runAsync(() async {
      await c.settings.init();
      await c.alarms.init();
    });
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(AlarmsOverlay(container: c)));
    c.alarms.visible.value = true;
    await tester.pump(const Duration(milliseconds: 100));
    expect(close, findsOneWidget);

    c.compassCenter.value = 'alarms';
    await tester.pump(const Duration(milliseconds: 100));
    expect(close, findsNothing);
    expect(c.alarms.visible.value, isTrue);

    c.compassCenter.value = '';
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(close);
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.alarms.visible.value, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Now Playing drops its button at the center', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    c.sendspin.nowPlaying.value = {
      'title': 'Song',
      'artist': 'Artist',
      'playing': true,
      'durationMs': 200000,
      'positionMs': 30000,
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
    };
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SendspinFullscreenView(container: c)),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.close), findsOneWidget);

    c.compassCenter.value = 'now_playing';
    await tester.pump();
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('Song'), findsOneWidget);

    c.compassCenter.value = 'calendar';
    await tester.pump();
    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the screensaver calendar keeps its button', (tester) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': '',
      'ks.ha.token': '',
    });
    final c = AppContainer();
    await c.settings.init();
    await c.calendar.init();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const snapshot = CalendarSnapshot(events: [], link: CalendarLink.live);

    // The layout's calendar, in the center.
    c.compassCenter.value = 'calendar';
    c.calendar.visible.value = true;
    await tester.pumpWidget(app(CalendarOverlay(container: c)));
    await tester.pump(const Duration(milliseconds: 50));
    c.calendar.snapshot.value = snapshot;
    await tester.pump(const Duration(milliseconds: 50));
    expect(close, findsNothing);
    c.compassCenter.value = '';
    await tester.pump(const Duration(milliseconds: 50));
    expect(close, findsOneWidget);
    c.calendar.visible.value = false;
    await tester.pump();

    // The screensaver's calendar ends the screensaver with it, whatever
    // the center is.
    await tester.pumpWidget(
      app(CalendarScreen(container: c, screensaver: true)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(close, findsOneWidget);
    c.compassCenter.value = 'calendar';
    await tester.pump(const Duration(milliseconds: 50));
    expect(close, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    // The socket closes a minute after the last screen lets go.
    await tester.pump(const Duration(seconds: 61));
  });

  // Its X ends the screensaver, and Now Playing with it. Beside Now
  // Playing as the Compass center both would only open again.
  testWidgets('the screensaver calendar beside a Now Playing center', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': '',
      'ks.ha.token': '',
      'ks.screensaver.mode': 'calendar',
      'ks.sendspin.fullscreen': true,
      'ks.sendspin.fullscreen_split': true,
    });
    final c = AppContainer();
    await c.settings.init();
    await c.calendar.init();
    c.screensaver.clock = tester.binding.clock.now;
    await c.screensaver.init();
    // The screensaver first, then the music: a session that music opened
    // would end with it.
    await c.screensaver.start();
    c.bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
    await tester.pump();
    expect(c.screensaver.activeView.value, 'calendar');
    expect(c.screensaver.nowPlayingShown, isTrue);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(CalendarScreen(container: c, screensaver: true)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    // Now Playing on a side of the layout, or in Classic: the X closes it.
    expect(close, findsOneWidget);

    c.compassCenter.value = 'now_playing';
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.screensaver.nowPlayingIsCenter, isTrue);
    expect(close, findsNothing);

    // The music stops: the calendar is a plain screensaver again and
    // needs its X.
    c.bus.publish(const SendspinNowPlayingChanged(active: false));
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.screensaver.isActive, isTrue);
    expect(c.screensaver.nowPlayingIsCenter, isFalse);
    expect(close, findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await c.screensaver.dispose();
    // The socket closes a minute after the last screen lets go.
    await tester.pump(const Duration(seconds: 61));
  });

  // Back stops a screensaver, and Now Playing is one. As the center it
  // would open again, so back opens the Menu, as on any other center.
  testWidgets('back on a Now Playing center opens the Menu', (tester) async {
    const backgroundChannel = MethodChannel('kiosk_satellite/background');
    const lockChannel = MethodChannel('kiosk_satellite/kiosk_lock');
    SharedPreferences.setMockInitialValues({
      'ks.nav.style': 'compass',
      'ks.nav.compass_layout': jsonEncode({
        'center': {'kind': 'now_playing'},
        'left': [
          {'kind': 'menu'},
        ],
      }),
      'ks.screensaver.mode': 'clock',
      'ks.sendspin.fullscreen': true,
    });
    final c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    c.jsApi = JsApiManager(c.bus, c.commands, c.log, c.device.appVersion);
    final hidden = <String>[];
    c.commands.register(
      Command(
        name: 'hideNowPlaying',
        description: 'test',
        handler: (_) async {
          hidden.add('hideNowPlaying');
          return const CommandResult.ok();
        },
      ),
    );
    // Keep the real screen mounted without creating a native WebView.
    final activityAttached = Completer<bool>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      backgroundChannel,
      (call) async =>
          call.method == 'isActivityAttached' ? activityAttached.future : null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      lockChannel,
      (_) async => null,
    );
    addTearDown(() async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        backgroundChannel,
        null,
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        lockChannel,
        null,
      );
      await c.settings.dispose();
      await c.bus.dispose();
      await c.log.dispose();
    });
    c.screensaver.clock = tester.binding.clock.now;
    await c.screensaver.init();
    c.sendspin.nowPlaying.value = {
      'title': 'Song',
      'artist': 'Artist',
      'playing': true,
      'durationMs': 200000,
      'positionMs': 30000,
    };
    c.sendspin.fullscreenActive.value = true;
    c.bus.publish(const SendspinNowPlayingChanged(active: true, playing: true));
    await tester.pump();
    await c.screensaver.start();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        navigatorObservers: [kioskRouteObserver],
        home: KioskScreen(container: c),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.compassCenter.value, 'now_playing');
    expect(c.screensaver.nowPlayingIsCenter, isTrue);
    bool menuUp() => tester
        .widgetList<KioskDrawer>(find.byType(KioskDrawer))
        .any((drawer) => drawer.tiles);
    expect(menuUp(), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(menuUp(), isTrue);
    // The Menu took Now Playing's place, the way a swipe to it does.
    expect(hidden, ['hideNowPlaying']);

    await tester.pumpWidget(const SizedBox.shrink());
    activityAttached.complete(true);
    await c.screensaver.dispose();
    // The page freeze under the Menu runs a second after it opens.
    await tester.pump(const Duration(seconds: 5));
  });
}
