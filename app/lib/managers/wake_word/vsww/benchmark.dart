import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import '../../../core/logging.dart';
import 'log_mel.dart';
import 'model_store.dart';
import 'ort_init.dart';

/// Micro-benchmark of a vsWakeWord ONNX model across execution providers, to
/// decide whether CPU inference keeps up with the 80 ms streaming budget or
/// whether an accelerator (XNNPACK / NNAPI) is needed — the mobile analogue of
/// "we needed WebGPU in the browser".
class VswwBenchmark {
  VswwBenchmark(this._log);
  final Logger _log;

  Future<Map<String, dynamic>> run(VswwModel model, {int iters = 60}) async {
    ensureOrtInit();
    final feat = model.manifest.feature;
    final shape = [1, feat.frames, feat.nMels];
    // Fixed feature buffer (compute time is data-independent for conv nets).
    final features = Float32List(feat.frames * feat.nMels);
    for (var i = 0; i < features.length; i++) {
      features[i] = (i % 40) / 40.0 - 0.5;
    }

    void oneThread(OrtSessionOptions o) {
      o.setIntraOpNumThreads(1);
      o.setInterOpNumThreads(1);
    }

    final configs = <String, void Function(OrtSessionOptions)>{
      'cpu-default': (o) {}, // ORT default (threads = cores)
      'cpu-1thread': oneThread,
      'xnnpack-1thread': (o) {
        oneThread(o);
        o.appendXnnpackProvider();
      },
      'nnapi': (o) => o.appendNnapiProvider(NnapiFlags.useNone),
    };

    final results = <String, dynamic>{
      'model': model.manifest.name,
      'iters': iters,
      'budgetMs': 80,
      'providers': <String, dynamic>{},
    };

    // Time the CPU log-mel feature extraction (the JS path did this on the
    // GPU too, so it's part of the realtime question).
    final extractor = LogMelExtractor(feat);
    final window = Float32List(feat.windowSamples);
    for (var i = 0; i < window.length; i++) {
      window[i] = (i % 320) / 320.0 - 0.5;
    }
    for (var i = 0; i < 5; i++) {
      extractor.extract(window); // warmup
    }
    final featSamples = <int>[];
    for (var i = 0; i < iters; i++) {
      final sw = Stopwatch()..start();
      extractor.extract(window);
      sw.stop();
      featSamples.add(sw.elapsedMicroseconds);
    }
    featSamples.sort();
    results['featureExtractMs'] = double.parse(
        (featSamples[featSamples.length ~/ 2] / 1000.0).toStringAsFixed(2));

    for (final entry in configs.entries) {
      final name = entry.key;
      try {
        final loadSw = Stopwatch()..start();
        final opts = OrtSessionOptions();
        entry.value(opts);
        final session = OrtSession.fromBuffer(model.onnxBytes, opts);
        loadSw.stop();
        final inputName = session.inputNames.first;
        final input =
            OrtValueTensor.createTensorWithDataList(features, shape);
        final runOpts = OrtRunOptions();

        // warmup
        for (var i = 0; i < 5; i++) {
          final o = session.run(runOpts, {inputName: input});
          for (final v in o) {
            v?.release();
          }
        }
        // timed
        final samples = <int>[]; // microseconds
        for (var i = 0; i < iters; i++) {
          final sw = Stopwatch()..start();
          final o = session.run(runOpts, {inputName: input});
          sw.stop();
          for (final v in o) {
            v?.release();
          }
          samples.add(sw.elapsedMicroseconds);
        }
        input.release();
        session.release();

        samples.sort();
        double ms(int us) => us / 1000.0;
        final avg = samples.reduce((a, b) => a + b) / samples.length;
        final stats = {
          'available': true,
          'loadMs': double.parse(ms(loadSw.elapsedMicroseconds).toStringAsFixed(1)),
          'avgMs': double.parse(ms(avg.round()).toStringAsFixed(2)),
          'minMs': double.parse(ms(samples.first).toStringAsFixed(2)),
          'p50Ms': double.parse(ms(samples[samples.length ~/ 2]).toStringAsFixed(2)),
          'p95Ms':
              double.parse(ms(samples[(samples.length * 0.95).floor()]).toStringAsFixed(2)),
          'maxMs': double.parse(ms(samples.last).toStringAsFixed(2)),
        };
        (results['providers'] as Map)[name] = stats;
        _log.info('vsww-bench',
            '$name: avg ${stats['avgMs']}ms p95 ${stats['p95Ms']}ms load ${stats['loadMs']}ms');
      } catch (e) {
        (results['providers'] as Map)[name] = {
          'available': false,
          'error': '$e',
        };
        _log.warn('vsww-bench', '$name unavailable: $e');
      }
    }
    return results;
  }
}
