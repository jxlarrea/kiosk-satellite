# Echo Show 5 (1st gen)

This setup has been verified on a 1st generation Echo Show 5 (`checkers`) from 2019 running the [Kiosk Satellite Edition of LineageOS for the Echo Show 5 (1st gen)](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-5-1st-gen.md), a LineageOS 18.1 (Android 11) image tuned for Kiosk Satellite. It is the recommended way to run Kiosk Satellite on the Show. The image builds on the LineageOS 18.1 port in [amazon-oss](https://github.com/amazon-oss) by [R0rt1z2](https://github.com/R0rt1z2) and [bengris32](https://github.com/bengris32), which brings the screen, camera and Bluetooth, and adds what a kiosk needs on top.

The [Echo Show 5 (2nd gen)](echo-show-5.md) from 2021 has its own image and guide.

## Why This Image

- **The wake word works over music.** The image gives Kiosk Satellite the Show's raw microphone, and Kiosk Satellite's echo canceller removes the speaker's sound from it. The wake word works with music playing. See [Volume](#volume).
- **Kiosk Satellite on first boot.** Once the Show is on Wi-Fi, the latest Kiosk Satellite release is downloaded, installed, given every permission it needs and made the device owner. There are no adb commands to run and Kiosk Satellite's updates install without a confirmation.
- **System updates.** Kiosk Satellite shows new releases of the image and installs them, also from Home Assistant. See [System Updates](#system-updates).
- **More free memory.** The image leaves out the apps and services a kiosk does not use. With Kiosk Satellite on screen for over an hour, about 400 MB of the Show's 1 GB stays available.
- **Privacy and the screen on separate presses.** A short press of the button turns the screen on and off. Holding it for about a second and a half turns privacy on and off. See [The Button](#the-button).
- **Double tap to wake.** A double tap on the screen turns it back on while it is off.
- **Steady Wi-Fi.** The Show keeps the access point it joined instead of moving between mesh nodes, which stalled audio and dropped Home Assistant.

The image's guide lists every change.

## Before You Start

The Show needs the [Kiosk Satellite Edition of LineageOS for the Echo Show 5 (1st gen)](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-5-1st-gen.md). Follow its guide to unlock the Show with amonet 2, install the image, set the time and join Wi-Fi from adb. Once that is done, Kiosk Satellite is installed and opens on the screen.

If the Show runs another LineageOS image, see [Moving from Another Image](#moving-from-another-image).

The Show names itself `echo-show-5-g1-ks` and the last three characters of its serial, `echo-show-5-g1-ks-qr1` for example, so it shows up under its own name on your router. Kiosk Satellite shows its model as **Amzn Echo Show 5 1st Gen (KS)**.

## Setup

Go through the setup wizard on the screen or at `http://<show ip>:2324` in a browser: an admin password, the Home Assistant connection, the dashboard and the Voice Satellite wake word. The image's guide shows how to find the Show's [IP address](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-5-1st-gen.md#after-installing). Then add the Show in Home Assistant under **Settings > Devices & services**, where it shows up as discovered.

## Wake Word

Pick the engine with **Wake word engine** under **Voice Satellite > Wake Word**, with the **VS Wake word engine** select in Home Assistant or in the setup wizard. The Show offers vsWakeWord, microWakeWord and openWakeWord.

**Amazon**, the engine Echo devices shipped with, shows up only when you install Pryon's files in `/data/pryon`. It needs Kiosk Satellite 2026.11.14 or newer. See [Amazon's wake word engine](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-5-1st-gen.md#amazons-wake-word-engine) in the image guide. Kiosk Satellite reads the models the image has when it starts, so restart the Show after you install or change the files. With **Amazon** picked, a **Wake word language** select shows up under the engine. It lists the locales of the models you installed and starts on the first one in `locales.txt`.

Each model also has its own stop word, so **Stop word interruption** works as it does with the other engines. Saying "stop" ends a ringing timer or a reply.

## Volume

Keep the Show's media volume at 70% and Kiosk Satellite's media player and assistant volumes at 100%. The Show has the same speaker as the Echo Show 5 (2nd gen). That fills a room, and the wake word still works over music. A fresh install of the image starts at these levels.

Kiosk Satellite 2026.11.14 and newer add a 20 dB base gain to the Show's microphone, so 0 dB under **Microphone gain** is the right level.

## The Button

The Show's power button is also its privacy button. The Show's privacy chip turns privacy on after a hold of about a second and a half, and any press turns it off again. So the image keeps the two apart:

- **A short press** turns the screen on and off.
- **Holding it for about a second and a half** turns privacy on and off. The red light shows when it is on.
- **While privacy is on,** a press only turns privacy off and leaves the screen as it is.

The image's guide shows how to get [Android's usual button](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-5-1st-gen.md#the-button) back.

## System Updates

The image updates itself from the [Echo Show 5 (1st gen) releases](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/releases?q=checkers) of its repository, and Kiosk Satellite shows these updates. In the remote admin, **About > System** shows the installed release of the image. Click the version to check for a newer one. When there is one, **Install** shows its release notes and starts the update. The Overview lists a new release under **Needs attention**. Home Assistant gets a **Firmware** update entity that checks and installs the same way, next to **Update** for Kiosk Satellite itself.

The image downloads the release, checks its signature and restarts into TWRP to install it. The Show has one copy of the system, so it is offline for a few minutes, once. Kiosk Satellite and its settings stay. The image checks for a new release a minute after every boot, and Kiosk Satellite asks it again twice a day. The image's [device commands](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-5-1st-gen.md#system-updates) do the same from adb.

## Moving from Another Image

The image installs by hand, not as an update, since it needs an erased data partition. Follow [Moving from another image](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-5-1st-gen.md#moving-from-another-image):

1. In the remote admin, use **Export configuration** and keep the file.
2. Install the image as its guide shows.
3. Once Kiosk Satellite is back, choose **Restore from configuration file** in the setup wizard and pick the file you exported.

If the Show was unlocked with an older amonet, update it to amonet 2 first. The image's guide covers [updating an older amonet](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/unlocking.md#updating-an-older-amonet).
