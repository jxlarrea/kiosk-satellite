import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screensaver's overlay announcements (ScreensaverViewChanged): the
/// browser's rendering freeze keys off them, and Dim must read as
/// "dashboard uncovered" or the freeze blanks the screen (issue #82).
/// Registry commands (setBrightness, keepScreenAwake, ...) are absent here
/// and fail soft, which is all these tests need.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late ScreensaverManager saver;
  late List<String?> views;

  Future<void> build(String mode) async {
    SharedPreferences.setMockInitialValues({'ks.screensaver.mode': mode});
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    saver = ScreensaverManager(bus, commands, log, settings);
    views = [];
    bus.on<ScreensaverViewChanged>().listen((e) => views.add(e.view));
  }

  test('dim runs with no overlay: the dashboard stays the display', () async {
    await build('dim');
    await saver.start();
    await pumpEventQueue();
    expect(saver.activeView.value, isNull);
    expect(views, [null]);
  });

  test('black covers the dashboard and uncovers it on stop', () async {
    await build('black');
    await saver.start();
    await pumpEventQueue();
    expect(saver.activeView.value, 'black');
    expect(views, ['black']);
    await saver.stop();
    await pumpEventQueue();
    expect(saver.activeView.value, isNull);
    expect(views, ['black', null]);
  });

  test('a content mode announces its own view', () async {
    await build('clock');
    await saver.start();
    await pumpEventQueue();
    expect(views, ['clock']);
  });
}
