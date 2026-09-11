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
    'empty, single, constant and negative histories fit narrow and dark layouts',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
                  chart: chart([
                    for (var i = 0; i < values.length; i++) i * 1000,
                  ], values),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull);
      }
    },
  );
}
