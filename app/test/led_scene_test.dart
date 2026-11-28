import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/led/led_scene.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;

/// The status light frames (LedManager): any number of lights, every
/// effect, brightness applied last.
void main() {
  const blue = 0x0000FF;
  const cyan = 0x00C8FF;

  LedScene scene(
    LedEffect effect, {
    double brightness = 1,
    double fraction = 1,
  }) => LedScene(
    name: 'test',
    effect: effect,
    color: blue,
    accent: cyan,
    brightness: brightness,
    fraction: fraction,
  );

  test('colors read from the settings', () {
    expect(parseRgb('0,200,255'), cyan);
    expect(parseRgb(' 255 , 0 , 0 '), 0xFF0000);
    expect(parseRgb('999,0,-4'), 0xFF0000);
    expect(parseRgb('nope', fallback: 1), 1);
  });

  test('solid fills every light and brightness scales it', () {
    expect(
      renderLedFrame(scene(LedEffect.solid), pixels: 12),
      List.filled(12, blue),
    );
    expect(
      renderLedFrame(scene(LedEffect.solid, brightness: 0.5), pixels: 3),
      List.filled(3, 0x000080),
    );
  });

  test('the listening arc covers a quarter of the row', () {
    final frame = renderLedFrame(scene(LedEffect.arc), pixels: 12);
    expect(frame.where((c) => c == cyan), hasLength(3));
    expect(frame.where((c) => c == blue), hasLength(9));
  });

  test('a spin goes round once a second', () {
    final start = renderLedFrame(scene(LedEffect.spin), pixels: 12);
    final half = renderLedFrame(
      scene(LedEffect.spin),
      pixels: 12,
      t: const Duration(milliseconds: 500),
    );
    final again = renderLedFrame(
      scene(LedEffect.spin),
      pixels: 12,
      t: const Duration(seconds: 1),
    );
    expect(half, isNot(start));
    expect(again, start);
  });

  test('a chase alternates the two colors and steps', () {
    final a = renderLedFrame(scene(LedEffect.chase), pixels: 4);
    final b = renderLedFrame(
      scene(LedEffect.chase),
      pixels: 4,
      t: const Duration(milliseconds: 150),
    );
    expect(a, [blue, cyan, blue, cyan]);
    expect(b, [cyan, blue, cyan, blue]);
  });

  test('a pulse starts dim and peaks halfway', () {
    final dim = renderLedFrame(scene(LedEffect.pulse), pixels: 1).single;
    final peak = renderLedFrame(
      scene(LedEffect.pulse),
      pixels: 1,
      t: const Duration(milliseconds: 600),
    ).single;
    expect(dim & 0xFF, lessThan(peak & 0xFF));
    expect(peak, blue);
  });

  test('a countdown lights its share of the row', () {
    final frame = renderLedFrame(
      scene(LedEffect.countdown, fraction: 0.5),
      pixels: 12,
    );
    expect(frame.take(6), everyElement(blue));
    expect(frame.skip(6), everyElement(0));
  });

  test('works for any number of lights', () {
    for (final effect in LedEffect.values) {
      for (final pixels in [1, 5, 24]) {
        expect(
          renderLedFrame(
            scene(effect),
            pixels: pixels,
            t: const Duration(milliseconds: 333),
          ),
          hasLength(pixels),
          reason: '$effect x $pixels',
        );
      }
    }
  });

  test('still poses show each effect at its most telling moment', () {
    final pulse = renderLedFrame(
      scene(LedEffect.pulse),
      pixels: 1,
      t: ledStillPose(LedEffect.pulse),
    );
    expect(pulse.single, blue);
    final blend = renderLedFrame(
      scene(LedEffect.blend),
      pixels: 1,
      t: ledStillPose(LedEffect.blend),
    );
    expect(blend.single, cyan);
    final orbit = renderLedFrame(
      scene(LedEffect.orbit),
      pixels: 12,
      t: ledStillPose(LedEffect.orbit),
    );
    expect(orbit.first, cyan);
    expect(orbit[6], blue);
  });

  test('only moving effects animate', () {
    expect(scene(LedEffect.solid).animated, isFalse);
    expect(scene(LedEffect.arc).animated, isFalse);
    expect(scene(LedEffect.countdown).animated, isFalse);
    expect(scene(LedEffect.spin).animated, isTrue);
    expect(scene(LedEffect.breathe).animated, isTrue);
  });

  group('the idle looks', () {
    LedScene look(String style, {double brightness = 1}) {
      final l = ledIdleLooks[style]!;
      return LedScene(
        name: 'idle',
        effect: l.effect,
        color: blue,
        palette: l.palette,
        brightness: brightness,
      );
    }

    test('are the Effect setting options, in order', () {
      expect(ledIdleLooks.keys, defs.ledIdleStyle.options);
      expect(
        defs.ledIdleStyle.optionLabels!.keys,
        unorderedEquals(ledIdleLooks.keys),
      );
    });

    test('render any number of lights with valid colors', () {
      for (final style in ledIdleLooks.keys) {
        for (final pixels in [1, 5, 12, 24]) {
          for (final ms in [0, 137, 777, 2400, 9001, 60000]) {
            final frame = renderLedFrame(
              look(style),
              pixels: pixels,
              t: Duration(milliseconds: ms),
            );
            expect(frame, hasLength(pixels), reason: style);
            for (final c in frame) {
              expect(c, inInclusiveRange(0, 0xFFFFFF), reason: style);
            }
          }
        }
      }
    });

    test('move over time and show something', () {
      for (final style in ledIdleLooks.keys) {
        final scene = look(style);
        final frames = {
          for (var ms = 0; ms < 12000; ms += 250)
            renderLedFrame(
              scene,
              pixels: 12,
              t: Duration(milliseconds: ms),
            ).join(','),
        };
        expect(
          frames.any((f) => f.split(',').any((c) => c != '0')),
          isTrue,
          reason: '$style is dark',
        );
        if (style != 'solid') {
          expect(frames.length, greaterThan(1), reason: '$style stands still');
        }
      }
    });

    test('the still pose of every look shows light', () {
      for (final style in ledIdleLooks.keys) {
        final scene = look(style);
        final frame = renderLedFrame(
          scene,
          pixels: 12,
          t: ledStillPose(scene.effect),
        );
        expect(frame.any((c) => c != 0), isTrue, reason: style);
      }
    });

    test('single color looks use the chosen color', () {
      for (final MapEntry(:key, :value) in ledIdleLooks.entries) {
        if (value.palette != null) continue;
        for (var ms = 0; ms < 4000; ms += 100) {
          final frame = renderLedFrame(
            look(key),
            pixels: 12,
            t: Duration(milliseconds: ms),
          );
          // Every light is some shade of blue or dark.
          for (final c in frame) {
            expect(c & 0xFFFF00, 0, reason: key);
          }
        }
      }
    });

    test('looks with colors of their own ignore the chosen color', () {
      final frame = renderLedFrame(look('rainbow'), pixels: 7);
      expect(frame.toSet(), hasLength(7));
      // Blocks of two lights, one color each, stepping a light at a time.
      expect(renderLedFrame(look('candy_cane'), pixels: 4), [
        0xFF0000,
        0xFF0000,
        0xFFFFFF,
        0xFFFFFF,
      ]);
      expect(
        renderLedFrame(
          look('candy_cane'),
          pixels: 4,
          t: const Duration(milliseconds: 250),
        ),
        [0xFF0000, 0xFFFFFF, 0xFFFFFF, 0xFF0000],
      );
    });

    test('brightness dims every look', () {
      final full = renderLedFrame(look('holiday'), pixels: 4);
      final half = renderLedFrame(look('holiday', brightness: 0.5), pixels: 4);
      for (var i = 0; i < 4; i++) {
        expect(
          (half[i] >> 16) & 0xFF,
          closeTo(((full[i] >> 16) & 0xFF) / 2, 1),
        );
      }
    });

    test('a scene with another palette is another scene', () {
      expect(look('frost'), isNot(look('forest')));
      expect(look('frost'), look('frost'));
      expect(look('frost').hashCode, look('frost').hashCode);
    });
  });
}
