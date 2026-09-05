# Photo screensaver performance

The previous Now Playing work was committed as `38904cbc` before these changes. Photo screensaver work is on `perf/photo-screensavers`.

## Changes

- Local Media, Photo Gallery, Immich and Clock background photos decode for their displayed size. Zooming transitions include 10% headroom. A separate image with a maximum edge of 256 pixels supplies the blurred backdrop. Foreground decodes have an 8 megapixel cap, so very large forced crops can render below native resolution.
- Local Media, Photo Gallery and Immich prepare one upcoming photo or portrait pair during the current hold. Obsolete preparations are discarded. Outgoing images remain available through the transition and are then evicted. Flutter can still evict prefetched images under cache pressure.
- Immich shares overlapping image and metadata requests. Metadata from an old connection cannot repopulate the current connection's cache.
- Native photo holds, preparation and Ken Burns movement pause while the screen is off. Remaining hold time resumes on wake. HA Media photo holds and CSS movement also pause. Existing video playback behavior is outside this change.
- A single photo or a single displayed Immich pair stays loaded without a recurring slide timer. Fill, transition and viewport changes still refresh the displayed photo.

The existing native blur isolation and HA Media's small precomputed canvas blur remain in use. Image aspect detection also fixes an EXIF rotation double-swap that could give portrait photos the wrong fit or pairing decision.

## Device comparison

Tested on `192.168.1.5`, a Samsung Galaxy Tab S8 SM-X700 running Android 16 at 2560 by 1600 pixels. Both APKs were release builds with the same temporary frame timing hook. The baseline was `38904cbc`. The optimized APK and source hashes are recorded in [measurements.json](measurements.json).

The workload used three deterministic 3000 by 4000 portrait JPEGs in Photo Gallery with Smart fill, Fade transitions, a five-second interval, no shuffle and no widgets. Capture began after eight seconds of warm-up and ran for approximately 42 seconds. Both runs displayed eight slide changes.

| Measurement | Before | After |
| --- | ---: | ---: |
| Build time, p95 | 1.150 ms | 0.892 ms |
| Raster time, p95 | 4.171 ms | 2.872 ms |
| Frames exceeding 16.67 ms in build or raster | 0 | 0 |
| Whole-device CPU, mean of health samples | 15.51% | 16.67% |
| Single-photo slide changes during 17 seconds awake | 3 | 0 |
| Single-photo slide changes during 17 seconds screen off | 3 | 0 |

The final comparison reduced p95 build time by 22% and p95 raster time by 31%. CPU varied between runs and did not consistently improve. This short synthetic test on one device does not establish battery savings or performance across all hardware, transitions and image collections.

For the portrait workload, foreground decode dimensions changed from 2560 by 3413 to 1200 by 1600, about 78% fewer pixels. Estimated RGBA foreground storage changed from 33.33 MiB to 7.32 MiB per image, plus about 0.19 MiB for its new backdrop. These are decoded pixel estimates, not measurements of total app memory. The baseline image exceeded Flutter's 32 MiB image cache limit, explaining its zero cached bytes despite a live image. The optimized current and next images fit in the cache at about 15.02 MiB combined. RSS samples are retained in the raw data but are not a controlled whole-app memory comparison.

## Reproduction

1. Generate fixtures with `python create_fixtures.py /tmp/photo-fixtures` using Pillow. Copy the three JPEGs to an app-readable directory on the device.
2. In a checkout of the baseline commit, run `python <path-to-this-report>/prepare_benchmark.py` from `app`. Build with `flutter build apk --release -t lib/main_photo_perf.dart`. Repeat on the optimized source.
3. Install each APK and configure the workload above. Start the screensaver, wait eight seconds and call the temporary `photoPerf` command with `reset: true` through the remote management API.
4. Collect 20 `/api/health` samples two seconds apart, then call `photoPerf` without reset to collect frame timings, slide changes, cache counters and RSS. CPU is the arithmetic mean of the health samples.
5. For the single-photo checks, select one fixture and Ken Burns, restart and wait seven seconds. Capture for 17 seconds awake, then reset capture and repeat for 17 seconds after `screenOff`. End with `screenOn`.
6. Remove `lib/main_photo_perf.dart` and rebuild the normal release entry point before restoring the device.

## Validation

Focused Flutter tests cover decode sizing, EXIF orientation, preloader cancellation and retry, remaining hold time, screen-off behavior, source-file removal after prefetch, single-photo settings and rotation changes, Immich request sharing, metadata connection changes and a retained portrait pair. Existing screensaver fill, navigation, widgets, scheduling and background tests also pass. Three Node behavioral tests cover HA Media hold timing, delayed photo completion while dark and stale image callbacks.

Android codec inspection confirmed that an EXIF orientation-6 JPEG stored at 4000 by 3000 reports display dimensions of 3000 by 4000 and decodes to 1200 by 1600. HA Media had no configured media source on this device, so its new behavior was verified with the JavaScript tests rather than a live HA Media slideshow.

Live checks also confirmed Local Media and Clock background rendering, Immich next/previous navigation with metadata and Immich wake recovery. A multi-photo Local Media session recorded zero slide changes during 11 seconds off and two changes during 11 seconds after wake.

The normal release APK was installed after testing. Both temporary benchmark commands were confirmed absent, original screensaver settings were restored and the synthetic device photos were removed.
