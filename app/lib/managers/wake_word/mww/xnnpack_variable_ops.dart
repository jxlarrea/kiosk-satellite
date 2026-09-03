import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
// ignore: implementation_imports
import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart'
    show TfLiteDelegate;

/// XNNPACK applied by hand, with its resource-variable support switched on,
/// so the whole microWakeWord graph runs inside the delegate (issue #416).
///
/// Left to the runtime's default XNNPACK, the VAR_HANDLE / READ_VARIABLE /
/// ASSIGN_VARIABLE ops the streaming models keep their ring buffers in stay
/// with the built-in kernels, and so does a convolution next to them. The
/// first time a built-in kernel multiplies matrices it initializes Ruy, and
/// the Ruy inside LiteRT 1.4.1 and 1.4.2 walks the CPU cache topology without
/// checking cpuinfo's answers: on a device that takes cores offline at idle
/// (the MediaTek Echo Shows) the last processor sharing a cache can be
/// missing at that moment, and the walk dereferences null. That is the
/// SIGSEGV at TfLiteInterpreterInvoke on armeabi-v7a in issue #416. Ruy's
/// fix (November 2023 upstream) has not reached a LiteRT release, so the
/// safe path is to never reach Ruy: with variable ops delegated, XNNPACK
/// takes every node and no built-in kernel runs.
///
/// One delegate per interpreter: TFLite keeps the pointer for the life of
/// the interpreter, so [delete] must follow the interpreter's close.
class VariableOpsXnnpackDelegate implements Delegate {
  VariableOpsXnnpackDelegate._(this._lib, this._delegate, this._options);

  final DynamicLibrary _lib;
  final Pointer<TfLiteDelegate> _delegate;
  final Pointer<_XnnpackOptions> _options;
  bool _deleted = false;

  /// Null where the delegate cannot be built (not Android, or a runtime
  /// without the symbols): the caller falls back to the default options.
  static VariableOpsXnnpackDelegate? create() {
    if (!Platform.isAndroid) return null;
    try {
      final lib = DynamicLibrary.open('libtensorflowlite_jni.so');
      final defaults = lib
          .lookupFunction<
            _XnnpackOptions Function(),
            _XnnpackOptions Function()
          >('TfLiteXNNPackDelegateOptionsDefault');
      final create = lib
          .lookupFunction<
            Pointer<TfLiteDelegate> Function(Pointer<_XnnpackOptions>),
            Pointer<TfLiteDelegate> Function(Pointer<_XnnpackOptions>)
          >('TfLiteXNNPackDelegateCreate');
      // Start from the runtime's own defaults (QS8/QU8 and whatever else this
      // release turns on) rather than a hand-written set, and add only the
      // variable-operator bit. The struct is padded well past the runtime's
      // so a release that grows it still returns into owned memory.
      final options = calloc<_XnnpackOptions>();
      final d = defaults();
      options.ref
        ..numThreads = d.numThreads
        ..runtimeFlags = d.runtimeFlags
        ..flags = d.flags | _flagVariableOperators
        ..weightsCache = d.weightsCache
        ..handleVariableOps = true
        ..weightCacheFilePath = d.weightCacheFilePath
        ..weightCacheFileDescriptor = d.weightCacheFileDescriptor
        ..weightCacheProvider = d.weightCacheProvider
        ..weightCacheLockMemory = d.weightCacheLockMemory;
      final delegate = create(options);
      if (delegate == nullptr) {
        calloc.free(options);
        return null;
      }
      return VariableOpsXnnpackDelegate._(lib, delegate, options);
    } catch (_) {
      return null;
    }
  }

  static const _flagVariableOperators = 0x10;

  @override
  Pointer<TfLiteDelegate> get base => _delegate;

  @override
  void delete() {
    if (_deleted) return;
    _deleted = true;
    final del = _lib
        .lookupFunction<
          Void Function(Pointer<TfLiteDelegate>),
          void Function(Pointer<TfLiteDelegate>)
        >('TfLiteXNNPackDelegateDelete');
    del(_delegate);
    calloc.free(_options);
  }
}

/// TfLiteXNNPackDelegateOptions as LiteRT 1.4.x lays it out, plus spare room.
final class _XnnpackOptions extends Struct {
  @Int32()
  external int numThreads;
  @Uint32()
  external int runtimeFlags;
  @Uint32()
  external int flags;
  external Pointer<Void> weightsCache;
  @Bool()
  external bool handleVariableOps;
  external Pointer<Void> weightCacheFilePath;
  @Int32()
  external int weightCacheFileDescriptor;
  external Pointer<Void> weightCacheProvider;
  @Bool()
  external bool weightCacheLockMemory;
  @Array(16)
  external Array<Uint32> spare;
}
