import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;

/// Which Immich photos share the screen: two portrait shots side by side
/// fill a landscape panel that either one alone would leave half empty.
void main() {
  const wide = 1280 / 800; // Echo Show 8 / Tab S8 class
  const portrait = 3 / 4;
  const tall = 9 / 16;
  const landscape = 4 / 3;

  group('immichPairsPortrait', () {
    test('two portrait photos on a landscape panel pair', () {
      expect(
        immichPairsPortrait(screenAspect: wide, first: portrait, second: tall),
        isTrue,
      );
    });

    test('a landscape photo never pairs, whichever half it is', () {
      expect(
        immichPairsPortrait(
          screenAspect: wide,
          first: portrait,
          second: landscape,
        ),
        isFalse,
      );
      expect(
        immichPairsPortrait(
          screenAspect: wide,
          first: landscape,
          second: portrait,
        ),
        isFalse,
      );
    });

    test('a square photo stays on its own: half a screen each reads small',
        () {
      expect(
        immichPairsPortrait(screenAspect: wide, first: 1, second: portrait),
        isFalse,
      );
    });

    test('an unmeasurable photo never pairs', () {
      expect(
        immichPairsPortrait(screenAspect: wide, first: null, second: portrait),
        isFalse,
      );
      expect(
        immichPairsPortrait(screenAspect: wide, first: portrait, second: null),
        isFalse,
      );
    });

    test('a portrait or squarish panel has no room for two', () {
      expect(
        immichPairsPortrait(
          screenAspect: 800 / 1280,
          first: portrait,
          second: portrait,
        ),
        isFalse,
      );
      expect(
        immichPairsPortrait(screenAspect: 1, first: portrait, second: portrait),
        isFalse,
      );
    });
  });

  group('the primitives the slideshow gates its extra fetch on', () {
    test('portrait is strictly taller than wide, square excluded', () {
      expect(immichPortraitPhoto(tall), isTrue);
      expect(immichPortraitPhoto(portrait), isTrue);
      expect(immichPortraitPhoto(1), isFalse);
      expect(immichPortraitPhoto(landscape), isFalse);
      expect(immichPortraitPhoto(null), isFalse);
    });

    test('a panel needs real width to hold a pair', () {
      expect(immichPairableScreen(wide), isTrue);
      expect(immichPairableScreen(16 / 9), isTrue);
      expect(immichPairableScreen(1), isFalse);
    });
  });

  group('exifAspect', () {
    test('reads the shape the server reported', () {
      expect(
        exifAspect({'exifImageWidth': 4032, 'exifImageHeight': 3024}),
        closeTo(4 / 3, 0.001),
      );
    });

    test('a turned photo measures portrait, whatever the frame says', () {
      // The phone case: a landscape frame plus "turn me a quarter circle".
      expect(
        exifAspect({
          'exifImageWidth': 4032,
          'exifImageHeight': 3024,
          'orientation': '6',
        }),
        closeTo(3 / 4, 0.001),
      );
    });

    test('missing or unusable dimensions read as unknown', () {
      expect(exifAspect(null), isNull);
      expect(exifAspect({'exifImageWidth': 4032}), isNull);
      expect(exifAspect({'exifImageWidth': 0, 'exifImageHeight': 100}), isNull);
    });
  });

  group('arrangeImmichPairs', () {
    ImmichAsset photo(String id, double aspect) =>
        ImmichAsset(id: id, isVideo: false, aspect: aspect);
    List<String> ids(List<ImmichAsset> assets) =>
        [for (final a in assets) a.id];

    test('a portrait photo reaches past landscape ones for its partner', () {
      final arranged = arrangeImmichPairs(
        [photo('p1', portrait), photo('l1', landscape), photo('p2', portrait)],
        screenAspect: wide,
      );
      expect(ids(arranged), ['p1', 'p2', 'l1']);
    });

    test('every photo is kept exactly once', () {
      final input = [
        photo('p1', portrait),
        photo('l1', landscape),
        photo('p2', portrait),
        photo('p3', portrait),
        photo('l2', landscape),
        photo('p4', portrait),
      ];
      final arranged = arrangeImmichPairs(input, screenAspect: wide);
      expect(ids(arranged)..sort(), ids(input)..sort());
      expect(ids(arranged), ['p1', 'p2', 'l1', 'p3', 'p4', 'l2']);
    });

    test('the odd portrait photo out keeps its place and shows alone', () {
      final arranged = arrangeImmichPairs(
        [photo('p1', portrait), photo('p2', portrait), photo('p3', portrait)],
        screenAspect: wide,
      );
      expect(ids(arranged), ['p1', 'p2', 'p3']);
    });

    test('videos are never pulled in as a partner', () {
      final arranged = arrangeImmichPairs(
        [
          photo('p1', portrait),
          const ImmichAsset(id: 'v1', isVideo: true),
          photo('p2', portrait),
        ],
        screenAspect: wide,
      );
      expect(ids(arranged), ['p1', 'p2', 'v1']);
    });

    test('a photo of unreported shape is left where it is', () {
      final arranged = arrangeImmichPairs(
        [
          photo('p1', portrait),
          const ImmichAsset(id: 'unknown', isVideo: false),
          photo('p2', portrait),
        ],
        screenAspect: wide,
      );
      expect(ids(arranged), ['p1', 'p2', 'unknown']);
    });

    test('a portrait panel is left completely alone', () {
      final input = [photo('p1', portrait), photo('l1', landscape),
          photo('p2', portrait)];
      expect(
        ids(arrangeImmichPairs(input, screenAspect: 800 / 1280)),
        ids(input),
      );
    });
  });

  test('pairing is on by default, like filling the screen', () {
    expect(defs.screensaverImmichPairPortrait.defaultValue, isTrue);
    expect(
      defs.allSettings.contains(defs.screensaverImmichPairPortrait),
      isTrue,
    );
  });
}
