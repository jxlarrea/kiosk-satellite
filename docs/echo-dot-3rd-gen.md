# Echo Dot (3rd gen)

This setup has been verified on a 3rd generation Echo Dot (`donut`) from 2018 running the [Kiosk Satellite Edition of LineageOS for the Echo Dot (3rd gen)](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot-3rd-gen.md), a LineageOS 18.1 (Android 11) image tuned for Kiosk Satellite. The image is the repository's own port, with its own device tree, audio driver layer and a kernel built from Amazon's source release. The Dot has no screen, so Kiosk Satellite runs headless on it: a voice satellite, intercom, alarm clock, timer and speaker for Home Assistant, set up and managed entirely from the remote admin.

> [!CAUTION]
> The image is only for the Echo Dot (3rd gen) released in 2018, model D9N29T. Amazon also sold a revised Echo Dot (3rd gen) in 2019 and 2020, model C78MP8, with different hardware, and neither the unlock nor the image works on it. Check the model number on the bottom of the Dot first.

The [Echo Dot (2nd gen)](echo-dot.md) has its own image and guide. Kiosk Satellite runs the same way on both, so the 2nd gen guide's sections on [Headless Mode](echo-dot.md#headless-mode), [Plugins](echo-dot.md#plugins) and [Fleet Management](echo-dot.md#fleet-management) apply here too.

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

## Before You Start

The Dot needs the [Kiosk Satellite Edition of LineageOS for the Echo Dot (3rd gen)](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot-3rd-gen.md) and Kiosk Satellite 2026.11.17 or newer, the first version with the microphone gain and the equalizer preset for this Dot. The Dot has no USB port on the outside, so the unlock means soldering a USB cable to test pads on its board. Follow the image's guide to unlock the Dot, install the image and join Wi-Fi. Kiosk Satellite is then installed on its own.

Android reports the Dot's model as **Echo Dot 3rd Gen (KS)**.

## Setup

Open `http://<dot ip>:2324` in a browser. The image's guide shows how to find the Dot's [IP address](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot-3rd-gen.md#after-installing). In the setup wizard, set an admin password, the Home Assistant connection and the Voice Satellite wake word. The wizard skips the dashboard step. Then add the Dot in Home Assistant under **Settings > Devices & services**, where it shows up as discovered.

A fresh install starts with **Use real Wi-Fi MAC address** on, so the Dot's ESPHome device links with the entries your router and network integrations already have for it ([Device Identity](esphome.md#device-identity)).

## Wake Word

Pick the engine with **Wake word engine** under **Voice Satellite > Wake Word**, with the **VS Wake word engine** select in Home Assistant or in the setup wizard. The Dot offers vsWakeWord, microWakeWord and openWakeWord.

**Amazon**, the engine Echo devices shipped with, shows up only when you install Pryon's files in `/data/pryon`. See [Amazon's wake word engine](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md#amazons-wake-word-engine) in the image guide, which uses the same layout on every Echo. Kiosk Satellite reads the models the image has when it starts, so restart the Dot after you install or change the files. With **Amazon** picked, a **Wake word language** select shows up under the engine. It lists the locales of the models you installed and starts on the first one in `locales.txt`.

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

## The Light Ring

The ring shows voice activity, timers, alarms, intercom calls, notifications and the microphone mute in the colors an Echo Dot uses. Each can be changed or switched off on the **LED Control** page. See [LED Control](led-control.md).

## System Updates

The image updates itself from the [Echo Dot (3rd gen) releases](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/releases?q=donut) of its repository, and Kiosk Satellite shows these updates. In the remote admin, **About > System** shows the installed release of the image. Click the version to check for a newer one. When there is one, **Install** shows its release notes and starts the update. The Overview lists a new release under **Needs attention**. Home Assistant gets a **Firmware** update entity that checks and installs the same way, next to **Update** for Kiosk Satellite itself.

The image downloads the release, checks its signature and then restarts twice to install it, once for each slot. The Dot is offline for a couple of minutes each time. Kiosk Satellite and its settings stay. The image checks for a new release a minute after every boot, and Kiosk Satellite asks it again twice a day. The image's [device commands](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot-3rd-gen.md#system-updates) do the same from adb.
