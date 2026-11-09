import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/compass/compass_controller.dart';
import 'package:kiosk_satellite/ui/navigation_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The view plugins hear as navigation.view and the views layer of plugin
// overlays (issue #1366).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppContainer c;
  late CompassController compass;
  late AnimationController drawer;
  late NavigationViewTracker tracker;
  late List<NavigationViewChanged> published;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = AppContainer();
    await c.settings.init();
    c.device.appVersion = 'test';
    compass = CompassController(c)..start();
    drawer = AnimationController(vsync: const TestVSync());
    published = [];
    c.bus.on<NavigationViewChanged>().listen(published.add);
    tracker = NavigationViewTracker(c, compass, drawer)..start();
  });

  tearDown(() async {
    tracker.dispose();
    drawer.dispose();
    compass.dispose();
    await c.settings.dispose();
    await c.bus.dispose();
    await c.log.dispose();
  });

  Map<String, Object?> now() => tracker.view.value.toJson();

  test('names the topmost page and publishes each change once', () async {
    expect(now(), {'mode': 'classic', 'view': 'dashboard', 'id': null});
    expect(tracker.viewsLayerHidden.value, isFalse);

    c.browser.overlayUrl.value = 'https://example.com';
    expect(now()['view'], 'overlay_page');
    c.calendar.visible.value = true;
    expect(now()['view'], 'calendar');
    // A camera view comes up over the calendar.
    c.camera.activeViewId.value = 'a1';
    expect(now(), {'mode': 'classic', 'view': 'camera', 'id': 'a1'});
    expect(tracker.viewsLayerHidden.value, isFalse);
    c.camera.activeViewId.value = null;
    c.calendar.visible.value = false;
    c.browser.overlayUrl.value = null;
    await Future<void>.delayed(Duration.zero);
    expect(published.map((e) => e.view), [
      'overlay_page',
      'calendar',
      'camera',
      'calendar',
      'overlay_page',
      'dashboard',
    ]);
  });

  test('the views layer stands down under the menu and a swipe', () async {
    drawer.value = 0.4;
    expect(now()['view'], 'menu');
    expect(tracker.viewsLayerHidden.value, isTrue);
    drawer.value = 0;
    expect(now()['view'], 'dashboard');
    expect(tracker.viewsLayerHidden.value, isFalse);

    await c.settings.setFromJson(defs.navStyle.key, 'compass');
    await Future<void>.delayed(Duration.zero);
    expect(now()['mode'], 'compass');
    compass.menuVisible.value = true;
    expect(now()['view'], 'menu');
    expect(tracker.viewsLayerHidden.value, isTrue);
    // A page opened from the Quick Controls comes up over them.
    c.alarms.visible.value = true;
    expect(now()['view'], 'alarms');
    expect(tracker.viewsLayerHidden.value, isFalse);

    compass.overlaysHidden.value = true;
    expect(tracker.viewsLayerHidden.value, isTrue);
    compass.overlaysHidden.value = false;
    expect(tracker.viewsLayerHidden.value, isFalse);
  });
}
