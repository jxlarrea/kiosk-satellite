import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/plugin_readings.dart';

void main() {
  test(
    'readings distinguish unknown, empty, zero and false with bounded precision',
    () {
      for (final (state, precision, expected) in [
        (null, 0, 'No data'),
        ('', 0, 'Empty'),
        (false, 0, 'Off'),
        (true, 0, 'On'),
        (0, 2, '0.00'),
        (-0.0001, 2, '0.00'),
        (12.3456, 2, '12.35'),
        (12.3456, 0, '12'),
        (1e12, 2, '1.00e+12'),
        (double.nan, 2, 'No data'),
        ('Line one\nLine two', 0, 'Line one\nLine two'),
      ]) {
        expect(
          formatPluginReading({'state': state, 'accuracyDecimals': precision}),
          expected,
        );
      }
    },
  );

  testWidgets(
    'readings wrap at narrow widths and large text without interactive controls',
    (tester) async {
      final readings = <Map<String, Object?>>[
        {
          'type': 'sensor',
          'key': 'cpu',
          'name': 'Simulated wave',
          'state': 12.5,
          'accuracyDecimals': 2,
          'unit': '%',
        },
        {
          'type': 'sensor',
          'key': 'unknown',
          'name': 'Temperature',
          'state': null,
          'unit': '°C',
        },
        {
          'type': 'text_sensor',
          'key': 'summary',
          'name': 'Sample details',
          'state':
              'Pattern: Triangle\nHistory: up to 120 samples\nInterval: 2 seconds',
        },
        {
          'type': 'text_sensor',
          'key': 'long',
          'name': 'Long reading',
          'state': 'a' * 512,
        },
        {
          'type': 'select',
          'key': 'mode',
          'name': 'Current mode',
          'state': 'Automatic',
        },
        {'type': 'switch', 'key': 'switch', 'name': 'Chart', 'state': false},
      ];
      for (final width in [320.0, 760.0]) {
        tester.view.resetPhysicalSize();
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(2),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: PluginReadings(readings: readings),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Readings'), findsOneWidget);
        expect(find.text('12.50 %', findRichText: true), findsOneWidget);
        expect(find.text('No data', findRichText: true), findsOneWidget);
        expect(find.text('°C', findRichText: true), findsNothing);
        expect(find.byType(Switch), findsNothing);
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(
        const MaterialApp(home: PluginReadings(readings: [])),
      );
      expect(find.text('Readings'), findsNothing);
    },
  );
}
