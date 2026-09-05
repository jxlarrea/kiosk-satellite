import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The slideshow edge zones (issue #453): a tap on the outer fifth of
/// either side steps the deck and leaves the screensaver up, the middle
/// three fifths still wake, and the switch takes the zones away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContainer container;
  late List<int> steps;

  Future<void> pump(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.screensaver.mode': 'gallery',
      ...prefs,
    });
    container = AppContainer();
    await container.settings.init();
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await container.screensaver.start();
    await tester.pumpWidget(
      MaterialApp(
        // The kiosk screen's raw Listener, which reports every finger on
        // its way down: the zones must survive that report.
        home: Listener(
          onPointerDown: (_) =>
              container.bus.publish(const ActivityDetected(source: 'touch')),
          child: Stack(children: [ScreensaverOverlay(container: container)]),
        ),
      ),
    );
    await tester.pump();
    expect(container.screensaver.activeView.value, 'gallery');
    // Over the gallery view's own navigator: the steps land here.
    steps = [];
    container.screensaver.attachSlides((d) async => steps.add(d));
  }

  Future<void> tapAt(WidgetTester tester, Offset at) async {
    await tester.tapAt(at);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the left edge steps back, the right edge forward', (
    tester,
  ) async {
    await pump(tester);
    await tapAt(tester, const Offset(50, 300));
    expect(steps, [-1]);
    expect(container.screensaver.activeView.value, 'gallery');
    await tapAt(tester, const Offset(950, 300));
    expect(steps, [-1, 1]);
    expect(container.screensaver.activeView.value, 'gallery');
    // The zone is the outer fifth: a tap just inside it still steps.
    await tapAt(tester, const Offset(199, 20));
    expect(steps, [-1, 1, -1]);
    expect(container.screensaver.activeView.value, 'gallery');
  });

  testWidgets('the middle still wakes', (tester) async {
    await pump(tester);
    await tapAt(tester, const Offset(500, 300));
    expect(steps, isEmpty);
    expect(container.screensaver.activeView.value, isNull);
  });

  testWidgets('just past the fifth wakes too', (tester) async {
    await pump(tester);
    await tapAt(tester, const Offset(201, 300));
    expect(steps, isEmpty);
    expect(container.screensaver.activeView.value, isNull);
  });

  testWidgets('the switch off, an edge tap wakes as before', (tester) async {
    await pump(tester, prefs: {'ks.screensaver.gallery_edge_taps': false});
    await tapAt(tester, const Offset(50, 300));
    expect(steps, isEmpty);
    expect(container.screensaver.activeView.value, isNull);
  });
}
