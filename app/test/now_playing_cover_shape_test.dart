import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/sendspin_player_overlay.dart';

// Issue #1511: Now Playing keeps wide and tall artwork in its own shape
// instead of cropping it to a square.
void main() {
  test('album covers keep the square crop', () {
    expect(nowPlayingCoverSize(1, 800, 600), const Size(600, 600));
    expect(nowPlayingCoverSize(1.2, 800, 600), const Size(600, 600));
    expect(nowPlayingCoverSize(0.8, 800, 600), const Size(600, 600));
  });

  test('a wide frame fills the width it can', () {
    final wide = nowPlayingCoverSize(16 / 9, 864, 1100);
    expect(wide.width, 864);
    expect(wide.height, closeTo(486, 0.01));
    final capped = nowPlayingCoverSize(16 / 9, 1600, 360);
    expect(capped.width, closeTo(640, 0.01));
    expect(capped.height, 360);
  });

  test('a poster fills the height it can', () {
    final poster = nowPlayingCoverSize(2 / 3, 864, 600);
    expect(poster.width, closeTo(400, 0.01));
    expect(poster.height, 600);
    final narrow = nowPlayingCoverSize(2 / 3, 300, 1200);
    expect(narrow.width, 300);
    expect(narrow.height, closeTo(450, 0.01));
  });

  test('bad sizes fall back to a square and never go negative', () {
    expect(nowPlayingCoverSize(double.nan, 500, 400), const Size(400, 400));
    expect(nowPlayingCoverSize(0, 500, 400), const Size(400, 400));
    expect(nowPlayingCoverSize(16 / 9, -10, 400), Size.zero);
    expect(nowPlayingCoverSize(16 / 9, 0, 0), Size.zero);
  });
}
