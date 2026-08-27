import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/theme.dart';

/// The segmented pill never wraps and never overflows the pane: when it
/// does not fit, it scrolls sideways under the edge fade. The Logs source
/// pill (three segments) is the one that outgrows a phone.
void main() {
  Widget page(double width) => MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: ScrollingSegments(
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 'app',
                        label: Text('Kiosk Satellite'),
                      ),
                      ButtonSegment(value: 'logcat', label: Text('Logcat')),
                      ButtonSegment(
                        value: 'console',
                        label: Text('Web Console'),
                      ),
                    ],
                    selected: const {'app'},
                    onSelectionChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('a pill wider than a phone scrolls instead of overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(page(320));
    await tester.pumpAndSettle();
    // No RenderFlex overflow was reported while laying out.
    expect(tester.takeException(), isNull);
    final pill = tester.getSize(find.byType(SegmentedButton<String>));
    final pane = tester.getSize(find.byType(ScrollingSegments));
    expect(pill.width, greaterThan(pane.width), reason: 'the case under test');
    // The pill sits in a horizontal scrollable that can travel the
    // difference.
    final scrollable = find.descendant(
      of: find.byType(ScrollingSegments),
      matching: find.byType(SingleChildScrollView),
    );
    expect(
      tester.widget<SingleChildScrollView>(scrollable).scrollDirection,
      Axis.horizontal,
    );
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: scrollable, matching: find.byType(Scrollable)),
        )
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    final before = tester.getTopLeft(find.byType(SegmentedButton<String>)).dx;
    await tester.drag(scrollable, const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(position.pixels, greaterThan(0), reason: 'the pill scrolled');
    final after = tester.getTopLeft(find.byType(SegmentedButton<String>)).dx;
    expect(after, lessThan(before), reason: 'the pill moved left');
  });

  testWidgets('a pill that fits has nothing to scroll', (tester) async {
    // The test font draws every glyph as a square, so the pill is far
    // wider than on a device; a pane wide enough for that stands in for
    // the wide pane.
    await tester.pumpWidget(page(900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ScrollingSegments),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(position.maxScrollExtent, 0);
  });
}
