#!/usr/bin/env python3
"""Generate benchmark adapters around the production workers, without edits.

Run from app/, then build .dart_tool/wake_benchmark/main.dart as a release APK. Generated
libraries stay in .dart_tool and are never used by the normal application.
"""

from pathlib import Path
import argparse
import re
import subprocess

APP = Path(__file__).resolve().parents[1]
OUTPUT = APP / ".dart_tool/wake_benchmark"
OUTPUT.mkdir(parents=True, exist_ok=True)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ref', help='Benchmark engine sources at this git revision')
args = parser.parse_args()
if args.ref:
    prefix = 'app/lib/managers/wake_word/'
    paths = subprocess.check_output(
        ['git', 'ls-tree', '-r', '--name-only', args.ref, prefix],
        cwd=APP.parent, text=True).splitlines()
    for path in paths:
        if path.endswith('.dart'):
            target = OUTPUT / 'source' / path.removeprefix(prefix)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(subprocess.check_output(
                ['git', 'show', f'{args.ref}:{path}'], cwd=APP.parent))

for engine, worker in [("mww", "_MwwWorker"), ("oww", "_OwwWorker"),
                       ("vsww", "_IsolateWorker")]:
    source = APP / f"lib/managers/wake_word/{engine}/{engine}_isolate.dart"
    if args.ref:
        source = OUTPUT / f'source/{engine}/{engine}_isolate.dart'

    def relocate(match):
        path = match[1]
        if ":" not in path:
            target = (source.parent / path).resolve()
            path = (str(target.relative_to(OUTPUT)) if args.ref else
                    "package:kiosk_satellite/" + str(target.relative_to(APP / "lib")))
        return f"import '{path}'"

    text = re.sub(r"import '([^']+)'", relocate, source.read_text())
    text = "import 'dart:async';\n" + text
    if engine == "vsww":
        text = text.replace('final logits = _run(k);',
            'final logits = _run(k);\n'
            '      if (_benchmarkOutputs != null && logits != null) {\n'
            '        _benchmarkOutputs!.add(Float32List.fromList(logits));\n'
            '      }')
    if engine == "oww":
        text = text.replace('final window = pipeline.process(chunk);',
            'final window = pipeline.process(chunk);\n'
            '    if (_benchmarkOutputs != null && window != null) {\n'
            '      _benchmarkOutputs!.add(Float32List.fromList(window));\n'
            '    }')
    text += '\nList<Float32List>? _benchmarkOutputs;\n'
    text += f"""
// Generated adapter. Every timed call uses the production onAudio method.
Future<Map<String, Object?>> benchmark(
    Map init, List<Uint8List> chunks, int iterations,
    int Function() nativeBytes) async {{
  final port = ReceivePort();
  final events = <Map>[];
  final subscription = port.listen((m) {{ if (m is Map) events.add(m); }});
  final worker = {worker}(port.sendPort);
  try {{
    worker.init(init);
    await Future<void>.delayed(Duration.zero);
    if (!events.any((m) => m['type'] == WakeMsg.ready)) {{
      throw StateError('worker failed to initialize: $events');
    }}
    // Keep all wake models scoring without starting real voice interactions.
    worker._tester = true;
    worker._telemetry = false;
    for (var i = 0; i < 64; i++) {{
      worker.onAudio(chunks[i % chunks.length]);
    }}
    await Future<void>.delayed(Duration.zero);
    final heapBefore = nativeBytes();
    final times = List<int>.filled(iterations, 0);
    final sw = Stopwatch();
    for (var i = 0; i < iterations; i++) {{
      sw..reset()..start();
      worker.onAudio(chunks[i % chunks.length]);
      sw.stop();
      times[i] = sw.elapsedMicroseconds;
    }}
    final heapAfter = nativeBytes();
    await Future<void>.delayed(Duration.zero);
    final errors = events.where((m) =>
        m['type'] == WakeMsg.error || m['level'] == 'warn').toList();
    if (errors.isNotEmpty) throw StateError('inference errors: $errors');
    // Verify scores and decisions separately so telemetry is outside timing.
    events.clear();
    worker.resumeDetection(0);
    worker._telemetry = true;
    _benchmarkOutputs = [];
    for (final chunk in chunks) {{ worker.onAudio(chunk); }}
    await Future<void>.delayed(Duration.zero);
    final scores = [for (final m in events)
      if (m['type'] == WakeMsg.telemetry)
        {{for (final e in m.entries)
          if (e.key != 'latencyUs' && e.key != 'chunkLatencyUs') e.key as String: e.value}}];
    times.sort();
    return {{
      'iterations': iterations,
      'meanUs': times.reduce((a, b) => a + b) / iterations,
      'p50Us': times[iterations ~/ 2],
      'p95Us': times[(iterations * .95).floor()],
      'p99Us': times[(iterations * .99).floor()],
      'maxUs': times.last,
      'overBudget': times.where((t) => t > 80000).length,
      'nativeHeapBefore': heapBefore,
      'nativeHeapAfter': heapAfter,
      'nativeHeapDelta': heapAfter - heapBefore,
      'scores': scores,
      'rawOutputs': _benchmarkOutputs,
    }};
  }} finally {{
    _benchmarkOutputs = null;
    worker.stop();
    await subscription.cancel();
    port.close();
  }}
}}
"""
    (OUTPUT / f"{engine}.dart").write_text(text)
(OUTPUT / "main.dart").write_text(
    (APP / "tool/wake_benchmark_main.dart.in").read_text())
print(f"Generated benchmark target: {OUTPUT / 'main.dart'}")
