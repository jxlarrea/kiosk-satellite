/// The Markdown subset a notification's words are read in (issue #439):
/// enough to put weight on a number and a list under a heading, and
/// nothing that turns an ordinary sentence into something else.
///
/// Inline: `**bold**`, `*italic*`, `` `code` ``, `~~struck~~`, a
/// `[label](url)` reads as its label, and a backslash keeps the character
/// after it. Underscores are left alone on purpose: `sensor.living_room`
/// is an ordinary thing to say in a notification and must not italicize
/// itself. A lone `*`, one followed by a space, or one with no partner
/// on the line is the character itself, so "2 * 3" survives.
///
/// Lines: every newline is a line break (a notification is read like a
/// note, not typeset like an essay), a blank line separates paragraphs,
/// `# ` opens a heading, `- ` (or `* `, `+ `) a bullet and `1. ` a
/// numbered item, with leading spaces nesting an item under the one
/// above. A real Markdown renderer is a dependency four lines on a card
/// do not justify.
library;

/// A stretch of one line drawn in one style.
class MarkupRun {
  const MarkupRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.strike = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final bool strike;

  bool get plain => !bold && !italic && !code && !strike;

  @override
  bool operator ==(Object other) =>
      other is MarkupRun &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.code == code &&
      other.strike == strike;

  @override
  int get hashCode => Object.hash(text, bold, italic, code, strike);

  @override
  String toString() =>
      'MarkupRun("$text"'
      '${bold ? ' bold' : ''}${italic ? ' italic' : ''}'
      '${code ? ' code' : ''}${strike ? ' strike' : ''})';
}

/// One vertical piece of the text.
sealed class MarkupBlock {
  const MarkupBlock(this.runs);

  /// The words, with a run of "\n" where a line breaks inside the block.
  final List<MarkupRun> runs;

  /// The words with the markup gone, for logs and finders.
  String get plainText => runs.map((run) => run.text).join();
}

/// Ordinary lines, up to the next blank line, heading or list item.
class MarkupParagraph extends MarkupBlock {
  const MarkupParagraph(super.runs);
}

/// A `# ` line. The level is not kept: on a card every heading is the
/// same weight, a bolder line above what follows.
class MarkupHeading extends MarkupBlock {
  const MarkupHeading(super.runs);
}

/// A bullet or numbered item. [depth] is 0 at the margin and one more
/// for every level of indentation; [number] is null for a bullet.
class MarkupListItem extends MarkupBlock {
  const MarkupListItem(super.runs, {this.depth = 0, this.number});

  final int depth;
  final String? number;
}

