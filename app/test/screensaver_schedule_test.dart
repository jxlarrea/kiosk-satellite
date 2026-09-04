import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';

void main() {
  group('parseScreensaverSchedule', () {
    test('parses, sorts by time and clamps brightness', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"19:00","mode":"black","brightness":2},'
          '{"at":"07:30","mode":"clock","brightness":0.4}]');
      expect(entries, hasLength(2));
      expect(entries.first['at'], '07:30');
      expect(entries.first['brightness'], 0.4);
      expect(entries.last['at'], '19:00');
      expect(entries.last['brightness'], 1);
    });

    test('drops malformed entries, keeps the valid ones', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"25:00","mode":"clock"},{"mode":"clock"},'
          '{"at":"08:00"},{"at":"08:00","mode":"dim"},"junk"]');
      expect(entries, hasLength(1));
      expect(entries.single['mode'], 'dim');
    });

    test('an entry without brightness stays without one', () {
      final entries =
          parseScreensaverSchedule('[{"at":"08:00","mode":"dim"}]');
      expect(entries.single.containsKey('brightness'), isFalse);
    });

    test('the motion override passes through only as a bool', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"08:00","mode":"clock","motion":true},'
          '{"at":"20:00","mode":"black","motion":false},'
          '{"at":"22:00","mode":"black","motion":"yes"},'
          '{"at":"23:00","mode":"black"}]');
      expect(entries[0]['motion'], isTrue);
      expect(entries[1]['motion'], isFalse);
      expect(entries[2].containsKey('motion'), isFalse);
      expect(entries[3].containsKey('motion'), isFalse);
    });

    test('the face override passes through only as a bool (issue #304)', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"08:00","mode":"clock","face":true},'
          '{"at":"20:00","mode":"black","face":false,"motion":true},'
          '{"at":"22:00","mode":"black","face":1},'
          '{"at":"23:00","mode":"black"}]');
      expect(entries[0]['face'], isTrue);
      expect(entries[0].containsKey('motion'), isFalse);
      expect(entries[1]['face'], isFalse);
      expect(entries[1]['motion'], isTrue);
      expect(entries[2].containsKey('face'), isFalse);
      expect(entries[3].containsKey('face'), isFalse);
    });

    test('the widgets override passes through only as a bool', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"08:00","mode":"clock","widgets":true},'
          '{"at":"20:00","mode":"clock","widgets":false},'
          '{"at":"22:00","mode":"black","widgets":"off"},'
          '{"at":"23:00","mode":"black"}]');
      expect(entries[0]['widgets'], isTrue);
      expect(entries[1]['widgets'], isFalse);
      // A widgets-less entry keeps no key at all, which is what the UI
      // layer reads as "follow the Widgets group".
      expect(entries[2].containsKey('widgets'), isFalse);
      expect(entries[3].containsKey('widgets'), isFalse);
    });

    test('the glance override passes through only as a bool', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"08:00","mode":"black","glance":true},'
          '{"at":"20:00","mode":"black","glance":false},'
          '{"at":"22:00","mode":"black","glance":1},'
          '{"at":"23:00","mode":"black"}]');
      expect(entries[0]['glance'], isTrue);
      expect(entries[1]['glance'], isFalse);
      expect(entries[2].containsKey('glance'), isFalse);
      expect(entries[3].containsKey('glance'), isFalse);
    });

    test('the overrides are independent of each other', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"08:00","mode":"clock","motion":true,"widgets":false,'
          '"glance":true,"brightness":0.4}]');
      expect(entries.single['motion'], isTrue);
      expect(entries.single['widgets'], isFalse);
      expect(entries.single['glance'], isTrue);
      expect(entries.single['brightness'], 0.4);
    });

    test('the proximity and person overrides pass through only as bools '
        '(issue #437)', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"08:00","mode":"clock","proximity":true,"person":false},'
          '{"at":"20:00","mode":"black","proximity":"on","person":1},'
          '{"at":"23:00","mode":"black"}]');
      expect(entries[0]['proximity'], isTrue);
      expect(entries[0]['person'], isFalse);
      expect(entries[1].containsKey('proximity'), isFalse);
      expect(entries[1].containsKey('person'), isFalse);
      expect(entries[2].containsKey('proximity'), isFalse);
      expect(entries[2].containsKey('person'), isFalse);
    });

    test('the screen-off minutes pass through clamped, as a whole number '
        '(issue #437)', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"08:00","mode":"clock","screen_off":0},'
          '{"at":"20:00","mode":"black","screen_off":90},'
          '{"at":"22:00","mode":"black","screen_off":"10"},'
          '{"at":"23:00","mode":"black"}]');
      expect(entries[0]['screen_off'], 0);
      expect(entries[1]['screen_off'], 60);
      expect(entries[1]['screen_off'], isA<int>());
      expect(entries[2].containsKey('screen_off'), isFalse);
      expect(entries[3].containsKey('screen_off'), isFalse);
    });

    test('garbage input is an empty schedule', () {
      expect(parseScreensaverSchedule('not json'), isEmpty);
      expect(parseScreensaverSchedule('{"at":"08:00"}'), isEmpty);
      expect(parseScreensaverSchedule('[]'), isEmpty);
    });
  });

  group('upsertScheduleEntry', () {
    // The editors decode the stored JSON afresh on every read, so an edited
    // entry is never the same object as the one in the list being written.
    // Matching by identity appended a duplicate instead of replacing it.
    test('an edit replaces the entry at its position', () {
      final entries = parseScreensaverSchedule(
          '[{"at":"07:00","mode":"clock"},{"at":"19:00","mode":"black"}]');
      final edited = {'at': '20:00', 'mode': 'black', 'widgets': false};
      final next = upsertScheduleEntry(entries, edited, 1);
      expect(next, hasLength(2));
      expect(next[0]['at'], '07:00');
      expect(next[1]['at'], '20:00');
      expect(next[1]['widgets'], isFalse);
    });

    test('no index adds a time', () {
      final entries = parseScreensaverSchedule('[{"at":"07:00","mode":"clock"}]');
      final next = upsertScheduleEntry(entries, {'at': '19:00', 'mode': 'black'}, null);
      expect(next, hasLength(2));
    });

    test('an index past the end adds rather than throws', () {
      final entries = parseScreensaverSchedule('[{"at":"07:00","mode":"clock"}]');
      final next = upsertScheduleEntry(entries, {'at': '19:00', 'mode': 'black'}, 5);
      expect(next, hasLength(2));
      expect(next.last['at'], '19:00');
    });

    test('the source list is left alone', () {
      final entries = parseScreensaverSchedule('[{"at":"07:00","mode":"clock"}]');
      upsertScheduleEntry(entries, {'at': '19:00', 'mode': 'black'}, null);
      expect(entries, hasLength(1));
    });
  });

  group('activeScheduleEntry', () {
    final entries = parseScreensaverSchedule(
        '[{"at":"07:00","mode":"clock"},{"at":"19:00","mode":"black"}]');

    test('the latest entry at or before now is in force', () {
      expect(activeScheduleEntry(entries, 8 * 60)!['mode'], 'clock');
      expect(activeScheduleEntry(entries, 20 * 60)!['mode'], 'black');
      expect(activeScheduleEntry(entries, 19 * 60)!['mode'], 'black');
    });

    test('before the first entry, yesterday\'s last still holds', () {
      expect(activeScheduleEntry(entries, 3 * 60)!['mode'], 'black');
    });

    test('an empty schedule has no entry', () {
      expect(activeScheduleEntry(const [], 8 * 60), isNull);
    });
  });
}
