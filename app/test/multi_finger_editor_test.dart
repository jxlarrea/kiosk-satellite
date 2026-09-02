import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The Show fingers camera gesture reuses the `fingers` key of the touch
// gestures with its own 1..5 dropdown. Both editors once saved a touch
// gesture from that dropdown, so a multi-finger tap or hold created in
// the remote admin came out as five fingers and the device editor
// dropped the pick. These pin each editor to its own 2/3 dropdown.
void main() {
  test('the remote admin saves the touch gesture from its own dropdown', () {
    final source = File(
      'assets/remote-ui/static/gestures.js',
    ).readAsStringSync();
    final touch = RegExp(
      r"if \(type === 'finger_taps' \|\| type === 'finger_hold'\) \{\s*"
      r'trigger\.fingers = Number\((\w+)\.select\.value\);',
    ).firstMatch(source);
    expect(touch, isNotNull);
    expect(touch!.group(1), 'fingersSel');
    expect(
      source,
      contains(
        "if (type === 'fingers') "
        'trigger.fingers = Number(fingerCountSel.select.value);',
      ),
    );
  });

  test('the device editor keeps the touch gesture finger pick', () {
    final source = File('lib/ui/gesture_settings.dart').readAsStringSync();
    final touch = RegExp(
      r"if \(type == 'finger_taps' \|\| type == 'finger_hold'\)\s*"
      r'LabeledField\((.*?)onChanged: \(value\) => setDialogState\(\s*'
      r'\(\) => (\w+) = value \?\? \w+,',
      dotAll: true,
    ).firstMatch(source);
    expect(touch, isNotNull);
    expect(touch!.group(2), 'fingers');
    expect(
      source,
      contains(
        "if (type == 'finger_taps' || type == 'finger_hold') "
        "'fingers': fingers,",
      ),
    );
  });
}