abstract final class Markup {
  /// Splits [text] into blocks. Never throws: whatever comes in reads as
  /// itself at worst.
  static List<MarkupBlock> parse(String text) {
    final blocks = <MarkupBlock>[];
    var paragraph = <MarkupRun>[];
    void closeParagraph() {
      if (paragraph.isNotEmpty) {
        blocks.add(MarkupParagraph(List.unmodifiable(paragraph)));
        paragraph = [];
      }
    }

    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        closeParagraph();
        continue;
      }
      final heading = _heading.firstMatch(line);
      if (heading != null) {
        closeParagraph();
        blocks.add(MarkupHeading(inline(heading[1]!)));
        continue;
      }
      final item = _listItem.firstMatch(line);
      if (item != null) {
        closeParagraph();
        final indent = item[1]!.replaceAll('\t', '  ').length;
        final marker = item[2]!;
        blocks.add(
          MarkupListItem(
            inline(item[3]!),
            depth: indent ~/ 2,
            number: marker.length == 1 ? null : marker,
          ),
        );
        continue;
      }
      if (paragraph.isNotEmpty) paragraph.add(const MarkupRun('\n'));
      paragraph.addAll(inline(line.trimLeft()));
    }
    closeParagraph();
    return List.unmodifiable(blocks);
  }

  /// The words of [text] as one line, with the markup gone.
  static String plain(String text) =>
      parse(text).map((block) => block.plainText).join('\n');

  /// One line's inline markup as runs. Markers with nothing to close them
  /// are text.
  static List<MarkupRun> inline(String text) {
    final runs = <MarkupRun>[];
    final buffer = StringBuffer();
    var bold = false;
    var italic = false;
    var strike = false;
    void flush() {
      if (buffer.isEmpty) return;
      runs.add(
        MarkupRun(
          buffer.toString(),
          bold: bold,
          italic: italic,
          strike: strike,
        ),
      );
      buffer.clear();
    }

    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (c == r'\' &&
          i + 1 < text.length &&
          _escapable.contains(text[i + 1])) {
        buffer.write(text[i + 1]);
        i += 2;
        continue;
      }
      if (c == '`') {
        final end = text.indexOf('`', i + 1);
        if (end > i + 1) {
          flush();
          runs.add(
            MarkupRun(
              text.substring(i + 1, end),
              bold: bold,
              italic: italic,
              strike: strike,
              code: true,
            ),
          );
          i = end + 1;
          continue;
        }
      }
      if (c == '[') {
        final link = _link.matchAsPrefix(text, i);
        if (link != null) {
          // The label reads as text; there is nowhere on a card for a
          // URL to go, and the label's own markup still applies.
          for (final run in inline(link[1]!)) {
            flush();
            runs.add(
              MarkupRun(
                run.text,
                bold: bold || run.bold,
                italic: italic || run.italic,
                strike: strike || run.strike,
                code: run.code,
              ),
            );
          }
          i = link.end;
          continue;
        }
      }
      if (c == '*' || c == '~') {
        final tripled =
            c == '*' &&
            i + 2 < text.length &&
            text[i + 1] == c &&
            text[i + 2] == c;
        // `***both***` is bold and italic at once; it toggles the pair
        // together so its closer is not read as `**` and a stray `*`.
        if (tripled && ((bold && italic) || _closes(text, i + 3, '***'))) {
          flush();
          bold = !bold;
          italic = !italic;
          i += 3;
          continue;
        }
        final doubled = i + 1 < text.length && text[i + 1] == c;
        if (c == '~' && !doubled) {
          buffer.write(c);
          i++;
          continue;
        }
        final marker = doubled ? '$c$c' : c;
        final open = doubled ? (c == '*' ? bold : strike) : italic;
        if (open || _closes(text, i + marker.length, marker)) {
          flush();
          if (doubled) {
            if (c == '*') {
              bold = !bold;
            } else {
              strike = !strike;
            }
          } else {
            italic = !italic;
          }
          i += marker.length;
          continue;
        }
        buffer.write(marker);
        i += marker.length;
        continue;
      }
      buffer.write(c);
      i++;
    }
    flush();
    return List.unmodifiable(runs);
  }

  /// Whether a [marker] opened just before [from] has a partner further
  /// along the line: the text after the opener starts with a non-space,
  /// and a closer sits after a non-space (and, for a single `*`, is not
  /// half of a `**`).
  static bool _closes(String text, int from, String marker) {
    if (from >= text.length || _space(text[from])) return false;
    if (marker == '*' && text[from] == '*') return false;
    var at = text.indexOf(marker, from + 1);
    while (at > 0) {
      final before = text[at - 1];
      final after = at + marker.length;
      final lone =
          marker != '*' ||
          (before != '*' && (after >= text.length || text[after] != '*'));
      if (!_space(before) && lone) return true;
      at = text.indexOf(marker, at + 1);
    }
    return false;
  }

  static bool _space(String c) => c == ' ' || c == '\t';

  static const _escapable = r'\*`~[]#-+_';
  static final _heading = RegExp(r'^#{1,6}\s+(.*)$');
  static final _listItem = RegExp(r'^([ \t]*)(-|\*|\+|\d{1,3}\.)\s+(.*)$');
  static final _link = RegExp(r'\[([^\[\]]+)\]\(([^)\s]+)\)');
}
