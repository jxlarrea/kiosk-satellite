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
class LrclibApi {
  static const _host = 'lrclib.net';

  /// Synced (LRC) lyrics for the track, or null. [artist] may be a
  /// Sendspin slash-joined credit; matching uses the primary artist.
  Future<String?> fetchSyncedLyrics({
    required String title,
    required String artist,
    int? durationSeconds,
  }) async {
    final query = _stripped(title);
    if (query.isEmpty) return null;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.https(_host, '/api/search', {'q': query});
      final request = await client.getUrl(uri);
      // LRCLIB asks clients to identify themselves with something a
      // maintainer could contact; the app-wide string carries the link.
      request.headers.set(HttpHeaders.userAgentHeader, AppIdentity.userAgent);
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      if (response.statusCode != 200) return null;
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(body);
      if (decoded is! List) return null;
      return pickLrclibLyrics(
        decoded,
        artist: artist.split('/').first.trim(),
        durationSeconds: durationSeconds,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

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
