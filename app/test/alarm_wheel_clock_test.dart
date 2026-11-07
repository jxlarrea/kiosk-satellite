import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/alarms_overlay.dart';

/// Settings > Alarms > 24-hour clock can change while the wheel is open,
/// from the remote admin. The hour wheel then swaps between 12 and 24
/// rows and must stay on the same hour, not on the row number it had.
void main() {
  testWidgets('the wheel keeps its hour when the clock changes', (
    tester,
  ) async {
    final reported = <(int, int)>[];
    Widget wheel(bool h24) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(1280, 800),
          alwaysUse24HourFormat: h24,
        ),
        child: Scaffold(
          body: Center(
            child: AlarmWheel(
              hour: 23,
              minute: 50,
              onChanged: (h, m) => reported.add((h, m)),
            ),
          ),
        ),
      ),
    );

    String centerHour() {
      // The hour on the band: the one nearest the wheel's middle.
      final middle = tester.getCenter(find.byType(AlarmWheel)).dy;
      final hours = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            RegExp(r'^\d{1,2}$').hasMatch(w.data ?? '') &&
            tester.getCenter(find.byWidget(w)).dx <
                tester.getCenter(find.text(':')).dx,
      );
      final texts = tester.widgetList<Text>(hours).toList();
      texts.sort(
        (a, b) => (tester.getCenter(find.byWidget(a)).dy - middle)
            .abs()
            .compareTo((tester.getCenter(find.byWidget(b)).dy - middle).abs()),
      );
      return texts.first.data!;
    }

    await tester.pumpWidget(wheel(false));
    await tester.pumpAndSettle();
    expect(centerHour(), '11');
    expect(find.text('PM'), findsOneWidget);

    await tester.pumpWidget(wheel(true));
    await tester.pumpAndSettle();
    expect(centerHour(), '23');
    expect(find.text('PM'), findsNothing);
    expect(reported.where((r) => r != (23, 50)), isEmpty);

    await tester.pumpWidget(wheel(false));
    await tester.pumpAndSettle();
    expect(centerHour(), '11');
    expect(reported.where((r) => r != (23, 50)), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
