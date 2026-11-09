import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart'
    show parseForecast;
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/glance/glance_manager.dart';
import 'package:kiosk_satellite/ui/digital_clock_face.dart';
import 'package:kiosk_satellite/ui/glance_row.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/weather_mood_information.dart';
import 'package:kiosk_satellite/ui/weather_readings.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AppContainer> container([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.mode': 'weather_mood',
      ...values,
    });
    final c = AppContainer();
    await c.settings.init();
    return c;
  }

  test(
    'Weather Mood clock preserves clock defaults and localized controls',
    () {
      for (final (mood, clock) in [
        (defs.screensaverWeatherClockFont, defs.screensaverClockFont),
        (
          defs.screensaverWeatherClockFontWeight,
          defs.screensaverClockFontWeight,
        ),
        (defs.screensaverWeatherClock24h, defs.screensaverClock24h),
        (defs.screensaverWeatherClockSeconds, defs.screensaverClockSeconds),
        (defs.screensaverWeatherClockDate, defs.screensaverClockDate),
        (defs.screensaverWeatherClockScale, defs.screensaverClockScale),
        (defs.screensaverWeatherClockColor, defs.screensaverClockColor),
        (defs.screensaverWeatherClockVertical, defs.screensaverClockVertical),
      ]) {
        expect(mood.defaultValue, clock.defaultValue);
        expect(mood.titleMessageId, clock.titleMessageId);
        expect(mood.descriptionMessageId, clock.descriptionMessageId);
        expect(mood.options, clock.options);
        expect(mood.optionMessageIds, clock.optionMessageIds);
      }
      expect(defs.screensaverWeatherClock.defaultValue, true);
      expect(defs.screensaverWeatherBar.defaultValue, true);
      expect(defs.screensaverWeatherClockShadow.defaultValue, true);
      expect(defs.screensaverWeatherBarShadow.defaultValue, true);
      expect(defs.screensaverWeatherBarTitles.defaultValue, false);
      expect(defs.screensaverWeatherBarOpacity.defaultValue, 50);
    },
  );
  test(
    'readings merge HA diffs and retain units with absent apparent temperatures',
    () {
      final r = WeatherMoodReadings();
      expect(r.available, false);
      r.update({
        'state': 'sunny',
        'attributes': {
          'temperature': 22.2,
          'temperature_unit': '°C',
          'wind_speed': 12.2,
          'wind_speed_unit': 'km/h',
        },
      });
      r.update({
        'attributes': {'apparent_temperature': 24.7},
      });
      expect(r.temperature(feelsLike: false), '22°C');
      expect(r.temperature(feelsLike: true), '25°C');
      r.update({
        'attributes': {'apparent_temperature': 22.4},
      });
      expect(r.temperature(feelsLike: true), '22°C');
      r.update({
        'attributes': {'apparent_temperature': null, 'visibility': double.nan},
      });
      expect(r.temperature(feelsLike: true), '22°C');
      expect(r.number('visibility'), isNull);
      expect(r.reading(r.number('wind_speed')!, 'wind_speed_unit'), '12 km/h');
      r.update({'state': 'unavailable'});
      expect(r.available, false);
    },
  );
  test('the glass blurs the scene except on low-power devices', () async {
    final c = await container({'ks.screensaver.weather_bar_opacity': 40});
    c.device.abis = const ['arm64-v8a', 'armeabi-v7a'];
    expect(weatherMoodLowPower(c), false);
    expect(weatherMoodGlass(c).blur, 20);
    expect(weatherMoodGlass(c).opacity, closeTo(.4, 1e-9));
    // A 32-bit device like the Echo Show 8 keeps the shader's frosting.
    c.device.abis = const ['armeabi-v7a', 'armeabi'];
    expect(weatherMoodLowPower(c), true);
    expect(weatherMoodGlass(c).blur, 0);
  });
  testWidgets('rain uses a rain cloud icon with the text shadow', (
    tester,
  ) async {
    Future<void> show(String condition, List<Shadow> shadows) =>
        tester.pumpWidget(
          MaterialApp(
            home: WeatherConditionIcon(
              condition,
              size: 40,
              color: Colors.white,
              shadows: shadows,
            ),
          ),
        );
    const shadow = [Shadow(offset: Offset(0, 2), blurRadius: 4)];
    for (final condition in ['rainy', 'pouring']) {
      await show(condition, const []);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      await show(condition, shadow);
      // The glyph plus a blurred copy underneath for the shadow.
      expect(find.byType(SvgPicture), findsNWidgets(2));
      expect(find.byType(ImageFiltered), findsOneWidget);
    }
    await show('sunny', shadow);
    expect(find.byType(SvgPicture), findsNothing);
    expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.wb_sunny);
  });
  for (final language in ['en', 'es', 'de', 'fr']) {
    testWidgets('clock and bar controls reveal and save in $language', (
      tester,
    ) async {
      final c = await container({
        'ks.screensaver.weather_clock': false,
        'ks.screensaver.weather_bar': false,
      });
      tester.view.physicalSize = const Size(1000, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final strings = lookupUiStrings(Locale(language));
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: SubpageSettingsScreen(
            container: c,
            category: 'Screensaver',
            subpage: 'Weather Mood screensaver',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(strings.settingScreensaverWeatherBlurTitle),
        findsOneWidget,
      );
      expect(
        find.text(strings.settingScreensaverClockScaleTitle),
        findsNothing,
      );
      expect(
        find.text(strings.settingScreensaverWeatherBarScaleTitle),
        findsNothing,
      );
      await tester.tap(find.text(strings.settingScreensaverWeatherClockTitle));
      await tester.pumpAndSettle();
      expect(
        find.text(strings.settingScreensaverClockScaleTitle),
        findsOneWidget,
      );
      expect(
        find.text(strings.settingScreensaverClockFontTitle),
        findsOneWidget,
      );
      expect(
        find.text(strings.settingScreensaverWidgetTextShadowTitle),
        findsOneWidget,
      );
      expect(
        find.text(strings.settingScreensaverClockSecondsTitle),
        findsOneWidget,
      );
      await tester.tap(find.text(strings.settingScreensaverClock24hTitle));
      await tester.pumpAndSettle();
      expect(c.settings.get(defs.screensaverWeatherClock24h), true);
      expect(c.settings.get(defs.screensaverClock24h), false);
      await tester.tap(find.text(strings.settingScreensaverWeatherBarTitle));
      await tester.pumpAndSettle();
      expect(
        find.text(strings.settingScreensaverWeatherBarScaleTitle),
        findsOneWidget,
      );
      expect(
        find.text(strings.settingScreensaverWidgetTextShadowTitle),
        findsNWidgets(2),
      );
      expect(
        find.text(strings.settingScreensaverWeatherBarTitlesTitle),
        findsOneWidget,
      );
      expect(find.text(strings.screensaverOverlayFeelsLikeOnly), findsNothing);
      expect(
        find.text(strings.screensaverWeatherBarFeelsLikeDescription),
        findsOneWidget,
      );
      await tester.tap(find.text(strings.screensaverOverlayFeelsLike));
      await tester.pumpAndSettle();
      expect(c.settings.get(defs.screensaverWeatherBarFeelsLike), true);
      await tester.tap(find.text(strings.settingScreensaverWeatherClockTitle));
      await tester.pumpAndSettle();
      expect(
        find.text(strings.settingScreensaverClockScaleTitle),
        findsNothing,
      );
      expect(
        find.text(strings.settingScreensaverWeatherBarScaleTitle),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'overlays fit landscape, portrait and large text and update live',
    (tester) async {
      final c = await container({
        'ks.screensaver.weather_clock': true,
        'ks.screensaver.weather_bar': true,
        'ks.screensaver.weather_bar_location': 'Home',
        'ks.screensaver.weather_bar_feels_like': true,
        'ks.screensaver.glance_enabled': true,
      });
      c.glance.entities.value = const [
        GlanceEntity(
          entityId: 'sensor.room',
          name: 'Living room',
          state: '23',
          unit: '°C',
        ),
      ];
      final readings = WeatherMoodReadings()
        ..update({
          'state': 'partlycloudy',
          'attributes': {
            'temperature': 26.4,
            'apparent_temperature': 29.2,
            'temperature_unit': '°C',
            'humidity': 72,
            'wind_speed': 12.3,
            'wind_speed_unit': 'km/h',
            'visibility': 10,
            'visibility_unit': 'km',
          },
        });
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader(
        'Rubik',
      )..addFont(rootBundle.load('assets/fonts/Rubik.ttf'))).load();
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      Future<void> show(Size size, double scale, String locale) async {
        tester.view.physicalSize = size;
        await c.settings.set(defs.screensaverWeatherBarScale, scale);
        await c.settings.set(
          defs.screensaverWeatherClockScale,
          scale == 200 ? 300 : 100,
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: appSupportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            home: RepaintBoundary(
              key: key,
              child: Material(
                color: const Color(0xFF33485F),
                child: WeatherMoodInformation(container: c, readings: readings),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$size, $scale, $locale',
        );
        expect(find.byType(DigitalClockFace), findsOneWidget);
        expect(find.text('29°C'), findsOneWidget);
        expect(find.text('26°C'), findsNothing);
        expect(
          find.text(
            lookupUiStrings(
              Locale(locale),
            ).screensaverWeatherFeelsLikeValue('29°C'),
          ),
          findsNothing,
        );
        expect(
          find.text(
            lookupUiStrings(
              Locale(locale),
            ).screensaverWeatherPreviewPartlycloudy,
          ),
          findsOneWidget,
        );
        expect(
          tester
              .getRect(find.byType(DigitalClockFace))
              .overlaps(tester.getRect(find.byType(WeatherMoodBar))),
          false,
        );
        expect(
          tester.getBottomLeft(find.byType(GlanceRow)).dy,
          lessThan(tester.getTopLeft(find.byType(WeatherMoodBar)).dy),
        );
        final directory = Platform.environment['WEATHER_MOOD_REVIEW_DIR'];
        if (directory != null) {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$directory/${size.width.toInt()}-${scale.toInt()}-$locale.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }

      for (final size in [
        const Size(1280, 800),
        const Size(720, 480),
        const Size(360, 800),
      ]) {
        await show(size, 100, 'en');
        await show(size, 200, 'de');
        final face = tester.widget<DigitalClockFace>(
          find.byType(DigitalClockFace),
        );
        expect(face.date, isNotNull);
        expect(face.dateGapFactor, .015);
        expect(face.dateOpacity, 1);
        expect(face.shadows, isNotEmpty);
      }
      await c.settings.set(defs.screensaverWeatherClockDate, false);
      await c.settings.set(defs.screensaverWeatherClock24h, true);
      await c.settings.set(defs.screensaverWeatherClockShadow, false);
      await c.settings.set(defs.screensaverWeatherBarHumidity, false);
      readings.update({
        'attributes': {'wind_speed': null, 'visibility': null},
      });
      await show(const Size(1280, 800), 100, 'fr');
      expect(find.text('72%'), findsNothing);
      expect(find.text('12 km/h'), findsNothing);
      final face = tester.widget<DigitalClockFace>(
        find.byType(DigitalClockFace),
      );
      expect(face.date, isNull);
      expect(face.shadows, isEmpty);
      expect(face.time, matches(RegExp(r'^\d{2}:\d{2}$')));
      // Show seconds adds them to the same face.
      await c.settings.set(defs.screensaverWeatherClockSeconds, true);
      await show(const Size(1280, 800), 100, 'fr');
      expect(
        tester.widget<DigitalClockFace>(find.byType(DigitalClockFace)).time,
        matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')),
      );
      await c.settings.set(defs.screensaverWeatherClockSeconds, false);
      List<ShapeDecoration> chips() => [
        for (final box in tester.widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(WeatherMoodBar),
            matching: find.byType(DecoratedBox),
          ),
        ))
          if (box.decoration case final ShapeDecoration decoration) decoration,
      ];
      await c.settings.set(defs.screensaverWeatherBarHumidity, true);
      readings.update({
        'attributes': {'wind_speed': 12.3, 'visibility': 10},
      });
      // The fill and edge of every chip fade with Background opacity.
      for (final (opacity, edge) in [(0, 0.0), (50, .08), (100, .16)]) {
        await c.settings.set(defs.screensaverWeatherBarOpacity, opacity);
        await show(const Size(1280, 800), 100, 'fr');
        expect(chips(), hasLength(4));
        // At a Glance wears the same glass, tinted alike.
        final pills = [
          for (final box in tester.widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(GlanceRow),
              matching: find.byType(DecoratedBox),
            ),
          ))
            if (box.decoration case final ShapeDecoration decoration)
              decoration,
        ];
        expect(pills, hasLength(1));
        expect(
          (pills.single.gradient! as LinearGradient).colors.last.a,
          closeTo(opacity / 100, .01),
        );
        // The test renderer has no backdrop shaders, so the chips are the
        // plain tinted fallback: no per-frame backdrop blur.
        expect(
          find.descendant(
            of: find.byType(WeatherMoodBar),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );
        for (final chip in chips()) {
          final tint = (chip.gradient! as LinearGradient).colors.last;
          expect(tint.a, closeTo(opacity / 100, .01));
          expect(
            (chip.shape as StadiumBorder).side.color.a,
            closeTo(edge, .01),
          );
        }
      }
      // At a Glance takes the chips' Text drop shadow too.
      List<Shadow>? glanceShadows() => tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byType(GlanceRow),
                  matching: find.byType(Text),
                )
                .first,
          )
          .style!
          .shadows;
      expect(glanceShadows(), isNotEmpty);
      await c.settings.set(defs.screensaverWeatherBarShadow, false);
      await show(const Size(1280, 800), 100, 'fr');
      expect(glanceShadows(), isEmpty);
      await c.settings.set(defs.screensaverWeatherBarShadow, true);
      List<Rect> chipRects() => [
        for (final element
            in find
                .descendant(
                  of: find.byType(WeatherMoodBar),
                  matching: find.byType(Container),
                )
                .evaluate())
          if ((element.widget as Container).decoration is ShapeDecoration)
            tester.getRect(find.byWidget(element.widget)),
      ]..sort((a, b) => a.left.compareTo(b.left));
      // Wide screens put the conditions chip at the bottom left and the
      // readings against the right edge on the same baseline, including a
      // 1205 pixel wide Tab S8 at 135% where the chips still fit one row.
      for (final (width, scale) in [
        (1280.0, 100.0),
        (1205.0, 135.0),
        (1205.0, 155.0),
      ]) {
        await show(Size(width, 800), scale, 'en');
        final rects = chipRects();
        expect(rects.first.left, closeTo(12 * scale / 100, 1));
        expect(rects.last.right, closeTo(width - 12 * scale / 100, 1));
        for (final rect in rects) {
          // Every chip shares one height and one row.
          expect(rect.height, closeTo(rects.first.height, .5));
          expect(rect.bottom, closeTo(rects.first.bottom, 1));
        }
        // The chips take only their own height, which the corner widgets
        // are told after layout, and leave the rest to the clock.
        final bar = tester.getRect(
          find.byKey(const ValueKey('weather-mood-bar')),
        );
        expect(bar.height, closeTo(rects.first.height + 12 * scale / 100, 1));
        expect(c.screensaver.weatherChipsHeight.value, closeTo(bar.height, .5));
      }
      // Under a UI scale exemption the MediaQuery size is the scaled one,
      // smaller than the space the chips get. They still reach both edges.
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(size: const Size(1113, 696)),
              child: Material(
                child: WeatherMoodInformation(container: c, readings: readings),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final exempt = chipRects();
      // Still at 155% text scale from the loop above.
      expect(exempt.first.left, closeTo(12 * 1.55, 1));
      expect(exempt.last.right, closeTo(1280 - 12 * 1.55, 1));
      // A phone-width screen stacks the readings above the main chip.
      await show(const Size(360, 800), 100, 'en');
      final stacked = chipRects();
      final main = stacked.reduce((a, b) => a.bottom > b.bottom ? a : b);
      expect(
        stacked.where((rect) => rect != main).every((r) => r.bottom < main.top),
        isTrue,
      );
      // Without titles each reading shows its value alone, at the size of
      // the temperature, and every chip keeps the same height.
      await c.settings.set(defs.screensaverWeatherBarTitles, true);
      await show(const Size(1280, 800), 100, 'en');
      final titled = chipRects();
      expect(find.text('Humidity'), findsOneWidget);
      await c.settings.set(defs.screensaverWeatherBarTitles, false);
      await show(const Size(1280, 800), 100, 'en');
      expect(find.text('Humidity'), findsNothing);
      double fontSize(String text) =>
          tester.widget<Text>(find.text(text)).style!.fontSize!;
      expect(fontSize('72%'), fontSize('29°C'));
      final untitled = chipRects();
      expect(untitled, hasLength(titled.length));
      for (final rect in untitled) {
        expect(rect.height, closeTo(titled.first.height, .5));
      }
      // With every reading off, the lone conditions chip sits centered.
      await c.settings.set(defs.screensaverWeatherBarHumidity, false);
      await c.settings.set(defs.screensaverWeatherBarWind, false);
      await c.settings.set(defs.screensaverWeatherBarVisibility, false);
      await show(const Size(1280, 800), 100, 'en');
      final lone = chipRects();
      expect(lone, hasLength(1));
      expect(lone.single.center.dx, closeTo(640, 1));
      readings.update({'state': 'unavailable'});
      await tester.pumpWidget(
        MaterialApp(
          home: WeatherMoodInformation(container: c, readings: readings),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WeatherMoodBar), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test('high and low read today from the daily forecast', () {
    final r = WeatherMoodReadings();
    final today = DateTime(2026, 11, 9, 15);
    expect(r.highLow(today), isNull);
    r.daily = parseForecast([
      {'datetime': '2026-11-08T12:00:00', 'temperature': 20, 'templow': 9},
      {'datetime': '2026-11-09T12:00:00', 'temperature': 22.6, 'templow': 13.2},
    ]);
    expect(r.highLow(today), '23° / 13°');
    // A forecast without a low has nothing to pair the high with.
    r.daily = parseForecast([
      {'datetime': '2026-11-09T12:00:00', 'temperature': 22},
    ]);
    expect(r.highLow(today), isNull);
  });
  testWidgets('High and low adds a chip with today\'s forecast', (
    tester,
  ) async {
    final c = await container();
    await c.settings.set(defs.screensaverWeatherBarHumidity, false);
    await c.settings.set(defs.screensaverWeatherBarWind, false);
    await c.settings.set(defs.screensaverWeatherBarVisibility, false);
    await c.settings.set(defs.screensaverWeatherBarTitles, true);
    final readings = WeatherMoodReadings()
      ..update({
        'state': 'sunny',
        'attributes': {'temperature': 18, 'temperature_unit': '°C'},
      });
    final now = DateTime.now();
    readings.daily = parseForecast([
      {
        'datetime': DateTime(
          now.year,
          now.month,
          now.day,
          12,
        ).toIso8601String(),
        'temperature': 21.4,
        'templow': 11.6,
      },
    ]);
    Future<void> show() async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: WeatherMoodInformation(container: c, readings: readings),
          ),
        ),
      );
      await tester.pump();
    }

    expect(defs.screensaverWeatherBarHighLow.defaultValue, true);
    await show();
    expect(find.text('21° / 12°'), findsOneWidget);
    expect(find.text('High and low'), findsOneWidget);
    expect(find.byIcon(Icons.thermostat), findsOneWidget);
    await c.settings.set(defs.screensaverWeatherBarHighLow, false);
    await show();
    expect(find.text('21° / 12°'), findsNothing);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('a ringing alarm keeps Snooze and Stop big on a small screen', (
    tester,
  ) async {
    final c = await container();
    final readings = WeatherMoodReadings();
    c.screensaver.alarmTakeover.value = 'ringing';
    Future<(Rect, Rect)> ring(Size size) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: WeatherMoodInformation(container: c, readings: readings),
          ),
        ),
      );
      await tester.pump();
      Rect pill(String label) => tester.getRect(
        find
            .ancestor(of: find.text(label), matching: find.byType(Material))
            .first,
      );
      return (pill('Snooze'), pill('Stop'));
    }

    // A Lenovo Smart Clock 2: the buttons keep their full size instead of
    // shrinking with the clock, and the pair still fits across.
    final (snooze, stop) = await ring(const Size(533, 320));
    expect(tester.takeException(), isNull);
    expect(snooze.height, greaterThan(60));
    expect(snooze.width, greaterThan(200));
    expect(snooze.left, greaterThanOrEqualTo(0));
    expect(stop.right, lessThanOrEqualTo(533));
    expect(stop.bottom, lessThanOrEqualTo(320));
    // A tablet is sized as before.
    final (big, _) = await ring(const Size(1280, 800));
    expect(big.width, closeTo(230 * 1.25, .5));
    expect(big.height, closeTo(68 * 1.25, .5));
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
