import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';

/// Fill the screen (issue #378), the rule every photo mode shares: Off
/// never crops, Always always does, and Smart crops only what the panel's
/// own shape can take.
void main() {
  // A 16:10 tablet in landscape, the panel these numbers were tuned on.
  const panel = 1.6;
  // An Echo Show 5 is nearly 2:1, which is what makes a 4:3 camera photo
  // on it the case the reporter hit: too far off to crop under Smart.
  const wide = 960 / 480;
  const photo43 = 4 / 3;
  const photo169 = 16 / 9;
  const portrait = 3 / 4;

  group('Smart', () {
    test('crops the common camera frames on a landscape panel', () {
      expect(photoCovers('smart', photo43, panel), isTrue);
      expect(photoCovers('smart', photo169, panel), isTrue);
    });

    test('keeps the frame where the crop would gut the photo', () {
      expect(photoCovers('smart', portrait, panel), isFalse);
      expect(photoCovers('smart', photo43, wide), isFalse);
    });

    test('crops a portrait photo in a portrait half of the panel', () {
      expect(photoCovers('smart', portrait, panel / 2), isTrue);
    });

    test('keeps the frame when the shape could not be read', () {
      expect(photoCovers('smart', null, panel), isFalse);
    });
  });

  group('Always', () {
    test('crops whatever the shape, including the reporter case', () {
      expect(photoCovers('always', photo43, wide), isTrue);
      expect(photoCovers('always', portrait, panel), isTrue);
    });

    test('still crops when the shape could not be read', () {
      expect(photoCovers('always', null, panel), isTrue);
    });
  });

  group('Off', () {
    test('never crops, whatever the shapes', () {
      expect(photoCovers('off', photo43, panel), isFalse);
      expect(photoCovers('off', panel, panel), isFalse);
      expect(photoCovers('off', null, panel), isFalse);
    });
  });

  test('a frame with no size yet decides nothing under Smart', () {
    expect(photoCovers('smart', photo43, 0), isFalse);
  });
}
