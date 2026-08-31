import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/ui_scale.dart';

void main() {
  // The default test window: 800x600 logical at a devicePixelRatio of 3.
  const window = Size(800, 600);
  const probe = Key('probe');

  Future<void> pump(
    WidgetTester tester, {
    required double scale,
    required Widget child,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, c) => UiScaler(scale: scale, child: c!),
        home: child,
      ),
    );
  }

  testWidgets('1.0 changes nothing', (tester) async {
    late MediaQueryData mq;
    await pump(
      tester,
      scale: 1.0,
      child: Builder(
        builder: (context) {
          mq = MediaQuery.of(context);
          return const SizedBox.expand(key: probe);
        },
      ),
    );
    expect(mq.size, window);
    expect(mq.devicePixelRatio, 3.0);
    expect(tester.getSize(find.byKey(probe)), window);
  });

  testWidgets('the chrome lays out against the divided window', (tester) async {
    late MediaQueryData mq;
    await pump(
      tester,
      scale: 1.5,
      child: Builder(
        builder: (context) {
          mq = MediaQuery.of(context);
          return const SizedBox.expand(key: probe);
        },
      ),
    );
    // Divided size, multiplied ratio: size times ratio stays physical.
    expect(mq.size, Size(window.width / 1.5, window.height / 1.5));
    expect(mq.devicePixelRatio, 4.5);
    expect(mq.size.width * mq.devicePixelRatio, window.width * 3.0);
    expect(
      tester.getSize(find.byKey(probe)),
      Size(window.width / 1.5, window.height / 1.5),
    );
  });

  testWidgets('a widget paints scaled and answers touch at its painted spot', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      scale: 1.5,
      child: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    // Laid out at 100 logical, painted at 150 on screen: a tap at 130
    // lands inside the painted square (and would miss an unscaled one),
    // a tap past 150 misses it.
    await tester.tapAt(const Offset(130, 130));
    expect(taps, 1);
    await tester.tapAt(const Offset(200, 200));
    expect(taps, 1);
  });

  testWidgets('touch reaches the far screen corner when the chrome shrinks', (
    tester,
  ) async {
    // The regression FittedBox exists to prevent: at a factor below 1 the
    // scaled space is LARGER than the window, and a naive transform's
    // bounds check against the window size would cull touches near the
    // bottom-right corner.
    var taps = 0;
    await pump(
      tester,
      scale: 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => taps++,
        child: const SizedBox.expand(),
      ),
    );
    await tester.tapAt(Offset(window.width - 1, window.height - 1));
    expect(taps, 1);
  });

  testWidgets('UiScaleExempt lays its child out at true screen size', (
    tester,
  ) async {
    for (final scale in [0.5, 1.0, 1.5]) {
      await pump(
        tester,
        scale: scale,
        child: const Stack(
          fit: StackFit.expand,
          children: [UiScaleExempt(child: SizedBox.expand(key: probe))],
        ),
      );
      // Whatever the factor, the exempted child keeps the slot's true
      // on-screen size: this is what keeps the WebView from ever
      // relayouting or resampling as the slider moves.
      expect(tester.getSize(find.byKey(probe)), window, reason: '$scale');
    }
  });

  testWidgets('an exempted child still answers touch across the screen', (
    tester,
  ) async {
    final hits = <Offset>[];
    await pump(
      tester,
      scale: 1.5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          UiScaleExempt(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => hits.add(d.localPosition),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
    // Net identity: a screen position arrives as the same local position.
    await tester.tapAt(const Offset(700, 500));
    expect(hits, hasLength(1));
    expect(hits.single.dx, closeTo(700, 0.1));
    expect(hits.single.dy, closeTo(500, 0.1));
  });

  test('the setting is a Device page percent slider', () {
    expect(defs.uiScale.category, 'Device');
    expect(defs.uiScale.section, 'User Interface');
    expect(defs.uiScale.defaultValue, 100);
    expect(defs.uiScale.min, 50);
    expect(defs.uiScale.max, 150);
    expect(defs.uiScale.unit, '%');
    expect(defs.allSettings, contains(defs.uiScale));
  });
}
