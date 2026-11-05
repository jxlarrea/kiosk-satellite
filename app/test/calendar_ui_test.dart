import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_manager.dart';
import 'package:kiosk_satellite/managers/calendar/calendar_model.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_widgets.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/calendar_editor.dart';
import 'package:kiosk_satellite/ui/calendar_overlay.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart'
    show CalendarWidgetOverlay;
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _calendars =
    '[{"entity":"calendar.leo","name":"Leo","color":"168,122,31"},'
    '{"entity":"calendar.sam","name":"Sam","color":"192,97,58"},'
    '{"entity":"calendar.maya","name":"Maya","color":"138,90,156"}]';

/// A busy week around today: a shared event, an all-day one, a trip over
/// two days and overlapping events.
List<CalendarEvent> _week() {
  final today = dateOnly(DateTime.now());
  DateTime at(int day, int h, [int m = 0]) =>
      DateTime(today.year, today.month, today.day + day, h, m);
  CalendarEvent e(
    String title,
    DateTime start,
    DateTime end,
    List<String> calendars, {
    bool allDay = false,
    String location = '',
  }) => CalendarEvent(
    summary: title,
    start: start,
    end: end,
    allDay: allDay,
    calendars: calendars,
    location: location,
  );
  return [
    e('Recycling pickup', at(0, 0), at(1, 0), ['calendar.sam'], allDay: true),
    e('Denver trip', at(2, 0), at(4, 0), ['calendar.sam'], allDay: true),
    e('Team standup', at(0, 9), at(0, 9, 30), ['calendar.sam']),
    e('Dentist', at(0, 11, 30), at(0, 12, 15), [
      'calendar.maya',
    ], location: 'Bright Smile Dental'),
    e('Choir', at(0, 15, 30), at(0, 16, 30), ['calendar.maya']),
    e(
      'Soccer practice with a long name',
      at(0, 16),
      at(0, 17, 30),
      ['calendar.leo', 'calendar.sam'],
      location: 'Riverside Park, Field 2',
    ),
    e('Taco night', at(0, 18, 30), at(0, 19, 30), ['calendar.leo']),
    e('Gym', at(1, 6, 30), at(1, 7, 30), ['calendar.sam']),
    e('Piano lesson', at(1, 15, 30), at(1, 16, 15), ['calendar.maya']),
    e('Book club', at(1, 19), at(1, 20, 30), ['calendar.sam']),
    for (var i = 0; i < 6; i++)
      e('Extra $i', at(3, 8 + i), at(3, 9 + i), ['calendar.leo']),
  ]..sort(compareEvents);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppContainer> container() async {
    SharedPreferences.setMockInitialValues({
      // No Home Assistant: the manager stays offline and the test feeds
      // the events itself.
      'ks.ha.url': '',
      'ks.ha.token': '',
      'ks.calendar.calendars': _calendars,
    });
    final c = AppContainer();
    await c.settings.init();
    await c.calendar.init();
    return c;
  }

  Future<void> letGo(WidgetTester tester, AppContainer c) async {
    c.calendar.visible.value = false;
    await tester.pump();
    // The socket closes a minute after the last screen lets go.
    await tester.pump(const Duration(seconds: 61));
  }

  for (final (name, size) in [
    ('a tablet', const Size(1280, 800)),
    ('a tablet in portrait', const Size(753, 1205)),
    ('an Echo Show 5', const Size(960, 480)),
    // Its real logical size at density 195.
    ('an Echo Show 5 at 1.22x', const Size(788, 394)),
    ('a phone', const Size(390, 844)),
  ]) {
    testWidgets('every view draws on $name', (tester) async {
      final c = await container();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      c.calendar.opening = (view: 'week', date: null);
      c.calendar.visible.value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [CalendarOverlay(container: c)]),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      c.calendar.snapshot.value = CalendarSnapshot(
        events: _week(),
        link: CalendarLink.live,
      );
      for (final view in ['Day', 'Week', 'Month', 'Schedule']) {
        // Through the manager, as the remote and ESPHome switch it: on a
        // small screen the switcher scrolls and a tap could miss.
        c.calendar.opening = (view: view.toLowerCase(), date: null);
        c.calendar.reopened.value++;
        await tester.pump(const Duration(milliseconds: 100));
        // A wider span subscribes again, which fails here without Home
        // Assistant: feed the events once more.
        c.calendar.snapshot.value = CalendarSnapshot(
          events: _week(),
          link: CalendarLink.live,
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull, reason: '$view on $name');
        // A month too small to list events shows dots instead.
        if (view != 'Month' || size.height >= 400) {
          expect(find.text('Recycling pickup'), findsWidgets, reason: view);
        }
      }
      // The shared event opens with both calendars named.
      c.calendar.opening = (view: 'day', date: null);
      c.calendar.reopened.value++;
      await tester.pump(const Duration(milliseconds: 100));
      c.calendar.snapshot.value = CalendarSnapshot(
        events: _week(),
        link: CalendarLink.live,
      );
      await tester.pump(const Duration(milliseconds: 50));
      final soccer = find.text('Soccer practice with a long name').first;
      await tester.ensureVisible(soccer);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(soccer);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Leo and Sam'), findsOneWidget);
      expect(find.text('Riverside Park, Field 2'), findsWidgets);
      expect(tester.takeException(), isNull);
      // Read only until Settings > Calendar > Editing says otherwise.
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      await tester.tap(find.text('Done'));
      await tester.pump(const Duration(milliseconds: 300));
      await letGo(tester, c);
    });
  }

  for (final (name, size) in [
    ('a tablet', const Size(1280, 800)),
    ('an Echo Show 5', const Size(960, 480)),
    ('an Echo Show 5 at 1.22x', const Size(788, 394)),
    ('a phone', const Size(390, 844)),
  ]) {
    testWidgets('adding, editing and deleting draw on $name', (tester) async {
      final c = await container();
      await c.settings.set(defs.calendarAllowEdit, true);
      await c.settings.set(defs.calendarAllowDelete, true);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      c.calendar.opening = (view: 'week', date: null);
      c.calendar.visible.value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [CalendarOverlay(container: c)]),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      Future<void> feed() async {
        c.calendar.snapshot.value = CalendarSnapshot(
          events: _week(),
          link: CalendarLink.live,
        );
        await tester.pump(const Duration(milliseconds: 50));
      }

      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await feed();
      expect(tester.takeException(), isNull, reason: 'week on $name');

      // New event: a pill on a tablet, a disc on a short panel, a button
      // at the bottom right on a phone.
      final add = size.width >= 640 && size.height < 600
          ? find.byTooltip('New event')
          : find.text('New event');
      expect(add, findsOneWidget);
      // The form is a route above the kiosk's own touch Listener: its
      // touches are reported for the screensaver's idle clock.
      final touches = <ActivityDetected>[];
      final heard = c.bus.on<ActivityDetected>().listen(touches.add);
      addTearDown(heard.cancel);
      await tester.tap(add);
      await settle();
      expect(find.text('Add a title'), findsOneWidget);
      touches.clear();
      await tester.tap(find.text('All day').last);
      await tester.pump();
      expect(touches.map((t) => t.source), ['touch']);
      expect(find.text('Leo'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'form on $name');
      await tester.enterText(
        find.widgetWithText(TextField, 'Add a title'),
        'Haircut',
      );
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await settle();
      expect(find.text('Add a title'), findsNothing);

      // An event opens with Delete and Edit, Edit opens the form filled
      // in, and a cancelled form comes back to the event.
      c.calendar.opening = (view: 'day', date: null);
      c.calendar.reopened.value++;
      await tester.pump(const Duration(milliseconds: 100));
      await feed();
      final soccer = find.text('Soccer practice with a long name').first;
      await tester.ensureVisible(soccer);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(soccer);
      await settle();
      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await settle();
      expect(find.text('Edit event'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Soccer practice with a long name'),
        findsOneWidget,
      );
      expect(find.text('Shows once, split between their colors.'), findsOne);
      expect(tester.takeException(), isNull, reason: 'edit on $name');
      await tester.tap(find.text('Cancel'));
      await settle();
      expect(find.text('Edit event'), findsNothing);
      await tester.tap(find.text('Delete'));
      await settle();
      expect(find.text('Delete Soccer practice with a long name?'), findsOne);
      expect(
        find.text(
          'It comes off every calendar it is on: Leo and Sam.',
          findRichText: true,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull, reason: 'delete on $name');
      await tester.tap(find.text('Cancel'));
      await settle();
      await tester.tap(find.text('Done'));
      await settle();

      // A tap on an empty hour of an empty day drops the slot, and the
      // slot opens New event.
      c.calendar.opening = (
        view: 'day',
        date: addDays(dateOnly(DateTime.now()), 5),
      );
      c.calendar.reopened.value++;
      await tester.pump(const Duration(milliseconds: 100));
      await feed();
      // The hours: the one vertical scrollable of the Day view.
      final hours = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      final box = tester.getRect(hours.last);
      await tester.tapAt(Offset(box.right - 30, box.center.dy));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CalendarSlot), findsOneWidget);
      await tester.tap(find.byType(CalendarSlot));
      await settle();
      expect(find.text('Add a title'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle();
      await letGo(tester, c);
    });
  }

  testWidgets('the screensaver calendar stays read only', (tester) async {
    final c = await container();
    await c.settings.set(defs.calendarAllowEdit, true);
    await c.settings.set(defs.calendarAllowDelete, true);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CalendarScreen(container: c, screensaver: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    c.calendar.snapshot.value = CalendarSnapshot(
      events: _week(),
      link: CalendarLink.live,
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('New event'), findsNothing);
    final touches = <ActivityDetected>[];
    final heard = c.bus.on<ActivityDetected>().listen(touches.add);
    addTearDown(heard.cancel);
    await tester.tap(find.text('Taco night').first);
    await tester.pump(const Duration(milliseconds: 300));
    // A touch report would end the screensaver.
    await tester.tap(find.text('Taco night').last);
    await tester.pump();
    expect(touches, isEmpty);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('a hidden chip takes its calendar off the screen', (
    tester,
  ) async {
    final c = await container();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    c.calendar.opening = (view: 'week', date: null);
    c.calendar.visible.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [CalendarOverlay(container: c)]),
        ),
      ),
    );
    c.calendar.snapshot.value = CalendarSnapshot(
      events: _week(),
      link: CalendarLink.live,
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Choir'), findsOneWidget);
    await tester.tap(find.text('Maya'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.calendar.hidden.value, {'calendar.maya'});
    expect(find.text('Choir'), findsNothing);
    // A shared event stays while one of its people shows.
    await tester.tap(find.text('Sam'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Soccer practice with a long name'), findsOneWidget);
    await letGo(tester, c);
  });

  testWidgets('the Today panel reaches every event left today', (tester) async {
    final c = await container();
    // A tablet just tall enough for the roomy layout, where the date and Up
    // next fill the panel.
    tester.view.physicalSize = const Size(961, 601);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    c.calendar.opening = (view: 'schedule', date: null);
    c.calendar.visible.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [CalendarOverlay(container: c)]),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    // Spread over what is left of today, whatever the time.
    final now = DateTime.now();
    final left = addDays(dateOnly(now), 1).difference(now);
    c.calendar.snapshot.value = CalendarSnapshot(
      events: [
        for (var i = 0; i < 6; i++)
          CalendarEvent(
            summary: 'Later $i',
            start: now.add(left * (i + 1) ~/ 8),
            end: now.add(left * (i + 1) ~/ 8 + left ~/ 16),
            allDay: false,
            calendars: const ['calendar.leo'],
            location: 'Room $i',
          ),
      ],
      link: CalendarLink.live,
    );
    await tester.pump(const Duration(milliseconds: 50));
    // One line: the header already names the month.
    expect(find.text(DateFormat.EEEE().add_d().format(now)), findsOneWidget);
    final last = find.text('Later 5');
    await tester.ensureVisible(last);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Room 5'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 300));
    await letGo(tester, c);
  });

  testWidgets('Up next marks events with pictures, or dots when asked', (
    tester,
  ) async {
    final c = await container();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Future<void> show(Map<String, Object?> config, {Color? night}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarWidgetOverlay(
              // A new key each time, so the widget starts over.
              key: UniqueKey(),
              container: c,
              spec: ScreensaverWidget(
                position: 'top_left',
                type: 'calendar',
                config: {...screensaverWidgetDefaults('calendar'), ...config},
              ),
              nightColor: night,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      // Spread over what is left of today, whatever the time.
      final now = DateTime.now();
      final left = addDays(dateOnly(now), 1).difference(now);
      c.calendar.snapshot.value = CalendarSnapshot(
        events: [
          for (final (i, (title, calendars)) in [
            ('Choir', ['calendar.maya']),
            ('Soccer', ['calendar.leo', 'calendar.sam']),
            ('Taco night', ['calendar.leo']),
          ].indexed)
            CalendarEvent(
              summary: title,
              start: now.add(left * (i + 1) ~/ 5),
              end: now.add(left * (i + 1) ~/ 5 + left ~/ 10),
              allDay: false,
              calendars: calendars,
            ),
        ],
        link: CalendarLink.live,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }

    final dots = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is CalendarBands,
    );
    // The pictures by default: without one, the name's initial on the
    // calendar's color, and both people on the shared event.
    await show(const {});
    expect(find.byType(CalendarAvatarStack), findsNWidgets(3));
    expect(find.text('L'), findsNWidgets(2));
    expect(find.text('S'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(dots, findsNothing);
    // The shared event's wider stack does not push its title out of line.
    final x = tester.getTopLeft(find.text('Choir')).dx;
    expect(tester.getTopLeft(find.text('Soccer')).dx, x);
    expect(tester.getTopLeft(find.text('Taco night')).dx, x);

    // Colored dots: one per event, no pictures.
    await show(const {'dots': true});
    expect(find.byType(CalendarAvatarStack), findsNothing);
    expect(dots, findsNWidgets(3));

    // Night mode keeps to the dots.
    await show(const {}, night: const Color(0xFF822222));
    expect(find.byType(CalendarAvatarStack), findsNothing);
    expect(dots, findsNWidgets(3));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('Up next leaves out all-day events when asked', (tester) async {
    final c = await container();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Future<void> show(Map<String, Object?> config) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarWidgetOverlay(
              // A new key each time, so the widget starts over.
              key: UniqueKey(),
              container: c,
              spec: ScreensaverWidget(
                position: 'top_left',
                type: 'calendar',
                config: config,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final now = DateTime.now();
      final today = dateOnly(now);
      final left = addDays(today, 1).difference(now);
      c.calendar.snapshot.value = CalendarSnapshot(
        events: [
          CalendarEvent(
            summary: 'Holiday',
            start: today,
            end: addDays(today, 1),
            allDay: true,
            calendars: const ['calendar.maya'],
          ),
          CalendarEvent(
            summary: 'Standup',
            start: now.add(left ~/ 3),
            end: now.add(left ~/ 2),
            allDay: false,
            calendars: const ['calendar.maya'],
          ),
        ],
        link: CalendarLink.live,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }

    // On by default, and all-day events come first.
    await show({...screensaverWidgetDefaults('calendar'), 'count': 1});
    expect(find.text('Holiday'), findsOneWidget);
    expect(find.text('Standup'), findsNothing);

    // A widget saved before the switch existed has no all_day key.
    await show(const {'count': 1});
    expect(find.text('Holiday'), findsOneWidget);

    // Off, the timed event gets the slot.
    await show(const {'count': 1, 'all_day': false});
    expect(find.text('Holiday'), findsNothing);
    expect(find.text('Standup'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('an empty week says so once, and the open view is reported', (
    tester,
  ) async {
    final c = await container();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final views = <String?>[];
    final sub = c.bus.on<CalendarViewChanged>().listen(
      (e) => views.add(e.view),
    );
    addTearDown(sub.cancel);
    c.calendar.opening = (view: 'week', date: null);
    c.calendar.visible.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [CalendarOverlay(container: c)]),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    c.calendar.snapshot.value = const CalendarSnapshot(link: CalendarLink.live);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Nothing planned this week'), findsOneWidget);
    expect(find.text('Nothing planned'), findsNothing);
    await tester.tap(find.text('Month').first);
    await tester.pump(const Duration(milliseconds: 50));
    await letGo(tester, c);
    expect(views, ['week', 'month', null]);
  });

  testWidgets(
    'as the screensaver it keeps the overlay opening, never idles out and '
    'its X ends the screensaver',
    (tester) async {
      final c = await container();
      var stops = 0;
      c.commands.register(
        Command(
          name: 'stopScreensaver',
          description: 'stub',
          handler: (_) async {
            stops++;
            return const CommandResult.ok();
          },
        ),
      );
      await c.settings.set(defs.calendarIdleCloseMinutes, '1');
      // Its own view, not the calendar's Default view.
      await c.settings.set(defs.calendarDefaultView, 'month');
      await c.settings.set(defs.screensaverCalendarView, 'day');
      c.calendar.opening = (view: 'schedule', date: null);
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CalendarScreen(container: c, screensaver: true)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(c.calendar.screensaverShown.value, isTrue);
      expect(c.calendar.shownView.value, 'day');
      // The opening waits for the overlay it was meant for.
      expect(c.calendar.opening.view, 'schedule');
      await tester.pump(const Duration(minutes: 2));
      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(stops, 0);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(stops, 1);
      // ESPHome's Closed and the remote close it the same way.
      await c.commands.execute('hideCalendar', const {});
      expect(stops, 2);
      expect(c.calendar.status()['visible'], isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(c.calendar.screensaverShown.value, isFalse);
      await tester.pump(const Duration(seconds: 61));
    },
  );

  testWidgets('Settings > Calendar lists the calendars over the definitions', (
    tester,
  ) async {
    final c = await container();
    c.homeAssistant.connectionOk.value = true;
    tester.view.physicalSize = const Size(500, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(container: c)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Calendar').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    for (final text in [
      'Open calendar',
      'Calendars',
      'Leo',
      'calendar.sam',
      'Add a calendar',
      'Default view',
      'Week starts on',
      'Weather',
      'Editing',
      'Allow adding and editing events',
      'Allow deleting events',
      'Show in the kiosk menu',
      'Close when idle',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(tester.takeException(), isNull);
  });
}
