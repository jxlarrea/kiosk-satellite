<h1 align="center" style="border-bottom: none">
   <picture>
      <source media="(prefers-color-scheme: dark)" srcset="assets/banners/ks_banner_dark.svg" />
      <source media="(prefers-color-scheme: light)" srcset="assets/banners/ks_banner_light.svg" />
      <img alt="Kiosk Satellite for Home Assistant" src="assets/banners/ks_banner_default.svg" width="650" />
   </picture>
</h1>

<p align="center">
<img src="https://img.shields.io/github/stars/jxlarrea/kiosk-satellite?style=for-the-badge&label=Stars&color=orange" alt="Stars">
<a href="https://github.com/jxlarrea/kiosk-satellite/releases"><img src="https://img.shields.io/github/downloads/jxlarrea/kiosk-satellite/total?style=for-the-badge&label=Downloads&color=blue" alt="Downloads"></a>
<a href="https://github.com/jxlarrea/kiosk-satellite/releases/latest"><img src="https://shields.io/github/v/release/jxlarrea/kiosk-satellite?style=for-the-badge&color=purple" alt="version"></a>
<a href="https://github.com/jxlarrea/kiosk-satellite/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/jxlarrea/kiosk-satellite/release.yml?style=for-the-badge&label=Build" alt="Build"></a>
</p>

<p align="center">
<a href="https://buymeacoffee.com/jxlarrea"><img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee"></a>
</p>

Turn any Android device into a beautiful, dedicated Home Assistant kiosk. Purpose-built for Home Assistant from the ground up, Kiosk Satellite delivers a smooth, native dashboard experience with optional voice control via [Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration). Kiosk Satellite is free and open source.

<p align="center">
 <img src="assets/ks-demo-lossy.gif" alt="Kiosk Satellite" width="650"/>
</p>

## Main Features

&bull; **Guided setup**: a five-step wizard connects to Home Assistant, picks
  the dashboard, detects Voice Satellite, and requests only the Android
  permissions your choices need. Run it on the tablet or from a browser
  on your computer.

&bull; **[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration), natively**: the kiosk gets its own
  `assist_satellite` entity and the app's built-in engine takes over
  wake-word detection: it keeps listening with the screen off, at a
  fraction of the CPU a browser needs. No configuration in Voice
  Satellite; everything is inherited.

<p align="center">
 <img src="assets/vs-demo.gif" alt="Voice Satellite" width="650"/>
</p>

&bull; **Plain HTTP instances, fully unlocked**: a loopback proxy inside the
  app makes an `http://` dashboard a genuine secure context, so the
  microphone and the rest of the https-only browser surface work with no
  certificates or reverse proxy. Enabled automatically during setup.
  
&bull; **Fast dashboards on slow tablets**: optional
  [optimizations](docs/optimizations.md) filter Home Assistant's state
  stream down to just the entities on the view currently on screen,
  turning constant stutter on older tablets into smooth scrolling, and
  pause the dashboard's rendering while the screensaver covers it, taking
  a busy dashboard's browser from over two full cores and 70% GPU to a
  fraction of one core and 0%. The connection and Voice Satellite keep
  working throughout, and any view the filter cannot fully resolve is
  left unfiltered, so nothing ever breaks.

<p align="center">
 <img src="assets/perf-vs-fully.svg" alt="Measured against Fully Kiosk on a Galaxy Tab S8+ running the same dashboard" width="650">
</p>

&bull; **Kiosk lockdown**: exit gesture with PIN, blocked back/volume/home
  buttons, a status-bar shield, instant re-wake on power button, and
  lock-task support on device-owner provisioned tablets.

&bull; **Gestures**: map corner taps, corner holds, multi-finger taps and
  holds, a knock-code corner sequence, 2 to 4 claps (the Clapper,
  heard through the microphone, no Voice Satellite required) or a hand
  showing fingers to the camera to
  [configurable actions](docs/gestures.md): jump to a dashboard view,
  call a Home Assistant service or script, open another app and more,
  all invisible to guests.

