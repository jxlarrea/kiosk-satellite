import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/lyrics.dart';

void main() {
  test('parses the format providers actually send', () {
    final lines = parseLrc(
      '[00:00.67] Is this the real life?\n'
      '[00:07.71] Caught in a landslide\n'
      '[01:15.15] Open your eyes\n',
    );
    expect(lines.map((l) => l.text).toList(), [
      'Is this the real life?',
      'Caught in a landslide',
      'Open your eyes',
    ]);
    expect(lines.first.at, const Duration(milliseconds: 670));
    expect(lines.last.at, const Duration(minutes: 1, seconds: 15, milliseconds: 150));
  });

  test('a repeated chorus becomes one entry per timestamp, in order', () {
    final lines = parseLrc('[00:30.00][02:10.50] Carry on\n[01:00.00] Verse');
    expect(lines.map((l) => l.text).toList(), ['Carry on', 'Verse', 'Carry on']);
    expect(lines[2].at, const Duration(minutes: 2, seconds: 10, milliseconds: 500));
  });

  test('metadata tags and blank lines are dropped', () {
    final lines = parseLrc('[ti:Song]\n[ar:Artist]\n\n[00:05.00] Real line\n[00:10.00]   ');
    expect(lines.length, 1);
    expect(lines.single.text, 'Real line');
  });

  test('both fraction lengths are read correctly', () {
    expect(parseLrc('[00:01.5] x').single.at, const Duration(milliseconds: 1050));
    expect(parseLrc('[00:01.50] x').single.at, const Duration(milliseconds: 1500));
    expect(parseLrc('[00:01.500] x').single.at, const Duration(milliseconds: 1500));
    // Some providers separate the fraction with a colon.
    expect(parseLrc('[00:01:50] x').single.at, const Duration(milliseconds: 1500));
  });

  test('unsynced lyrics yield nothing, since they cannot be followed', () {
    expect(parseLrc('Just some words\nAnd more words'), isEmpty);
    expect(parseLrc(''), isEmpty);
    expect(parseLrc(null), isEmpty);
  });

  test('the current line holds until the next one starts', () {
    final lines = parseLrc('[00:10.00] one\n[00:20.00] two\n[00:30.00] three');
    // Before the first line: nothing highlighted, songs open instrumental.
    expect(currentLyricIndex(lines, const Duration(seconds: 5)), -1);
    expect(currentLyricIndex(lines, const Duration(seconds: 10)), 0);
    expect(currentLyricIndex(lines, const Duration(seconds: 19)), 0);
    expect(currentLyricIndex(lines, const Duration(seconds: 20)), 1);
    // Past the end it stays on the last line rather than clearing.
    expect(currentLyricIndex(lines, const Duration(minutes: 5)), 2);
    expect(currentLyricIndex(const [], const Duration(seconds: 5)), -1);
  });
}
