import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/browser/carousel_script.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;

/// Carousel priority over gesture-handling cards (issue #238): a swipe
/// starting on a fullscreen camera card (a fullscreen video under the
/// finger) is claimable once the opt-in flag is on, while sliders,
/// dialogs, maps, form controls and natively scrolling cards stay
/// protected unconditionally. The script is a string baked into the
/// page, so the contract is asserted on its markers.
void main() {
  test('the toggle exists, off by default, gated on the carousel', () {
    expect(defs.haCarouselOverCards.defaultValue, isFalse);
    expect(defs.haCarouselOverCards.dependsOn, defs.haDashboardCarousel.key);
    expect(defs.allSettings, contains(defs.haCarouselOverCards));
  });

  test('media elements and swipe cards yield only while the flag is off',
      () {
    // Split out of the unconditional block...
    expect(dashboardCarouselScript,
        isNot(contains('button|a|video')));
    expect(dashboardCarouselScript, contains('video|audio|canvas|iframe'));
    // ...and consulted only when the opt-in flag is not set.
    expect(dashboardCarouselScript, contains('!greedy'));
    expect(dashboardCarouselScript,
        contains('window.__ksCarouselOverCards === true'));
  });

  test('sliders, dialogs and maps are blocked before the greedy check', () {
    final unconditional = dashboardCarouselScript.indexOf("indexOf('slider')");
    final greedy = dashboardCarouselScript.indexOf('!greedy');
    expect(unconditional, greaterThan(-1));
    expect(greedy, greaterThan(-1));
    expect(unconditional, lessThan(greedy));
    expect(dashboardCarouselScript, contains("indexOf('dialog')"));
    expect(dashboardCarouselScript, contains("indexOf('-map')"));
  });

  test('a locked greedy drag eats the touch and pointer streams', () {
    expect(dashboardCarouselScript, contains('e.stopPropagation()'));
    // Pointer events are a separate dispatch from touch: both release
    // and move must be silenced or a pointer-driven card reacts anyway.
    expect(dashboardCarouselScript, contains("'pointermove', eatPointer"));
    expect(dashboardCarouselScript, contains("'pointerup', eatPointer"));
    expect(dashboardCarouselScript, contains("e.pointerType === 'touch'"));
  });
}
