import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/clock_faces.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Clock screensaver's Font setting (issue #391): the bundled Rubik
/// plus Android's generic families, mapped by clockFontFamily and applied
/// to all three clock styles. Nothing new ships in the APK.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const families = {
    'rubik': 'Rubik',
    'nunito': 'Nunito',
    'inter': 'Inter',
    'system': null,
    'serif': 'serif',
    'condensed': 'sans-serif-condensed',
    'monospace': 'monospace',
    'casual': 'casual',
    'cursive': 'cursive',
    'lcd': 'DSEG14',
  };

  test('every option maps to its family, unknown falls to Rubik', () {
    families.forEach((value, family) {
      expect(clockFontFamily(value), family);
    });
    // A stored value from a newer or older build keeps the original face
    // rather than handing the clock to the platform default.
    expect(clockFontFamily('comic-sans'), 'Rubik');
    expect(clockFontFamily(''), 'Rubik');
  });

  test('only Nunito renders the time heavy: it exists to be the StandBy '
      'look, and at the face\'s usual w300 it read as merely thin', () {
    for (final value in families.keys) {
      expect(
        clockFontWeight(value),
        value == 'nunito' ? FontWeight.w700 : FontWeight.w300,
        reason: value,
      );
    }
  });

  test('the weight override maps every step and leaves Default alone', () {
    expect(clockWeightOverride('default'), isNull);
    expect(clockWeightOverride('light'), FontWeight.w300);
    expect(clockWeightOverride('regular'), FontWeight.w400);
    expect(clockWeightOverride('medium'), FontWeight.w500);
    expect(clockWeightOverride('bold'), FontWeight.w700);
    expect(clockWeightOverride('black'), FontWeight.w900);
    expect(clockWeightOverride('garbage'), isNull);
    expect(defs.screensaverClockFontWeight.defaultValue, 'default');
    for (final option in defs.screensaverClockFontWeight.options!) {
      expect(defs.screensaverClockFontWeight.optionLabels?[option], isNotNull);
    }
    expect(defs.screensaverClockFontWeight.section, 'Clock screensaver');
    expect(defs.screensaverClockFontWeight.subpage, 'Clock screensaver');
    expect(defs.screensaverClockFontWeight.dependsOn, 'screensaver.mode');
    expect(defs.screensaverClockFontWeight.dependsOnValue, 'clock');
  });

  test('Inter asks for its display optical size, the rest for nothing', () {
    expect(clockOpticalSize('inter'), 32);
    expect(clockOpticalSize('rubik'), isNull);
    expect(clockOpticalSize('lcd'), isNull);
    expect(clockFontVariations(null, FontWeight.w300), isNull);
    expect(clockFontVariations(32, FontWeight.w700), [
      const FontVariation('opsz', 32),
      const FontVariation('wght', 700),
    ]);
  });

  test('the definition offers exactly the mapped set, Rubik by default', () {
    expect(defs.screensaverClockFont.defaultValue, 'rubik');
    expect(defs.screensaverClockFont.options, families.keys.toList());
    for (final option in defs.screensaverClockFont.options!) {
      expect(defs.screensaverClockFont.optionLabels?[option], isNotNull);
    }
    expect(defs.screensaverClockFont.section, 'Clock screensaver');
    expect(defs.screensaverClockFont.subpage, 'Clock screensaver');
    expect(defs.screensaverClockFont.dependsOn, 'screensaver.mode');
    expect(defs.screensaverClockFont.dependsOnValue, 'clock');
  });

  test('the LCD and Nunito faces are bundled: neither look exists in any '
      'system font', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final family in ['DSEG14', 'Nunito', 'Inter']) {
      expect(pubspec.contains('- family: $family'), isTrue);
      expect(File('assets/fonts/$family.ttf').existsSync(), isTrue);
      expect(File('assets/fonts/$family-OFL.txt').existsSync(), isTrue);
    }
  });

  group('the faces draw in the picked font', () {
    Future<void> pumpClock(
      WidgetTester tester,
      Map<String, Object> prefs,
    ) async {
      SharedPreferences.setMockInitialValues({
        'ks.ha.url': 'http://ha.local:8123',
        'ks.ha.token': 'token',
        'ks.screensaver.mode': 'clock',
        // The date renders through the locale machinery, which is not the
        // subject here.
        'ks.screensaver.clock_show_date': false,
        ...prefs,
      });
      final container = AppContainer();
      await container.settings.init();
      await tester.pumpWidget(
        MaterialApp(home: ClockScreensaver(container: container)),
      );
    }

    String? faceFont(WidgetTester tester, Pattern data) {
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        if ((t.data ?? '').contains(data)) return t.style?.fontFamily;
      }
      return null;
    }

    FontWeight? faceWeight(WidgetTester tester, Pattern data) {
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        if ((t.data ?? '').contains(data)) return t.style?.fontWeight;
      }
      return null;
    }

    testWidgets('a picked weight lands on every face; Default keeps each '
        "face's own", (tester) async {
      await pumpClock(tester, {'ks.screensaver.clock_font_weight': 'bold'});
      expect(faceWeight(tester, ':'), FontWeight.w700);
      await pumpClock(tester, {
        'ks.screensaver.clock_style': 'flip',
        'ks.screensaver.clock_font_weight': 'light',
      });
      expect(faceWeight(tester, RegExp(r'^\d\d$')), FontWeight.w300);
      await pumpClock(tester, {'ks.screensaver.clock_style': 'flip'});
      expect(faceWeight(tester, RegExp(r'^\d\d$')), FontWeight.w400);
      await pumpClock(tester, {
        'ks.screensaver.clock_style': 'roller',
        'ks.screensaver.clock_font_weight': 'medium',
      });
      expect(faceWeight(tester, RegExp(r'^\d$')), FontWeight.w500);
      await pumpClock(tester, {'ks.screensaver.clock_style': 'roller'});
      expect(faceWeight(tester, RegExp(r'^\d$')), FontWeight.w800);
      // Default on the digital face: light, or heavy in Nunito.
      await pumpClock(tester, {});
      expect(faceWeight(tester, ':'), FontWeight.w300);
      await pumpClock(tester, {'ks.screensaver.clock_font': 'nunito'});
      expect(faceWeight(tester, ':'), FontWeight.w700);
    });

    testWidgets('the digital face', (tester) async {
      await pumpClock(tester, {'ks.screensaver.clock_font': 'monospace'});
      expect(faceFont(tester, ':'), 'monospace');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the digital face draws Nunito heavy', (tester) async {
      await pumpClock(tester, {'ks.screensaver.clock_font': 'nunito'});
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        if ((t.data ?? '').contains(':')) {
          expect(t.style?.fontFamily, 'Nunito');
          expect(t.style?.fontWeight, FontWeight.w700);
        }
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the flip face', (tester) async {
      await pumpClock(tester, {
        'ks.screensaver.clock_font': 'condensed',
        'ks.screensaver.clock_style': 'flip',
      });
      expect(faceFont(tester, RegExp(r'^\d+$')), 'sans-serif-condensed');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a wide font keeps both flip digits on one line: Inter\'s '
        'tabular pair is wider than the card and wrapped its second digit '
        'onto a line below', (tester) async {
      // The test font draws every glyph a full em wide, so two digits at
      // the card's font size overflow it the way Inter's do on a device.
      await pumpClock(tester, {
        'ks.screensaver.clock_font': 'inter',
        'ks.screensaver.clock_style': 'flip',
      });
      final face = tester.getRect(find.byType(FlipClockFace));
      // Each card is 0.84 of its height wide, and the face is its height.
      final cardW = face.height * 0.84;
      final digits = find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^\d+$').hasMatch(w.data ?? ''),
      );
      expect(digits, findsWidgets);
      // One size for the face: the single-digit hour does not keep the
      // full size while the minutes shrink beside it.
      final sizes = {
        for (final e in digits.evaluate()) (e.widget as Text).style!.fontSize!,
      };
      expect(sizes, hasLength(1));
      expect(sizes.single, lessThan(face.height * 0.66));
      for (final e in digits.evaluate()) {
        final text = e.widget as Text;
        final rich = find.descendant(
          of: find.byWidget(text),
          matching: find.byType(RichText),
        );
        final paragraph = tester.renderObject<RenderParagraph>(rich);
        // The style's line height is one em, so a wrapped pair lays out
        // twice the font size tall.
        expect(
          paragraph.textSize.height,
          lessThanOrEqualTo(text.style!.fontSize! * 1.01),
          reason: '${text.data} wrapped',
        );
        // And the pair is shrunk to sit inside the card, not spilling out.
        expect(
          tester.getRect(rich).width,
          lessThanOrEqualTo(cardW),
          reason: '${text.data} overflows the card',
        );
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the default is the Rubik the clock always used', (
      tester,
    ) async {
      await pumpClock(tester, {});
      expect(faceFont(tester, ':'), 'Rubik');
      await tester.pumpWidget(const SizedBox());
    });
  });
}
