# Kiosk Satellite

Turn any Android tablet into a beautiful, voice-enabled Home Assistant
kiosk — in about two minutes.

Kiosk Satellite is a free kiosk browser built **specifically for Home
Assistant**, and the official companion app for
[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration).
Mount a tablet on the wall, run the setup wizard, and you get a locked-down,
always-on dashboard that listens for your wake word natively — even while
the screen is off or another app is in front.

## What it does

- **Guided setup** — a five-step onboarding wizard connects to your Home
  Assistant, validates the connection, lets you pick the dashboard to
  display, detects Voice Satellite, and requests exactly the Android
  permissions your choices need. Run it on the tablet, or from a web
  browser on your computer (much nicer for pasting access tokens).
- **Voice Satellite, natively** — when the wizard finds the Voice Satellite
  integration on your instance, it assigns this kiosk its own
  `assist_satellite` entity and hands wake-word detection to the app's
  built-in engine. Native detection keeps listening with the screen off or
  the app in the background, uses a fraction of the CPU a browser engine
  needs, and hands the microphone back to the dashboard the instant you
  speak. No configuration inside the card — everything is inherited.
- **Kiosk lockdown** — exit gesture with PIN, blocked back/volume/home
  buttons, a status-bar shield, instant re-wake when someone presses the
  power button, and full lock-task support on device-owner provisioned
  tablets.
- **Screensavers** — dim, black, clock, Home Assistant media, local
  folders, or a photo gallery picked straight from the system picker, with
  crossfade / slide / zoom / Ken Burns transitions.
- **Remote administration** — an embedded web admin at
  `http://<device-ip>:2324` mirrors every setting on the device, shows a
  live screenshot, web console and logs, and can export/import the entire
  configuration (including the dashboard's local storage) as a single
  backup file.
- **Kiosk conveniences** — pull-to-refresh with optional cache clearing,
  start on boot, keep screen awake, default brightness, scheduled
  light/dark theme that can flip the dashboard and the app together, and
  self-signed certificate support out of the box.

## Kiosk Satellite + Voice Satellite

[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration)
turns a Home Assistant dashboard into a full hands-free voice assistant —
wake word, conversations, timers and announcements. It runs entirely in the
browser, which is exactly its limit on a wall tablet: browsers can't listen
while the screen is off, and browser-side wake-word engines are expensive.

Kiosk Satellite removes that limit. The app runs Voice Satellite's own
wake-word models natively and transparently: the card detects it is running
inside Kiosk Satellite and hands detection over on its own. You keep
configuring everything in Voice Satellite as usual; the kiosk just makes it
always-on, cheaper, and screen-independent.

The performance difference is one of the main reasons to use Kiosk
Satellite. Native inference runs the entire wake-word pipeline many times
faster than realtime on the CPU alone — tens of times faster on a modern
tablet — at a fraction of the CPU and battery a browser-side engine burns,
and it keeps the dashboard perfectly smooth while listening. It is
efficient enough that vsWakeWord now runs even on an Amazon Echo Show 5,
on CPU, with no GPU or accelerator needed.

Voice Satellite is not required — Kiosk Satellite is a complete Home
Assistant kiosk on its own — but together they make a tablet into something
very close to a purpose-built voice hub.

## Installation

Kiosk Satellite is distributed as a free APK for sideloading:

1. Download the latest APK from the
   [releases page](../../releases).
2. Copy it to the tablet (or download it there directly) and open it —
   allow installing from unknown sources when Android asks.
3. Open the app and follow the setup wizard. Tip: enable remote
   administration in the first step and finish the setup from a browser on
   your computer — pasting the Home Assistant access token there is much
   easier than typing it on glass.

**Requirements:** Android 7.0 or newer, a Home Assistant instance you can
reach from the tablet, and a long-lived access token (HA profile →
Security → Long-lived access tokens). For voice, install
[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration)
from the default HACS repository.

## Everyday use

- **Menu**: swipe from the left edge — Dashboard, Settings, Web Console,
  Clear web cache, Log out, Exit.
- **Remote admin**: `http://<device-ip>:2324` in any browser on your
  network, protected by the password you chose during setup.
- **Kiosk mode**: once enabled, the menu swipe is replaced by the exit
  gesture (fast taps) and your PIN.

## Status

Kiosk Satellite is in **beta**. It runs day and night on the author's own
wall tablets, but expect rough edges — bug reports and feature requests are
very welcome in the issues.

## Documentation

- [JavaScript API](docs/js-api.md) — `window.kioskSatellite`, wake-word handoff protocol
- [Remote API](docs/remote-api.md) — REST + WebSocket surface

## License

Kiosk Satellite is free for personal, non-commercial use. It is licensed
under
[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/):
you may use and share it, but commercial use and derivative works are not
permitted. See [LICENSE](LICENSE).
