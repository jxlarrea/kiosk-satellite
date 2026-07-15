import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Nested zero-filled lists matching a tensor shape, e.g. [1,3,40].
Object _zeros(List<int> shape) {
  if (shape.length == 1) return List<int>.filled(shape.first, 0);
  return List<Object>.generate(shape.first, (_) => _zeros(shape.sublist(1)));
}

/// Can this device's TFLite runtime actually load and run a microWakeWord
/// model?
///
/// The models are stateful: they take one feature frame at a time and keep
/// their own ring buffers through resource-variable ops (VAR_HANDLE /
/// READ_VARIABLE / ASSIGN_VARIABLE), and their input tensor is int8 quantized.
/// The browser runs them under TFLite WASM, which is the same runtime family,
/// but that is an argument rather than evidence. This answers it on the actual
/// hardware before any of the fixed-point frontend gets ported.
Future<Map<String, Object?>> probeMww(String url) async {
  final result = <String, Object?>{'url': url};
  try {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      return {...result, 'ok': false, 'error': 'HTTP ${resp.statusCode}'};
    }
    result['bytes'] = resp.bodyBytes.length;

    final interpreter = Interpreter.fromBuffer(resp.bodyBytes);
    try {
      String describe(Tensor t) => '${t.name} ${t.shape} ${t.type}';
      final inputs = interpreter.getInputTensors();
      final outputs = interpreter.getOutputTensors();
      result['inputs'] = inputs.map(describe).toList();
      result['outputs'] = outputs.map(describe).toList();

      // Invoke with zeros, shaped exactly as the tensors declare: proves the
      // graph is executable here, resource variables and all, not merely
      // parseable. Run it repeatedly to time steady state, since the first
      // invoke pays one-off allocation.
      final inShape = inputs.first.shape; // e.g. [1, 3, 40]
      final outShape = outputs.first.shape; // e.g. [1, 1]
      final input = _zeros(inShape);
      final output = <int, Object>{0: _zeros(outShape)};

      interpreter.runForMultipleInputs([input], output); // warm up
      const iterations = 50;
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        interpreter.runForMultipleInputs([input], output);
      }
      sw.stop();
      result['invokeUs'] = (sw.elapsedMicroseconds / iterations).round();
      result['sampleOutput'] = '$output';
      result['ok'] = true;
    } finally {
      interpreter.close();
    }
  } catch (e) {
    result['ok'] = false;
    result['error'] = '$e';
  }
  return result;
}
