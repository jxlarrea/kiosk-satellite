import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/compass/compass_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The reason Compass logs when it turns a swipe down, so a report of
/// swipes doing nothing says why from the console log alone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(AppContainer, CompassController)> setUpCompass({
    String style = 'compass',
  }) async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    await c.settings.setFromJson(defs.navStyle.key, style);
    final compass = CompassController(c)..start();
    addTearDown(() async {
      compass.dispose();
      await c.settings.dispose();
      await c.bus.dispose();
      await c.log.dispose();
    });
    return (c, compass);
  }

  test('nothing in the way leaves the swipe free', () async {
    final (_, compass) = await setUpCompass();
    expect(compass.swipeBlocker, isNull);
    expect(compass.swipeReady, isTrue);
  });

  test('Classic says Compass is off', () async {
    final (_, compass) = await setUpCompass(style: 'classic');
    expect(compass.swipeBlocker, 'Compass is off');
    expect(compass.swipeReady, isFalse);
  });

  test('a page over the center names it', () async {
    final (c, compass) = await setUpCompass();
    c.calendar.visible.value = true;
    expect(compass.swipeBlocker, 'the calendar view is open');
    expect(compass.swipeReady, isFalse);
    c.calendar.visible.value = false;
    c.browser.overlayUrl.value = 'https://example.com';
    expect(compass.swipeBlocker, 'a link page is open');
  });
}
