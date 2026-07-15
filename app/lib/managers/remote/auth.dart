import 'dart:convert';
import 'dart:math';

/// In-memory bearer tokens + per-IP login throttling for the remote server.
class AuthStore {
  static const _tokenTtl = Duration(hours: 12);
  static const _maxFailures = 5;
  static const _throttleWindow = Duration(minutes: 5);

  final _tokens = <String, DateTime>{}; // token -> expiry
  final _failures = <String, List<DateTime>>{}; // ip -> failure times

  String issueToken() {
    final random = Random.secure();
    final token = base64UrlEncode(
        List<int>.generate(24, (_) => random.nextInt(256)));
    _tokens[token] = DateTime.now().add(_tokenTtl);
    return token;
  }

  bool validate(String? token) {
    if (token == null) return false;
    final expiry = _tokens[token];
    if (expiry == null) return false;
    if (DateTime.now().isAfter(expiry)) {
      _tokens.remove(token);
      return false;
    }
    return true;
  }

  bool isThrottled(String ip) {
    final failures = _failures[ip];
    if (failures == null) return false;
    final cutoff = DateTime.now().subtract(_throttleWindow);
    failures.removeWhere((t) => t.isBefore(cutoff));
    return failures.length >= _maxFailures;
  }

  void recordFailure(String ip) =>
      (_failures[ip] ??= []).add(DateTime.now());

  void clearFailures(String ip) => _failures.remove(ip);
}
