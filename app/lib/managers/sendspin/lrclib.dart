import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/app_identity.dart';

/// Direct LRCLIB lookup, the FALLBACK behind Music Assistant's own
/// providers (issue #90).
///
/// Music Assistant stays authoritative: its providers include the user's
/// own .lrc files, which no public database beats. But its matching is
/// strict, and LRCLIB's crowd-sourced credits are not ("The Porter's Gate,
/// ve, Liz Vice" for a track tagged "The Porter's Gate/Liz Vice"), so a
/// song whose lyrics plainly exist can come back empty.
///
/// The query is deliberately just the title, punctuation stripped: LRCLIB's
/// search answers that shape in under a second while longer or punctuated
/// queries stall it (measured during and after their 2026-07-30 outage,
/// but the short query is the safe shape either way). The artist and
/// duration then filter OUR side, where sloppy credits cost nothing.
/// LRCLIB could not be asked: no route to it (a device kept off the
/// internet), a timeout, or an answer that was not a search result. Told
/// apart from "no lyrics for this track" so a fallback can step in for
/// the one and not the other.
class LrclibUnreachable implements Exception {
  const LrclibUnreachable(this.reason);

  final String reason;

  @override
  String toString() => 'LRCLIB unreachable: $reason';
}

class LrclibApi {
  LrclibApi({LrclibFetch? fetch}) : _fetch = fetch ?? _fetchOverHttp;

  static const _host = 'lrclib.net';

  final LrclibFetch _fetch;

  /// Synced (LRC) lyrics for the track, or null when it has none there.
  /// Throws [LrclibUnreachable] when the service could not be asked.
  /// [artist] may be a Sendspin slash-joined credit; matching uses the
  /// primary artist.
  ///
  /// Three asks, each only if the one before came back empty: the exact
  /// lookup by title and artist, which answers most tracks in one round
  /// trip; the search qualified by artist, which forgives a differently
  /// cased or punctuated title; and last the title-only search the
  /// client began with, filtered on this side, for a credit LRCLIB
  /// spells too differently to match. The first two are what keep a
  /// common title ("Crush", "5am") from losing to twenty namesakes.
  Future<String?> fetchSyncedLyrics({
    required String title,
    required String artist,
    int? durationSeconds,
  }) async {
    final query = _stripped(title);
    if (query.isEmpty) return null;
    final primary = artist.split('/').first.trim();
    if (primary.isNotEmpty) {
      final exact = await _get(
        Uri.https(_host, '/api/get', {
          'track_name': title.trim(),
          'artist_name': primary,
          if (durationSeconds != null) 'duration': '$durationSeconds',
        }),
        notFound: 404,
      );
      if (exact is Map) {
        final synced = exact['syncedLyrics'];
        if (synced is String && synced.trim().isNotEmpty) return synced;
      }
      final qualified = await _get(
        Uri.https(_host, '/api/search', {
          'track_name': title.trim(),
          'artist_name': primary,
        }),
      );
      if (qualified is List) {
        final hit = pickLrclibLyrics(
          qualified,
          artist: primary,
          durationSeconds: durationSeconds,
        );
        if (hit != null) return hit;
      }
    }
    final loose = await _get(Uri.https(_host, '/api/search', {'q': query}));
    if (loose is! List) return null;
    return pickLrclibLyrics(
      loose,
      artist: primary,
      durationSeconds: durationSeconds,
    );
  }

  /// One request, decoded. A status of [notFound] is an empty answer
  /// (null); any other failure to get a JSON answer is the service out
  /// of reach.
  Future<Object?> _get(Uri uri, {int? notFound}) async {
    final (status, body) = await _fetch(uri);
    if (status == notFound) return null;
    if (status != 200) throw LrclibUnreachable('HTTP $status');
    try {
      return jsonDecode(body);
    } catch (_) {
      throw const LrclibUnreachable('not a result');
    }
  }

  static Future<(int, String)> _fetchOverHttp(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      // LRCLIB asks clients to identify themselves with something a
      // maintainer could contact; the app-wide string carries the link.
      request.headers.set(HttpHeaders.userAgentHeader, AppIdentity.userAgent);
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));
      return (response.statusCode, body);
    } on LrclibUnreachable {
      rethrow;
    } catch (e) {
      throw LrclibUnreachable('$e');
    } finally {
      client.close(force: true);
    }
  }
}

/// How the client reaches LRCLIB: the status and body of one GET.
/// Swapped in tests.
typedef LrclibFetch = Future<(int, String)> Function(Uri uri);

/// The best synced lyric among LRCLIB search results for a title-only
/// query. Tiered, strictest first, and with a KNOWN artist that artist
/// must appear in the credit — a common title with a matching runtime is
/// not the same song ("Souvenir" served up an Italian namesake of the
/// right length):
///  1. the artist appears in the credit AND the duration fits,
///  2. the artist appears in the credit.
/// Only with no artist to check does the duration alone qualify a result.
/// Within a tier the first entry wins (LRCLIB orders by relevance). The
/// duration window is a few seconds; a different edition's timings drift
/// off the vocal within a verse.
String? pickLrclibLyrics(
  List<Object?> results, {
  String artist = '',
  int? durationSeconds,
}) {
  final wantedArtist = _stripped(artist);
  bool artistFits(Map<Object?, Object?> entry) {
    if (wantedArtist.isEmpty) return false;
    final credited = _stripped('${entry['artistName'] ?? ''}');
    return credited.contains(wantedArtist) || wantedArtist.contains(credited);
  }

  bool durationFits(Map<Object?, Object?> entry) {
    final duration = entry['duration'];
    return durationSeconds != null &&
        duration is num &&
        (duration - durationSeconds).abs() <= 7;
  }

  final tiers = wantedArtist.isNotEmpty
      ? <bool Function(Map<Object?, Object?>)>[
          (e) => artistFits(e) && durationFits(e),
          artistFits,
        ]
      : <bool Function(Map<Object?, Object?>)>[durationFits];
  for (final fits in tiers) {
    for (final entry in results) {
      if (entry is! Map) continue;
      final synced = entry['syncedLyrics'];
      if (synced is! String || synced.trim().isEmpty) continue;
      if (fits(entry)) return synced;
    }
  }
  return null;
}

/// Lowercased, punctuation flattened to spaces, whitespace collapsed: the
/// shape LRCLIB's search likes and the one loose credits compare best in.
String _stripped(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
