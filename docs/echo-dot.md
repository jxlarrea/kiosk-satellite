# Echo Dot

This setup has been verified on a 2nd generation Echo Dot (`biscuit`) running the [Kiosk Satellite Edition of LineageOS for the Echo Dot](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md), a LineageOS 18.1 (Android 11) image tuned for Kiosk Satellite. The Dot has no screen, so Kiosk Satellite runs headless on it: a voice satellite, intercom, alarm clock, timer and speaker for Home Assistant, set up and managed entirely from the remote admin.

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

The Dot needs the [Kiosk Satellite Edition of LineageOS for the Echo Dot](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md). Follow its guide to unlock the Dot, install the image and join Wi-Fi. Once the Dot is on Wi-Fi, the latest Kiosk Satellite release is downloaded, installed, given every permission it needs and made the device owner, so there are no adb commands to run.

The image also improves on the upstream port in ways that matter for Kiosk Satellite: the wake word works over music at full volume, the microphone is louder, the light ring no longer flickers and more memory stays free. Its guide lists every change.

The Dot names itself `echo-dot-ks` and the last three characters of its serial, `echo-dot-ks-he4` for example, so it shows up under its own name on your router. Kiosk Satellite shows its model as **Amzn Echo Dot (KS)**.

## Setup

Open `http://<dot ip>:2324` in a browser. The image's guide shows how to find the Dot's [IP address](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md#after-installing). In the setup wizard, set an admin password, the Home Assistant connection and the Voice Satellite wake word. The wizard skips the dashboard step. Then add the Dot in Home Assistant under **Settings > Devices & services**, where it shows up as discovered.

A fresh install starts with **Use real Wi-Fi MAC address** on, so the Dot's ESPHome device links with the entries your router and network integrations already have for it ([Device Identity](esphome.md#device-identity)).

The Action button and the volume buttons reach Kiosk Satellite as broadcasts from the image, so Kiosk Satellite needs no accessibility service.

On the CM14.1 image the Action button goes through an accessibility service instead, which is switched on at every boot. Force-stopping Kiosk Satellite there, with `adb shell am force-stop` or **Force stop** in Android's app settings, switches the service off until the next reboot. **Restart app** does not switch it off.

## Wake Word

Pick the engine with **Wake word engine** under **Voice Satellite > Wake Word**, with the **VS Wake word engine** select in Home Assistant or in the setup wizard. The Dot offers these:

| Engine | What it is |
|---|---|
| vsWakeWord | The default. Its models ship with the app. |
| microWakeWord | The engine of Home Assistant's voice hardware. Its models ship with the app, and it also offers the custom models Home Assistant has. |
| openWakeWord | Its models ship with the app. |
| Amazon | The engine the Dot shipped with. It shows up only when you install Pryon's files in `/data/pryon` on image 2026.11.3 or newer. See [Amazon's wake word engine](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md#amazons-wake-word-engine) in the image guide. The [Echo Show 5 (1st gen)](echo-show-5-1st-gen.md#wake-word), [Echo Show 5 (2nd gen)](echo-show-5.md#wake-word), [Echo Show 8 (1st gen)](echo-show-8.md#wake-word) and [Echo Show 8 (2nd gen)](echo-show-8-2nd-gen.md#wake-word) images offer it too. |

vsWakeWord, microWakeWord and openWakeWord also take your own models. See [Custom wake word models](custom-wake-words.md).

### Amazon

Kiosk Satellite reads the models the image has when it starts, so restart the Dot after you install or change the files in `/data/pryon`. If the engine does not show up, the app log lists the files the image could not read and the models it skipped.

With **Amazon** picked, a **Wake word language** select shows up under the engine. It lists the locales of the models you installed and starts on the first one in `locales.txt`. If you remove the files of the picked locale, the first one is used. **Wake word sensitivity** applies too.

Each model also has its own stop word, so **Stop word interruption** works as it does with the other engines. Saying "stop" ends a ringing timer or a reply.

## Volume

Keep the **Master volume** on the **Audio** page at 100%, the assistant and intercom volumes at 100% and the media volume at 85%. A fresh install starts at these levels and a Dot that updates moves to them once, together with the equalizer preset below. The image removes the speaker's sound from the Dot's microphones while music plays, so the wake word works at any media volume, up to 100%.

## Equalizer

The Dot's small speaker is weak from 300 to 500 Hz and loud around 3 kHz, which sounds thin. Kiosk Satellite turns the [Equalizer](equalizer.md) on for the Dot with a preset that corrects it: 100 Hz at +1 dB, 300 Hz at +2 dB, 1 kHz at -3 dB, 3 kHz at -7 dB and 10 kHz at -1 dB, with **Automatic preamp** off so the Dot keeps its volume. The preset and the volumes above are set once, on a fresh install or on the first start of a version that has them. Change the bands, the volumes or turn the equalizer off under **Audio > Equalizer** in the remote admin and your setting stays.

## The Buttons

| Button | What it does |
|---|---|
| Action | Answers a ringing intercom call, stops a ringing alarm, dismisses a ringing timer or the voice turn, or ends an intercom call. With none of those happening, it starts a voice command. |
| Microphone | Mutes and unmutes Voice Satellite. The mute follows the Dot's microphone mute both ways, so the button, the **VS Mute** switch in Home Assistant and the remote admin always agree, and the light ring shows it. |
| Volume up and down | Change the volume. With **Volume buttons control the player** set to **While the player is playing** under Media Player, they control the followed player or the Music Assistant group the Dot plays in instead. On the CM14.1 image this needs 2026.10.2 or newer. Each press is one step: holding a button does not repeat. |

The Action button can also run any gesture action. Add a **Button** gesture on the [Gestures](gestures.md) page for a press, a double press or a hold of the Action button. A press no gesture claims keeps the job above. The LineageOS build handles the microphone and volume buttons itself, so they cannot be mapped.

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

Then set up the Button gestures on the Dot's own remote admin. The other categories are safe to sync: the Dot ignores the leader's values for the settings it holds fixed, such as the screensaver switch.

## System Updates

The image updates itself from the [Echo Dot releases](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/releases?q=biscuit) of its repository, and Kiosk Satellite shows these updates. In the remote admin, **About > System** shows the installed release of the image. Click the version to check for a newer one. When there is one, **Install** shows its release notes and starts the update. The Overview lists a new release under **Needs attention**. Home Assistant gets a **Firmware** update entity that checks and installs the same way, next to **Update** for Kiosk Satellite itself.

The image downloads the release, checks its signature and then restarts twice to install it, once for each slot. The Dot is offline for about a minute each time. Kiosk Satellite and its settings stay. The image checks for a new release a minute after every boot, and Kiosk Satellite asks it again twice a day. The image's [device commands](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md#system-updates) do the same from adb.

## Moving from the CM14.1 Image

The CM14.1 image updates only from its own repository, which gets no more releases, so it reports that it is up to date. Kiosk Satellite checks the new image's Echo Dot releases itself. When there is one, **About > System** shows **New image available** with a link to the guide, the Overview lists it under **Needs attention** and the **Firmware** entity in Home Assistant shows its version, with the guide as its release page.

The new image installs by hand, not as an update, since the move from Android 7 to Android 11 needs an erased data partition. **Install** on the Firmware entity does nothing. Follow [Moving from the CM14.1 image](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md#moving-from-the-cm141-image):

1. In the remote admin, use **Export configuration** and keep the file.
2. Install the new image as its guide shows.
3. Once Kiosk Satellite is back, choose **Restore from configuration file** in the setup wizard and pick the file you exported.

## Memory

The Overview's RAM tile counts the memory Android can give out, usually about 0.25 GB on the Dot. Android keeps the rest filled with cached apps and files it gives back on demand. The image already leaves out the system apps the Dot does not need and sets up about 240 MB of compressed swap (zram).

## Bluetooth

Bluetooth is on, so the [Bluetooth proxy](esphome.md) works with no setup. The Dot starts out as a Bluetooth speaker that phones can play to. To play the Dot's audio on Bluetooth headphones or a speaker instead, put them in pairing mode and run `adb shell biscuit_service bt connect '<name>'`. The Dot does one or the other, not both. The image's guide covers [Bluetooth](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite/blob/main/docs/echo-dot.md#bluetooth).

On the CM14.1 image Bluetooth is off on a fresh install, which saves 15 to 20 MB. Turn it on with `adb shell biscuit_service bt on`. It stays on across reboots, and `adb shell biscuit_service bt off` turns it off again.
