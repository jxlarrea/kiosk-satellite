import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/lrclib.dart';

/// The LRCLIB client's three asks: the exact lookup, the artist-qualified
/// search, then the title-only search, each only when the one before
/// came back empty, and the service out of reach told apart from a
/// track it simply lacks.
void main() {
  const synced = '[00:01.00] a line';
  String entry(String artist, String track, {bool synced = true}) =>
      '{"artistName":"$artist","trackName":"$track","duration":200,'
      '"syncedLyrics":${synced ? '"[00:01.00] a line"' : 'null'}}';

  LrclibApi client(Map<String, (int, String)> answers, {List<Uri>? asked}) =>
      LrclibApi(
        fetch: (uri) async {
          asked?.add(uri);
          final key = uri.path + (uri.queryParameters['q'] != null ? '?q' : '');
          return answers[key] ?? (404, '');
        },
      );

  test('the exact lookup answers in one round trip', () async {
    final asked = <Uri>[];
    final api = client({
      '/api/get': (200, entry('Ethel Cain', 'Crush')),
    }, asked: asked);
    expect(
      await api.fetchSyncedLyrics(title: 'Crush', artist: 'Ethel Cain'),
      synced,
    );
    expect(asked, hasLength(1));
    expect(asked.single.queryParameters['artist_name'], 'Ethel Cain');
  });

  test('a plain exact hit falls through to the qualified search', () async {
    final asked = <Uri>[];
    final api = client({
      '/api/get': (200, entry('Leith Ross', '5am', synced: false)),
      '/api/search': (200, '[${entry('Leith Ross', '5am')}]'),
    }, asked: asked);
    expect(
      await api.fetchSyncedLyrics(title: '5am', artist: 'Leith Ross'),
      synced,
    );
    expect(asked, hasLength(2));
    expect(asked.last.queryParameters['track_name'], '5am');
  });

  test('a miss on both ends with the title-only search', () async {
    final asked = <Uri>[];
    final api = client({
      '/api/search': (200, '[]'),
      '/api/search?q': (200, '[${entry('Wild Painting', 'Distractions')}]'),
    }, asked: asked);
    expect(
      await api.fetchSyncedLyrics(
        title: 'Distractions',
        artist: 'Wild Painting',
      ),
      synced,
    );
    expect(asked, hasLength(3));
    expect(asked.last.queryParameters['q'], 'distractions');
  });

  test('nothing anywhere is null, not an error', () async {
    final api = client({
      '/api/search': (200, '[]'),
      '/api/search?q': (200, '[]'),
    });
    expect(
      await api.fetchSyncedLyrics(title: 'Nothing', artist: 'Nobody'),
      isNull,
    );
  });

  test('the service out of reach throws', () async {
    final down = LrclibApi(fetch: (_) async => (503, 'busy'));
    expect(
      () => down.fetchSyncedLyrics(title: 'Crush', artist: 'Ethel Cain'),
      throwsA(isA<LrclibUnreachable>()),
    );
    final broken = LrclibApi(fetch: (_) async => (200, '<html>'));
    expect(
      () => broken.fetchSyncedLyrics(title: 'Crush', artist: 'Ethel Cain'),
      throwsA(isA<LrclibUnreachable>()),
    );
  });

  test('a file with its stamps squeezed together is passed over', () async {
    // What LRCLIB holds for one 100 second track: most copies carry
    // every line between 0:48 and 0:56, one copy is stamped across the
    // song. The exact lookup answers with a broken one; the search has
    // the good one further down.
    String squeezed(String artist) =>
        '{"artistName":"$artist","trackName":"Sex","duration":100,'
        '"syncedLyrics":"[00:48.69] a\\n[00:50.13] b\\n[00:50.40] c\\n'
        '[00:50.66] d\\n[00:50.99] e\\n[00:51.27] f\\n[00:55.75] g"}';
    const sane =
        '{"artistName":"Leith Ross","trackName":"Sex","duration":100,'
        '"syncedLyrics":"[00:08.46] a\\n[00:20.00] b\\n[00:35.00] c\\n'
        '[00:50.00] d\\n[01:05.00] e\\n[01:20.00] f\\n[01:30.88] g"}';
    final asked = <Uri>[];
    final api = client({
      '/api/get': (200, squeezed('Leith Ross')),
      '/api/search': (200, '[${squeezed('Leith Ross')},$sane]'),
    }, asked: asked);
    final lrc = await api.fetchSyncedLyrics(
      title: 'Sex',
      artist: 'Leith Ross',
      durationSeconds: 100,
    );
    expect(lrc, startsWith('[00:08.46]'));
    expect(asked, hasLength(2));
    // The check itself: a third of the song with the length known,
    // a second and a half between lines without it, and a short file
    // is left alone.
    expect(
      plausiblySynced(
        '[00:48.69] a\n[00:50.13] b\n[00:50.40] c\n'
        '[00:50.66] d\n[00:50.99] e\n[00:51.27] f',
        durationSeconds: 100,
      ),
      isFalse,
    );
    expect(
      plausiblySynced(
        '[00:48.69] a\n[00:50.13] b\n[00:50.40] c\n'
        '[00:50.66] d\n[00:50.99] e\n[00:51.27] f',
      ),
      isFalse,
    );
    expect(
      plausiblySynced(
        '[00:08.46] a\n[00:20.00] b\n[00:35.00] c\n'
        '[00:50.00] d\n[01:05.00] e\n[01:20.00] f',
        durationSeconds: 100,
      ),
      isTrue,
    );
    expect(
      plausiblySynced('[00:48.69] a\n[00:50.13] b', durationSeconds: 100),
      isTrue,
    );
  });

  test('a slash-joined credit asks by its first artist', () async {
    final asked = <Uri>[];
    final api = client({
      '/api/get': (200, entry('boygenius', 'Cool About It')),
    }, asked: asked);
    await api.fetchSyncedLyrics(
      title: 'Cool About It',
      artist: 'boygenius/Julien Baker/Phoebe Bridgers',
    );
    expect(asked.single.queryParameters['artist_name'], 'boygenius');
  });
}
