import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Stateless bearer tokens + per-IP login throttling for the remote server.
///
/// Tokens are HMAC-signed with a persistent secret and carry their own
/// expiry, so they survive app restarts (no in-memory token map to lose).
/// This is what keeps the remote UI logged in across the kiosk restarting —
/// an in-memory store signed the user out on every relaunch.
class AuthStore {
  AuthStore(this._secret);

  final String _secret;

  static const _tokenTtl = Duration(days: 7);

  /// Ceiling for a caller-chosen expiry (issue #84): ten years is
  /// "permanent" for an automation token without literally never expiring.
  static const maxTtl = Duration(days: 3650);
  static const _maxFailures = 5;
  static const _throttleWindow = Duration(minutes: 5);

  // Throttling is fine to keep in memory (resetting on restart is harmless).
  final _failures = <String, List<DateTime>>{};

  /// A signed token. The default week suits the admin UI's session; an
  /// automation (a Home Assistant rest_command firing for years) passes its
  /// own [ttl], clamped to [maxTtl].
  ///
  /// [claims] ride in the payload beside the expiry: a fleet token names
  /// the leader it was minted for (`fleet`), which the server reads back
  /// with [claimsOf] to keep it off everything but the fleet endpoints.
  String issueToken({Duration? ttl, Map<String, Object?> claims = const {}}) {
    final effective = ttl == null || ttl <= Duration.zero
        ? _tokenTtl
        : (ttl > maxTtl ? maxTtl : ttl);
    final exp = DateTime.now().add(effective).millisecondsSinceEpoch;
    final payload = base64Url.encode(
      utf8.encode(jsonEncode({...claims, 'exp': exp})),
    );
    return '$payload.${_sign(payload)}';
  }

  /// The payload of a token that [validate] accepts or null for any other.
  Map<String, Object?>? claimsOf(String? token) {
    if (!validate(token)) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(token!.split('.').first)),
    );
    return payload is Map ? payload.cast<String, Object?>() : null;
  }

  bool validate(String? token) {
    if (token == null) return false;
    final parts = token.split('.');
    if (parts.length != 2) return false;
    if (!_constantTimeEquals(parts[1], _sign(parts[0]))) return false;
    try {
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(parts[0]))) as Map;
      final exp = payload['exp'] as int;
      return DateTime.now().millisecondsSinceEpoch < exp;
    } catch (_) {
      return false;
    }
  }

  String _sign(String data) {
    final digest = Hmac(
      sha256,
      utf8.encode(_secret),
    ).convert(utf8.encode(data));
    return base64Url.encode(digest.bytes);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  bool isThrottled(String ip) {
    final failures = _failures[ip];
    if (failures == null) return false;
    final cutoff = DateTime.now().subtract(_throttleWindow);
    failures.removeWhere((t) => t.isBefore(cutoff));
    return failures.length >= _maxFailures;
  }

  void recordFailure(String ip) => (_failures[ip] ??= []).add(DateTime.now());

  void clearFailures(String ip) => _failures.remove(ip);
}
