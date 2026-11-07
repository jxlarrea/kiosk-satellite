import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/ui/weather_mood_information.dart';
import 'package:kiosk_satellite/ui/weather_readings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Weather Mood bar keeps its shadowed chip as an image, and a child
/// repainting does not retake it. The rain icons are SVGs that draw nothing
/// until they load, so a change to rain left an empty circle in the chip
/// until the temperature next changed.
///
/// flutter_svg compiles synchronously in debug builds, which hides this: an
/// icon is there on its first frame. A release build compiles on an isolate
/// the first time an icon is drawn and only then has it at once. These tests
/// seed the cache with a pending future to get the release timing.
void main() {
  const frame = ValueKey('frame');
  final icon = find.byType(WeatherConditionIcon);

  Future<AppContainer> container() async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.mode': 'weather_mood',
    });
    final c = AppContainer();
    await c.settings.init();
    return c;
  }

  WeatherMoodReadings readings(String condition) =>
      WeatherMoodReadings()..update({
        'state': condition,
        'attributes': {'temperature': 27, 'temperature_unit': '°C'},
      });

  Widget host(AppContainer c, WeatherMoodReadings r) => MaterialApp(
    home: RepaintBoundary(
      key: frame,
      child: ColoredBox(
        color: Colors.black,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: WeatherMoodBar(container: c, readings: r),
        ),
      ),
    ),
  );

  Future<void> frames(WidgetTester tester, [int count = 6]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// The icon's compiled bytes, and the key its loader caches them under.
  Future<(ByteData, Object)> compiled(
    WidgetTester tester,
    String condition,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: WeatherConditionIcon(condition, size: 24, color: Colors.white),
      ),
    );
    await frames(tester, 2);
    final loader =
        tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader
            as SvgStringLoader;
    final bytes = await loader.loadBytes(null);
    final key = loader.cacheKey(null);
    await tester.pumpWidget(const SizedBox());
    svg.cache.clear();
    return (bytes, key);
  }

  // Bright pixels inside the circle: the icon is white on a dark disc.
  Future<int> iconPixels(WidgetTester tester) async {
    final rect = tester.getRect(icon);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(frame),
    );
    final (data, width) = (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData();
      final width = image.width;
      image.dispose();
      return (bytes!, width);
    }))!;
    var bright = 0;
    for (var y = rect.top.floor(); y < rect.bottom.ceil(); y++) {
      for (var x = rect.left.floor(); x < rect.right.ceil(); x++) {
        if (data.getUint8((y * width + x) * 4) > 200) bright++;
      }
    }
    return bright;
  }

  setUp(() => svg.cache.clear());
  tearDown(() => svg.cache.clear());

  for (final condition in ['pouring', 'rainy']) {
    testWidgets('$condition shows when it loads after the change', (
      tester,
    ) async {
      final (bytes, key) = await compiled(tester, condition);
      final loading = Completer<ByteData>();
      svg.cache.putIfAbsent(key, () => loading.future);
      final c = await container();
      final r = readings('cloudy');
      await tester.pumpWidget(host(c, r));
      await frames(tester);
      r.update({'state': condition});
      await tester.pumpWidget(host(c, r));
      await frames(tester);
      loading.complete(bytes);
      await frames(tester);
      expect(await iconPixels(tester), greaterThan(20));
    });

    testWidgets('$condition shows when it was already cached', (tester) async {
      final (bytes, key) = await compiled(tester, condition);
      svg.cache.putIfAbsent(key, () => Future.value(bytes));
      final c = await container();
      final r = readings('cloudy');
      await tester.pumpWidget(host(c, r));
      await frames(tester);
      r.update({'state': condition});
      await tester.pumpWidget(host(c, r));
      await frames(tester);
      expect(await iconPixels(tester), greaterThan(20));
    });
  }

  testWidgets('a rain icon that loads late replaces the other', (tester) async {
    final (rainyBytes, rainyKey) = await compiled(tester, 'rainy');
    final (pouringBytes, pouringKey) = await compiled(tester, 'pouring');
    svg.cache.putIfAbsent(rainyKey, () => Future.value(rainyBytes));
    final loading = Completer<ByteData>();
    svg.cache.putIfAbsent(pouringKey, () => loading.future);
    final c = await container();
    final r = readings('rainy');
    await tester.pumpWidget(host(c, r));
    await frames(tester);
    final rainy = await iconPixels(tester);
    r.update({'state': 'pouring'});
    await tester.pumpWidget(host(c, r));
    await frames(tester);
    loading.complete(pouringBytes);
    await frames(tester);
    final pouring = await iconPixels(tester);
    expect(pouring, greaterThan(20));
    // The chip's width moves the old icon a pixel, so a stale image differs
    // by a pixel or two. The two icons differ by about ten.
    expect((pouring - rainy).abs(), greaterThan(5));
  });
}
