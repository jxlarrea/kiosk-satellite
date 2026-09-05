# HA dashboard camera suspension on Galaxy Tab S8

Measured on 2026-09-05 on `192.168.1.5:5555`, a Samsung Galaxy Tab S8
(SM-X700) running Android 16. The signed arm64 release APK includes the
default-on `browser.pause_dashboard_cameras` setting. Its hash and source
base commit are recorded in [measurements.json](measurements.json).

## Comparison

Both phases used the same installed APK and dashboard with two muted Home
Assistant WebRTC camera players. The Clock screensaver covered the dashboard.
Rendering pause, update filtering and background connection retention stayed
enabled. Native vsWakeWord listening stayed enabled. Only dashboard camera
suspension changed between phases, without reloading the page.

| Metric behind the screensaver | Toggle off | Toggle on |
| --- | ---: | ---: |
| Mean whole-device CPU | 23.09% | 13.76% |
| Connected dashboard camera players | 2 | 0 |
| Combined inbound video RTP payload | 115,342 bytes/s | 0 |
| Combined decoded video frames | 41.75 frames/s | 0 |
| Measurement window | 65.4 seconds | 69.2 seconds |

The observed CPU reduction was 9.33 percentage points, or 40.4% relative.
This is a single pair of short measurements on a live dashboard with ordinary
device frequency scaling and background activity. It does not establish battery
savings or a guaranteed reduction on other hardware.

The test collected 30 samples per phase through `/api/health` and the dashboard's
WebRTC `getStats()` counters after a five-second settling period. CPU is the
device API's utilization across all cores, not a sum of process percentages.
Video rates use counter differences divided by elapsed time and exclude network
protocol overhead. With suspension enabled, both player components were absent.
A separate cleanup check confirmed closed peer connections and ended video
tracks. Other application network traffic continued.

## Recovery and compatibility checks

- Ten consecutive screensaver cycles restored both cameras. Time from the
  stop command completing to both players reporting a connected state and
  decoded video ranged from 0.58 to 3.98 seconds.
- All ten cycles retained the same Home Assistant socket. Native wake word
  detection reported active and listening during every suspended phase.
- Disabling the toggle while covered restored both streams without a page
  reload. Enabling it again released both streams.
- Camera suspension worked with rendering pause disabled.
- Dim kept both cameras playing. Switching from Dim to Clock suspended them.
- Reloading the dashboard behind the screensaver kept its cameras suspended.
  Both recovered after dismissal. The tested reload recovery took 7.40 seconds.
- An unmuted dashboard camera continued playing through Home Assistant's HLS
  player. Muting it while covered made it eligible for suspension.
- The device settings widget tests and the installed remote UI showed the new
  toggle in Optimizations with the requested HA dashboard wording and an
  enabled default.

These checks verify camera recovery and continued native listening. They are
not an acoustic wake word accuracy comparison. The measured suspension workload
used WebRTC. Muted HLS and MJPEG suspension still need dedicated device coverage.
Custom camera components with their own players remain outside this setting.

## Automated validation

- 52 focused Flutter tests passed, covering camera policy, screensaver behavior,
  browser recovery, settings pages and remote static assets.
- Six JavaScript behavior tests passed with
  `node --test test/dashboard_camera_script_test.mjs` from `app/`. These include
  HA replacing the component registry after document-start injection.
- Static analysis of the changed Dart implementation and camera policy tests
  passed. The signed release APK built and installed successfully.
