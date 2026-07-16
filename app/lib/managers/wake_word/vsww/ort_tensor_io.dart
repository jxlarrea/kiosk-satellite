import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:onnxruntime/onnxruntime.dart';
// ignore: implementation_imports
import 'package:onnxruntime/src/bindings/onnxruntime_bindings_generated.dart'
    as bg;

/// Direct FFI tensor I/O for the vsWakeWord hot path.
///
/// The onnxruntime plugin's convenience surface pays a boxing tax on every
/// call: `OrtValueTensor.createTensorWithDataList` flattens the input through
/// a growable `List<double>` before copying it into a fresh native buffer, and
/// `OrtValue.value` materializes the output as nested `List<List<List<double>>>`.
/// At one inference per 80 ms chunk that tax dominates the whole pipeline
/// (measured ~1.9 ms of a ~2.7 ms chunk on a Tab S8), so the streaming loop
/// uses these helpers instead: one input tensor created once over a persistent
/// native buffer that features are memcpy'd into, and outputs read straight
/// out of ORT's buffer into a reusable `Float32List`.
///
/// Only float32 tensors are supported — that is all `vs-wake-word-ctc-v1`
/// models use.

// Cached FFI trampolines (creating them per call is measurable overhead).
// Lazy so they resolve after `ensureOrtInit` has loaded the ORT env.
final _getTensorMutableData = OrtEnv.instance.ortApiPtr.ref
    .GetTensorMutableData
    .asFunction<
        bg.OrtStatusPtr Function(
            ffi.Pointer<bg.OrtValue>, ffi.Pointer<ffi.Pointer<ffi.Void>>)>();
final _getTensorTypeAndShape = OrtEnv.instance.ortApiPtr.ref
    .GetTensorTypeAndShape
    .asFunction<
        bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtValue>,
            ffi.Pointer<ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>>)>();
final _getTensorShapeElementCount = OrtEnv.instance.ortApiPtr.ref
    .GetTensorShapeElementCount
    .asFunction<
        bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>,
            ffi.Pointer<ffi.Size>)>();
final _releaseTensorTypeAndShapeInfo = OrtEnv
    .instance.ortApiPtr.ref.ReleaseTensorTypeAndShapeInfo
    .asFunction<void Function(ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>)>();

/// A float32 input tensor created once and written per inference.
///
/// `CreateTensorWithDataAsOrtValue` wraps the caller's buffer rather than
/// copying it, so [write] (a memcpy into that buffer) is all it takes to feed
/// the next window. The one tensor can back any number of sessions' runs, as
/// long as they all take the same input shape.
class ReusableInputTensor {
  ReusableInputTensor._(this.tensor, this._buf, this._length);

  final OrtValueTensor tensor;
  final ffi.Pointer<ffi.Float> _buf;
  final int _length;

  static ReusableInputTensor create(List<int> shape) {
    var count = 1;
    for (final d in shape) {
      count *= d;
    }
    final buf = calloc<ffi.Float>(count);
    final shapePtr = calloc<ffi.Int64>(shape.length);
    for (var i = 0; i < shape.length; i++) {
      shapePtr[i] = shape[i];
    }
    final memInfoPP = calloc<ffi.Pointer<bg.OrtMemoryInfo>>();
    final valuePP = calloc<ffi.Pointer<bg.OrtValue>>();
    try {
      // Owned by the allocator — queried, not created, so never released here.
      var status = OrtEnv.instance.ortApiPtr.ref.AllocatorGetInfo.asFunction<
              bg.OrtStatusPtr Function(ffi.Pointer<bg.OrtAllocator>,
                  ffi.Pointer<ffi.Pointer<bg.OrtMemoryInfo>>)>()(
          OrtAllocator.instance.ptr, memInfoPP);
      OrtStatus.checkOrtStatus(status);
      status = OrtEnv.instance.ortApiPtr.ref.CreateTensorWithDataAsOrtValue
              .asFunction<
                  bg.OrtStatusPtr Function(
                      ffi.Pointer<bg.OrtMemoryInfo>,
                      ffi.Pointer<ffi.Void>,
                      int,
                      ffi.Pointer<ffi.Int64>,
                      int,
                      int,
                      ffi.Pointer<ffi.Pointer<bg.OrtValue>>)>()(
          memInfoPP.value,
          buf.cast(),
          count * 4,
          shapePtr,
          shape.length,
          ONNXTensorElementDataType.float.value,
          valuePP);
      OrtStatus.checkOrtStatus(status);
      // Handing buf as dataPtr makes tensor.release() free it too.
      final tensor = OrtValueTensor(valuePP.value, buf.cast());
      return ReusableInputTensor._(tensor, buf, count);
    } finally {
      calloc.free(valuePP);
      calloc.free(shapePtr);
      calloc.free(memInfoPP);
    }
  }

  /// Copy [data] into the tensor's native buffer. [data] must have the
  /// tensor's element count.
  void write(Float32List data) {
    _buf.asTypedList(_length).setAll(0, data);
  }

  /// Releases the ORT value and the native buffer backing it.
  void release() => tensor.release();
}

/// Number of elements in a tensor-typed [OrtValue].
int tensorElementCount(OrtValue value) {
  final infoPP = calloc<ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>>();
  final countP = calloc<ffi.Size>();
  try {
    OrtStatus.checkOrtStatus(_getTensorTypeAndShape(value.ptr, infoPP));
    try {
      OrtStatus.checkOrtStatus(
          _getTensorShapeElementCount(infoPP.value, countP));
      return countP.value;
    } finally {
      _releaseTensorTypeAndShapeInfo(infoPP.value);
    }
  } finally {
    calloc.free(countP);
    calloc.free(infoPP);
  }
}

/// Copy a float32 tensor's data into [out] (which must hold exactly the
/// tensor's element count — check once with [tensorElementCount]).
void readFloatTensor(OrtValue value, Float32List out) {
  final dataPP = calloc<ffi.Pointer<ffi.Void>>();
  try {
    OrtStatus.checkOrtStatus(_getTensorMutableData(value.ptr, dataPP));
    out.setAll(0, dataPP.value.cast<ffi.Float>().asTypedList(out.length));
  } finally {
    calloc.free(dataPP);
  }
}
