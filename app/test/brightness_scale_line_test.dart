import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/screen/screen_manager.dart';

void main() {
  test('the scale line carries what the device reports beside the scale', () {
    // A Redmi Pad 2 (issue #1430): the constant says 4095 and Android
    // converts the setting on 255.
    expect(
      ScreenManager.brightnessScaleLine({
        'min': 10,
        'max': 255,
        'reportedMax': 4095,
        'frameworkMax': 255,
      }),
      'brightness scale 10..255, reported 4095, framework 255',
    );
  });

  test('the scale line leaves out what the device did not answer', () {
    expect(
      ScreenManager.brightnessScaleLine({'min': 0, 'max': 255}),
      'brightness scale 0..255',
    );
    expect(
      ScreenManager.brightnessScaleLine({
        'min': 0,
        'max': 255,
        'reportedMax': null,
        'frameworkMax': 255,
      }),
      'brightness scale 0..255, framework 255',
    );
  });
}
