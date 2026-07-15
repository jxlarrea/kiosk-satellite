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
/// `ir_version` declares the *file format*, and a runtime checks it before it
/// looks at a single node — so a model built from ops ORT 1.15 knows perfectly
/// well is rejected for the header alone. Lower the claim and the same bytes
/// load and run identically. Verified on device against every openWakeWord
/// classifier.
///
/// Safe by construction: if the graph really did use newer operators, loading
/// still fails loudly with an unsupported-op error rather than misbehaving.
///
/// This is a shim, and it is deliberately still here now that the cause is
/// fixed. Voice Satellite's converter used to emit IR 10 for no reason (it
/// writes opset 12, whose IR version is 7) and now emits 7, but this must keep
/// working for models we did not build: users drop their own .onnx into
/// `/config/voice_satellite/models/openwakeword/` and the integration serves
/// them as-is, so whatever exporter they used decides the IR version, not us.
bool downgradeIrVersion(Uint8List bytes, {int target = 9}) {
  final current = irVersionOf(bytes);
  if (current == null || current <= target) return false;
  bytes[1] = target; // single-byte varint: same width, patch in place
  return true;
}
