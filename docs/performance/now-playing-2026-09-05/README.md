# Now Playing performance on Galaxy Tab S8

Measured on 2026-09-05 on `192.168.1.5:5555`, a Samsung Galaxy Tab S8
(SM-X700) running Android 16 at 2560 by 1600 pixels. Baseline source was
`e512c186`. Both builds were signed arm64 release APKs with the same temporary
Flutter frame timing hook. APK hashes and raw samples are in
[measurements.json](measurements.json).

## Changes

- Isolate the blurred artwork in an `ImageFiltered` repaint boundary. Decode
  its background image at 256 pixels wide and foreground covers at their
  display size.
- Stop the floating player's progress timer and unmount its scrolling text
  while a screensaver covers it. Defer artwork loads until it is visible.
- Share concurrent artwork downloads and encoded bytes between the floating
  player, fullscreen view and remote artwork endpoint. Keep at most 16 covers
  totaling 8 MiB, evicting the least recently used entries.
- Give progress and seeking their own widget. Position reports and the 500 ms
  progress tick no longer rebuild the title, cover or transport buttons.

These changes are automatic and add no settings. Queue thumbnails retain their
existing separate bounded cache.

## Comparison

Both phases played "How to disappear" by Lana Del Rey through native Sendspin.
The fullscreen view had the same cover and layout, with queue and lyrics closed.
The floating player remained enabled behind it. HA dashboard optimizations,
including camera suspension, remained enabled.

| Metric | Baseline | Optimized |
| --- | ---: | ---: |
| Build time, mean | 5.55 ms | 2.33 ms |
| Build time, p95 | 9.43 ms | 5.03 ms |
| Raster time, mean | 6.74 ms | 4.35 ms |
| Raster time, p95 | 8.85 ms | 6.24 ms |
| Flutter frames rendered per second | 3.18 | 2.27 |
| Frames with build or raster over 16.67 ms | 0 | 0 |
| Mean whole-device CPU | 17.70% | 18.55% |
| Native AudioTrack underruns | 0 | 0 |
| Measurement window | 73.79 s | 63.85 s |

The observed p95 build reduction was 46.7% and p95 raster reduction was 29.5%.
Fewer rendered frames here means less redundant work on a mostly static view.
The progress bar still updates twice per second.

Whole-device CPU increased by 0.85 percentage points. These measurements show
less Flutter UI work but do not demonstrate lower overall CPU usage or battery
consumption. Device frequency scaling and unrelated background work were not
controlled. This is one short paired comparison on one tablet.

Raw image cache and RSS values are retained for inspection. The baseline had
previously loaded more covers, so those values are not a controlled memory
comparison. The encoded cache bounds and download deduplication are verified
by automated tests.

## Method

From `app/`, run `python3 ../docs/performance/now-playing-2026-09-05/prepare_benchmark.py`
to generate the temporary entry point. Build each revision with:

```sh
flutter build apk --release --target-platform android-arm64 -t lib/main_now_playing_perf.dart
```

Install with ADB, start the same track and open Now Playing with queue and lyrics
disabled. Allow five seconds to settle. Using authenticated remote management,
POST `{"reset":true}` to `/api/commands/nowPlayingPerf`. Collect 30 samples from
`/api/health` and `/api/commands/sendspinStatus`, sleeping two seconds between
samples. POST `{}` to the timing command to finish. Request overhead accounts
for the differing window lengths. All samples in both phases confirmed the
same track was playing.

The timing hook uses `WidgetsBinding.addTimingsCallback`. The p95 is the sorted
sample at the rounded index `(count - 1) * 0.95`. Frame counts are normalized by
the measured elapsed time. CPU is the health API's whole-device utilization
across cores. It is not Flutter process CPU.

Remove `app/lib/main_now_playing_perf.dart` afterward and build with the default
entry point. The production APK does not include the timing command.

## Validation

- 109 focused Flutter tests passed across artwork caching, Now Playing,
  remote playback and lyrics. Coverage includes seeking, transport commands,
  volume controls, layout changes and phone layouts.
- New tests verify shared downloads, bounded eviction, retry after failure,
  stale artwork responses and preservation of static widgets during progress
  updates. A covered floating player with scrolling text schedules no frames
  and fetches its latest artwork when revealed.
- Static analysis of all changed Dart implementation and test files passed.
- Both instrumented and production arm64 release builds succeeded.
- Device checks confirmed pause and resume through the transport button,
  seeking, next-track artwork, queue display and highlighted lyrics. The
  floating player returned with the current track and cover after dismissal.
- The production APK was installed on the tablet. The temporary timing command
  was absent, queue and lyrics settings were restored and playback was stopped.

Device interaction results are recorded in [live-controls.json](live-controls.json).
