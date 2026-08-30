# Amazon Fire tablets

Verified on a Fire HD 10 (`KFTUWI`, Fire OS 8, Android 11). The lock
screen behavior below was reported and confirmed on a Fire HD 8
(`KFONWI`, Fire OS 7, Android 9) as well. Fire OS 5 tablets (Android
5.1) are below the app's Android 7 minimum and `adb install` refuses them
with `INSTALL_FAILED_OLDER_SDK`.

## Install

Fire tablets have no Google Play. The APK installs over `adb install`
like anywhere else, and the in-app updater takes it from there.

adb is under **Settings, Device Options, Developer Options**, which
appears after tapping the serial number seven times. Fire OS 8 also has
**Wireless debugging**, but it lives on a port that changes at every
reboot and is off after one, so anything that needs a reboot is easier
over a cable.

## Setup in one sitting

Everything a Fire needs, from a computer on the same network. The grants
are the Android 11 subset of [Permissions](permissions.md), the last
block is Fire-specific and the reasons are further down this page.

```
adb connect <fire ip>:<port>       # the port Wireless debugging shows, or a USB cable
adb install -r kiosk-satellite.apk
```

```
adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO
adb shell pm grant me.jxl.kiosk_satellite android.permission.CAMERA
adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant me.jxl.kiosk_satellite android.permission.WRITE_EXTERNAL_STORAGE
adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow
adb shell appops set me.jxl.kiosk_satellite WRITE_SETTINGS allow
adb shell appops set me.jxl.kiosk_satellite MANAGE_EXTERNAL_STORAGE allow
adb shell appops set me.jxl.kiosk_satellite GET_USAGE_STATS allow
adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite
adb shell dpm set-active-admin me.jxl.kiosk_satellite/.KioskAdminReceiver
```

```
# The lock screen: without this, a screen turned off by the app wakes onto
# the lock screen and goes dark again seconds later (see below)
adb shell locksettings set-disabled true
adb reboot
```

Optional, the System UI guard behind Kiosk Mode's protections, the line
from [Permissions](permissions.md):

```
adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/me.jxl.kiosk_satellite.KioskAccessibilityService
adb shell settings put secure accessibility_enabled 1
```

Then finish the setup wizard on the tablet or from a browser at
`http://<fire ip>:2324`.

## The lock screen

Turning the screen off, from the Home Assistant **Screen** entity or the
screensaver's **Turn screen off after**, is Android's device-admin lock.
That call arms the lock screen on any device that has one, and a Fire
has one whether or not a passcode is set: with no passcode it is the
swipe-away screen. Every other Android lets an app clear that unsecured
lock screen when it wakes the panel, and the app does. Fire OS refuses
the request to every app but Amazon's own:

```
AmazonWindowManager: me.jxl.kiosk_satellite cannot dismissKeyguard without com.amazon.permission.ENABLE_KEYGUARD_FLAGS permission.
```

`ENABLE_KEYGUARD_FLAGS` is a signature permission no installed app can
hold, and the refusal comes with no callback. Showing over the lock
screen is refused the same way, so the re-wake behind Kiosk Mode's
**Disable power button** protection cannot get past it either.

What that looks like unattended: the screen comes on showing the lock
screen, the kiosk sits paused underneath, the screensaver stands down
because another window is in front and releases its hold on the panel,
and the lock screen's own timeout puts the panel back to sleep about
fifteen seconds later. The app log reads `the panel lit on the lock
screen; dismissing it` followed by `the lock screen refused to go`, then
`screen off (system)`, on every wake. Swiping the lock screen away by
hand lands on the kiosk and the panel then stays on, which is the tell.

Fire OS offers no way to turn the lock screen off in its Settings. Its
**Lock Screen Passcode** page sets or removes a passcode, and removing
one leaves the swipe screen. The switch Android keeps for it is reachable
over adb:

```
adb shell locksettings set-disabled true
adb reboot
```

The reboot is not optional: the lock screen reads the switch when it is
created, so setting it live reports success, `locksettings get-disabled`
answers `true` and the next screen-off still raises the lock screen until
the tablet restarts. After the reboot the kiosk keeps the screen through
the whole cycle and the screen-off still powers the panel down properly.
`locksettings set-disabled false` and a reboot bring the lock screen
back.

A Fire that never turns its panel off, one that runs a screensaver all
night instead, never meets the lock screen and needs none of this.

## What to know before provisioning

| Quirk | Effect | What to do |
| --- | --- | --- |
| The lock screen cannot be cleared by an app | A screen turned off by the app wakes onto the lock screen and sleeps again seconds later, see above | `adb shell locksettings set-disabled true` and a reboot, once |
| Wireless debugging is off after every reboot, on a new port | A setup that ends in a reboot loses adb | Use a cable, or turn Wireless debugging back on afterwards and read the new port from its page |
| Amazon's WebView has no WebRTC | Go2RTC camera streams cannot play over WebRTC | Nothing: the app falls back to MSE on its own and records the switch in the App Logs. **Prefer MSE over WebRTC** (Settings, Camera Streams, Playback) skips the failed attempt. See [Cameras](cameras.md) |
| Bluetooth scanning is gated on location | Fire OS 8 is Android 11, where a scanner without the Location permission and Location Based Services on runs and hears nothing | Grant location (the block above) and turn **Location Based Services** on in the tablet's Settings. The Nearby devices row on the Bluetooth Proxy page reads the gate. See [ESPHome](esphome.md) |
| Sticky services restart lazily | A crashed kiosk on other devices is back in about a second; Fire OS takes its time to restart the guard | Nothing: the crash self-heal has a heartbeat alarm for this. Keep the Display over other apps grant, the relaunch needs it |
| Amazon's WebView can crash the process in its audio path | A native crash in `libaaudio` under the WebView's audio playback takes the app down | Nothing to prevent it; the crash self-heal relaunches the kiosk |
| Amazon accounts cannot be removed while the tablet is registered | Device ownership, which gives silent updates and real lock task on Android 11, needs a device with no accounts, so `dpm set-device-owner` refuses a registered Fire | Each update takes one tap on Android's confirmation, which the app brings to the front and re-arms the kiosk after. See [Updates](updates.md) |
