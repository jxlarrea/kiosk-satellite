import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/ui/alarms_overlay.dart';
import 'package:kiosk_satellite/ui/timer_editor.dart';

/// On a very small screen, such as the Lenovo Smart Clock 2, five rows of
/// the alarm and timer wheels only fit shrunk, which left numbers too small
/// to drag (#1474). Where five rows do not fit at full size the wheels show
/// three bigger ones instead.
void main() {
  test('five rows where they fit, three grown ones where they do not', () {
    // The alarm wheel's compact sizes: 60 tall rows, 300 for five, which
    // may shrink to 255.
    expect(wheelFit(room: const Size(1280, 600), extent: 60, width: 200), (
      rows: 5,
      scale: 1.0,
    ));
    expect(wheelFit(room: const Size(1280, 255), extent: 60, width: 200), (
      rows: 5,
      scale: 1.0,
    ));
    // A Smart Clock 2 sized space: three rows, a quarter bigger.
    final small = wheelFit(room: const Size(600, 225), extent: 60, width: 200);
    expect(small.rows, 3);
    expect(small.scale, closeTo(1.25, 0.001));
    // No wider than the room.
    expect(
      wheelFit(room: const Size(220, 225), extent: 60, width: 200).scale,
      closeTo(1.1, 0.001),
    );
    // The caption above the timer wheel counts: five rows of 56 and a
    // caption of 20 take 300, at least 255.
    Size tall(double h) => Size(1280, h);
    expect(
      wheelFit(room: tall(255), extent: 56, width: 200, extra: 20).rows,
      5,
    );
    expect(
      wheelFit(room: tall(254), extent: 56, width: 200, extra: 20).rows,
      3,
    );
    expect(wheelFit(room: null, extent: 60, width: 200).rows, 5);
  });

  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: UiStrings.localizationsDelegates,
    supportedLocales: UiStrings.supportedLocales,
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(1280, 800),
        alwaysUse24HourFormat: true,
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  /// The number on the band in the column holding [anyOf]'s numbers.
  String centerOf(WidgetTester tester, Finder wheel, Set<String> anyOf) {
    final middle = tester.getCenter(wheel).dy;
    final texts = tester
        .widgetList<Text>(
          find.descendant(
            of: wheel,
            matching: find.byWidgetPredicate(
              (w) => w is Text && anyOf.contains(w.data),
            ),
          ),
        )
        .toList();
    texts.sort(
      (a, b) => (tester.getCenter(find.byWidget(a)).dy - middle)
          .abs()
          .compareTo((tester.getCenter(find.byWidget(b)).dy - middle).abs()),
    );
    return texts.first.data!;
  }

  testWidgets('the alarm wheel grows on a small screen and keeps its time '
      'when its room changes', (tester) async {
    final reported = <(int, int)>[];
    Widget wheel(Size? room) => host(
      AlarmWheel(
        hour: 20,
        minute: 0,
        compact: true,
        room: room,
        onChanged: (h, m) => reported.add((h, m)),
      ),
    );
    final hours = {for (var i = 0; i < 24; i++) '$i'.padLeft(2, '0')};

    await tester.pumpWidget(wheel(null));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AlarmWheel)).height, 300);
    final fullFont = tester.widget<Text>(find.text('20')).style!.fontSize!;
    expect(centerOf(tester, find.byType(AlarmWheel), hours), '20');

    await tester.pumpWidget(wheel(const Size(600, 225)));
    await tester.pumpAndSettle();
    // Three rows of 75.
    expect(tester.getSize(find.byType(AlarmWheel)).height, 225);
    expect(
      tester.widget<Text>(find.text('20')).style!.fontSize,
      closeTo(fullFont * 1.25, 0.001),
    );
    expect(centerOf(tester, find.byType(AlarmWheel), hours), '20');
    expect(reported.where((r) => r != (20, 0)), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the timer wheel grows on a small screen and keeps its time '
      'when its room changes', (tester) async {
    final reported = <int>[];
    Widget wheel(Size? room) => host(
      DurationWheel(
        seconds: 5 * 60,
        compact: true,
        room: room,
        onChanged: reported.add,
      ),
    );
    final minutes = find.byKey(const ValueKey('timer-wheel-minutes'));
    final twoDigits = {for (var i = 0; i < 60; i++) '$i'.padLeft(2, '0')};

    await tester.pumpWidget(wheel(null));
    await tester.pumpAndSettle();
    // Five rows of 56 and the caption.
    expect(tester.getSize(find.byType(DurationWheel)).height, 300);
    expect(centerOf(tester, minutes, twoDigits), '05');

    await tester.pumpWidget(wheel(const Size(600, 236)));
    await tester.pumpAndSettle();
    // Three rows and the caption, 1.25 times their full size.
    expect(tester.getSize(find.byType(DurationWheel)).height, 236);
    expect(centerOf(tester, minutes, twoDigits), '05');
    expect(reported.where((s) => s != 300), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the name field of a new timer goes next to the buttons on a '
      'small screen and under the wheel on a big one', (tester) async {
    Future<void> show(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: UiStrings.localizationsDelegates,
          supportedLocales: UiStrings.supportedLocales,
          home: Scaffold(
            body: TimerEditorStep(
              compact: size.width < 600 || size.height < 480,
              seconds: 300,
              isNew: true,
              name: '',
              onCancel: () {},
              onSet: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    addTearDown(tester.view.reset);
    final name = find.byKey(const ValueKey('timer-name'));
    final start = find.byKey(const ValueKey('timer-set'));

    await show(const Size(600, 360));
    expect(tester.getCenter(name).dy, closeTo(tester.getCenter(start).dy, 1));
    expect(tester.getSize(find.byType(DurationWheel)).height, greaterThan(188));

    await tester.enterText(name, 'Pasta');
    await show(const Size(1280, 800));
    expect(
      tester.getBottomLeft(find.byType(DurationWheel)).dy,
      lessThan(tester.getTopLeft(name).dy),
    );
    expect(tester.getTopLeft(name).dy, lessThan(tester.getTopLeft(start).dy));
    // The field kept what was typed when it moved.
    expect(find.text('Pasta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
