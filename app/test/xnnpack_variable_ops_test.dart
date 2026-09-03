import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/wake_word/mww/xnnpack_variable_ops.dart';

void main() {
  test('the hand-applied XNNPACK delegate is Android only', () {
    // Off Android there is no libtensorflowlite_jni.so to look the symbols
    // up in; the isolate then falls back to the runtime's default options
    // rather than failing to load a model at all.
    expect(VariableOpsXnnpackDelegate.create(), isNull);
  });
}
