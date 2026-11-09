# Echo Show 8

This setup has been verified on a 1st generation Echo Show 8 (`crown`) running the [Kiosk Satellite Edition of LineageOS for the Echo Show 8](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8.md), a LineageOS 18.1 (Android 11) image tuned for Kiosk Satellite. It is the recommended way to run Kiosk Satellite on the Show. The image builds on [R0rt1z2](https://github.com/R0rt1z2)'s LineageOS 18.1 port, which brings the screen, camera and Bluetooth, and adds what a kiosk needs on top.

## Why This Image

Kiosk Satellite also runs on the upstream port, but the image fixes what gets in its way there:

- **The wake word works over music.** Kiosk Satellite hears the Show through the far-field processing Amazon's own wake word used on Fire OS, with echo cancellation and a beamformer over all four microphones. The wake word works over loud music and over the assistant's own voice. See [Volume](#volume).
- **Kiosk Satellite installs itself.** Once the Show is on Wi-Fi, the latest Kiosk Satellite release is downloaded, installed, given every permission it needs and made the device owner. There are no adb commands to run and Kiosk Satellite's updates install without a confirmation.
- **System updates.** Kiosk Satellite shows new releases of the image and installs them, also from Home Assistant. See [System Updates](#system-updates).
- **More free memory.** The image leaves out the apps and services a kiosk does not use. With Kiosk Satellite on screen for over an hour, about 1.1 GB of the Show's 2 GB stays available.
- **Privacy and the screen on separate presses.** A short press of the button turns the screen on and off. Holding it for about a second and a half turns privacy on and off. See [The Button](#the-button).
- **Steady Wi-Fi.** The Show keeps the access point it joined instead of moving between mesh nodes, which stalled audio and dropped Home Assistant.

The image's guide lists every change.

## Before You Start

The Show needs the [Kiosk Satellite Edition of LineageOS for the Echo Show 8](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8.md). Follow its guide to unlock the Show, install the image, set the time and join Wi-Fi from adb. Kiosk Satellite then installs itself and opens on the screen.

If the Show runs R0rt1z2's image, see [Moving from R0rt1z2's Image](#moving-from-r0rt1z2s-image).

The Show names itself `echo-show-8-ks` and the last three characters of its serial, `echo-show-8-ks-62e` for example, so it shows up under its own name on your router. Kiosk Satellite shows its model as **Amzn Echo Show 8 1st Gen (KS)**.

## Setup

Go through the setup wizard on the screen or at `http://<show ip>:2324` in a browser: an admin password, the Home Assistant connection, the dashboard and the Voice Satellite wake word. The image's guide shows how to find the Show's [IP address](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8.md#after-installing). Then add the Show in Home Assistant under **Settings > Devices & services**, where it shows up as discovered.

## Wake Word

Pick the engine with **Wake word engine** under **Voice Satellite > Wake Word**, with the **VS Wake word engine** select in Home Assistant or in the setup wizard. The Show offers vsWakeWord, microWakeWord and openWakeWord.

**Amazon**, the engine Echo devices shipped with, shows up only when you install Pryon's files in `/data/pryon` on image 2026.11.4 or newer. See [Amazon's wake word engine](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8.md#amazons-wake-word-engine) in the image guide. Kiosk Satellite reads the models the image has when it starts, so restart the Show after you install or change the files. With **Amazon** picked, a **Wake word language** select shows up under the engine. It lists the locales of the models you installed and starts on the first one in `locales.txt`.

Each model also has its own stop word, so **Stop word interruption** works as it does with the other engines. Saying "stop" ends a ringing timer or a reply.

## Volume

Keep the Show's media volume at 50% and Kiosk Satellite's media player and assistant volumes at 100%. The Show 8's speakers are much louder than the Echo Show 5's, and 50% already fills a room. Above it, music drowns out a voice from across the room and the wake word misses more often. A fresh install of the image starts at these levels.

## The Button

The Show's power button is also its privacy button. The Show's privacy chip turns privacy on after a hold of about a second and a half, and any press turns it off again. So the image keeps the two apart:

- **A short press** turns the screen on and off.
- **Holding it for about a second and a half** turns privacy on and off. The red light shows when it is on.
- **While privacy is on,** a press only turns privacy off and leaves the screen as it is.

The image's guide shows how to get [Android's usual button](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8.md#the-button) back.

## System Updates

The image updates itself from the [Echo Show 8 releases](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/releases?q=crown) of its repository, and Kiosk Satellite shows these updates. In the remote admin, **About > System** shows the installed release of the image. Click the version to check for a newer one. When there is one, **Install** shows its release notes and starts the update. The Overview lists a new release under **Needs attention**. Home Assistant gets a **Firmware** update entity that checks and installs the same way, next to **Update** for Kiosk Satellite itself.

The image downloads the release, checks its signature and restarts into TWRP to install it. The Show has one copy of the system, so it is offline for a few minutes, once. Kiosk Satellite and its settings stay. The image checks for a new release a minute after every boot, and Kiosk Satellite asks it again twice a day. The image's [device commands](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8.md#system-updates) do the same from adb.

## Moving from R0rt1z2's Image

The image installs by hand, not as an update, since it needs an erased data partition. Follow [Moving from R0rt1z2's image](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-show-8.md#moving-from-r0rt1z2s-image):

1. In the remote admin, use **Export configuration** and keep the file.
2. Install the image as its guide shows.
3. Once Kiosk Satellite is back, choose **Restore from configuration file** in the setup wizard and pick the file you exported.
