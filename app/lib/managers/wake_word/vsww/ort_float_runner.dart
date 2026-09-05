import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:onnxruntime/onnxruntime.dart';
// ignore: implementation_imports
import 'package:onnxruntime/src/bindings/onnxruntime_bindings_generated.dart'
    as bg;

import 'ort_tensor_io.dart';

final _run = OrtEnv.instance.ortApiPtr.ref.Run.asFunction<
    bg.OrtStatusPtr Function(
      ffi.Pointer<bg.OrtSession>,
      ffi.Pointer<bg.OrtRunOptions>,
      ffi.Pointer<ffi.Pointer<ffi.Char>>,
      ffi.Pointer<ffi.Pointer<bg.OrtValue>>,
      int,
      ffi.Pointer<ffi.Pointer<ffi.Char>>,
      int,
      ffi.Pointer<ffi.Pointer<bg.OrtValue>>,
    )>();
final _releaseValue = OrtEnv.instance.ortApiPtr.ref.ReleaseValue
    .asFunction<void Function(ffi.Pointer<bg.OrtValue>)>();
final _getData = OrtEnv.instance.ortApiPtr.ref.GetTensorMutableData.asFunction<
    bg.OrtStatusPtr Function(
      ffi.Pointer<bg.OrtValue>,
      ffi.Pointer<ffi.Pointer<ffi.Void>>,
    )>();

/// Synchronous CPU inference with one fixed float input and one float output.
///
/// Names and pointer arrays live as long as the runner. ORT allocates the
/// output on the first run, then writes into that same tensor on later runs
/// (OrtApi::Run accepts caller-provided output values). This avoids the
/// plugin's per-run name allocations, leaked UTF8 strings, shape queries,
/// output wrappers and output copies. Models must have a fixed output shape.
///
/// The session, input and run options belong to the caller and must outlive
/// this runner. Release the runner before releasing those objects.
class OrtFloatRunner {
  OrtFloatRunner(
    OrtSession session,
    OrtRunOptions options,
    ReusableInputTensor input, {
    this.expectedElements,
  })  : _session = ffi.Pointer.fromAddress(session.address),
        _options = ffi.Pointer.fromAddress(options.address) {
    try {
      _inputNames.value = session.inputNames.first.toNativeUtf8().cast();
      _outputNames.value = session.outputNames.first.toNativeUtf8().cast();
      _inputs.value = input.tensor.ptr;
    } catch (_) {
      release();
      rethrow;
    }
  }

  final int? expectedElements;
  final ffi.Pointer<bg.OrtSession> _session;
  final ffi.Pointer<bg.OrtRunOptions> _options;
  final _inputNames = calloc<ffi.Pointer<ffi.Char>>();
  final _outputNames = calloc<ffi.Pointer<ffi.Char>>();
  final _inputs = calloc<ffi.Pointer<bg.OrtValue>>();
  final _outputs = calloc<ffi.Pointer<bg.OrtValue>>();
  Float32List? _view;
  bool _released = false;

  /// Native output view, valid until the next run or release. Do not retain
  /// it beyond the runner's lifetime or change it while inference runs.
  Float32List run() {
    if (_released) throw StateError('runner released');
    try {
      OrtStatus.checkOrtStatus(
        _run(
          _session,
          _options,
          _inputNames,
          _inputs,
          1,
          _outputNames,
          1,
          _outputs,
        ),
      );
      return _view ??= _outputView();
    } catch (_) {
      // A failed run can leave a partially written output. Never expose it.
      _clearOutput();
      rethrow;
    }
  }

  Float32List _outputView() {
    final info = calloc<ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>>();
    final type = calloc<ffi.Int32>();
    final count = calloc<ffi.Size>();
    final data = calloc<ffi.Pointer<ffi.Void>>();
    final api = OrtEnv.instance.ortApiPtr.ref;
    try {
      OrtStatus.checkOrtStatus(
        api.GetTensorTypeAndShape.asFunction<
            bg.OrtStatusPtr Function(
              ffi.Pointer<bg.OrtValue>,
              ffi.Pointer<ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>>,
            )>()(_outputs.value, info),
      );
      OrtStatus.checkOrtStatus(
        api.GetTensorElementType.asFunction<
            bg.OrtStatusPtr Function(
              ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>,
              ffi.Pointer<ffi.Int32>,
            )>()(info.value, type),
      );
      OrtStatus.checkOrtStatus(
        api.GetTensorShapeElementCount.asFunction<
            bg.OrtStatusPtr Function(
              ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>,
              ffi.Pointer<ffi.Size>,
            )>()(info.value, count),
      );
      if (type.value != ONNXTensorElementDataType.float.value ||
          count.value < 1 ||
          (expectedElements != null && count.value != expectedElements)) {
        throw StateError(
          'expected float32 output with '
          '${expectedElements ?? 'at least one'} elements, got type '
          '${type.value} with ${count.value} elements',
        );
      }
      OrtStatus.checkOrtStatus(_getData(_outputs.value, data));
      return data.value.cast<ffi.Float>().asTypedList(count.value);
    } finally {
      if (info.value != ffi.nullptr) {
        api.ReleaseTensorTypeAndShapeInfo.asFunction<
            void Function(
                ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>)>()(info.value);
      }
      calloc.free(data);
      calloc.free(count);
      calloc.free(type);
      calloc.free(info);
    }
  }

  void _clearOutput() {
    _view = null;
    if (_outputs.value != ffi.nullptr) {
      _releaseValue(_outputs.value);
      _outputs.value = ffi.nullptr;
    }
  }

  void release() {
    if (_released) return;
    _released = true;
    _clearOutput();
    calloc.free(_inputNames.value);
    calloc.free(_outputNames.value);
    calloc.free(_inputNames);
    calloc.free(_outputNames);
    calloc.free(_inputs);
    calloc.free(_outputs);
  }
}
