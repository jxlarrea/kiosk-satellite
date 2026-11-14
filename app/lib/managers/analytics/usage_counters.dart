import 'dart:convert';

import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// How often something happened since the last snapshot went out: voice
/// turns by what answered them, wake word arbitration outcomes. Counted
/// only while Usage analytics is on, kept across restarts and reported as
/// buckets, never as times or content.
class UsageCounters {
  UsageCounters._();

  static const _key = 'analytics_usage_counters';

  /// Count one [name], or [by] of them at once, while Usage analytics is
  /// on.
  static Future<void> bump(
    SettingsManager settings,
    String name, {
    int by = 1,
  }) async {
    if (by <= 0 || !settings.get(defs.analyticsUsage)) return;
    final counts = read(settings);
    counts[name] = (counts[name] ?? 0) + by;
    await settings.setInternal(_key, jsonEncode(counts));
  }

  /// Every count held now.
  static Map<String, int> read(SettingsManager settings) {
    try {
      final raw = jsonDecode(settings.internal(_key));
      if (raw is Map) {
        return {
          for (final e in raw.entries)
            if (e.value is int) '${e.key}': e.value as int,
        };
      }
    } catch (_) {}
    return {};
  }

  /// Take off what a sent snapshot reported. A count bumped while the
  /// snapshot was on its way stays for the next one.
  static Future<void> consume(
    SettingsManager settings,
    Map<String, int> reported,
  ) async {
    final counts = read(settings);
    for (final e in reported.entries) {
      final left = (counts[e.key] ?? 0) - e.value;
      if (left > 0) {
        counts[e.key] = left;
      } else {
        counts.remove(e.key);
      }
    }
    await settings.setInternal(_key, counts.isEmpty ? '' : jsonEncode(counts));
  }

  /// A count as the snapshot reports it: a range rather than a number, so
  /// installs that use a feature about as much read the same.
  static String bucket(int n) => switch (n) {
    <= 0 => '0',
    <= 5 => '1-5',
    <= 20 => '6-20',
    _ => '21+',
  };
}
