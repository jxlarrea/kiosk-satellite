import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/markup.dart';

/// The Markdown subset notifications are read in (issue #439): what
/// renders, and, as importantly, what ordinary text is left alone.
void main() {
  List<MarkupRun> inline(String text) => Markup.inline(text);

  test('plain text is one plain run', () {
    expect(inline('Washing machine finished'), [
      const MarkupRun('Washing machine finished'),
    ]);
  });

  test('bold, italic, code and strike', () {
    expect(inline('Battery level: **15%**'), [
      const MarkupRun('Battery level: '),
      const MarkupRun('15%', bold: true),
    ]);
    expect(inline('a *quiet* word'), [
      const MarkupRun('a '),
      const MarkupRun('quiet', italic: true),
      const MarkupRun(' word'),
    ]);
    expect(inline('run `ha core restart` now'), [
      const MarkupRun('run '),
      const MarkupRun('ha core restart', code: true),
      const MarkupRun(' now'),
    ]);
    expect(inline('~~done~~ pending'), [
      const MarkupRun('done', strike: true),
      const MarkupRun(' pending'),
    ]);
  });

  test('markup nests', () {
    expect(inline('**bold and *italic* inside**'), [
      const MarkupRun('bold and ', bold: true),
      const MarkupRun('italic', bold: true, italic: true),
      const MarkupRun(' inside', bold: true),
    ]);
    expect(inline('***both***'), [
      const MarkupRun('both', bold: true, italic: true),
    ]);
    expect(inline('*a **b** c*'), [
      const MarkupRun('a ', italic: true),
      const MarkupRun('b', italic: true, bold: true),
      const MarkupRun(' c', italic: true),
    ]);
    expect(inline('**`code` in bold**'), [
      const MarkupRun('code', bold: true, code: true),
      const MarkupRun(' in bold', bold: true),
    ]);
  });

  test('ordinary text with stars, underscores and tildes is left alone', () {
    // Nothing closes it, or a space follows the opener: arithmetic and
    // footnote marks are text.
    expect(inline('2 * 3 * 4'), [const MarkupRun('2 * 3 * 4')]);
    expect(inline('rated 4* by guests'), [
      const MarkupRun('rated 4* by guests'),
    ]);
    expect(inline('* not a bullet'), [const MarkupRun('* not a bullet')]);
    // Underscores never emphasize: entity ids are ordinary here.
    expect(inline('sensor.living_room_temp is __low__'), [
      const MarkupRun('sensor.living_room_temp is __low__'),
    ]);
    expect(inline('~5 minutes ~ish'), [const MarkupRun('~5 minutes ~ish')]);
    // A backtick with no partner is a backtick.
    expect(inline('it`s fine'), [const MarkupRun('it`s fine')]);
    expect(inline('**unclosed'), [const MarkupRun('**unclosed')]);
  });

  test('a link reads as its label and a backslash escapes', () {
    expect(inline('see [the docs](https://x.y/z) today'), [
      const MarkupRun('see '),
      const MarkupRun('the docs'),
      const MarkupRun(' today'),
    ]);
    expect(inline('**[bold link](u)**'), [
      const MarkupRun('bold link', bold: true),
    ]);
    expect(inline(r'a literal \*star\* and \`tick'), [
      const MarkupRun('a literal *star* and `tick'),
    ]);
  });

  test('lines break, blank lines separate paragraphs', () {
    final blocks = Markup.parse('First line\nsecond line\n\nNew paragraph');
    expect(blocks, hasLength(2));
    expect(blocks[0], isA<MarkupParagraph>());
    expect(blocks[0].runs, [
      const MarkupRun('First line'),
      const MarkupRun('\n'),
      const MarkupRun('second line'),
    ]);
    expect(blocks[1].plainText, 'New paragraph');
    expect(
      Markup.plain('First line\nsecond line\n\nNew paragraph'),
      'First line\nsecond line\nNew paragraph',
    );
  });

  test('headings and lists', () {
    final blocks = Markup.parse(
      '# Daily summary\n'
      '- Doors: **closed**\n'
      '* Windows: open\n'
      '  - kitchen\n'
      '\t- bathroom\n'
      '1. first\n'
      '2. second\n'
      'trailing words',
    );
    expect(blocks.map((b) => b.runtimeType), [
      MarkupHeading,
      MarkupListItem,
      MarkupListItem,
      MarkupListItem,
      MarkupListItem,
      MarkupListItem,
      MarkupListItem,
      MarkupParagraph,
    ]);
    expect(blocks[0].plainText, 'Daily summary');
    final doors = blocks[1] as MarkupListItem;
    expect(doors.runs, [
      const MarkupRun('Doors: '),
      const MarkupRun('closed', bold: true),
    ]);
    expect(doors.depth, 0);
    expect(doors.number, isNull);
    expect((blocks[3] as MarkupListItem).depth, 1);
    expect((blocks[4] as MarkupListItem).depth, 1);
    expect((blocks[5] as MarkupListItem).number, '1.');
    expect((blocks[6] as MarkupListItem).number, '2.');
    expect(blocks[7].plainText, 'trailing words');
  });

  test('a hash or dash without a space after it is text', () {
    expect(Markup.parse('#1 priority').single, isA<MarkupParagraph>());
    expect(Markup.parse('#1 priority').single.plainText, '#1 priority');
    expect(
      Markup.parse('-5 degrees outside').single.plainText,
      '-5 degrees outside',
    );
    expect(Markup.parse(r'\- not a bullet').single, isA<MarkupParagraph>());
    expect(Markup.parse(r'\- not a bullet').single.plainText, '- not a bullet');
  });

  test('empty and whitespace-only text parse to nothing', () {
    expect(Markup.parse(''), isEmpty);
    expect(Markup.parse(' \n\t\n'), isEmpty);
  });
}