&bull; **Sendspin player**: the tablet doubles as a synchronized
  [Sendspin](https://www.sendspin-audio.com/) speaker for Music
  Assistant, in sample-accurate sync with every other Sendspin player in
  the house, with metadata, artwork and volume in Home Assistant.

<p align="center">
 <img src="assets/screenshots/now-playing.png" alt="Now Playing Sendspin" width="650"/>
</p>

&bull; **Screensavers**: dim, black, clock, Home Assistant media, local
  folders, a photo gallery picked straight from the system picker, or an
  [Immich](docs/immich.md) library or album as a full photo frame with
  metadata overlay, all with crossfade / slide / zoom / Ken Burns
  transitions and an optional corner clock. Supports dismiss on motion, face detection and presence detection.

&bull; **Remote administration**: an embedded web admin at
  `http://<device-ip>:2324` mirrors every setting, shows a live
  screenshot, web console and logs, and exports the entire configuration
  as a single backup file.

&bull; **Dashboard view rotation**: cycle through a chosen set of dashboard
  views in an endless loop, each on screen for a configurable number of
  seconds.

&bull; **DLNA renderer**: push images, video and live cameras full screen
  onto the kiosk with `media_player.play_media`, from Home Assistant
  automations, the media browser or any DLNA app.

<p align="center">
 <img src="assets/screenshots/dashboard.png" alt="Dashboard" width="650"/>
</p>

&bull; **Native ESPHome device**: enable ESPHome and Home Assistant
  discovers every tablet on its own, no broker, no YAML, one pasted key.
  The device carries the full entity catalog: a screen light, volume
  sliders, screensaver and settings switches, action buttons, camera view
  and dashboard selects, an update entity, a live camera, and the whole
  diagnostics set.

&bull; **Bluetooth proxy**: the same ESPHome connection relays BLE
  advertisements and carries active device connections, exactly like an
  ESP32 proxy: BTHome sensors, thermometers, presence beacons, locks and
  buttons, with several kiosks forming a Bluetooth mesh on their own.

&bull; **Kiosk conveniences**: pull-to-refresh, start on boot, keep screen
  awake, default and adaptive brightness, scheduled light/dark theme,
  custom JavaScript injection, and self-signed certificate support.

&bull; **Open other apps from the dashboard**: point any card's tap action at
  `app://<package>` and the tablet opens that app, with the kiosk still
  running behind it.

  ```yaml
  tap_action:
    action: url
    url_path: app://com.android.deskclock
  ```
  
&bull; **Camera Streams**: import streams from Go2RTC or add WebRTC, MSE, HLS or MJPEG cameras
  manually, then arrange up to four cameras into responsive
  [camera views](docs/cameras.md) that can be opened from the tablet,
  Remote Admin or Home Assistant.

<p align="center">
 <img src="assets/screenshots/camera-1.png" alt="Cameras" width="650"/>
</p>

## Kiosk Satellite + Voice Satellite

[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration)
turns a Home Assistant dashboard into a full hands-free voice assistant
with wake word, conversations, timers and announcements. It runs entirely in the
browser, which is exactly its limit on a wall tablet: browsers can't listen
while the screen is off, browser-side wake-word engines are expensive, and
on a plain http instance the browser refuses the microphone altogether.

Kiosk Satellite removes that limit. The app runs Voice Satellite's own
wake-word models natively and transparently: Voice Satellite detects it is
running inside Kiosk Satellite and hands detection over on its own. You keep
configuring everything in Voice Satellite as usual; the kiosk just makes it
always-on, cheaper, and screen-independent.

<p align="center">
 <img src="assets/screenshots/vs-settings.png" alt="Voice Satellite Settings" width="650"/>
</p>

The performance difference is one of the main reasons to use Kiosk
Satellite. Native inference runs the entire wake-word pipeline many times
faster than realtime on the CPU alone (tens of times faster on a modern
tablet) at a fraction of the CPU and battery a browser-side engine burns,
and it keeps the dashboard perfectly smooth while listening. It is
efficient enough that vsWakeWord now runs even on an Amazon Echo Show 5,
on CPU, with no GPU or accelerator needed.

Detection also no longer depends on the page being visible: with
background listening enabled, the wake word keeps working while the
screen is off or **another app entirely is in the foreground**. Say the
word and the kiosk brings the dashboard back and answers.

| Capability | Voice Satellite alone | Kiosk Satellite + Voice Satellite |
| --- | --- | --- |
| Wake word with the dashboard on screen | ✅ | ✅ |
| Wake word with the screen off | ❌ | ✅ |
| Wake word with another app in front | ❌ | ✅ Returns to the dashboard on trigger |
| Mic access in non-HTTPS HA instances | ❌ | ✅ |
| Detection cost | ⚠️ Browser based, heavy on tablets | ✅ Native CPU inference, 10x-30x faster |
| Wake word on low-end hardware | ⚠️ Struggles | ✅ CPU only, no GPU needed |
| Survives reboots | ⚠️ Manual relaunch | ✅ Start on boot |

Voice Satellite is not required, since Kiosk Satellite is a complete Home
Assistant kiosk on its own, but together they make a tablet into something
very close to a purpose-built voice hub.

## Installation

Kiosk Satellite is distributed as a free APK for sideloading:

1. Download the latest APK from the
   [releases page](../../releases).
2. Copy it to the tablet (or download it there directly) and open it.
   Allow installing from unknown sources when Android asks.
3. Open the app and follow the setup wizard. The first step names the
   device, which is what Home Assistant and the network will call it. Tip:
   enable remote administration in the same step and finish the setup from
   a browser on your computer, where pasting the Home Assistant access
   token is much easier than typing it on glass.

**Requirements:** Android 7.0 or newer, a Home Assistant instance you can
reach from the tablet, and a long-lived access token (HA profile →
Security → Long-lived access tokens). For voice, install
[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration)
from the default HACS repository.


## Documentation

- [JavaScript API](docs/js-api.md): `window.kioskSatellite`, wake-word handoff protocol
- [Remote API](docs/remote-api.md): REST + WebSocket surface
- [ESPHome](docs/esphome.md): native Home Assistant entities and a Bluetooth proxy over the ESPHome API.
- [MQTT](docs/mqtt.md): the MQTT integration, on its way out in favor of ESPHome and kept for existing setups until it is removed
- [Camera streams](docs/cameras.md): Go2RTC import, camera views, and Home Assistant controls
- [Screen](docs/screen.md): keep-awake, default brightness, and adaptive brightness from the device's own light sensor.
- [Screensavers](docs/screensavers.md): the modes, schedule, brightness, motion wake, and what starts and dismisses them.
- [Device camera](docs/camera.md): the tablet's own camera as a Home Assistant still camera and motion detector.
- [Sendspin](docs/sendspin.md): the built-in synchronized Music Assistant audio player
- [DLNA](docs/dlna.md): push images, video and cameras to the kiosk from Home Assistant or any other DLNA app.
- [Immich](docs/immich.md): the Immich photo-frame screensaver, metadata overlay, local cache.
- [At a Glance](docs/at-a-glance.md): a row of entity states on the screensaver.
- [Kiosk and Lockdown](docs/kiosk.md): Kiosk Mode's protections, Lockdown Mode, the grants they need, and the device owner tier.
- [Home Launcher](docs/home-launcher.md): Kiosk Satellite as the device's home screen, what that replaces, and the crash fuse that hands the role back if the app cannot start.
- [Gestures](docs/gestures.md): touch gestures mapped to configurable actions.
- [Microphone](docs/microphone.md): capture mode, gain and AGC, for devices whose microphone reads too quiet.
- [Optimizations](docs/optimizations.md): the connection and performance switches, what each one does and when to use it.
- [Permissions](docs/permissions.md): every Android grant the app uses, what each is for, adb commands to grant them all at once, and the Kiosk Satellite Service that keeps the app alive with the screen off.
- [Updates](docs/updates.md): how the app finds and installs new releases, what Android asks for on each version, and hands-free updates through device ownership.

### Device Specific
- [Meta Portal](docs/portal.md): Notes about running Kiosk Satellite on a Portal device and required permissions for its Person detector.
- [Amazon Fire tablets](docs/fire.md): Notes about running Kiosk Satellite on a Fire tablet, the lock screen it cannot clear and the adb switch that turns it off.

## License

Kiosk Satellite is free for personal, non-commercial use. It is licensed
under
[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/):
you may use and share it, but commercial use and derivative works are not
permitted. See [LICENSE](LICENSE).

## Acknowledgements

Kiosk Satellite stands on a lot of amazing projects. Thanks to:

- [Home Assistant](https://www.home-assistant.io/) and [ESPHome](https://esphome.io/), the ecosystem this app was made for.
- [Music Assistant](https://www.music-assistant.io/) which carries the media player experience in Kiosk Satellite.
- [Immich](https://immich.app/) for the photo-frame screensaver which everyone loves.
- [Flutter](https://flutter.dev/) and [flutter_inappwebview](https://inappwebview.dev/), which carries the whole dashboard experience.
- [ONNX Runtime](https://onnxruntime.ai/) for on-device wake word inference, running [vsWakeWord](https://github.com/jxlarrea/voice-satellite-card-integration), [openWakeWord](https://github.com/dscripka/openWakeWord) and [microWakeWord](https://github.com/kahrendt/microWakeWord) models.
- [Material Design Icons](https://pictogrammers.com/library/mdi/) for the icon set.
- The [Rubik](https://fonts.google.com/specimen/Rubik), [Nunito](https://fonts.google.com/specimen/Nunito) and [DSEG](https://github.com/keshikan/DSEG) fonts, all under the SIL Open Font License.

And every package author in `pubspec.yaml` whose work this app quietly depends on.
