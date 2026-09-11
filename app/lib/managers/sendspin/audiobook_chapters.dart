/// A chapter's bounds on the book's absolute playback timeline.
class AudiobookChapter {
  const AudiobookChapter(this.name, this.startMs, this.endMs);

  final String name;
  final int startMs;
  final int endMs;

  int get durationMs => endMs - startMs;
  int absolutePosition(int relativeMs) =>
      startMs + relativeMs.clamp(0, durationMs);
}

/// Normalize optional provider metadata. Invalid chapters leave the ordinary
/// book timeline available, and missing ends use the next start or book end.
List<AudiobookChapter> audiobookChapters(Map<String, Object?>? snapshot) {
  if (snapshot?['mediaType'] != 'audiobook') return const [];
  final raw = snapshot?['chapters'];
  if (raw is! List) return const [];
  int? milliseconds(Object? value) =>
      value is num && value.isFinite ? (value * 1000).round() : null;
  final entries = <({String name, int start, int? end})>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final start = milliseconds(item['start']);
    if (start == null || start < 0) continue;
    entries.add((
      name: '${item['name'] ?? ''}'.trim(),
      start: start,
      end: milliseconds(item['end']),
    ));
  }
  entries.sort((a, b) => a.start.compareTo(b.start));
  final duration = (snapshot?['durationMs'] as num?)?.toInt() ?? 0;
  final result = <AudiobookChapter>[];
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final next = i + 1 < entries.length ? entries[i + 1].start : null;
    var end = entry.end ?? next ?? duration;
    if (next != null && end > next) end = next;
    if (duration > 0 && end > duration) end = duration;
    if (end <= entry.start) continue;
    result.add(
      AudiobookChapter(
        entry.name.isEmpty ? 'Chapter ${result.length + 1}' : entry.name,
        entry.start,
        end,
      ),
    );
  }
  return result;
}

int currentChapterIndex(
  List<AudiobookChapter> chapters,
  int positionMs,
  int durationMs,
) => chapters.indexWhere(
  (chapter) =>
      positionMs >= chapter.startMs &&
      (positionMs < chapter.endMs ||
          (positionMs == durationMs && chapter.endMs == durationMs)),
);

int playbackPositionMs(Map<String, Object?> snapshot, int nowMs) {
  var position = (snapshot['positionMs'] as num?)?.toInt() ?? 0;
  final receivedAt = (snapshot['receivedAt'] as num?)?.toInt();
  if (snapshot['playing'] == true && receivedAt != null) {
    position += (nowMs - receivedAt).clamp(0, 1 << 53);
  }
  final duration = (snapshot['durationMs'] as num?)?.toInt() ?? 0;
  return position.clamp(0, duration > 0 ? duration : 1 << 53);
}
