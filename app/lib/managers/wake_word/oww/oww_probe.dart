import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:onnxruntime/onnxruntime.dart';

import '../vsww/ort_init.dart';

/// Can this device run openWakeWord's three-stage chain in real time on the CPU?
///
/// Voice Satellite requires WebGPU for openWakeWord: its comments put the
/// pure-JS embedding model at ~80 ms per chunk and the whole chain at ~25 ms
/// even on the GPU. The budget is 80 ms per 1280-sample chunk, so the question
/// is not academic. Native ARM should be far quicker than JS, but that is an
/// assumption, and this measures it on the slowest device we support before any
/// of the pipeline gets ported.
///
///   audio `[1, 1760]`      -> melspectrogram.onnx -> mels
///   mels  `[1, 76, 32, 1]` -> embedding_model.onnx -> embedding `[1, 96]`
///   embs  `[1, 16, 96]`    -> `<wakeword>.onnx`    -> probability
/// The model's ONNX IR version, or null if the file does not start the way
/// every ONNX file does.
///
/// An ONNX file is a protobuf whose field 1 is `ir_version`, a varint, and it
/// is emitted first: the first two bytes are `08 <version>`.
int? irVersionOf(Uint8List bytes) {
  if (bytes.length < 2 || bytes[0] != 0x08) return null;
  final v = bytes[1];
  return v < 0x80 ? v : null; // multi-byte varint: not a version we expect
}

/// Rewrite `ir_version` down to 9 in place, returning true if it changed.
///
/// The runtime bundled with the onnxruntime package is ORT 1.15, which refuses
/// anything above IR 9. Voice Satellite's own conversions emit IR 10 (the
/// upstream tf2onnx ones are v8 and load fine), but IR 10 is essentially a
/// container revision: if the *operators* are ones ORT 1.15 knows, the model
/// runs identically once the header stops claiming a version it does not
/// recognise. If the ops were genuinely newer, loading still fails loudly with
/// an unsupported-op error rather than misbehaving, which is why this is worth
/// trying before shipping a whole new runtime.
bool downgradeIrVersion(Uint8List bytes, {int target = 9}) {
  final current = irVersionOf(bytes);
  if (current == null || current <= target) return false;
  bytes[1] = target; // single-byte varint: same width, patch in place
  return true;
}

Future<Map<String, Object?>> probeOww(String base, String wakeWord) async {
  final result = <String, Object?>{'base': base, 'wakeWord': wakeWord};
  final sessions = <OrtSession>[];
  try {
    ensureOrtInit();

    Future<OrtSession> load(String file) async {
      final resp = await http.get(Uri.parse('$base/$file'));
      if (resp.statusCode != 200) {
        throw StateError('$file HTTP ${resp.statusCode}');
      }
      final bytes = Uint8List.fromList(resp.bodyBytes);
      result['${file}_ir'] = irVersionOf(bytes);
      final patched = downgradeIrVersion(bytes);
      result['${file}_patched'] = patched;
      final opts = OrtSessionOptions()
        ..setIntraOpNumThreads(1)
        ..setInterOpNumThreads(1);
      final s = OrtSession.fromBuffer(bytes, opts);
      sessions.add(s);
      result['${file}_bytes'] = bytes.length;
      return s;
    }

    final mel = await load('melspectrogram.onnx');
    final emb = await load('embedding_model.onnx');
    final cls = await load('$wakeWord.onnx');

    result['melInput'] = mel.inputNames.toString();
    result['embInput'] = emb.inputNames.toString();
    result['clsInput'] = cls.inputNames.toString();

    int timeStage(String label, int iterations, void Function() run) {
      run(); // warm up
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        run();
      }
      sw.stop();
      final us = (sw.elapsedMicroseconds / iterations).round();
      result['${label}Us'] = us;
      return us;
    }

    // Stage 1: mel over 1760 samples (1280 chunk + 480 samples of history).
    final melIn = Float32List(1760);
    final melUs = timeStage('mel', 20, () {
      OrtValueTensor? t;
      List<OrtValue?>? out;
      try {
        t = OrtValueTensor.createTensorWithDataList(melIn, [1, 1760]);
        out = mel.run(OrtRunOptions(), {mel.inputNames.first: t});
      } finally {
        t?.release();
        out?.forEach((o) => o?.release());
      }
    });

    // Stage 2: embedding over the latest 76 mel frames x 32 bins.
    final embIn = Float32List(76 * 32);
    final embUs = timeStage('embedding', 20, () {
      OrtValueTensor? t;
      List<OrtValue?>? out;
      try {
        t = OrtValueTensor.createTensorWithDataList(embIn, [1, 76, 32, 1]);
        out = emb.run(OrtRunOptions(), {emb.inputNames.first: t});
      } finally {
        t?.release();
        out?.forEach((o) => o?.release());
      }
    });

    // Stage 3: classifier over the latest 16 embeddings.
    final clsIn = Float32List(16 * 96);
    final clsUs = timeStage('classifier', 20, () {
      OrtValueTensor? t;
      List<OrtValue?>? out;
      try {
        t = OrtValueTensor.createTensorWithDataList(clsIn, [1, 16, 96]);
        out = cls.run(OrtRunOptions(), {cls.inputNames.first: t});
      } finally {
        t?.release();
        out?.forEach((o) => o?.release());
      }
    });

    final totalUs = melUs + embUs + clsUs;
    result['totalUs'] = totalUs;
    // One chunk is 80 ms of audio; the chain must finish inside that.
    result['realtimeFactor'] =
        (80000 / totalUs).toStringAsFixed(1); // >1 means faster than realtime
    result['cpuPercentPerWakeWord'] =
        (totalUs / 80000 * 100).toStringAsFixed(1);
    result['ok'] = true;
  } catch (e) {
    result['ok'] = false;
    result['error'] = '$e';
  } finally {
    for (final s in sessions) {
      s.release();
    }
  }
  return result;
}
