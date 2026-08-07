import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/kit.dart';

void main() {
  // The mask itself is a shader, which widget tests cannot inspect; what
  // they can pin down is the state driving it: which edges the widget
  // considers "hiding content" as the list lays out, scrolls, and shrinks.
  (bool top, bool bottom) edges(WidgetTester tester) {
    final state = tester.state(find.byType(EdgeFade)) as dynamic;
    return (state.debugTop as bool, state.debugBottom as bool);
  }

  Future<void> pump(WidgetTester tester, {required int rows}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: EdgeFade(
              child: ListView(
                children: [
                  for (var i = 0; i < rows; i++)
                    SizedBox(height: 40, child: Text('row $i')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('content that fits fades neither edge', (tester) async {
    await pump(tester, rows: 3);
    expect(edges(tester), (false, false));
  });

  testWidgets('overflow fades only the bottom before any scroll', (
    tester,
  ) async {
    await pump(tester, rows: 20);
    expect(edges(tester), (false, true));
  });

  testWidgets('mid-scroll fades both edges, the end only the top', (
    tester,
  ) async {
    await pump(tester, rows: 20);
    final list = find.byType(Scrollable);
    await tester.drag(list, const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(edges(tester), (true, true));
    await tester.drag(list, const Offset(0, -10000));
    await tester.pumpAndSettle();
    expect(edges(tester), (true, false));
  });

  testWidgets('a reversed list starts with the fade above', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: EdgeFade(
              child: ListView(
                reverse: true,
                children: [
                  for (var i = 0; i < 20; i++)
                    SizedBox(height: 40, child: Text('line $i')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Pinned to the newest line at the visual bottom: the older lines hide
    // past the top edge, nothing hides below.
    expect(edges(tester), (true, false));
  });
}
