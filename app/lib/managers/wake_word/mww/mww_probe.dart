import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'xnnpack_variable_ops.dart';

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
Future<Map<String, Object?>> probeMww(String url,
    {bool compare = false}) async {
  final result = <String, Object?>{'url': url};
  try {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      return {...result, 'ok': false, 'error': 'HTTP ${resp.statusCode}'};
    }
    result['bytes'] = resp.bodyBytes.length;

    // The same setup as the wake word isolate, so the probe answers for the
    // path that actually runs (see VariableOpsXnnpackDelegate).
    final delegate = VariableOpsXnnpackDelegate.create();
    final interpreter = Interpreter.fromBuffer(
      resp.bodyBytes,
      options: delegate == null
          ? null
          : (InterpreterOptions()..addDelegate(delegate)),
    );
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
      delegate?.delete();
    }
    if (compare) result['compare'] = compareDelegates(resp.bodyBytes);
  } catch (e) {
    result['ok'] = false;
    result['error'] = '$e';
  }
  return result;
}

/// Run one deterministic input sequence through the model twice, once on the
/// runtime's default setup and once on XNNPACK with variable operators (the
/// setup the wake word isolate uses, see [VariableOpsXnnpackDelegate]), and
/// report both output streams. The models are stateful, so a long sequence
/// is what proves the delegated ring buffers behave like the built-in ones.
///
/// The default setup is the one issue #416 is about: on a device with cores
/// offline at that moment this comparison itself crashes the app. That is
/// the bug on display, not a fault of the probe.
Map<String, Object?> compareDelegates(Uint8List model, {int steps = 80}) {
  final delegate = VariableOpsXnnpackDelegate.create();
  if (delegate == null) return {'ok': false, 'error': 'delegate unavailable'};
  final a = Interpreter.fromBuffer(model);
  final b = Interpreter.fromBuffer(model,
      options: InterpreterOptions()..addDelegate(delegate));
  try {
    final inA = a.getInputTensor(0);
    final inB = b.getInputTensor(0);
    final outA = a.getOutputTensor(0);
    final outB = b.getOutputTensor(0);
    final n = inA.data.length;
    if (n != inB.data.length) {
      return {
        'ok': false,
        'error': 'input sizes differ: $n vs ${inB.data.length}',
      };
    }
    var seed = 0x2545F491;
    final input = Uint8List(n);
    final seqA = <int>[];
    final seqB = <int>[];
    var maxDiff = 0;
    var equal = 0;
    for (var s = 0; s < steps; s++) {
      for (var i = 0; i < n; i++) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        // Mostly quiet features with bursts, like speech over a quiet room.
        input[i] = (s ~/ 10).isOdd ? (seed >> 16) & 0xff : (seed >> 20) & 0x1f;
      }
      inA.data = input;
      inB.data = input;
      a.invoke();
      b.invoke();
      final oa = outA.data[0];
      final ob = outB.data[0];
      seqA.add(oa);
      seqB.add(ob);
      final d = (oa - ob).abs();
      if (d > maxDiff) maxDiff = d;
      if (d == 0) equal++;
    }
    return {
      'ok': true,
      'steps': steps,
      'maxDiff': maxDiff,
      'equalSteps': equal,
      'default': seqA,
      'variableOps': seqB,
    };
  } catch (e) {
    return {'ok': false, 'error': '$e'};
  } finally {
    a.close();
    b.close();
    delegate.delete();
  }
}
