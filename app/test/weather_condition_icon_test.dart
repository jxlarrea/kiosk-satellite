import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/weather_readings.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget icon) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: icon),
    ),
  );

  String coloredAsset(WidgetTester tester) =>
      (tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader
              as SvgAssetLoader)
          .assetName;

  group('monochrome icons', () {
    testWidgets('a sunny day shows the sun, a sunny night the moon', (
      tester,
    ) async {
      await pump(
        tester,
        const WeatherConditionIcon('sunny', size: 24, color: Colors.white),
      );
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
      await pump(
        tester,
        const WeatherConditionIcon(
          'sunny',
          size: 24,
          color: Colors.white,
          night: true,
        ),
      );
      expect(find.byIcon(Icons.wb_sunny), findsNothing);
      expect(find.byIcon(Icons.nights_stay), findsOneWidget);
    });

    testWidgets('partly cloudy at night draws the moon behind a cloud', (
      tester,
    ) async {
      await pump(
        tester,
        const WeatherConditionIcon(
          'partlycloudy',
          size: 24,
          color: Colors.white,
          night: true,
        ),
      );
      expect(find.byIcon(Icons.wb_cloudy), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });

  group('colored icons', () {
    testWidgets('a sunny or partly cloudy night takes the night icons', (
      tester,
    ) async {
      for (final (condition, night, asset) in [
        ('sunny', false, 'clear_day'),
        ('sunny', true, 'clear_night'),
        ('partlycloudy', false, 'partly_cloudy_day'),
        ('partlycloudy', true, 'partly_cloudy_night'),
        ('clear-night', false, 'clear_night'),
        // No sun in the rain icon, so the night leaves it alone.
        ('rainy', true, 'showers_rain'),
      ]) {
        await pump(
          tester,
          ColoredWeatherConditionIcon(
            condition,
            size: 24,
            fallbackColor: Colors.white,
            night: night,
          ),
        );
        expect(
          coloredAsset(tester),
          'assets/weather_icons/$asset.svg',
          reason: '$condition at night: $night',
        );
      }
    });

    testWidgets('a condition without a colored icon falls back to the glyph', (
      tester,
    ) async {
      await pump(
        tester,
        const ColoredWeatherConditionIcon(
          'meteor-shower',
          size: 24,
          fallbackColor: Colors.white,
        ),
      );
      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });
  });
}
