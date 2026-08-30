import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/date_picker.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Immich screensaver's fixed windows as the user meets them on the
/// device (issue #383): Since reveals the From date, Timeframe reveals From
/// and To, a rolling window reveals neither, and both dates are picked off
/// a calendar rather than typed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContainer container;

  Future<void> boot(String takenWithin) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      // The filters only render behind a validated Immich connection.
      'ks.screensaver.mode': 'immich',
      'ks.screensaver.immich_url': 'http://immich.local:2283',
      'ks.screensaver.immich_key': 'key',
      'ks.screensaver.immich_validated': true,
      'ks.screensaver.immich_taken_within': takenWithin,
    });
    container = AppContainer();
    await container.settings.init();
    container.homeAssistant.connectionOk.value = true;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  /// The Immich second-level page, on a tall narrow pane so the whole page
  /// lays out without scrolling the rows under test out of the tree.
  Future<void> openImmich(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await settle(tester);
    await tester.tap(find.text('Screensaver'));
    await settle(tester);
    await tester.tap(find.text('Immich Media screensaver'));
    await settle(tester);
  }

  testWidgets('a rolling window shows neither date', (tester) async {
    await boot('365');
    await openImmich(tester);

    expect(find.text(screensaverImmichTakenWithin.title), findsOneWidget);
    expect(find.text(screensaverImmichTakenFrom.title), findsNothing);
    expect(find.text(screensaverImmichTakenTo.title), findsNothing);
    expect(find.byType(DateBox), findsNothing);
  });

  testWidgets('Since reveals From alone, reading its placeholder', (
    tester,
  ) async {
    await boot(immichTakenSince);
    await openImmich(tester);

    expect(find.text(screensaverImmichTakenFrom.title), findsOneWidget);
    expect(find.text(screensaverImmichTakenTo.title), findsNothing);
    expect(find.byType(DateBox), findsOneWidget);
    // Empty is the open end, which the box names rather than "Not set".
    expect(find.text(screensaverImmichTakenFrom.placeholder!), findsOneWidget);
  });

  testWidgets('Timeframe reveals both dates and shows the days set', (
    tester,
  ) async {
    await boot(immichTakenRange);
    await container.settings.set(
      screensaverImmichTakenFrom,
      '2020-01-01',
    );
    await container.settings.set(screensaverImmichTakenTo, '2020-06-30');
    await openImmich(tester);

    expect(find.text(screensaverImmichTakenFrom.title), findsOneWidget);
    expect(find.text(screensaverImmichTakenTo.title), findsOneWidget);
    expect(find.byType(DateBox), findsNWidgets(2));
    expect(find.text('2020-01-01'), findsOneWidget);
    expect(find.text('2020-06-30'), findsOneWidget);
  });

  testWidgets('the calendar reaches a distant year without stepping months', (
    tester,
  ) async {
    await boot(immichTakenSince);
    await container.settings.set(
      screensaverImmichTakenFrom,
      '2020-01-01',
    );
    await openImmich(tester);

    await tester.tap(find.byType(DateBox));
    await settle(tester);
    // The month heading is the way into the years, so a library starting
    // in 2000 is a few taps away rather than 240 on the chevrons.
    await tester.tap(find.text('January 2020'));
    await settle(tester);
    // The years scroll, so 2000 is a flick away rather than 240 chevron
    // taps. It opens on the year showing, hence the scroll back.
    expect(find.text('2020'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('2000'),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await settle(tester);
    await tester.tap(find.text('2000'));
    await settle(tester);
    await tester.tap(find.text('15'));
    await settle(tester);
    await tester.tap(find.text('Set'));
    await settle(tester);
    expect(container.settings.get(screensaverImmichTakenFrom), '2000-01-15');
  });

  testWidgets('the calendar fits a short panel, buttons and all', (
    tester,
  ) async {
    // An Echo Show 5's panel, the shortest thing this runs on: the dialog
    // sizes itself to what is there, and the calendar scrolls inside it,
    // so the buttons are never pushed off the bottom.
    tester.view.physicalSize = const Size(960, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showKsDatePicker(context, title: 'From', initial: '2020-01-01'),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);

    // No overflow (the binding fails the test on one), and every action is
    // on screen.
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    for (final action in ['Clear', 'Cancel', 'Set']) {
      expect(find.text(action), findsOneWidget, reason: action);
      expect(
        tester.getRect(find.text(action)).bottom,
        lessThanOrEqualTo(480),
        reason: action,
      );
    }
  });

  testWidgets('the date box opens the calendar, and Clear empties it', (
    tester,
  ) async {
    await boot(immichTakenSince);
    await container.settings.set(
      screensaverImmichTakenFrom,
      '2020-01-01',
    );
    await openImmich(tester);

    await tester.tap(find.byType(DateBox));
    await settle(tester);
    expect(find.byType(CalendarDatePicker), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await settle(tester);
    expect(container.settings.get(screensaverImmichTakenFrom), '');
    expect(find.text(screensaverImmichTakenFrom.placeholder!), findsOneWidget);
  });
}
