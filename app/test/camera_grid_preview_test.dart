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

  testWidgets('10 cameras lead with two large tiles', (tester) async {
    final tiles = await pump(tester, 10);
    expect(tiles[0].width, 105);
    expect(tiles[0].height, 63);
    expect(tiles[1].left, 105);
    expect(tiles[1].width, 105);
    // The eight remaining tiles fill the lower half, four per row.
    expect(tiles[2].top, 63);
    expect(tiles[2].width, 210 / 4);
  });
}
