import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/audiobook_chapters.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';

void main() {
  Map<String, Object?> book(List<Object?> chapters) => {
    'mediaType': 'audiobook',
    'durationMs': 300000,
    'chapters': chapters,
  };

  test('queue metadata identifies the book and preserves its chapters', () {
    final snapshot = queueTrackSnapshot({
      'state': 'paused',
      'elapsed_time': 125,
      'current_item': {
        'duration': 300,
        'media_item': {
          'name': 'Book',
          'media_type': 'audiobook',
          'uri': 'library://audiobook/1',
          'metadata': {
            'chapters': [
              {'name': 'Opening', 'start': 0, 'end': 120},
              {'name': 'Ending', 'start': 120},
            ],
          },
        },
      },
    });
    expect(snapshot?['mediaType'], 'audiobook');
    expect(snapshot?['mediaUri'], 'library://audiobook/1');
    expect(snapshot?['positionMs'], 125000);
    final chapters = audiobookChapters(snapshot);
    expect(chapters.last.name, 'Ending');
    expect(chapters.last.durationMs, 180000);
    expect(chapters.last.absolutePosition(5000), 125000);
  });

  test('chapters sort by start and infer missing ends', () {
    final chapters = audiobookChapters(
      book([
        {'name': 'Three', 'start': 240},
        {'name': 'One', 'start': 0},
        {'name': 'Two', 'start': 90.5},
      ]),
    );
    expect(chapters.map((c) => c.name), ['One', 'Two', 'Three']);
    expect(chapters.map((c) => c.durationMs), [90500, 149500, 60000]);
    expect(currentChapterIndex(chapters, 90499, 300000), 0);
    expect(currentChapterIndex(chapters, 90500, 300000), 1);
    expect(currentChapterIndex(chapters, 300000, 300000), 2);
    expect(chapters[1].absolutePosition(-1), 90500);
    expect(chapters[1].absolutePosition(999999), 240000);
  });

  test('invalid bounds and gaps do not invent chapter progress', () {
    final chapters = audiobookChapters(
      book([
        null,
        {'start': double.nan},
        {'start': -10},
        {'start': '0'},
        {'start': 0, 'end': 10},
        {'start': 20, 'end': 20},
        {'start': 30, 'end': 80},
        {'start': 60, 'end': 999},
        {'start': 400},
      ]),
    );
    expect(chapters.map((c) => c.endMs), [10000, 60000, 300000]);
    expect(currentChapterIndex(chapters, 15000, 300000), -1);
    expect(audiobookChapters({'mediaType': 'track', 'chapters': []}), isEmpty);
    expect(audiobookChapters(book([])), isEmpty);
    expect(
      audiobookChapters(
        book([
          {'start': 400},
        ]),
      ),
      isEmpty,
    );
  });

  test('live chapter position advances only during playback', () {
    final snapshot = {
      ...book([]),
      'positionMs': 89000,
      'receivedAt': 1000,
      'playing': true,
    };
    expect(playbackPositionMs(snapshot, 3000), 91000);
    expect(playbackPositionMs({...snapshot, 'playing': false}, 3000), 89000);
    expect(playbackPositionMs(snapshot, 999999), 300000);
  });
}
