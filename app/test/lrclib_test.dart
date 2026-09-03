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
