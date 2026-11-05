import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/alarms/alarm_model.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;

/// The alarm list's storage and the ring arithmetic: which alarm rings
/// next and when, across days, weeks and midnight, for repeating and one
/// time alarms. 2026-10-02 is a Friday.
void main() {
  Alarm alarm(
    String time, {
    List<int> days = const [],
    String? date,
    bool on = true,
    String id = 'a',
  }) => Alarm.fromJson({
    'id': id,
    'time': time,
    'days': days,
    'date': ?date,
    'on': on,
  })!;

  group('storage', () {
    test('round trips every field', () {
      const source = Alarm(
        id: 'x1',
        hour: 6,
        minute: 30,
        days: [1, 2, 3, 4, 5],
        label: 'Wake up',
        tone: 'rooster.mp3',
        sunrise: true,
      );
      final back = decodeAlarms(encodeAlarms([source])).single;
      expect(back.id, 'x1');
      expect(back.time, '06:30');
      expect(back.days, [1, 2, 3, 4, 5]);
      expect(back.label, 'Wake up');
      expect(back.tone, 'rooster.mp3');
      expect(back.sunrise, isTrue);
      expect(back.on, isTrue);
    });

    test('keeps the ease choice, the speech switch and the phrase', () {
      const source = Alarm(
        id: 'x2',
        hour: 7,
        minute: 0,
        ease: false,
        speak: true,
        phrase: 'Up, {label}',
      );
      final back = decodeAlarms(encodeAlarms([source])).single;
      expect(back.ease, isFalse);
      expect(back.speak, isTrue);
      expect(back.phrase, 'Up, {label}');
      // An alarm that never chose keeps following the default.
      final plain = decodeAlarms('[{"id":"p","time":"07:00"}]').single;
      expect(plain.ease, isNull);
      expect(plain.speak, isFalse);
      expect(plain.phrase, isEmpty);
      expect(plain.copyWith(ease: () => true).ease, isTrue);
      expect(source.copyWith(ease: () => null).ease, isNull);
    });

    test('drops bad entries and repeated ids instead of the whole list', () {
      final list = decodeAlarms(
        '[{"id":"a","time":"07:00"},{"id":"b","time":"25:00"},'
        '"nonsense",{"id":"a","time":"08:00"},{"id":"c","time":"09:15",'
        '"days":[9,3,3,-1]}]',
      );
      expect(list.map((a) => a.id), ['a', 'c']);
      expect(list.last.days, [3]);
      expect(decodeAlarms('not json'), isEmpty);
    });

    test('the setting refuses a list that is not alarms', () {
      expect(defs.validateAlarmsList('[]'), isNull);
      expect(defs.validateAlarmsList('[{"time":"06:30"}]'), isNull);
      expect(defs.validateAlarmsList('[{"time":"6:30"}]'), isNotNull);
      expect(defs.validateAlarmsList('{}'), isNotNull);
      expect(defs.validateAlarmsList('oops'), isNotNull);
    });

    test('sorts by time of day', () {
      final sorted = sortAlarms([
        alarm('22:30', id: 'late'),
        alarm('06:00', id: 'early'),
        alarm('13:15', id: 'noon'),
      ]);
      expect(sorted.map((a) => a.id), ['early', 'noon', 'late']);
    });
  });

  group('next ring', () {
    final friday7am = DateTime(2026, 10, 2, 7);

    test('a weekday alarm already past today rings Monday', () {
      expect(
        nextRing(alarm('06:30', days: [1, 2, 3, 4, 5]), friday7am),
        DateTime(2026, 10, 5, 6, 30),
      );
    });

    test('a weekday alarm still ahead rings today', () {
      expect(
        nextRing(alarm('08:00', days: [1, 2, 3, 4, 5]), friday7am),
        DateTime(2026, 10, 2, 8),
      );
    });

    test('an every day alarm crosses midnight', () {
      expect(
        nextRing(
          alarm('00:15', days: [0, 1, 2, 3, 4, 5, 6]),
          DateTime(2026, 10, 2, 23, 50),
        ),
        DateTime(2026, 10, 3, 0, 15),
      );
    });

    test('the exact ring minute counts as past', () {
      expect(
        nextRing(alarm('07:00', days: [5]), friday7am),
        DateTime(2026, 10, 9, 7),
      );
      expect(lastRing(alarm('07:00', days: [5]), friday7am), friday7am);
    });

    test('a one time alarm rings on its date and then never', () {
      final once = alarm('06:30', date: '2026-10-03');
      expect(nextRing(once, friday7am), DateTime(2026, 10, 3, 6, 30));
      expect(nextRing(once, DateTime(2026, 10, 3, 6, 31)), isNull);
      expect(
        lastRing(once, DateTime(2026, 10, 3, 6, 31)),
        DateTime(2026, 10, 3, 6, 30),
      );
      expect(lastRing(once, friday7am), isNull);
    });

    test('an alarm that is off never rings', () {
      expect(nextRing(alarm('08:00', days: [5], on: false), friday7am), isNull);
      expect(lastRing(alarm('06:00', days: [5], on: false), friday7am), isNull);
    });

    test('the latest ring of a weekday alarm on a Saturday is Friday', () {
      expect(
        lastRing(
          alarm('06:30', days: [1, 2, 3, 4, 5]),
          DateTime(2026, 10, 3, 9),
        ),
        DateTime(2026, 10, 2, 6, 30),
      );
    });

    test('the next ring across the list is the soonest', () {
      final next = nextOf([
        alarm('09:00', days: [5], id: 'later'),
        alarm('08:00', days: [5], id: 'sooner'),
        alarm('07:30', days: [5], id: 'off', on: false),
      ], friday7am);
      expect(next?.alarm.id, 'sooner');
      expect(next?.at, DateTime(2026, 10, 2, 8));
    });

    test('a one time alarm set now rings today or tomorrow', () {
      expect(onceDate(8, 0, friday7am), '2026-10-02');
      expect(onceDate(6, 0, friday7am), '2026-10-03');
      expect(onceDate(7, 0, friday7am), '2026-10-03');
    });
  });

  test('repeat summaries', () {
    expect(repeatWord([0, 1, 2, 3, 4, 5, 6]), 'Every day');
    expect(repeatWord([1, 2, 3, 4, 5]), 'Weekdays');
    expect(repeatWord([0, 6]), 'Weekends');
    expect(repeatWord([1, 3, 5]), isNull);
    expect(repeatWord(const []), isNull);
  });

  group('fillAlarmPhrase', () {
    String fill(String t, {String label = '', String name = ''}) =>
        fillAlarmPhrase(
          t,
          label: label,
          name: name,
          time: '7:00 AM',
          hour: '7',
          minute: '5',
          date: 'October 2, 2026',
          day: 'Friday',
          dayOfMonth: '2',
          month: 'October',
          year: '2026',
        );

    test('fills every placeholder', () {
      expect(
        fill("It's {time} on {day}. {label}", label: 'Gym'),
        "It's 7:00 AM on Friday. Gym",
      );
    });

    test('fills the hour, the minute and the date on their own', () {
      expect(
        fill(
          '{hour} hours and {minute} minutes on the {dayofmonth} of {month}, {year}',
        ),
        '7 hours and 5 minutes on the 2 of October, 2026',
      );
      expect(fill('Today is {date}'), 'Today is October 2, 2026');
    });

    test('{day} stays the day of the week', () {
      expect(fill('Happy {day}'), 'Happy Friday');
    });

    test('an empty name leaves no stray punctuation', () {
      expect(fill('Good morning {name}! {time}'), 'Good morning! 7:00 AM');
      expect(fill('{name}, wake up'), 'wake up');
      expect(fill('Hi {name}. {label}', name: 'Sam'), 'Hi Sam.');
      expect(fill('{label} {name} at {time}'), 'at 7:00 AM');
    });

    test('a label that reads like a variable stays as it is', () {
      expect(fill('{label}', label: '{time}'), '{time}');
    });

    test('an unknown variable stays as it is', () {
      expect(fill('{weather} at {time}'), '{weather} at 7:00 AM');
    });

    test('an empty label leaves no stray punctuation', () {
      expect(fill("It's {time}. {label}"), "It's 7:00 AM.");
      expect(fill('{label}, time to get up'), 'time to get up');
      expect(fill('Wake up {label}!'), 'Wake up!');
      expect(fill('Good morning, {label}. {time}'), 'Good morning. 7:00 AM');
    });

    test('a phrase without placeholders is left alone', () {
      expect(fill('Rise and shine'), 'Rise and shine');
      expect(fill('Wait... really?! {time}'), 'Wait... really?! 7:00 AM');
      expect(fill('Hello, {label} how are you'), 'Hello, how are you');
    });
  });
}
