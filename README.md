<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/banners/ks_banner_dark.svg" />
    <source media="(prefers-color-scheme: light)" srcset="assets/banners/ks_banner_light.svg" />
    <img alt="Kiosk Satellite for Home Assistant" src="assets/banners/ks_banner_default.svg" width="650" />
  </picture>
</h1>

<p align="center">
<img src="https://img.shields.io/github/stars/jxlarrea/kiosk-satellite?style=for-the-badge&label=Stars&color=d6a102" alt="Stars">
<a href="https://github.com/jxlarrea/kiosk-satellite/releases"><img src="https://img.shields.io/github/downloads/jxlarrea/kiosk-satellite/total?style=for-the-badge&label=Downloads&color=e8604c" alt="Downloads"></a>
<a href="https://github.com/jxlarrea/kiosk-satellite/releases/latest"><img src="https://shields.io/github/v/release/jxlarrea/kiosk-satellite?style=for-the-badge&color=5da3a6" alt="version"></a>
<a href="https://github.com/jxlarrea/kiosk-satellite/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/jxlarrea/kiosk-satellite/release.yml?style=for-the-badge&label=Build&color=3fbf5f" alt="Build"></a>
</p>

<p align="center">
<a href="https://buymeacoffee.com/jxlarrea"><img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee"></a>
</p>

<p align="center">
  Kiosk Satellite is an Android app designed for dedicated Home Assistant kiosks, with native Voice Satellite support, synchronized music playback and photo screensavers.<br />
  Kiosk Satellite is fully local and free for personal, non-commercial use.
</p>

<p align="center">
  <a href="https://kiosksatellite.com/download/">Download</a> · <a href="https://kiosksatellite.com/#get-started">Get started</a> · <a href="https://kiosksatellite.com/docs/">Documentation</a>
</p>

<p align="center">
  <img src="assets/ks-demo-lossy.gif" alt="Kiosk Satellite running on a Home Assistant display" width="650" />
</p>

## Features

