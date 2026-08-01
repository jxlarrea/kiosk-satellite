import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/lrclib.dart';
import 'package:kiosk_satellite/managers/sendspin/lyrics.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';

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

  test("the format's own offset tag shifts every line", () {
    // Positive offset means the lines belong later in the track.
    final later = parseLrc('[offset:+500]\n[00:10.00] one\n[00:20.00] two');
    expect(later[0].at, const Duration(milliseconds: 10500));
    expect(later[1].at, const Duration(milliseconds: 20500));
    final earlier = parseLrc('[offset:-2000]\n[00:10.00] one');
    expect(earlier.single.at, const Duration(seconds: 8));
    // A shift past the start of the track clamps rather than going negative.
    expect(parseLrc('[offset:-5000]\n[00:01.00] x').single.at, Duration.zero);
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

  group('pickLrclibLyrics (issue #90 fallback)', () {
    test('a sloppy credit still matches the primary artist, duration first',
        () {
      final results = <Object?>[
        {'syncedLyrics': null, 'plainLyrics': 'words', 'duration': 197.0},
        {
          'syncedLyrics': '[00:01.00] wrong edition',
          'artistName': "The Porter's Gate",
          'duration': 240.0,
        },
        {
          'syncedLyrics': '[00:27.32] Brother sun',
          'artistName': "The Porter's Gate, ve, Liz Vice",
          'duration': 198.0,
        },
      ];
      expect(
        pickLrclibLyrics(
          results,
          artist: "The Porter's Gate",
          durationSeconds: 197,
        ),
        '[00:27.32] Brother sun',
      );
    });

    test('artist match beats duration match when both cannot hold', () {
      final results = <Object?>[
        {
          'syncedLyrics': '[00:01.00] same length, someone else',
          'artistName': 'Somebody Else',
          'duration': 197.0,
        },
        {
          'syncedLyrics': '[00:02.00] right artist, other edition',
          'artistName': 'Phoebe Bridgers',
          'duration': 260.0,
        },
      ];
      expect(
        pickLrclibLyrics(
          results,
          artist: 'Phoebe Bridgers',
          durationSeconds: 197,
        ),
        '[00:02.00] right artist, other edition',
      );
    });

    test('a bare title never takes an unconstrained match', () {
      final results = <Object?>[
        {
          'syncedLyrics': '[00:01.00] wrong song entirely',
          'artistName': 'Somebody Else',
          'duration': 500.0,
        },
      ];
      expect(
        pickLrclibLyrics(results, artist: 'Adele', durationSeconds: 197),
        isNull,
      );
      expect(pickLrclibLyrics(results), isNull);
    });

    test('with a known artist, a right-length namesake is never taken', () {
      // The "Souvenir" case: an Italian song of the same title and nearly
      // the same runtime must not pass just because the duration fits.
      final results = <Object?>[
        {
          'syncedLyrics': '[00:05.00] parole in italiano',
          'artistName': 'Cantante Italiano',
          'duration': 198.0,
        },
      ];
      expect(
        pickLrclibLyrics(
          results,
          artist: 'Phoebe Bridgers',
          durationSeconds: 197,
        ),
        isNull,
      );
      // Without an artist to check, the duration remains the only signal.
      expect(
        pickLrclibLyrics(results, durationSeconds: 197),
        '[00:05.00] parole in italiano',
      );
    });

    test('nothing synced means nothing', () {
      expect(
        pickLrclibLyrics(<Object?>[
          {'plainLyrics': 'text only', 'duration': 100.0},
          'junk',
        ], durationSeconds: 100),
        isNull,
      );
      expect(pickLrclibLyrics(const []), isNull);
    });
  });

  group('lyricsRetryArtist (issue #90)', () {
    test('a slash-joined credit yields the primary artist', () {
      expect(
        lyricsRetryArtist("The Porter's Gate/Liz Vice"),
        "The Porter's Gate",
      );
      expect(lyricsRetryArtist('Phoenix/Clairo/Someone'), 'Phoenix');
      expect(lyricsRetryArtist('A / B'), 'A');
    });

    test('a single artist offers no retry, slash in the name or not', () {
      expect(lyricsRetryArtist('Adele'), isNull);
      // "AC/DC" only reaches the retry after the whole name missed, and
      // "AC" is a different string, so a retry is still offered.
      expect(lyricsRetryArtist('AC/DC'), 'AC');
      expect(lyricsRetryArtist(''), isNull);
      expect(lyricsRetryArtist('/leading'), isNull);
    });
  });
}
