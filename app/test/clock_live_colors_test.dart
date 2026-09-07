import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The clock faces read their colors at build and used to repaint them
/// only at the next minute tick, so a color written through the remote
/// API while the clock was on screen (an automation turning the clock
/// green for trash day, issue #469) waited out the minute or a restart of
/// the screensaver. Every color of the three faces now applies the moment
/// it changes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> pumpClock(
    WidgetTester tester,
    Map<String, Object> prefs,
  ) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.local:8123',
      'ks.ha.token': 'token',
      'ks.screensaver.mode': 'clock',
      'ks.screensaver.clock_show_date': false,
      ...prefs,
    });
    final container = AppContainer();
    await container.settings.init();
    await tester.pumpWidget(
      MaterialApp(home: ClockScreensaver(container: container)),
    );
    return container;
  }

  // The change event reaches the face through the bus, a hop after the
  // write returns, so the frame that shows it is the second one.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  // The face's own box: the one that holds the display-sized stack.
  Color faceBackground(WidgetTester tester) => tester
      .widget<ColoredBox>(
        find.byWidgetPredicate((w) => w is ColoredBox && w.child is Stack),
      )
      .color;

  testWidgets('the digital face repaints its background on a write', (
    tester,
  ) async {
    final c = await pumpClock(tester, {});
    expect(faceBackground(tester), Colors.black);
    await c.settings.set(defs.screensaverClockBgColor, '0,128,0');
    await settle(tester);
    expect(faceBackground(tester), const Color(0xFF008000));
    await c.settings.set(defs.screensaverClockBgColor, '0,0,0');
    await settle(tester);
    expect(faceBackground(tester), Colors.black);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the flip and roller faces follow their own backdrop keys', (
    tester,
  ) async {
    var c = await pumpClock(tester, {'ks.screensaver.clock_style': 'flip'});
    await c.settings.set(defs.screensaverFlipBackdropColor, '0,0,255');
    await settle(tester);
    expect(faceBackground(tester), const Color(0xFF0000FF));
    await tester.pumpWidget(const SizedBox());

    c = await pumpClock(tester, {'ks.screensaver.clock_style': 'roller'});
    await c.settings.set(defs.screensaverRollerBgColor, '255,0,0');
    await settle(tester);
    expect(faceBackground(tester), const Color(0xFFFF0000));
    await tester.pumpWidget(const SizedBox());
  });
}
