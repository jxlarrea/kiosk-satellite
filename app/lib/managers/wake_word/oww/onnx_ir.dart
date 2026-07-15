import 'dart:typed_data';

/// The model's ONNX IR version, or null if the file does not start the way
/// every ONNX file does.
///
/// An ONNX file is a protobuf whose field 1 is `ir_version`, a varint, emitted
/// first: the opening bytes are `08 <version>`.
int? irVersionOf(Uint8List bytes) {
  if (bytes.length < 2 || bytes[0] != 0x08) return null;
  final v = bytes[1];
  return v < 0x80 ? v : null; // multi-byte varint: not a version we expect
}

/// Rewrite `ir_version` down to [target] in place; returns true if it changed.
///
/// The onnxruntime package bundles ORT 1.15, which refuses anything above IR 9.
/// Voice Satellite's own model conversions emit IR 10 (its upstream tf2onnx
/// models are v8 and load fine), and IR 10 is essentially a container revision:
/// where the *operators* are ones ORT 1.15 knows, the model runs identically
/// once the header stops claiming a version it does not recognise. Verified on
/// device against the openWakeWord classifiers.
///
/// Safe by construction: if the graph really did use newer operators, loading
/// still fails loudly with an unsupported-op error rather than misbehaving.
///
/// This is a compatibility shim, not the cure. The real fix is the exporter
/// emitting IR 9; this keeps already-shipped models working either way.
bool downgradeIrVersion(Uint8List bytes, {int target = 9}) {
  final current = irVersionOf(bytes);
  if (current == null || current <= target) return false;
  bytes[1] = target; // single-byte varint: same width, patch in place
  return true;
}