&bull; **Native voice control:** Kiosk Satellite is a Home Assistant Assist satellite on its own, with [Voice Satellite](https://kiosksatellite.com/docs/voice-satellite/) built in: ten skins, timers, announcements and wake word detection that works with the screen off or, with background listening enabled, while another app is open. Nothing to install in Home Assistant.

<p align="center">
  <img src="assets/vs-demo.gif" alt="Hands-free voice control with Voice Satellite" width="650" />
</p>

&bull; **Dashboard performance:** Optional [optimizations](https://kiosksatellite.com/docs/optimizations/) reduce unnecessary dashboard updates and pause rendering during screensavers to lower CPU and GPU usage on older devices. Voice and the Home Assistant connection stay active.

&bull; **[Music playback](https://kiosksatellite.com/docs/sendspin/):** Synchronized Music Assistant audio through Sendspin, AirPlay from an iPhone, iPad or Mac and the option to follow a Home Assistant or Sonos player. The full-screen Now Playing view shows album art, playback controls and supported lyrics, and the [Music Library](https://kiosksatellite.com/docs/music-library/) browses Music Assistant, Home Assistant or Sonos and plays on any speaker.

<p align="center">
  <a href="assets/screenshots/now-playing.png"><img src="assets/screenshots/now-playing.png" alt="Now Playing with album artwork and music controls" width="650" /></a>
  <a href="assets/screenshots/ml_discover_light.png"><img src="assets/screenshots/ml_discover_light.png" alt="Music Library Discover in  Kiosk Satellite" width="320" /></a>
  <a href="assets/screenshots/ml_playlist_dark.png"><img src="assets/screenshots/ml_playlist_dark.png" alt="Music Library Discover in  Kiosk Satellite" width="320" /></a>
</p>

&bull; **Screensavers:** [Immich albums](https://kiosksatellite.com/docs/immich/), local photos, clocks, weather mood and a live night sky, with motion, face or presence detection to wake the kiosk.

&bull; **[Motion, face and person detection](https://kiosksatellite.com/docs/camera/):** The device camera detects motion and faces on the device itself. Motion wakes the screen when someone walks up and holds off the screensaver while the room is in use. Face detection wakes it only when someone looks at the screen, so people walking past leave the screensaver up. Person detection uses the built-in sensor on supported devices. Motion and person also show up in Home Assistant as sensors for your automations.

<p align="center">
  <a href="assets/screenshots/screensaver-np.png"><img src="assets/screenshots/screensaver-np.png" alt="Settings in Kiosk Satellite" width="650" /></a>
  <a href="assets/screenshots/clock-digital.png"><img src="assets/screenshots/clock-digital.png" alt="Digital Clock Screensaver in  Kiosk Satellite" width="320" /></a>
  <a href="assets/screenshots/weathermood-dawn.png"><img src="assets/screenshots/weathermood-dawn.png" alt="Weather Mood Screensaver in Kiosk Satellite" width="320" /></a>
</p>

&bull; **Home Assistant integration:** The built-in [ESPHome connection](https://kiosksatellite.com/docs/esphome/) exposes screen controls, volume and device sensors. An optional Bluetooth proxy relays nearby Bluetooth devices to Home Assistant.

&bull; **Remote administration:** Configure the app, view live screenshots, read logs and back up settings from a browser. [Fleet management](https://kiosksatellite.com/docs/fleet/) shares configuration profiles and coordinates updates across multiple kiosks.

<p align="center">
  <a href="assets/screenshots/remote.png"><img src="assets/screenshots/remote.png" alt="Remote Administration in Kiosk Satellite" width="650" /></a>
</p>

&bull; **Intercom:** Kiosks can call each other or broadcast to all kiosks at once using the [Intercom](https://kiosksatellite.com/docs/intercom/) feature. Kiosks are auto discovered in the local network. 

&bull; **Alarms:** Set [alarms](https://kiosksatellite.com/docs/alarms/) that ring on the kiosk itself, with no Home Assistant or network needed. A sunrise can brighten the screen before the alarm rings, and a Clock or Weather Mood screensaver can show the alarm with Snooze and Stop in its own style.

&bull; **Calendar:** Show your Home Assistant calendars as a family [calendar](https://kiosksatellite.com/docs/calendar/) with Day, Week, Month and Schedule views. Each person gets a color, and an event shared by several people is split between their colors.

<p align="center">
  <a href="assets/screenshots/calendar-day.png"><img src="assets/screenshots/calendar-day.png" alt="Calendar Days" width="320" /></a>
  <a href="assets/screenshots/calendar_schedule.png"><img src="assets/screenshots/calendar_schedule.png" alt="Calendar Schedule" width="320" /></a>
</p>

&bull; **Kiosk conveniences:** Use [hand gestures](https://kiosksatellite.com/docs/gestures/#show-fingers) to run Home Assistant actions or open a camera view by holding up fingers to the device camera. Set Kiosk Satellite as the [home launcher](https://kiosksatellite.com/docs/home-launcher/) on supported devices so the Home button returns to your dashboard. Arrange up to twelve live feeds in [camera views](https://kiosksatellite.com/docs/cameras/), with camera imports from Home Assistant or Go2RTC.

Also built in: [PIN-protected kiosk mode](https://kiosksatellite.com/docs/kiosk/), [touch and clap gestures](https://kiosksatellite.com/docs/gestures/), [DLNA media playback](https://kiosksatellite.com/docs/dlna/), [RTSP streaming](https://kiosksatellite.com/docs/camera/#rtsp-streaming), [Shizuku support](https://kiosksatellite.com/docs/shizuku/) and more!

<p align="center">
  <a href="assets/screenshots/now-playing.png"><img src="assets/screenshots/now-playing.png" alt="Now Playing with album artwork and music controls" width="320" /></a>
  <a href="assets/screenshots/camera-1.png"><img src="assets/screenshots/camera-1.png" alt="Live camera feeds in Kiosk Satellite" width="320" /></a>
</p>

## Get started

You need **Android 7.0 or newer**, a reachable Home Assistant instance and a long-lived access token from **Home Assistant Profile → Security → Long-lived access tokens**.

1. [Download the latest APK](https://kiosksatellite.com/download) on your Android device.
2. Open it to install. Allow installation from this source if Android asks.
3. Launch Kiosk Satellite and follow the setup wizard to connect Home Assistant and choose your dashboard.

You can also enable Remote Administration in the first setup step and finish setup from your computer at `http://<device-ip>:2324`.

For voice control, leave Voice Satellite on in the setup wizard, then add the kiosk in Home Assistant under **Settings > Devices & services**, where it shows up as discovered. See [Voice Satellite](https://kiosksatellite.com/docs/voice-satellite/).

## Documentation

[Voice Satellite](https://kiosksatellite.com/docs/voice-satellite/) · [Screensavers](https://kiosksatellite.com/docs/screensavers/) · [Music](https://kiosksatellite.com/docs/sendspin/) · [ESPHome & Bluetooth](https://kiosksatellite.com/docs/esphome/) · [Fleet management](https://kiosksatellite.com/docs/fleet/)

<details>
<summary><strong>All guides and API references</strong></summary>
<p></p>
  
&bull; **Display:** [Screen settings](https://kiosksatellite.com/docs/screen/), [custom pages](https://kiosksatellite.com/docs/custom-pages/), [screensavers](https://kiosksatellite.com/docs/screensavers/), [Immich](https://kiosksatellite.com/docs/immich/) and [At a Glance widgets](https://kiosksatellite.com/docs/at-a-glance/).

&bull; **Voice and media:** [Voice Satellite](https://kiosksatellite.com/docs/voice-satellite/), [microphone](https://kiosksatellite.com/docs/microphone/), [media player](https://kiosksatellite.com/docs/sendspin/), [camera views](https://kiosksatellite.com/docs/cameras/), [device camera](https://kiosksatellite.com/docs/camera/), [intercom](https://kiosksatellite.com/docs/intercom/) and [DLNA](https://kiosksatellite.com/docs/dlna/).

&bull; **Kiosk setup:** [Lockdown](https://kiosksatellite.com/docs/kiosk/), [home launcher](https://kiosksatellite.com/docs/home-launcher/), [gestures](https://kiosksatellite.com/docs/gestures/), [LED control](https://kiosksatellite.com/docs/led-control/), [alarms](https://kiosksatellite.com/docs/alarms/), [optimizations](https://kiosksatellite.com/docs/optimizations/), [permissions](https://kiosksatellite.com/docs/permissions/), [Shizuku](https://kiosksatellite.com/docs/shizuku/) and [updates](https://kiosksatellite.com/docs/updates/).

&bull; **Automation and management:** [ESPHome](https://kiosksatellite.com/docs/esphome/), [fleet management](https://kiosksatellite.com/docs/fleet/), [Remote API](https://kiosksatellite.com/docs/remote-api/), [TLS encryption](https://kiosksatellite.com/docs/tls/) and [JavaScript API](https://kiosksatellite.com/docs/js-api/).

&bull; **Device guides:** [Amazon Fire tablets](https://kiosksatellite.com/docs/fire/), [Echo Dot](https://kiosksatellite.com/docs/echo-dot/), [Echo Show 5](https://kiosksatellite.com/docs/echo-show-5/), [Echo Show 8](https://kiosksatellite.com/docs/echo-show-8/), [Meta Portal](https://kiosksatellite.com/docs/portal/) and [Raspberry Pi 4](https://kiosksatellite.com/docs/raspberry-pi/).

&bull; **Plugin Manager:** Install and create [community plugins](https://kiosksatellite.com/docs/plugins/) for Kiosk Satellite.

</details>
 
## Thank you for your support

Thank you to everyone who supports my work through [Buy Me a Coffee](https://buymeacoffee.com/jxlarrea). I test everything on real hardware, which means buying devices to reproduce issues and check changes across different manufacturers and Android flavors. Your contributions help cover those purchases and make that testing possible.


## License and credits

Free for personal, non-commercial use under [CC BY-NC-ND 4.0](LICENSE). Commercial use of the application and redistribution of modified application builds are not permitted. Independent plugins have [additional permission](PLUGIN-EXCEPTION.md).

<details>
<summary>Built with these projects</summary>
<p></p>
  
Thanks to [Home Assistant](https://www.home-assistant.io/), [ESPHome](https://esphome.io/), [Music Assistant](https://www.music-assistant.io/), [Immich](https://immich.app/), [Flutter](https://flutter.dev/), [flutter_inappwebview](https://inappwebview.dev/) and [ONNX Runtime](https://onnxruntime.ai/).

Wake-word support builds on [vsWakeWord](https://github.com/jxlarrea/voice-satellite-card-integration), [openWakeWord](https://github.com/dscripka/openWakeWord) and [microWakeWord](https://github.com/kahrendt/microWakeWord). Echo cancellation uses [WebRTC audio processing](https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing) and [Abseil](https://abseil.io/). Icons come from [Material Design Icons](https://pictogrammers.com/library/mdi/). Fonts include [Rubik](https://fonts.google.com/specimen/Rubik), [Nunito](https://fonts.google.com/specimen/Nunito), [Inter](https://rsms.me/inter/) and [DSEG](https://github.com/keshikan/DSEG).

Thank you to the package authors whose work makes Kiosk Satellite possible.

</details>
