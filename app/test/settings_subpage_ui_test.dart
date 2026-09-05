import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/settings_search.dart';
import 'package:kiosk_satellite/ui/subpage_icons.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The second-level settings page as the user meets it: an entry row where
/// the group used to be, a page of its own behind it, and Back returning to
/// the row. Both layouts, since they navigate differently — the narrow one
/// pushes a route, the wide one swaps the split view's right pane.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContainer container;

  Future<void> boot({String url = 'http://ha.local:8123'}) async {
    SharedPreferences.setMockInitialValues({
      // A validated connection: the settings under test only render once the
      // Home Assistant page is unlocked.
      'ks.ha.url': url,
      'ks.ha.token': 'token',
    });
    container = AppContainer();
    await container.settings.init();
    container.homeAssistant.connectionOk.value = true;
  }

  /// The Home Assistant page never goes quiet — the dashboard picker keeps a
  /// spinner up while its fetch hangs in a test — so animations are advanced
  /// by hand instead of waiting for quiescence.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  /// The Home Assistant page fires a dashboard-list request that arms a 10s
  /// timeout; let it expire, or the binding fails the test on a pending timer.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 11));
    await settle(tester);
  }

  Future<void> openHa(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await settle(tester);
    if (size.width < 720) {
      // Narrow: the hub lists the categories, and Home Assistant pushes.
      await tester.tap(find.text('Home Assistant Setup'));
      await settle(tester);
    }
  }

  /// The second-level pages the Home Assistant page opens, in the order its
  /// entry rows appear.
  const haPages = [
    'User Interface',
    'Theme',
    'Dashboard View Rotation',
    'Return to home dashboard view',
    'Hold mode',
    'Optimizations',
  ];

  /// The row title of the group that moved, and the entry row standing in
  /// for it. Both are plain text, so they are matched the same way.
  Finder entryRow() => find.widgetWithText(ListTile, 'User Interface');

  group('narrow (pushed pages)', () {
    testWidgets('the category page shows the entry row, not the group', (
      tester,
    ) async {
      await boot();
      await openHa(tester, size: const Size(500, 1400));

      // The entry row is there, hinting at what is inside.
      expect(entryRow(), findsOneWidget);
      expect(find.text(subpageHints['User Interface']!), findsOneWidget);
      // And the settings themselves have left this page.
      expect(find.text(haHaptics.title), findsNothing);
      expect(find.text(haKioskMode.title), findsNothing);
      // The connection rows the rest of the page waits behind stay put.
      expect(find.text(haUrl.title), findsOneWidget);

      await drain(tester);
    });

    testWidgets('the page title sits right after the back arrow', (
      tester,
    ) async {
      await boot();
      // The app's own theme: the spacing is a theme rule, and a phone is
      // where the default gap between the arrow and the glyph showed.
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: SettingsScreen(container: container),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Home Assistant Setup'));
      await settle(tester);
      // The category page: its glyph follows the arrow's button closely.
      final bar = find.byType(AppBar);
      final arrow = tester.getRect(
        find.descendant(of: bar, matching: find.byType(BackButton)),
      );
      final glyph = tester.getRect(
        find.descendant(of: bar, matching: find.byType(Icon)).last,
      );
      expect(glyph.left - arrow.right, lessThanOrEqualTo(8));

      await tester.tap(entryRow());
      await settle(tester);
      // And the second-level page's, the same way.
      final subArrow = tester.getRect(
        find.descendant(of: bar, matching: find.byType(BackButton)),
      );
      final subGlyph = tester.getRect(
        find.descendant(of: bar, matching: find.byType(SubpageGlyph)),
      );
      expect(subGlyph.left - subArrow.right, lessThanOrEqualTo(8));

      await drain(tester);
    });

    testWidgets('every group that moved left an entry row behind', (
      tester,
    ) async {
      await boot();
      await openHa(tester, size: const Size(500, 2400));

      for (final page in haPages) {
        expect(
          find.widgetWithText(ListTile, page),
          findsOneWidget,
          reason: page,
        );
        expect(find.text(subpageHints[page]!), findsOneWidget, reason: page);
      }
      // The headings they used to sit under are gone with them.
      expect(find.text('Haptics'), findsNothing);

      await drain(tester);
    });

    testWidgets('each entry row gets a card of its own', (tester) async {
      await boot();
      await openHa(tester, size: const Size(500, 2400));

      // The card each entry row landed in. Element identity, so two rows in
      // one card compare equal and two cards never do.
      Element cardOf(String page) => tester.element(
        find.ancestor(
          of: find.widgetWithText(ListTile, page),
          matching: find.byType(SettingsCard),
        ),
      );

      // A page entry is a destination, not a setting: no two of them share a
      // card, which would read as one group of related settings.
      final cards = [for (final page in haPages) cardOf(page)];
      expect(cards.toSet(), hasLength(cards.length));

      await drain(tester);
    });

    testWidgets('the entry row opens the page, and Back returns', (
      tester,
    ) async {
      await boot();
      await openHa(tester, size: const Size(500, 1400));

      await tester.tap(entryRow());
      await settle(tester);

      // A page of its own: its title in the bar, both groups' cards under it.
      expect(find.widgetWithText(AppBar, 'User Interface'), findsOneWidget);
      expect(find.text(haKioskMode.title), findsOneWidget);
      expect(find.text(haHaptics.title), findsOneWidget);
      expect(find.text(haTapSound.title), findsOneWidget);
      // The second group keeps its heading; the first one's would only
      // repeat the page title, so it is dropped.
      expect(find.text('Haptics'), findsOneWidget);
      expect(
        find.text('User Interface'),
        findsOneWidget,
      ); // the bar, not a heading
      // Nothing from the parent page came along.
      expect(find.text(haUrl.title), findsNothing);

      // Back, the app bar's arrow.
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(entryRow(), findsOneWidget);
      expect(find.text(haHaptics.title), findsNothing);

      await drain(tester);
    });

    testWidgets('the hand-built groups moved with their cards intact', (
      tester,
    ) async {
      // These five are not plain sectioned renders — a live dashboard list, a
      // cross-group disabled state, telemetry under a toggle — so each one is
      // opened and checked for a row only its own card draws.
      const expected = {
        'Theme': 'Match theme to time of day',
        'Dashboard View Rotation': 'Enable dashboard view rotation',
        'Return to home dashboard view': 'Return after (seconds)',
        'Hold mode': 'Show in the kiosk menu',
        'Optimizations': 'Filter dashboard updates',
      };
      await boot();
      // The return-home timeout row is gated on its own switch, so the gate
      // goes on before the page is opened looking for it.
      await container.settings.set(haReturnHomeEnabled, true);
      await openHa(tester, size: const Size(500, 2400));

      for (final entry in expected.entries) {
        await tester.tap(find.widgetWithText(ListTile, entry.key));
        await settle(tester);
        expect(
          find.widgetWithText(AppBar, entry.key),
          findsOneWidget,
          reason: entry.key,
        );
        expect(find.text(entry.value), findsOneWidget, reason: entry.key);
        if (entry.key == 'Optimizations') {
          expect(find.text(pauseDashboardCameras.title), findsOneWidget);
          expect(find.text(pauseDashboardCameras.description), findsOneWidget);
          expect(container.settings.get(pauseDashboardCameras), isTrue);
        }
        // The page title says it; a heading repeating it would say it twice.
        expect(
          find.widgetWithText(SectionHeading, entry.key),
          findsNothing,
          reason: entry.key,
        );
        await tester.tap(find.byTooltip('Back'));
        await settle(tester);
      }

      await drain(tester);
    });

    testWidgets('the system back gesture leaves the page too', (tester) async {
      await boot();
      await openHa(tester, size: const Size(500, 1400));
      await tester.tap(entryRow());
      await settle(tester);
      expect(find.text(haHaptics.title), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(entryRow(), findsOneWidget);
      expect(find.text(haHaptics.title), findsNothing);

      await drain(tester);
    });
  });

  group('Screensaver', () {
    Future<void> openScreensaver(WidgetTester tester, {String? mode}) async {
      await boot();
      if (mode != null) {
        await container.settings.set(screensaverMode, mode);
      }
      tester.view.physicalSize = const Size(500, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Screensaver').first);
      await settle(tester);
    }

    /// The row that opens a page, matched by its landing anchor rather than
    /// its text: the mode select shows the very same words as its value.
    Finder entry(String page) => find.byWidgetPredicate(
      (w) => w is SearchLandingTarget && w.id == 'sub:$page',
    );

    testWidgets('the always-on groups became pages', (tester) async {
      await openScreensaver(tester);

      for (final page in [
        'Widgets',
        'At a Glance',
        'Motion Detection',
        'Scheduled Screensavers',
      ]) {
        expect(entry(page), findsOneWidget, reason: page);
      }
      // Their rows went with them.
      expect(find.text(screensaverGlanceEnabled.title), findsNothing);
      expect(find.text(screensaverDismissOnMotion.title), findsNothing);
      // The base settings stayed put.
      expect(find.text(screensaverTimeoutSeconds.title), findsOneWidget);
      expect(find.text(screensaverMode.title), findsOneWidget);
    });

    testWidgets('a mode page appears only while that mode is picked', (
      tester,
    ) async {
      await openScreensaver(tester, mode: 'clock');
      expect(entry('Clock screensaver'), findsOneWidget);
      expect(entry('Photo Gallery screensaver'), findsNothing);
      expect(entry('Immich Media screensaver'), findsNothing);
      expect(entry('Home Assistant Media screensaver'), findsNothing);
      // Its rows are on the page, not here.
      expect(find.text(screensaverClockStyle.title), findsNothing);

      await tester.tap(entry('Clock screensaver'));
      await settle(tester);
      expect(find.widgetWithText(AppBar, 'Clock screensaver'), findsOneWidget);
      expect(find.text(screensaverClockStyle.title), findsOneWidget);
      expect(find.text(screensaverClockScale.title), findsOneWidget);
      expect(
        find.widgetWithText(SectionHeading, 'Clock screensaver'),
        findsNothing,
      );
    });

    testWidgets('the Home Assistant Media page carries its picker and fill', (
      tester,
    ) async {
      await openScreensaver(tester, mode: 'media');
      expect(entry('Home Assistant Media screensaver'), findsOneWidget);
      expect(find.text(screensaverMediaId.title), findsNothing);

      await tester.tap(entry('Home Assistant Media screensaver'));
      await settle(tester);
      expect(
        find.widgetWithText(AppBar, 'Home Assistant Media screensaver'),
        findsOneWidget,
      );
      // The Browse row is a replacement rendered for the media key; it has
      // to follow the row onto its page.
      expect(find.text(screensaverMediaId.title), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
      expect(find.text(screensaverMediaFill.title), findsOneWidget);
    });

    testWidgets('the modes the user left inline stay inline', (tester) async {
      await openScreensaver(tester, mode: 'website');
      // Website keeps its group on the page.
      expect(
        find.widgetWithText(SectionHeading, 'Website screensaver'),
        findsOneWidget,
      );
      expect(entry('Website screensaver'), findsNothing);
      expect(find.text(screensaverWebsiteUrl.title), findsOneWidget);
    });

    testWidgets('a page keeps the extras that belong to its rows', (
      tester,
    ) async {
      // The Immich validate row is rendered under the API key by the
      // category's `after` map; it has to follow the row onto its page.
      await openScreensaver(tester, mode: 'immich');
      await tester.tap(entry('Immich Media screensaver'));
      await settle(tester);

      expect(
        find.widgetWithText(AppBar, 'Immich Media screensaver'),
        findsOneWidget,
      );
      expect(find.text(screensaverImmichApiKey.title), findsOneWidget);
      expect(find.text('Validate connection'), findsOneWidget);
    });
  });

  group('Device', () {
    testWidgets('the grants sit at the bottom, below Configuration', (
      tester,
    ) async {
      await boot();
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Device').first);
      await settle(tester);

      // Remote Administration is a page now, taking the Access card with it.
      expect(
        find.widgetWithText(ListTile, 'Remote Administration'),
        findsOneWidget,
      );
      expect(find.text(remotePort.title), findsNothing);
      expect(find.widgetWithText(SectionHeading, 'Access'), findsNothing);

      final config = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Configuration'),
      );
      final perms = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Permissions Manager'),
      );
      expect(
        perms.dy,
        greaterThan(config.dy),
        reason: 'the grants are the page\'s footnote, not its middle',
      );
    });

    testWidgets('the User Interface group carries the Scale UI slider', (
      tester,
    ) async {
      await boot();
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Device').first);
      await settle(tester);

      expect(
        find.widgetWithText(SectionHeading, 'User Interface'),
        findsOneWidget,
      );
      expect(find.text('Scale UI'), findsOneWidget);
      // Above the hand-built cards that close the page.
      final ui = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'User Interface'),
      );
      final config = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Configuration'),
      );
      expect(ui.dy, lessThan(config.dy));
    });

    testWidgets('the Remote Administration page carries the Access card', (
      tester,
    ) async {
      await boot();
      await container.settings.set(remoteEnabled, true);
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Device').first);
      await settle(tester);

      await tester.tap(find.widgetWithText(ListTile, 'Remote Administration'));
      await settle(tester);

      expect(
        find.widgetWithText(AppBar, 'Remote Administration'),
        findsOneWidget,
      );
      expect(find.text(remotePort.title), findsOneWidget);
      expect(find.text(remotePassword.title), findsOneWidget);
      // Where to reach it, under the settings that decide whether it can be.
      expect(find.widgetWithText(SectionHeading, 'Access'), findsOneWidget);
      // The page title says it; the group heading would repeat it.
      expect(
        find.widgetWithText(SectionHeading, 'Remote Administration'),
        findsNothing,
      );
      // Nothing from the page above.
      expect(find.text(deviceName.title), findsNothing);
    });

    testWidgets('the Kiosk Satellite Service page shows status, reasons, '
        'its setting and its grants', (tester) async {
      await boot();
      // The native service, answering as a running one.
      const channel = MethodChannel('kiosk_satellite/background');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'serviceStatus') {
              return <String, Object?>{
                'running': true,
                'foreground': true,
                'types': ['specialUse'],
                'cpuLockHeld': false,
                'wifiLockHeld': true,
                'screenInteractive': true,
                'uptimeMs': 125000,
                'notificationsEnabled': true,
              };
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Device').first);
      await settle(tester);

      // Its entry row leads the page's rows, ahead of Remote Administration.
      final service = tester.getTopLeft(
        find.widgetWithText(ListTile, 'Kiosk Satellite Service'),
      );
      final remote = tester.getTopLeft(
        find.widgetWithText(ListTile, 'Remote Administration'),
      );
      expect(service.dy, lessThan(remote.dy));
      expect(find.text(serviceCpuAwake.title), findsNothing);

      await tester.tap(
        find.widgetWithText(ListTile, 'Kiosk Satellite Service'),
      );
      await settle(tester);

      expect(
        find.widgetWithText(AppBar, 'Kiosk Satellite Service'),
        findsOneWidget,
      );
      // Top to bottom: status, reasons, the setting, the grants.
      final status = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Status'),
      );
      final reasons = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Keeping it running'),
      );
      final options = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Options'),
      );
      final grants = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Required system permissions'),
      );
      expect(status.dy, lessThan(reasons.dy));
      expect(reasons.dy, lessThan(options.dy));
      expect(options.dy, lessThan(grants.dy));
      // The mocked service's own report, uptime included.
      expect(find.text('Running for 2m.'), findsOneWidget);
      expect(find.text('specialUse'), findsOneWidget);
      // The base reason is always listed.
      expect(find.text('Home Assistant connection'), findsOneWidget);
      expect(find.text(serviceCpuAwake.title), findsOneWidget);
      // The three grants the service needs whatever runs; no feature
      // reason is on, so no feature grant.
      expect(find.text('Unrestricted battery'), findsOneWidget);
      expect(find.text('Display over other apps'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Microphone'), findsNothing);
      // Nothing from the page above.
      expect(find.text(deviceName.title), findsNothing);

      // Back off the page so its status poll stops with it.
      await tester.pageBack();
      await settle(tester);
    });
  });

  group('Kiosk', () {
    testWidgets('the allowed actions moved, the protections stayed', (
      tester,
    ) async {
      await boot();
      await container.settings.set(kioskEnabled, true);
      await container.settings.set(kioskAllowDrawer, true);
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Kiosk Mode').first);
      await settle(tester);

      expect(find.widgetWithText(ListTile, 'Allowed Actions'), findsOneWidget);
      expect(find.text(kioskAllowDrawer.title), findsNothing);
      expect(find.text(kioskAllowCamera.title), findsNothing);
      // What kiosk mode itself is stays on the page, grants included.
      expect(find.text(kioskExitGesture.title), findsOneWidget);
      expect(find.text(kioskDisableStatusBar.title), findsOneWidget);
      expect(
        find.widgetWithText(SectionHeading, 'Required system permissions'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ListTile, 'Allowed Actions'));
      await settle(tester);

      expect(find.widgetWithText(AppBar, 'Allowed Actions'), findsOneWidget);
      expect(find.text(kioskAllowDrawer.title), findsOneWidget);
      expect(find.text(kioskAllowCamera.title), findsOneWidget);
      expect(
        find.widgetWithText(SectionHeading, 'Allowed Actions'),
        findsNothing,
      );
      expect(find.text(kioskExitGesture.title), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.widgetWithText(ListTile, 'Allowed Actions'), findsOneWidget);
    });
  });

  group('ESPHome', () {
    testWidgets('the Notifications page sits above Bluetooth Proxy', (
      tester,
    ) async {
      await boot();
      await container.settings.set(esphomeEnabled, true);
      await container.settings.set(esphomeNodeName, 'kitchen-tablet');
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('ESPHome').first);
      await settle(tester);

      // One entry row each, Notifications first.
      final notifications = find.widgetWithText(ListTile, 'Notifications');
      final proxy = find.widgetWithText(ListTile, 'Bluetooth Proxy');
      expect(notifications, findsOneWidget);
      expect(proxy, findsOneWidget);
      expect(
        tester.getTopLeft(notifications).dy,
        lessThan(tester.getTopLeft(proxy).dy),
      );
      // Its rows are on the page, not here.
      expect(find.text(notificationsChimeFile.title), findsNothing);
      expect(find.text(notificationsVolume.title), findsNothing);

      await tester.tap(notifications);
      await settle(tester);

      expect(find.widgetWithText(AppBar, 'Notifications'), findsOneWidget);
      // The intro row names this kiosk's action, with the test button,
      // above the sound and volume rows.
      expect(
        find.textContaining('esphome.kitchen_tablet_notification'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Test'), findsOneWidget);
      expect(find.text(notificationsChimeFile.title), findsOneWidget);
      expect(find.text('Built-in chime'), findsOneWidget);
      expect(find.text(notificationsVolume.title), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      final intro = tester.getTopLeft(
        find.widgetWithText(FilledButton, 'Test'),
      );
      final sound = tester.getTopLeft(find.text(notificationsChimeFile.title));
      expect(intro.dy, lessThan(sound.dy));
      // The page's own name would only repeat the title bar.
      expect(
        find.widgetWithText(SectionHeading, 'Notifications'),
        findsNothing,
      );

      await drain(tester);
    });

    testWidgets('the Person Detection page sits under Proximity Detection, '
        'with its status row and grant, where the Portal probe is unanswered', (
      tester,
    ) async {
      // No bridge answers here, which reads as "could be a Portal": the
      // page renders. A device that answered unsupported hides it
      // (deviceHiddenKeys, covered in portal_presence_test.dart).
      await boot();
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Screensaver').first);
      await settle(tester);

      final person = find.widgetWithText(ListTile, 'Person Detection');
      final proximity = find.widgetWithText(ListTile, 'Proximity Detection');
      expect(person, findsOneWidget);
      expect(
        tester.getTopLeft(person).dy,
        greaterThan(tester.getTopLeft(proximity).dy),
      );
      await tester.tap(person);
      await settle(tester);

      expect(find.widgetWithText(AppBar, 'Person Detection'), findsOneWidget);
      expect(find.text(screensaverDismissOnPerson.title), findsOneWidget);
      // The postpone switch rides the dismiss one, off by default.
      expect(find.text(screensaverPostponeOnPerson.title), findsNothing);
      // The status row under the switch, and the grant at the foot.
      expect(find.text('Occupancy'), findsOneWidget);
      final grants = find.widgetWithText(
        SectionHeading,
        'Required system permissions',
      );
      expect(grants, findsOneWidget);
      expect(find.text('Log access'), findsOneWidget);
      expect(
        tester.getTopLeft(grants).dy,
        greaterThan(
          tester.getTopLeft(find.text(screensaverDismissOnPerson.title)).dy,
        ),
      );
      // The page's own name would only repeat the title bar.
      expect(
        find.widgetWithText(SectionHeading, 'Person Detection'),
        findsNothing,
      );

      await tester.tap(find.byType(Switch).first);
      await settle(tester);
      expect(container.settings.get(screensaverDismissOnPerson), isTrue);
      expect(find.text(screensaverPostponeOnPerson.title), findsOneWidget);

      await drain(tester);
    });

    testWidgets('the GPS Sensor page sits under Bluetooth Proxy, with the '
        'grant at its foot', (tester) async {
      await boot();
      await container.settings.set(esphomeEnabled, true);
      await container.settings.set(esphomeEntities, true);
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('ESPHome').first);
      await settle(tester);

      final location = find.widgetWithText(ListTile, 'GPS Sensor');
      final proxy = find.widgetWithText(ListTile, 'Bluetooth Proxy');
      final advanced = find.widgetWithText(ListTile, 'Advanced settings');
      expect(location, findsOneWidget);
      expect(
        tester.getTopLeft(location).dy,
        greaterThan(tester.getTopLeft(proxy).dy),
      );
      expect(
        tester.getTopLeft(location).dy,
        lessThan(tester.getTopLeft(advanced).dy),
      );
      // Its rows are on the page, not here.
      expect(find.text(locationEnabled.title), findsNothing);

      await tester.tap(location);
      await settle(tester);

      expect(find.widgetWithText(AppBar, 'GPS Sensor'), findsOneWidget);
      expect(find.text(locationEnabled.title), findsOneWidget);
      // The interval rides the switch, off by default.
      expect(find.text(locationInterval.title), findsNothing);
      // The last coordinates under the switch, and the grant at the foot.
      expect(find.text('Last coordinates'), findsOneWidget);
      final grants = find.widgetWithText(
        SectionHeading,
        'Required system permissions',
      );
      expect(grants, findsOneWidget);
      expect(
        tester.getTopLeft(grants).dy,
        greaterThan(tester.getTopLeft(find.text(locationEnabled.title)).dy),
      );
      // The page's own name would only repeat the title bar.
      expect(find.widgetWithText(SectionHeading, 'GPS Sensor'), findsNothing);

      await tester.tap(find.byType(Switch).first);
      await settle(tester);
      expect(container.settings.get(locationEnabled), isTrue);
      expect(find.text(locationInterval.title), findsOneWidget);

      await drain(tester);
    });

    testWidgets('the Bluetooth half moved, the entity server stayed', (
      tester,
    ) async {
      await boot();
      await container.settings.set(esphomeEnabled, true);
      await container.settings.set(btproxyEnabled, true);
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('ESPHome').first);
      await settle(tester);

      expect(find.widgetWithText(ListTile, 'Bluetooth Proxy'), findsOneWidget);
      // Its rows went with it; the entity server's stayed.
      expect(find.text(btproxyEnabled.title), findsNothing);
      expect(find.text(btproxyMacLookup.title), findsNothing);
      expect(find.text(esphomeEntities.title), findsOneWidget);
      expect(find.text(btproxyPort.title), findsOneWidget);
      // The Bluetooth grants went with the proxy they gate.
      expect(
        find.widgetWithText(SectionHeading, 'Required system permissions'),
        findsNothing,
      );

      await tester.tap(find.widgetWithText(ListTile, 'Bluetooth Proxy'));
      await settle(tester);

      expect(find.widgetWithText(AppBar, 'Bluetooth Proxy'), findsOneWidget);
      expect(find.text(btproxyEnabled.title), findsOneWidget);
      // The nearby group keeps its heading inside the page; the page's own
      // name would only repeat the title bar.
      expect(
        find.widgetWithText(SectionHeading, 'Nearby devices'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SectionHeading, 'Bluetooth Proxy'),
        findsNothing,
      );
      // The grants sit right above the Nearby devices group, whose list
      // stays empty without them.
      final grants = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Required system permissions'),
      );
      final nearby = tester.getTopLeft(
        find.widgetWithText(SectionHeading, 'Nearby devices'),
      );
      expect(grants.dy, lessThan(nearby.dy));
      final proxy = tester.getTopLeft(find.text(btproxyEnabled.title));
      expect(grants.dy, greaterThan(proxy.dy));
      // And nothing else from the page above.
      expect(find.text(esphomeEntities.title), findsNothing);

      await drain(tester);
    });
  });

  group('Screen & Audio', () {
    Future<void> openScreenAudio(WidgetTester tester) async {
      await boot();
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Screen & Audio').first);
      await settle(tester);
    }

    testWidgets('capture tuning became a page, the mixer did not', (
      tester,
    ) async {
      await openScreenAudio(tester);

      expect(
        find.widgetWithText(ListTile, 'Microphone settings'),
        findsOneWidget,
      );
      expect(find.text(subpageHints['Microphone settings']!), findsOneWidget);
      // Its rows went with it.
      expect(find.text(micAudioSource.title), findsNothing);
      expect(find.text(micAgc.title), findsNothing);
      // The groups that stayed are still here.
      expect(
        find.widgetWithText(SectionHeading, 'Audio Volume'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SectionHeading, 'Audio Devices'),
        findsOneWidget,
      );
      expect(find.text(mediaVolume.title), findsOneWidget);
    });

    testWidgets('the page carries the rows and the group note', (tester) async {
      await openScreenAudio(tester);

      await tester.tap(find.widgetWithText(ListTile, 'Microphone settings'));
      await settle(tester);

      expect(
        find.widgetWithText(AppBar, 'Microphone settings'),
        findsOneWidget,
      );
      expect(find.text(micAudioSource.title), findsOneWidget);
      expect(find.text(micAgc.title), findsOneWidget);
      // The caveat that used to sit under the heading came along.
      expect(find.byType(GroupNote), findsOneWidget);
      // The page title says it; a heading repeating it would say it twice.
      expect(
        find.widgetWithText(SectionHeading, 'Microphone settings'),
        findsNothing,
      );
      // Nothing from the page above.
      expect(find.text(mediaVolume.title), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(
        find.widgetWithText(ListTile, 'Microphone settings'),
        findsOneWidget,
      );
      expect(find.text(micAudioSource.title), findsNothing);
    });
  });

  group('Voice Satellite (live rows, not settings)', () {
    // Its two pages are almost entirely entity rows from the integration, so
    // they render through VsControlsSection rather than the definitions.
    late HttpServer server;

    setUp(() async {
      // The Voice Satellite page is gated on the integration being installed,
      // which is an HTTP probe against Home Assistant. The test binding stubs
      // every request to 400, so this group answers it for real.
      HttpOverrides.global = null;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.statusCode =
            request.uri.path == '/voice_satellite/voice-satellite-card.js'
            ? 200
            : 404;
        request.response.close();
      });
    });

    tearDown(() async => server.close(force: true));

    Future<void> openVs(WidgetTester tester) async {
      await boot(url: 'http://127.0.0.1:${server.port}');
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(container: container)),
      );
      await settle(tester);
      await tester.tap(find.text('Voice Satellite').first);
      await settle(tester);
      // The detection probe is real I/O, so give it turns of the real event
      // loop before the page can have decided anything.
      for (
        var i = 0;
        i < 20 && find.text('Wake Word').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await settle(tester);
      }
    }

    testWidgets('the page offers a row for each of its two pages', (
      tester,
    ) async {
      await openVs(tester);

      for (final page in ['Wake Word', 'Appearance']) {
        expect(
          find.widgetWithText(ListTile, page),
          findsOneWidget,
          reason: page,
        );
        expect(find.text(subpageHints[page]!), findsOneWidget, reason: page);
      }
      // The detection settings went to the Wake Word page with the group.
      expect(find.text(wakeWordPreferFp32.title), findsNothing);
      expect(find.text(wakeWordResumeTimeoutSeconds.title), findsNothing);
      // "Keep listening in the background" stays in General, where the page
      // adopts it out of the detection card.
      expect(find.text(wakeWordBackground.title), findsOneWidget);
      await drain(tester);
    });

    testWidgets('the Wake Word page carries the detection settings', (
      tester,
    ) async {
      await openVs(tester);

      await tester.tap(find.widgetWithText(ListTile, 'Wake Word'));
      await settle(tester);
      expect(find.widgetWithText(AppBar, 'Wake Word'), findsOneWidget);
      expect(find.text(wakeWordPreferFp32.title), findsOneWidget);
      expect(find.text(wakeWordResumeTimeoutSeconds.title), findsOneWidget);
      // The page title says it; a heading repeating it would say it twice.
      expect(find.widgetWithText(SectionHeading, 'Wake Word'), findsNothing);
      // And General did not come along.
      expect(find.widgetWithText(SectionHeading, 'General'), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.widgetWithText(ListTile, 'Wake Word'), findsOneWidget);
      expect(find.text(wakeWordPreferFp32.title), findsNothing);
      await drain(tester);
    });

    testWidgets('the Appearance page opens and Back returns', (tester) async {
      await openVs(tester);

      await tester.tap(find.widgetWithText(ListTile, 'Appearance'));
      await settle(tester);
      expect(find.widgetWithText(AppBar, 'Appearance'), findsOneWidget);
      expect(find.widgetWithText(SectionHeading, 'Appearance'), findsNothing);
      // Nothing from the page above.
      expect(find.text(wakeWordBackground.title), findsNothing);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.widgetWithText(ListTile, 'Appearance'), findsOneWidget);
      await drain(tester);
    });
  });

  group('wide (split view)', () {
    testWidgets('the subpage takes the right pane, keeping the rail', (
      tester,
    ) async {
      await boot();
      await openHa(tester, size: const Size(1200, 1000));

      expect(entryRow(), findsOneWidget);
      expect(find.text(haHaptics.title), findsNothing);

      await tester.tap(entryRow());
      await settle(tester);

      expect(find.text(haHaptics.title), findsOneWidget);
      // The rail is still there — this is a pane change, not a push.
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Web Browsing'), findsOneWidget);
      // And the pane carries its own back arrow, since it has no app bar.
      expect(find.byTooltip('Back'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(entryRow(), findsOneWidget);
      expect(find.text(haHaptics.title), findsNothing);

      await drain(tester);
    });

    testWidgets('the back gesture closes the subpage before Settings', (
      tester,
    ) async {
      await boot();
      await openHa(tester, size: const Size(1200, 1000));
      await tester.tap(entryRow());
      await settle(tester);
      expect(find.text(haHaptics.title), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      // One level only: back on the category page, Settings still open.
      expect(entryRow(), findsOneWidget);
      expect(find.text(haHaptics.title), findsNothing);
      expect(find.text('Home Assistant Setup'), findsWidgets);

      await drain(tester);
    });

    testWidgets('coming back from a subpage keeps the pane where it was', (
      tester,
    ) async {
      await boot();
      // Short enough that the category pane scrolls.
      await openHa(tester, size: const Size(1200, 600));
      // The right pane's scrollable, told apart from the rail's by a row
      // that is on screen from the start.
      final pane = find
          .ancestor(
            of: find.text('Home Assistant base URL'),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(entryRow(), 200, scrollable: pane);
      await settle(tester);
      final before = tester.state<ScrollableState>(pane);
      final offset = before.position.pixels;
      expect(offset, greaterThan(0));

      await tester.tap(entryRow());
      await settle(tester);
      expect(find.text(haHaptics.title), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);

      // The same pane, not a rebuilt one: a rebuilt pane restores its
      // offset against rows that have not loaded yet and settles at the
      // top once they do.
      final after = tester.state<ScrollableState>(pane);
      expect(identical(after, before), isTrue);
      expect(after.position.pixels, offset);
      expect(entryRow(), findsOneWidget);

      await drain(tester);
    });

    testWidgets('picking another category closes an open subpage', (
      tester,
    ) async {
      await boot();
      await openHa(tester, size: const Size(1200, 1000));
      await tester.tap(entryRow());
      await settle(tester);
      expect(find.text(haHaptics.title), findsOneWidget);

      // A category near the top of the rail, so the tap lands without
      // scrolling it.
      await tester.tap(find.text('Web Browsing'));
      await settle(tester);
      // The stale subpage must not survive the switch.
      expect(find.text(haHaptics.title), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);

      await drain(tester);
    });
  });
}
