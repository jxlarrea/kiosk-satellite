import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/plugin_chart.dart';

Map<String, Object?> chart(List<num> times, List<num?> values) => {
  'key': 'cpu',
  'title': 'CPU history',
  'unit': '%',
  'timestamps': times,
  'series': [
    {'name': 'Renderer', 'values': values},
    {
      'name': 'Reference',
      'color': '#AABBCC',
      'values': [for (final _ in times) 2],
    },
  ],
};
void main() {
  testWidgets(
    'inspect samples, keep selected timestamps across updates and handle gaps',
    (tester) async {
      final notifier = ValueNotifier(chart([1000, 2000, 3000], [10, null, 30]));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ValueListenableBuilder<Map<String, Object?>>(
                valueListenable: notifier,
                builder: (_, value, _) => PluginChart(chart: value),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Renderer: 30 %'), findsOneWidget);
      final plot = find.byType(CustomPaint).last;
      final bounds = tester.getRect(plot);
      await tester.tapAt(Offset(bounds.left + 1, bounds.center.dy));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Renderer: 10 %'), findsOneWidget);
      notifier.value = chart([1000, 2000, 3000, 4000], [10, null, 30, 40]);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Renderer: 10 %'), findsOneWidget);
      await tester.tapAt(
        Offset(bounds.left + bounds.width / 3, bounds.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Renderer: No data'), findsOneWidget);
      notifier.value = chart([3000, 4000], [30, 40]);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Renderer: 40 %'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      notifier.dispose();
    },
  );
  testWidgets('mini charts retain inspection without the full axes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PluginChart(
            chart: {
              ...chart([1000, 2000], [10, 20]),
              'compact': true,
            },
          ),
        ),
      ),
    );
    final plot = find.byType(CustomPaint).last;
    expect(tester.getSize(plot).height, 56);
    expect(find.text('Renderer: 20 %'), findsOneWidget);
    expect(find.textContaining('Tap or drag'), findsNothing);
    final bounds = tester.getRect(plot);
    await tester.tapAt(Offset(bounds.left + 1, bounds.center.dy));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Renderer: 10 %'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'grouped bars preserve time spacing, zero and negative readings',
    (tester) async {
      final notifier = ValueNotifier<Map<String, Object?>>({
        ...chart([1000, 2000, 5000], [10, -10, null]),
        'type': 'bar',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<Map<String, Object?>>(
              valueListenable: notifier,
              builder: (_, value, _) => PluginChart(chart: value),
            ),
          ),
        ),
      );
      for (final compact in [false, true]) {
        notifier.value = {...notifier.value, 'compact': compact};
        await tester.pump();
        final plot = find.byType(CustomPaint).last;
        final painter = tester.widget<CustomPaint>(plot).painter!;
        final canvas = TestRecordingCanvas();
        painter.paint(canvas, const Size(600, 160));
        final calls = canvas.invocations.map((e) => e.invocation).toList();
        final rects = calls
            .where((e) => e.memberName == #drawRect)
            .map((e) => e.positionalArguments[0] as Rect)
            .toList();
        expect(rects.length, 5); // The missing sample leaves its slot empty.
        expect(calls.where((e) => e.memberName == #drawPath), isEmpty);
        expect(rects[0].bottom, closeTo(80, .001));
        expect(rects[1].top, closeTo(80, .001));
        expect(rects[0].right, lessThan(rects[2].left));
        expect(
          rects.every((r) => r.left >= 0 && r.right <= 600 && r.height > 0),
          true,
        );
        expect(rects[3].center.dx - rects[2].center.dx, closeTo(120, .001));
        expect(rects[4].center.dx - rects[3].center.dx, closeTo(360, .001));
        expect(tester.getSize(plot).height, compact ? 56 : 160);
        final bounds = tester.getRect(plot);
        await tester.tapAt(
          Offset(bounds.left + bounds.width * .3, bounds.center.dy),
        );
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Renderer: -10 %'), findsOneWidget);
      }
      notifier.value = {...notifier.value, 'type': 'line'};
      await tester.pump();
      expect(find.text('Renderer: -10 %'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      notifier.dispose();
    },
  );
  testWidgets(
    'empty, single, constant and negative histories fit narrow and dark layouts',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final type in ['line', 'bar']) {
        for (final values in <List<num?>>[
          [],
          [0],
          [-5, -5],
          [null, null],
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: PluginChart(
                    chart: {
                      ...chart([
                        for (var i = 0; i < values.length; i++) i * 1000,
                      ], values),
                      'type': type,
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
