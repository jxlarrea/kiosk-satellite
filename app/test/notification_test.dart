import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/esp_entities.dart';
import 'package:kiosk_satellite/managers/notifications/notification_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/notification_overlay.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifications pushed at the kiosk from Home Assistant (issue #269).
///
/// The two ends that have to agree: what the ESPHome `notification` action
/// sends (all arguments always present, defaults expressed as empty
/// strings and negative numbers, because the protocol has no optional
/// ones) and what the command does with them. Plus the stack: several
/// notifications share the screen, each with its own countdown.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late NotificationManager notifications;
  late List<(String, Map<String, Object?>)> executed;

  setUp(() async {
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    notifications = NotificationManager(bus, commands, log);
    await notifications.init();
    executed = [];
    // The chime is a command away, and there is no audio in a unit test.
    commands.register(
      Command(
        name: 'playChime',
        description: 'stub',
        handler: (p) async {
          executed.add(('playChime', p));
          return const CommandResult.ok();
        },
      ),
    );
  });

  tearDown(() async => notifications.dispose());

  Future<int> show(Map<String, Object?> params) async {
    final result = await commands.execute('showNotification', params);
    return ((result.data! as Map)['id'] as num).toInt();
  }

  List<String> onScreen() =>
      [for (final note in notifications.current.value) note.message];

  test('a notification shows and chimes', () async {
    await show({
      'message': 'Laundry is done',
      'title': 'Utility room',
      'duration': 5,
      'type': 'warning',
    });
    final shown = notifications.current.value.single;
    expect(shown.message, 'Laundry is done');
    expect(shown.title, 'Utility room');
    expect(shown.level, NotificationLevel.warning);
    // Chime on by default: nobody is watching the screen when it arrives.
    expect(executed.map((e) => e.$1), contains('playChime'));
  });

  test('a second notification joins the first, newest on top', () async {
    await show({'message': 'Washing machine finished', 'duration': 0});
    await show({'message': 'Front door opened', 'duration': 0});
    expect(onScreen(), ['Front door opened', 'Washing machine finished']);
  });

  test('the oldest makes way once the stack is full', () async {
    for (var i = 1; i <= NotificationManager.maxVisible + 2; i++) {
      await show({'message': 'Message $i', 'duration': 0});
    }
    expect(onScreen(), ['Message 6', 'Message 5', 'Message 4', 'Message 3']);
  });

  test('the same words twice are two notifications', () async {
    await show({'message': 'Motion in the hallway', 'duration': 0});
    await show({'message': 'Someone at the door', 'duration': 0});
    await show({'message': 'Motion in the hallway', 'duration': 0});
    // A caller saying it again means it happened again; nothing is
    // collapsed away.
    expect(onScreen(), [
      'Motion in the hallway',
      'Someone at the door',
      'Motion in the hallway',
    ]);
  });

  test('each notification keeps its own countdown', () async {
    await show({'message': 'Goes on its own', 'duration': 1});
    await show({'message': 'Stays put', 'duration': 0});
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(onScreen(), ['Stays put']);
  });

  test('dismiss takes one card down, or the whole stack', () async {
    final first = await show({'message': 'First', 'duration': 0});
    await show({'message': 'Second', 'duration': 0});
    await commands.execute('dismissNotification', {'id': first});
    expect(onScreen(), ['Second']);
    await commands.execute('dismissNotification', const {});
    expect(notifications.current.value, isEmpty);
  });

  test('duration 0 stays up until something dismisses it', () async {
    await show({
      'message': 'Water leak in the basement',
      'duration': 0,
      'type': 'error',
    });
    expect(
      notifications.current.value.single.level,
      NotificationLevel.error,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(notifications.current.value, hasLength(1));
    await commands.execute('dismissNotification', const {});
    expect(notifications.current.value, isEmpty);
  });

  test('the action sentinels: empty title, negative duration, no chime',
      () async {
    await show({
      'message': 'Front door opened',
      'title': '',
      'duration': -1,
      'type': '',
      'chime': false,
    });
    final shown = notifications.current.value.single;
    expect(shown.title, isNull);
    expect(shown.level, NotificationLevel.info);
    expect(executed, isEmpty);
    // A negative duration means "the default", not "gone at once".
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(notifications.current.value, hasLength(1));
  });

  test('scale takes decimals, clamps, and reads 0 as the ordinary size',
      () async {
    await show({'message': 'Half again as big', 'scale': 1.5, 'duration': 0});
    expect(notifications.current.value.first.scale, 1.5);
    // The action cannot leave a number out, so 0 means "as usual".
    await show({'message': 'Ordinary', 'scale': 0, 'duration': 0});
    expect(notifications.current.value.first.scale, 1);
    await show({'message': 'Too big', 'scale': 12, 'duration': 0});
    expect(
      notifications.current.value.first.scale,
      NotificationManager.maxScale,
    );
    // Under one would be smaller than the design, not larger.
    await show({'message': 'Too small', 'scale': 0.2, 'duration': 0});
    expect(notifications.current.value.first.scale, 1);
    // REST and JS callers send strings.
    await show({'message': 'From REST', 'scale': '2.5', 'duration': 0});
    expect(notifications.current.value.first.scale, 2.5);
  });

  test('an icon name is kept, prefix and case and all', () async {
    await show({
      'message': 'Laundry',
      'icon': 'mdi:washing-machine',
      'duration': 0,
    });
    expect(notifications.current.value.first.icon, 'washing-machine');
    // The action sends an empty string when the caller wants the icon
    // the type picks, and nonsense must not become a blank circle.
    await show({'message': 'No icon', 'icon': '', 'duration': 0});
    expect(notifications.current.value.first.icon, isNull);
    await show({'message': 'Bad icon', 'icon': 'not an icon!', 'duration': 0});
    expect(notifications.current.value.first.icon, isNull);
  });

  test('a call with nothing to say is refused', () async {
    final result = await commands.execute('showNotification', {
      'message': '',
      'title': '',
    });
    expect(result.ok, isFalse);
    expect(notifications.current.value, isEmpty);
  });

  test('string arguments from the REST and JS callers are understood',
      () async {
    await show({
      'message': 'Alarm armed',
      'duration': '0',
      'type': 'SUCCESS',
      'chime': 'false',
    });
    expect(
      notifications.current.value.single.level,
      NotificationLevel.success,
    );
    expect(executed, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(notifications.current.value, hasLength(1));
  });

  test('the ESPHome action declares every argument the command reads',
      () async {
    SharedPreferences.setMockInitialValues({});
    final log = Logger();
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    final surface = EspEntitySurface(bus, commands, log, settings);
    final service = surface.buildServices().single;
    expect(service['name'], 'notification');
    expect(
      [for (final arg in service['args']! as List) (arg as Map)['name']],
      // Order is API: the wire carries values positionally.
      ['message', 'title', 'duration', 'type', 'chime', 'scale', 'icon'],
    );

    await surface.handleService('notification', {
      'message': 'Dinner is ready',
      'title': '',
      'duration': 0,
      'type': 'success',
      'chime': true,
      'scale': 0,
      'icon': '',
    });
    final shown = notifications.current.value.single;
    expect(shown.message, 'Dinner is ready');
    expect(shown.title, isNull);
    expect(shown.level, NotificationLevel.success);
  });

  testWidgets('the overlay stacks at the top and dismisses card by card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              NotificationOverlay(notifications: notifications),
            ],
          ),
        ),
      ),
    );
    await show({
      'message': 'Washing machine finished',
      'title': 'Utility room',
      'duration': 0,
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Washing machine finished'), findsOneWidget);
    expect(find.text('Utility room'), findsOneWidget);

    // Read from across a room: bigger than the app's own toast (14.5/13).
    final title = tester.widget<Text>(find.text('Utility room'));
    final message = tester.widget<Text>(find.text('Washing machine finished'));
    expect(title.style!.fontSize, greaterThanOrEqualTo(22));
    expect(message.style!.fontSize, greaterThanOrEqualTo(18));

    // Top of the screen, not the bottom where the toast lives.
    final box = tester.getRect(find.byType(NotificationOverlay));
    final first = tester.getRect(find.text('Utility room'));
    expect(first.top, lessThan(box.height / 2));

    await show({'message': 'Front door opened', 'duration': 0});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Front door opened'), findsOneWidget);
    // Both on screen, the newest above the one it joined.
    expect(
      tester.getRect(find.text('Front door opened')).top,
      lessThan(tester.getRect(find.text('Utility room')).top),
    );

    // A scaled card draws everything larger, type included.
    await show({
      'message': 'Read me from the kitchen',
      'title': 'Big',
      'duration': 0,
      'scale': 2.5,
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final big = tester.widget<Text>(find.text('Big'));
    expect(big.style!.fontSize, 24 * 2.5);
    expect(
      tester.getSize(find.text('Read me from the kitchen')).height,
      greaterThan(
        tester.getSize(find.text('Washing machine finished')).height,
      ),
    );
    await tester.tap(find.text('Read me from the kitchen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // A tap takes down that card and leaves the other standing.
    await tester.tap(find.text('Front door opened'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Front door opened'), findsNothing);
    expect(find.text('Washing machine finished'), findsOneWidget);
    expect(onScreen(), ['Washing machine finished']);
  });
}
