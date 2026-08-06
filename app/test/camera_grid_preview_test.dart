import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/camera_settings.dart';

void main() {
  Future<List<Positioned>> pump(WidgetTester tester, int count) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CameraGridPreview(count: count)),
      ),
    );
    return tester
        .widgetList<Positioned>(find.byType(Positioned))
        .toList();
  }

  testWidgets('every count from 1 to 12 places every camera', (tester) async {
    for (var count = 1; count <= 12; count++) {
      final tiles = await pump(tester, count);
      expect(tiles.length, count, reason: '$count cameras');
    }
  });

  testWidgets('5 cameras lead with a large tile over the left half', (
    tester,
  ) async {
    final tiles = await pump(tester, 5);
    final first = tiles.first;
    expect(first.left, 0);
    expect(first.top, 0);
    expect(first.width, 105); // half of the 210 wide preview
    expect(first.height, 126); // both rows of the 4x2 grid
  });

  testWidgets('10 cameras stack two large tiles on the left', (tester) async {
    final tiles = await pump(tester, 10);
    // Large tiles at indexes 0 and 5, one above the other on the left half.
    expect(tiles[0].width, 105);
    expect(tiles[0].height, 63);
    expect(tiles[0].left, 0);
    expect(tiles[5].width, 105);
    expect(tiles[5].left, 0);
    expect(tiles[5].top, 63);
    // Everything else is small and on the right half.
    for (final index in [1, 2, 3, 4, 6, 7, 8, 9]) {
      expect(tiles[index].width, 52.5);
      expect(tiles[index].left, greaterThanOrEqualTo(105));
    }
  });

  testWidgets('11 cameras hold three large tiles', (tester) async {
    final tiles = await pump(tester, 11);
    // Large: top-left, top-middle, bottom-left; the rest are equal smalls.
    expect(tiles[0].width, 84);
    expect(tiles[0].height, 63);
    expect(tiles[1].left, 84);
    expect(tiles[1].width, 84);
    expect(tiles[4].left, 0);
    expect(tiles[4].top, 63);
    expect(tiles[4].width, 84);
    for (final index in [2, 3, 5, 6, 7, 8, 9, 10]) {
      expect(tiles[index].width, 42);
      expect(tiles[index].height, 31.5);
    }
  });

  testWidgets('7 cameras split the last quadrant into four', (tester) async {
    final tiles = await pump(tester, 7);
    for (final tile in tiles.take(3)) {
      expect(tile.width, 105);
      expect(tile.height, 63);
    }
    for (final tile in tiles.skip(3)) {
      expect(tile.width, 52.5);
      expect(tile.height, 31.5);
      expect(tile.left, greaterThanOrEqualTo(105));
      expect(tile.top, greaterThanOrEqualTo(63));
    }
  });

  testWidgets('8 cameras pair four large tiles with a small column', (
    tester,
  ) async {
    final tiles = await pump(tester, 8);
    // Large tiles at indexes 0, 1, 4, 5; the right column holds the rest.
    for (final index in [0, 1, 4, 5]) {
      expect(tiles[index].width, 70);
      expect(tiles[index].height, 63);
    }
    for (final index in [2, 3, 6, 7]) {
      expect(tiles[index].left, 140);
      expect(tiles[index].height, 31.5);
    }
  });

  testWidgets('cameras fill the largest tiles first', (tester) async {
    await pump(tester, 10);
    // In the 10 layout the two large tiles stack on the left; cameras one
    // and two own them, so number 2 sits bottom-left, not on a small tile.
    Positioned tileOf(String number) => tester.widget<Positioned>(
      find
          .ancestor(of: find.text(number), matching: find.byType(Positioned))
          .first,
    );
    final second = tileOf('2');
    expect(second.left, 0);
    expect(second.top, 63);
    expect(second.width, 105);
    // Camera three takes the first small tile on the right instead.
    final third = tileOf('3');
    expect(third.left, greaterThanOrEqualTo(105));
    expect(third.width, 52.5);
  });

  testWidgets('12 cameras fill the last quadrant with nine tiles', (
    tester,
  ) async {
    final tiles = await pump(tester, 12);
    for (final tile in tiles.take(3)) {
      expect(tile.width, 105);
      expect(tile.height, 63);
    }
    for (final tile in tiles.skip(3)) {
      expect(tile.width, 35);
      expect(tile.height, 21);
      expect(tile.left, greaterThanOrEqualTo(105));
      expect(tile.top, greaterThanOrEqualTo(63));
    }
  });
}
