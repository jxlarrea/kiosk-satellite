import 'package:onnxruntime/onnxruntime.dart';

bool _inited = false;

/// Initialize the ONNX Runtime environment once per process. `OrtEnv.init()`
/// creates a fresh env on every call, so both the engine and the benchmark
/// must funnel through this guard.
void ensureOrtInit() {
  if (_inited) return;
  OrtEnv.instance.init();
  _inited = true;
}
