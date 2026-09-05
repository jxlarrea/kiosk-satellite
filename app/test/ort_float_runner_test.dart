import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/ort_float_runner.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/ort_init.dart';
import 'package:kiosk_satellite/managers/wake_word/vsww/ort_tensor_io.dart';

// ONNX IR 8, opset 13. Both graphs take x: float32[1,4]. The first returns
// Add(x,x), the second ArgMax(x) with an int64 output. No weights or downloads.
final _add = base64Decode(
    'CAg6RwoOCgF4CgF4EgF5IgNBZGQSC3J1bm5lcl90ZXN0WhMKAXgSDgoMCAESCAoCCAEKAggEYhMKAXkSDgoMCAESCAoCCAEKAggEQgIQDQ==');
final _argmax = base64Decode(
    'CAg6RwoOCgF4EgF5IgZBcmdNYXgSC3J1bm5lcl90ZXN0WhMKAXgSDgoMCAESCAoCCAEKAggEYhMKAXkSDgoMCAcSCAoCCAEKAggEQgIQDQ==');

bool _nativeAvailable() {
  try {
    DynamicLibrary.open(
        Platform.isAndroid ? 'libonnxruntime.so' : 'libonnxruntime.so.1.15.1');
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  group('persistent ONNX runner', () {
    setUpAll(ensureOrtInit);

    OrtSession session(Uint8List model) {
      final options = OrtSessionOptions()
        ..setIntraOpNumThreads(1)
        ..setInterOpNumThreads(1);
      try {
        return OrtSession.fromBuffer(model, options);
      } finally {
        options.release();
      }
    }

    test('reuses output storage and matches ordinary runs for changing inputs',
        () {
      final model = session(_add);
      final options = OrtRunOptions();
      final input = ReusableInputTensor.create([1, 4]);
      final runner = OrtFloatRunner(model, options, input, expectedElements: 4);
      try {
        Float32List? previous;
        for (var i = 0; i < 200; i++) {
          final values =
              Float32List.fromList([i.toDouble(), -i / 3, .125, -32768]);
          input.write(values);
          final output = runner.run();
          if (previous != null) expect(identical(output, previous), isTrue);
          previous = output;
          final expected =
              Float32List.fromList([for (final x in values) x * 2]);
          expect(output, expected);
          final ordinary = model.run(options, {'x': input.tensor});
          try {
            final actual = Float32List(4);
            readFloatTensor(ordinary.single!, actual);
            expect(output, actual);
          } finally {
            for (final value in ordinary) {
              value?.release();
            }
          }
        }
        expect(() => input.write(Float32List(3)), throwsArgumentError);
      } finally {
        runner.release();
        runner.release();
        input.release();
        options.release();
        model.release();
      }
      expect(runner.run, throwsStateError);
    });

    test('rejects shape and dtype mismatches without retaining failed output',
        () {
      for (final fixture in [_add, _argmax]) {
        final model = session(fixture);
        final options = OrtRunOptions();
        final input = ReusableInputTensor.create([1, 4]);
        final runner = OrtFloatRunner(model, options, input,
            expectedElements: identical(fixture, _add) ? 5 : 4);
        try {
          for (var i = 0; i < 3; i++) {
            expect(runner.run, throwsStateError);
          }
        } finally {
          runner.release();
          input.release();
          options.release();
          model.release();
        }
      }
    });
  }, skip: _nativeAvailable() ? false : 'ONNX native library not installed');
}
