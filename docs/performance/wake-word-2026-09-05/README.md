# Wake word performance on Echo Show 8

Measured on 2026-09-05, on `192.168.1.70:5555`, using signed Flutter release
builds for `armeabi-v7a`. Baseline engine source:
`7c4986f9c4eecf4f81b8e4d91ee631ad76db6901`.

## Results

| Engine | Models | Before mean | After mean | Reduction | Before p95 | After p95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| vsWakeWord (int8) | 1 | 9.602 ms | 9.410 ms | 2.0% | 9.928 ms | 9.847 ms |
| vsWakeWord (int8) | 2 | 15.152 ms | 14.860 ms | 1.9% | 15.561 ms | 15.282 ms |
| microWakeWord | 1 | 4.433 ms | 4.307 ms | 2.8% | 4.945 ms | 4.806 ms |
| microWakeWord | 2 | 4.630 ms | 4.492 ms | 3.0% | 5.150 ms | 5.020 ms |
| openWakeWord | 1 | 43.474 ms | 42.038 ms | 3.3% | 44.759 ms | 43.318 ms |
| openWakeWord | 2 | 43.848 ms | 42.544 ms | 3.0% | 44.984 ms | 43.855 ms |

Values are medians of three independent trials' means and p95s. Each call
processes 80 ms of audio. All 27,600 timed chunks across both builds finished
within that budget. These are observed reductions on this device, not estimates
of battery savings or guarantees for other hardware.

## Workload and controls

- The standalone target runs each production worker in a compute isolate.
  The generated adapter calls the real `onAudio` method and times PCM decoding,
  feature extraction, all active classifiers, decoding and detection gates.
  Capture, platform/isolate transport, dashboard rendering and telemetry
  delivery are outside these timings.
- Every trial starts fresh worker/session state and runs 64 warmup chunks,
  followed by 1,000 timed chunks for microWakeWord/vsWakeWord or 300 for
  openWakeWord. Models and input bytes are identical before and after.
- The repeatable input is 128 chunks of digital silence, quiet and loud seeded
  noise, a square wave, and alternating clipped samples. Buffers deliberately
  start at an odd offset to exercise PCM alignment handling. This is a synthetic
  correctness/performance workload, not a speech-recognition accuracy corpus.
- Energy gating is disabled and tester suppression prevents voice interactions.
  Telemetry is disabled during timing. A separate 128-chunk pass collects
  scores and outputs after rearming the worker.
- CPU minimum and maximum frequency were temporarily fixed at 1,216 MHz.
  The interactive governor and hotplug policy were retained. The original
  600 MHz minimum and 1,300 MHz maximum were restored after measurement.
- One-model/two-model cases use `ok_nova`/`ok_nova + alexa` for vsWakeWord
  (int8), `ok_nabu`/`ok_nabu + alexa` for microWakeWord, and
  `alexa`/`alexa + ok_nabu` for openWakeWord. Model hashes are recorded in
  [fixture-hashes.json](fixture-hashes.json).

The initial attempt to run the harness on the platform isolate was discarded
because it blocked Android foreground-service startup. Both reported builds
use compute isolates and completed all 18 cases without inference errors.

## Output and memory checks

All 18 paired score/decision hashes match exactly. The vsWakeWord raw logits
and openWakeWord classifier feature windows also match bit for bit. The
microWakeWord unit tests compare PCM16 and float input across fragmented
chunks, full-scale samples and resets, and retain the existing frontend goldens.

The native runner tests exercise 200 changing inputs against the ordinary ONNX
runner, output-storage reuse, shape/type rejection, and repeated release.
The targeted suite passed 119 tests with the native ONNX library enabled.

| Engine | Models | Before allocated-byte delta | After allocated-byte delta |
| --- | ---: | ---: | ---: |
| vsWakeWord (int8) | 1 | +17,936 | -2,272 |
| vsWakeWord (int8) | 2 | +41,824 | -6,224 |
| microWakeWord | 1 | -4,176 | -6,200 |
| microWakeWord | 2 | -2,080 | -2,080 |
| openWakeWord | 1 | +10,576 | -12,368 |
| openWakeWord | 2 | +11,328 | -8,272 |

These are medians of process-wide `mallinfo().uordblks` differences across each
timed loop. They include unrelated native allocations/frees and are not a
precise leak counter. Negative numbers mean other memory was freed during the
loop. The source-level leak in the pinned ONNX wrapper is removed from the
streaming engines: input/output names and pointer arrays are allocated once,
outputs are reused, and all runner-owned handles are released on shutdown.
No long-duration RSS or battery-life claim is inferred from these snapshots.

## Changes

- Persistent ONNX runner with fixed output storage, first-run shape/type
  validation and direct native output views.
- Explicit release of ONNX session options and failed input allocations.
- PCM buffer consumption with `takeBytes`, including unaligned PCM16 fallback.
- Direct PCM16 microWakeWord frontend input and cached quantization constants.
- Shared RMS calculation between telemetry and energy gating.
- Reused CTC edit-distance rows, bounded exact-match scanning, and no stream
  updates when the manifest disables stream matching.
- Full-chunk processing telemetry in the wake word tester, retaining the
  per-model inference measurement for consumers that use it.

## Reproducing

From `app/`, generate benchmark adapters around a revision's engine source:

```sh
python3 tool/prepare_wake_benchmark.py --ref 7c4986f9c4eecf4f81b8e4d91ee631ad76db6901
flutter build apk --release --target-platform android-arm \
  -t .dart_tool/wake_benchmark/main.dart --dart-define=BENCH_LABEL=baseline
```

Omit `--ref` to benchmark the working tree and use `BENCH_LABEL=optimized`.
The adapters are generated under `.dart_tool/wake_benchmark` and are not used
by the normal app. The target expects the files listed in `fixture-hashes.json`
under the app support directory's `wake_benchmark/` folder, with the same
relative paths. On this rooted device that is
`/data/data/me.jxl.kiosk_satellite/files/wake_benchmark/`. Push the fixtures with
ADB and preserve the app directory's owner and SELinux context.

Install each benchmark APK with `adb -s 192.168.1.70:5555 install -r`, then
start `me.jxl.kiosk_satellite/.MainActivity`. Save the original APK first and
stop the app before switching builds. Wait until the output JSON's `complete`
field is true. Results are written to `baseline.json` or `optimized.json` in
the fixture directory; progress is also logged with `WAKE_BENCH`.

Restore the device's CPU settings and install the ordinary release target
(`flutter build apk --release --target-platform android-arm`) when finished.
The optimized ordinary app was installed and left listening with the original
int8 Ok Nova model and the stop classifier available. Suspending and resuming
listening succeeded, and live energy-gate sleep/wake cycles continued without
inference errors. See [live-validation.json](live-validation.json).

Raw results: [baseline.json](baseline.json), [optimized.json](optimized.json).
Build fingerprints and CPU configuration: [environment.json](environment.json).
Machine-readable comparison: [summary.json](summary.json).
