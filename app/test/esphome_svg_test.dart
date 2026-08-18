import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the ESPHome mark parses and renders like its siblings',
      (tester) async {
    for (final asset in [
      'assets/svg/esphome.svg',
      'assets/svg/music-assistant.svg',
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SvgPicture.asset(
            asset,
            width: 21,
            height: 21,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: asset);
      expect(find.byType(SvgPicture), findsOneWidget, reason: asset);
    }
  });
}
