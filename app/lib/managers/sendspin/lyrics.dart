/// One line of a synced lyric.
class LyricLine {
  const LyricLine(this.at, this.text);

  /// Where the line starts, from the beginning of the track.
  final Duration at;
  final String text;
}

/// Parses LRC, the format every lyrics provider agrees on: a timestamp per
/// line, `[mm:ss.xx]`, with `[mm:ss:xx]` seen in the wild too.
///
/// A line can carry several timestamps when the same words repeat (a
/// chorus), which becomes one entry per timestamp. Metadata tags (`[ti:…]`,
/// `[ar:…]`) are dropped, and so are the empty lines providers use as
/// spacing, since the display shows the gap by holding on the previous line.
///
/// Returns lines in time order. An unsynced lyric — plain text, no
/// timestamps — yields nothing: there is no honest way to follow along with
/// it, and a wall of text on a screensaver is not what was asked for.
List<LyricLine> parseLrc(String? lrc) {
  if (lrc == null || lrc.isEmpty) return const [];
  final timestamp = RegExp(r'\[(\d+):([0-5]\d)(?:[.:](\d{1,3}))?\]');
  final metadataOnly = RegExp(r'^\[[a-zA-Z]+:[^\]]*\]$');
  // The format's own correction tag, in milliseconds, which some providers
  // use to fix a file they know runs early or late. Positive means the
  // lyrics should appear LATER, per the LRC convention.
  final offsetTag = RegExp(r'^\[offset:\s*([+-]?\d+)\s*\]$', caseSensitive: false);
  var offsetMs = 0;
  final lines = <LyricLine>[];
  for (final raw in lrc.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final offsetMatch = offsetTag.firstMatch(line);
    if (offsetMatch != null) {
      offsetMs = int.tryParse(offsetMatch.group(1)!) ?? 0;
      continue;
    }
    if (metadataOnly.hasMatch(line)) continue;
    final matches = timestamp.allMatches(line).toList();
    if (matches.isEmpty) continue;
    final text = line.replaceAll(timestamp, '').trim();
    if (text.isEmpty) continue;
    for (final match in matches) {
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final fraction = match.group(3);
      // Two digits are hundredths, three are milliseconds.
      final milliseconds = fraction == null
          ? 0
          : fraction.length == 3
              ? int.parse(fraction)
              : int.parse(fraction) * 10;
      final at = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          ) +
          Duration(milliseconds: offsetMs);
      lines.add(LyricLine(at < Duration.zero ? Duration.zero : at, text));
    }
  }
  lines.sort((a, b) => a.at.compareTo(b.at));
  return lines;
}

/// The index of the line that should be highlighted at [position], or -1
/// before the first one starts (songs commonly open with an instrumental).
int currentLyricIndex(List<LyricLine> lines, Duration position) {
  var index = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].at > position) break;
    index = i;
  }
  return index;
}
