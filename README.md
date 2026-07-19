<h1 align="center" style="border-bottom: none">
   <img alt="Kiosk Satellite for Home Assistant" src="https://raw.githubusercontent.com/jxlarrea/kiosk-satellite/refs/heads/main/assets/banners/kiosk_satellite_banner.png" width="650" />
</h1>

<p align="center">
<img src="https://img.shields.io/github/stars/jxlarrea/kiosk-satellite?style=for-the-badge&label=Stars&color=orange" alt="Stars">
<a href="https://github.com/jxlarrea/kiosk-satellite/releases"><img src="https://img.shields.io/github/downloads/jxlarrea/kiosk-satellite/total?style=for-the-badge&label=Downloads&color=blue" alt="Downloads"></a>
<a href="https://github.com/jxlarrea/kiosk-satellite/releases"><img src="https://shields.io/github/v/release/jxlarrea/kiosk-satellite?style=for-the-badge&color=purple" alt="version"></a>
<a href="https://github.com/jxlarrea/kiosk-satellite/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/jxlarrea/kiosk-satellite/release.yml?style=for-the-badge&label=Build" alt="Build"></a>
</p>

<p align="center">
<a href="https://buymeacoffee.com/jxlarrea"><img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee"></a>
</p>

Turn any Android tablet into a beautiful, voice-enabled Home Assistant
kiosk in about two minutes.

Kiosk Satellite is an open source lightweight kiosk browser built **specifically for Home
Assistant**, and the official companion app for
[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration).
Mount a tablet on the wall, run the setup wizard, and you get a locked-down,
always-on dashboard that listens for your wake word natively, even while
the screen is off or another app is in front.

<p align="center">
 <img src="https://raw.githubusercontent.com/jxlarrea/kiosk-satellite/refs/heads/main/assets/screenshots/drawer.png" alt="Assist" width="94%"/>
</p>

## What it does

- **Guided setup**: a five-step onboarding wizard connects to your Home
  Assistant, validates the connection, lets you pick the dashboard to
  display, detects Voice Satellite, and requests exactly the Android
  permissions your choices need. Run it on the tablet, or from a web
  browser on your computer (much nicer for pasting access tokens).
- **Voice Satellite, natively**: when the wizard finds the Voice Satellite
  integration on your instance, it assigns this kiosk its own
  `assist_satellite` entity and hands wake-word detection to the app's
  built-in engine. Native detection keeps listening with the screen off or
  the app in the background, uses a fraction of the CPU a browser engine
  needs, and hands the microphone back to the dashboard the instant you
  speak. No configuration needed in Voice Satellite; everything is inherited.
- **Plain HTTP instances, fully unlocked**: browsers withhold the
  microphone and every other secure-context feature from `http://` pages,
  which normally cripples voice on a non HTTPS Home Assistant instance. Kiosk
  Satellite routes the dashboard through a loopback proxy inside the app,
  making the page a genuine secure context: the microphone, AudioWorklet
  and the rest of the https-only browser surface work on an http-only
  instance, with no certificates or reverse proxy to set up. Enabled
  automatically during setup when your URL is plain HTTP.
- **Kiosk lockdown**: exit gesture with PIN, blocked back/volume/home
  buttons, a status-bar shield, instant re-wake when someone presses the
  power button, and full lock-task support on device-owner provisioned
  tablets.
- **Screensavers**: dim, black, clock, Home Assistant media, local
  folders, or a photo gallery picked straight from the system picker, with
  crossfade / slide / zoom / Ken Burns transitions.
- **Remote administration**: an embedded web admin at
  `http://<device-ip>:2324` mirrors every setting on the device, shows a
  live screenshot, web console and logs, and can export/import the entire
  configuration (including the dashboard's local storage) as a single
  backup file.
- **Dashboard view rotation**: cycle through a chosen set of dashboard
  views in an endless loop, each on screen for a configurable number of
  seconds. Perfect for flipping between a camera wall, an energy map, and
  the main dashboard.
- **Kiosk conveniences**: pull-to-refresh with optional cache clearing,
  start on boot, keep screen awake, default brightness, scheduled
  light/dark theme that can flip the dashboard and the app together,
  custom JavaScript injected into every page, and self-signed certificate
  support out of the box.

## Kiosk Satellite + Voice Satellite

<p align="center">
 <img src="https://raw.githubusercontent.com/jxlarrea/kiosk-satellite/refs/heads/main/assets/screenshots/vs-settings.png" alt="Assist" width="94%"/>
</p>

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
| Mic acces in non-HTTPS HA instances | ❌ | ✅ |
| Detection cost | ⚠️ Browser based, heavy on tablets | ✅ Native CPU inference, 10x-30x faster |
| Wake word on low-end hardware | ⚠️ Struggles | ✅ CPU only, no GPU needed |
| Voice on a plain http instance | ❌ Browsers block the microphone | ✅ Secure context proxy built in |
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
3. Open the app and follow the setup wizard. Tip: enable remote
   administration in the first step and finish the setup from a browser on
   your computer, where pasting the Home Assistant access token is much
   easier than typing it on glass.

**Requirements:** Android 7.0 or newer, a Home Assistant instance you can
reach from the tablet, and a long-lived access token (HA profile →
Security → Long-lived access tokens). For voice, install
[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration)
from the default HACS repository.

## Everyday use

- **Menu**: swipe from the left edge for Dashboard, Settings, Web Console,
  Clear web cache, Log out, Exit.
- **Remote admin**: `http://<device-ip>:2324` in any browser on your
  network, protected by the password you chose during setup.
- **Kiosk mode**: once enabled, the menu swipe is replaced by the exit
  gesture (fast taps) and your PIN.

## Status

Kiosk Satellite is in **beta**. It runs day and night on the author's own
wall tablets, but expect rough edges. Bug reports and feature requests are
very welcome in the issues.

## Documentation

- [JavaScript API](docs/js-api.md): `window.kioskSatellite`, wake-word handoff protocol
- [Remote API](docs/remote-api.md): REST + WebSocket surface

## License

Kiosk Satellite is free for personal, non-commercial use. It is licensed
under
[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/):
you may use and share it, but commercial use and derivative works are not
permitted. See [LICENSE](LICENSE).
