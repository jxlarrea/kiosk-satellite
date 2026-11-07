/// The native CrashJournal's text, taken apart: one entry per recorded
/// crash, oldest first, with the deliberate restarts the journal also
/// notes told apart from the crashes that are worth reporting.
///
/// The journal appends every entry under a header line and trims its head
/// when it grows past its cap, so the text may open mid-trace; anything
/// before the first header is dropped. Text with no header at all (a
/// hand-written journal, a test) is one entry.
library;

/// `=== crash at 2026-09-08 15:32:33 (app 2026.9.30, thread main) ===`
final _header = RegExp(
  r'^=== crash at (\S+ \S+) \(app ([^,]+), thread ([^)]+)\) ===$',
  multiLine: true,
);

/// What `CrashJournal.note` writes: a restart the app asked for, not an
/// exception. Never a crash report.
const deliberateMarker = 'process restarted deliberately';

class CrashEntry {
  const CrashEntry({
    required this.text,
    this.recordedAt,
    this.appVersion,
    this.thread,
  });

  /// The entry as recorded: header line, if any, plus the trace.
  final String text;
  final String? recordedAt;
  final String? appVersion;
  final String? thread;

  /// The first line under the header: the exception and its message.
  String get headline {
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('===') || t.startsWith('FATAL EXCEPTION')) {
        continue;
      }
      return t;
    }
    return '';
  }

  /// A restart the app asked for (frame watchdog, restart command, home
  /// fuse), noted so the death is visible in the Logs screen.
  bool get deliberate => headline.contains(deliberateMarker);

  /// The frame or main thread watchdog killing a wedged UI, or the camera
  /// watchdog clearing threads a HAL1 camera leaked (LegacyCameraShim.kt):
  /// the app asked for it, but nobody else did, so it is reported, apart
  /// from crashes.
  bool get watchdog =>
      deliberate &&
      (headline.contains('frame watchdog') ||
          headline.contains('main thread watchdog') ||
          headline.contains('camera watchdog'));

  /// A shell user ran `am crash` against the app (adb, or a tool with
  /// shell rights): Android delivers that as an uncaught exception on the
  /// main thread, so the journal sees it like any crash. Nothing in the
  /// app failed, and every such trace reads the same.
  bool get shellInduced => headline.contains('CrashedByAdbException');

  /// What Diagnostics reports: exceptions, and watchdog restarts. Not the
  /// restarts a person or an automation asked for, and not a kill a shell
  /// asked for, which the journal still notes so the Logs screen can say
  /// why the app died.
  bool get reportable => (!deliberate || watchdog) && !shellInduced;

  /// The reason behind a deliberate restart, without the marker.
  String get reason {
    final i = headline.indexOf(deliberateMarker);
    if (i < 0) return headline;
    return headline
        .substring(i + deliberateMarker.length)
        .replaceFirst(RegExp(r'^:\s*'), '');
  }
}

List<CrashEntry> parseCrashJournal(String journal) {
  final matches = _header.allMatches(journal).toList();
  if (matches.isEmpty) {
    final t = journal.trim();
    return t.isEmpty ? const [] : [CrashEntry(text: t)];
  }
  final out = <CrashEntry>[];
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final end = i + 1 < matches.length ? matches[i + 1].start : journal.length;
    final text = journal.substring(m.start, end).trim();
    out.add(
      CrashEntry(
        text: text,
        recordedAt: m[1],
        appVersion: m[2]?.trim(),
        thread: m[3]?.trim(),
      ),
    );
  }
  return out;
}
