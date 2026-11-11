# Echo Show 8 (2nd gen)

This setup has been verified on a 2nd generation Echo Show 8 (`athena`) from 2021 running the [Kiosk Satellite Edition of LineageOS for the Echo Show 8 (2nd gen)](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8-2nd-gen.md), a LineageOS 18.1 (Android 11) image tuned for Kiosk Satellite. It is the recommended way to run Kiosk Satellite on the Show. The image is the repository's own port and uses [R0rt1z2](https://github.com/R0rt1z2)'s unlock and TWRP to install.

The [Echo Show 8 (1st gen)](echo-show-8.md) from 2019 has its own image and guide.

## Why This Image

- **A raw microphone for the wake word.** Kiosk Satellite gets the Show's microphones as captured, with no processing from Amazon's audio stack in between, and runs its own echo canceller over them. See [Volume](#volume).
- **Kiosk Satellite is installed on first boot.** Once the Show is on Wi-Fi, the latest Kiosk Satellite release is downloaded, installed, given every permission it needs and made the device owner. There are no adb commands to run for it and Kiosk Satellite's updates install without a confirmation.
- **System updates.** Kiosk Satellite shows new releases of the image and installs them, also from Home Assistant. See [System Updates](#system-updates).
- **More free memory.** The image leaves out the apps and services a kiosk does not use. With Kiosk Satellite on screen, about 1 GB of the Show's 2 GB stays available.
- **Privacy and the screen on separate presses.** A short press of the button turns privacy on and off. Holding it for 3 seconds turns the screen on and off. See [The Button](#the-button).
- **Double tap to wake.** A double tap on the screen while it is off turns it back on.
- **Steady Wi-Fi.** The Show keeps the access point it joined instead of moving between mesh nodes, which stalls audio and drops Home Assistant.

The image's guide lists every change.

## Before You Start

The Show needs the [Kiosk Satellite Edition of LineageOS for the Echo Show 8 (2nd gen)](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8-2nd-gen.md) and Kiosk Satellite 2026.11.16 or newer, the first version with the microphone gain for this Show. Follow the image's guide to unlock the Show, install the image, set the time and join Wi-Fi from adb. Kiosk Satellite is then installed and opens on the screen.

The Show names itself `echo-show-8-g2-ks` and the last three characters of its serial, `echo-show-8-g2-ks-6g0` for example, so it shows up under its own name on your router. Android reports its model as **Echo Show 8 2nd Gen (KS)**.

## Setup

Go through the setup wizard on the screen or at `http://<show ip>:2324` in a browser: an admin password, the Home Assistant connection, the dashboard and the Voice Satellite wake word. The image's guide shows how to find the Show's [IP address](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8-2nd-gen.md#after-installing). Then add the Show in Home Assistant under **Settings > Devices & services**, where it shows up as discovered.

## Wake Word

Pick the engine with **Wake word engine** under **Voice Satellite > Wake Word**, with the **VS Wake word engine** select in Home Assistant or in the setup wizard. The Show offers vsWakeWord, microWakeWord and openWakeWord.

**Amazon**, the engine Echo devices shipped with, shows up only when you install Pryon's files in `/data/pryon`. See [Amazon's wake word engine](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8-2nd-gen.md#amazons-wake-word-engine) in the image guide. Kiosk Satellite reads the models the image has when it starts, so restart the Show after you install or change the files. With **Amazon** picked, a **Wake word language** select shows up under the engine. It lists the locales of the models you installed and starts on the first one in `locales.txt`.

Each model also has its own stop word, so **Stop word interruption** works as it does with the other engines. Saying "stop" ends a ringing timer or a reply.

## Volume

Keep the Show's master volume at 60% and Kiosk Satellite's media player and assistant volumes at 100%. That fills a room. The Show's amplifier is far stronger than its speakers need, so the image holds the speaker 6 dB under the amplifier's full output even at 100%. A fresh install of the image starts at these levels.

The microphones come in raw, so Kiosk Satellite adds a 24 dB base gain under **Microphone gain** on this Show. The slider's 0 dB is the right level for the device.

## The Button

The Show's power button is also its privacy button. The Show's privacy chip turns privacy on and off on any press shorter than about 3 seconds. So the image keeps the two apart:

- **A short press** turns privacy on and off. The red light shows when it is on.
- **Holding it for 3 seconds** turns the screen on and off and leaves privacy alone.

This is the other way around from the Echo Show 8 (1st gen), where a short press is the screen. The image's guide shows how to get [Android's usual button](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8-2nd-gen.md#the-button) back and how to set a [privacy timeout](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8-2nd-gen.md#privacy-timeout).

A double tap on the screen also turns it back on. Android does not say what woke the screen, so **Wake to screensaver** counts a double tap as **Power button**.

## System Updates

The image updates from the [Echo Show 8 (2nd gen) releases](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/releases?q=athena) of its repository, and Kiosk Satellite shows these updates. In the remote admin, **About > System** shows the installed release of the image. Click the version to check for a newer one. When there is one, **Install** shows its release notes and starts the update. The Overview lists a new release under **Needs attention**. Home Assistant gets a **Firmware** update entity that checks and installs the same way, next to **Update** for Kiosk Satellite itself.

The image downloads the release, checks its signature and restarts into TWRP to install it. The Show has one copy of the system, so it is offline for a few minutes, once. Kiosk Satellite and its settings stay. The image checks for a new release a minute after every boot, and Kiosk Satellite asks it again twice a day. The image's [device commands](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8-2nd-gen.md#system-updates) do the same from adb.
