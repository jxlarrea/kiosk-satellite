# Echo Dot (3rd gen)

This setup has been verified on a 3rd generation Echo Dot (`donut`) from 2018 running the [Kiosk Satellite Edition of LineageOS for the Echo Dot (3rd gen)](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot-3rd-gen.md), a LineageOS 18.1 (Android 11) image tuned for Kiosk Satellite. The image is the repository's own port, with its own device tree, audio driver layer and a kernel built from Amazon's source release. The Dot has no screen, so Kiosk Satellite runs headless on it: a voice satellite, intercom, alarm clock, timer and speaker for Home Assistant, set up and managed entirely from the remote admin.

> [!CAUTION]
> The image is only for the Echo Dot (3rd gen) released in 2018, model D9N29T. Amazon also sold a revised Echo Dot (3rd gen) in 2019 and 2020, model C78MP8, with different hardware, and neither the unlock nor the image works on it. Check the model number on the bottom of the Dot first.

The [Echo Dot (2nd gen)](echo-dot.md) has its own image and guide.

## Why This Image

- **A raw microphone for the wake word.** Kiosk Satellite gets one of the Dot's four microphones as captured, with nothing removed from it, and runs its own echo canceller over it. See [Volume](#volume).
- **Kiosk Satellite is installed on first boot.** Once the Dot is on Wi-Fi, the latest Kiosk Satellite release is downloaded, installed, given every permission it needs and made the device owner. There are no adb commands to run for it and Kiosk Satellite's updates install without a confirmation.
- **System updates.** Kiosk Satellite shows new releases of the image and installs them, also from Home Assistant. See [System Updates](#system-updates).
- **The buttons reach Kiosk Satellite.** The Action button and the volume buttons come in as broadcasts from the image, with no accessibility service, and the privacy button's state always matches what Kiosk Satellite shows. See [The Buttons](#the-buttons).
- **The light ring.** Kiosk Satellite drives the ring with [LED Control](led-control.md).
- **The line out jack.** With something plugged in, the Dot plays through the jack and its own speaker is off.
- **Steady Wi-Fi.** The Dot keeps the access point it joined instead of moving between mesh nodes, which stalls audio and drops Home Assistant.
- **More free memory.** The image leaves out everything that draws on a screen. With Kiosk Satellite connected, about 235 MB of the Dot's 490 MB stays available.

The image's guide lists every change.

## Headless Mode

Kiosk Satellite turns headless on its own on any device whose display is a stub (the Dot reports a 1x1 display). Nothing needs to be switched on. On a headless device:

- No screen is ever drawn. There is no WebView, dashboard, screensaver, camera or camera view, and the app never opens an Activity.
- The Kiosk Satellite Service starts when the device boots, whatever **Start on boot** says. The [Home Launcher](home-launcher.md) is not needed.
- Voice Satellite, the intercom, alarms, timers, the [DLNA renderer](dlna.md), the [Sendspin player](sendspin.md), ESPHome, [Fleet Management](#fleet-management) and plugins work as usual.
- Plugins that need a screen do not install. See [Plugins](#plugins).
- The remote admin leaves out every page and control that needs a screen: Web Browsing, Screensaver, Camera, Camera Streams, Kiosk Mode, Lockdown Mode, Home Launcher and App Launcher, the dashboard settings of Home Assistant, the screenshot and the screen tiles of the Overview, and the display settings on the other pages.
- ESPHome leaves out the screen, screensaver, dashboard and camera entities.
- The DLNA renderer offers audio only, so Home Assistant's media browser lists only what the Dot can play.
- Intercom calls are always hands-free.
- **Remote management** stays on, since the remote admin is the only way in.
- Android is kept awake. Asleep, Android drops the Action button before the app can hear it.

## Before You Start

The Dot needs the [Kiosk Satellite Edition of LineageOS for the Echo Dot (3rd gen)](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot-3rd-gen.md) and Kiosk Satellite 2026.11.17 or newer, the first version with the microphone gain and the equalizer preset for this Dot. The Dot has no USB port on the outside, so the unlock means soldering a USB cable to test pads on its board. Follow the image's guide to unlock the Dot, install the image and join Wi-Fi. Kiosk Satellite is then installed on its own.

Android reports the Dot's model as **Echo Dot 3rd Gen (KS)**.

## Setup

Open `http://<dot ip>:2324` in a browser. The image's guide shows how to find the Dot's [IP address](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot-3rd-gen.md#after-installing). In the setup wizard, set an admin password, the Home Assistant connection and the Voice Satellite wake word. The wizard skips the dashboard step. Then add the Dot in Home Assistant under **Settings > Devices & services**, where it shows up as discovered.

A fresh install starts with **Use real Wi-Fi MAC address** on, so the Dot's ESPHome device links with the entries your router and network integrations already have for it ([Device Identity](esphome.md#device-identity)).

## Wake Word

Pick the engine with **Wake word engine** under **Voice Satellite > Wake Word**, with the **VS Wake word engine** select in Home Assistant or in the setup wizard. The Dot offers these:

| Engine | What it is |
|---|---|
| vsWakeWord | The default. Its models ship with the app. |
| microWakeWord | The engine of Home Assistant's voice hardware. Its models ship with the app, and it also offers the custom models Home Assistant has. |
| openWakeWord | Its models ship with the app. |
| Amazon | The engine the Dot shipped with. It shows up only when you install Pryon's files in `/data/pryon`. See [Amazon's wake word engine](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md#amazons-wake-word-engine) in the image guide, which uses the same layout on every Echo. |

vsWakeWord, microWakeWord and openWakeWord also take your own models. See [Custom wake word models](custom-wake-words.md).

### Amazon

Kiosk Satellite reads the models the image has when it starts, so restart the Dot after you install or change the files in `/data/pryon`. If the engine does not show up, the app log lists the files the image could not read and the models it skipped.

With **Amazon** picked, a **Wake word language** select shows up under the engine. It lists the locales of the models you installed and starts on the first one in `locales.txt`. If you remove the files of the picked locale, the first one is used. **Wake word sensitivity** applies too.

Each model also has its own stop word, so **Stop word interruption** works as it does with the other engines. Saying "stop" ends a ringing timer or a reply.

## Volume

Keep the Dot's master volume at 80% and Kiosk Satellite's assistant and intercom volumes at 100%, with the media volume at 85%. Turn music down in Kiosk Satellite or Music Assistant rather than with the master volume. A fresh install of Kiosk Satellite starts at these media and intercom volumes, and a Dot that updates moves to them once, together with the equalizer preset below. To set the master volume to 80% from adb, run `adb shell biscuit_service volume set 12`.

The microphones come in raw and quiet, so Kiosk Satellite adds a 27 dB base gain under **Microphone gain** on this Dot. The slider's 0 dB is the right level for the device. The image keeps the microphones' own gain low, since the Dot's speaker already drives them close to full scale at full volume.

## Equalizer

Kiosk Satellite turns the [Equalizer](equalizer.md) on for the Dot with a preset for its speaker: 100 Hz at +3 dB, 300 Hz at +2 dB, 1 kHz at -1 dB, 3 kHz at -3 dB and 10 kHz at +1 dB, with **Automatic preamp** off so the Dot keeps its volume. The preset and the volumes above are set once, on a fresh install or on the first start of a version that has them. Change the bands, the volumes or turn the equalizer off under **Audio > Equalizer** in the remote admin and your setting stays.

## The Buttons

| Button | What it does |
|---|---|
| Action | Answers a ringing intercom call, stops a ringing alarm, dismisses a ringing timer or the voice turn, or ends an intercom call. With none of those happening, it starts a voice command. |
| Privacy | Cuts all four microphones in hardware and lights the button's own LED. The image sets Android's microphone mute to match, so the **VS Mute** switch in Home Assistant, the remote admin and the light ring always show the real state. While privacy is on, only the button turns the microphones back on. |
| Volume up and down | Change the volume. With **Volume buttons control the player** set to **While the player is playing** under Media Player, they control the followed player or the Music Assistant group the Dot plays in instead. Each press is one step: holding a button does not repeat. |

The Action button can also run any gesture action. Add a **Button** gesture on the [Gestures](gestures.md) page for a press, a double press or a hold of the Action button. A press no gesture claims keeps the job above. The image handles the privacy and volume buttons itself, so they cannot be mapped.

[Claps](gestures.md#claps) work as well, since they only need the microphone.

## The Light Ring

The ring shows voice activity, timers, alarms, intercom calls, notifications and the microphone mute in the colors an Echo Dot uses. Each can be changed or switched off on the **LED Control** page. See [LED Control](led-control.md).

## Plugins

[Plugins](plugins.md) work on the Dot, except for the parts that need a screen:

- A plugin that publishes entities, reacts to Voice Satellite or talks to Home Assistant runs as it would anywhere else.
- A plugin built around overlays or screensavers does not install. The Plugin Manager shows **This plugin needs a screen** and keeps its Install button disabled, and a fleet leader that tries to push one shows the same reason on the Dot's row.
- A plugin can declare that it also runs without a screen. It then installs and leaves out its overlays and screensavers on the Dot.

The **LED Control** page drives the light ring itself, so the ring needs no plugin.

## Fleet Management

The Dot can follow a [fleet](fleet.md) leader like any other kiosk, but give it a profile of its own. A leader with a screen does not offer the **Button** gesture trigger, so a profile that includes the **Gestures** category sends a gesture list without button gestures and replaces the Dot's at every sync.

- Create a profile on the leader without the **Gestures** category and assign the Dot, and any other device without a screen, to it. To keep the rest of the Gestures category in sync, keep the category and exclude only the **Gestures** setting, the gesture list itself.
- If the Dot only needs updates from the fleet, assign it to the built-in **Updates only** profile.

Then set up the Button gestures on the Dot's own remote admin. The other categories are safe to sync: the Dot ignores the leader's values for the settings it holds fixed, such as the screensaver switch. The equalizer stays on each device, so the Dot keeps its own preset.

## System Updates

The image updates itself from the [Echo Dot (3rd gen) releases](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/releases?q=donut) of its repository, and Kiosk Satellite shows these updates. In the remote admin, **About > System** shows the installed release of the image. Click the version to check for a newer one. When there is one, **Install** shows its release notes and starts the update. The Overview lists a new release under **Needs attention**. Home Assistant gets a **Firmware** update entity that checks and installs the same way, next to **Update** for Kiosk Satellite itself.

The image downloads the release, checks its signature and then restarts twice to install it, once for each slot. The Dot is offline for a couple of minutes each time. Kiosk Satellite and its settings stay. The image checks for a new release a minute after every boot, and Kiosk Satellite asks it again twice a day. The image's [device commands](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot-3rd-gen.md#system-updates) do the same from adb.

## Memory

The Overview's RAM tile counts the memory Android can give out, usually about 0.24 GB on the Dot. Android keeps the rest filled with cached apps and files it gives back on demand. The image already leaves out everything that draws on a screen and the system apps the Dot does not need.

## Bluetooth

Bluetooth is on, so the [Bluetooth proxy](esphome.md) works with no setup. The Dot starts out as a Bluetooth speaker that phones can play to. To play the Dot's audio on Bluetooth headphones or a speaker instead, put them in pairing mode and run `adb shell biscuit_service bt connect '<name>'`. The Dot does one or the other, not both. `adb shell biscuit_service bt off` turns Bluetooth off and `adb shell biscuit_service bt on` turns it back on.
