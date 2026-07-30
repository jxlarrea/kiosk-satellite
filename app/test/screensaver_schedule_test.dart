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

    test('garbage input is an empty schedule', () {
      expect(parseScreensaverSchedule('not json'), isEmpty);
      expect(parseScreensaverSchedule('{"at":"08:00"}'), isEmpty);
      expect(parseScreensaverSchedule('[]'), isEmpty);
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
