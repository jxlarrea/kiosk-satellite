# Permissions

Every Android grant Kiosk Satellite can use, what each one is for, and the
adb commands that grant the lot in one sitting.

In the app, **Settings, Device, Permissions Manager** shows the same list
with live status, and every row has a button that opens the right Android
dialog or settings screen, including from the remote admin. That is the
normal path. This page is for the other way around: a wall panel being
provisioned from a computer, where tapping through ten Android screens on
the device is the slow part. Everything here works over plain `adb`, no
root required.

## Granted at install

These come with the APK and never ask: internet and network state, Wi-Fi
multicast (SendSpin server discovery), wake lock, audio settings, boot
completed (Start on boot), the foreground service pair behind background
listening, and the install permissions behind in-app updates. Nothing to
do.

## The grants that need a human

| Grant | What it is for |
| --- | --- |
| Microphone | Wake word detection and speech to text, plus any dashboard page that asks for the microphone. |
| Camera | Motion detection, camera snapshots, and pages that ask for the camera. |
| Notifications | The ongoing notification that keeps background listening alive. Only a runtime prompt on Android 13+; older versions allow it by default. |
| Unrestricted battery | Keeps the Home Assistant and MQTT connections alive with the screen off. Matters on every install, voice or not. |
| Display over other apps | Lets the app bring itself back to the front after a crash, an update, or a wake word heard behind another app, lets the lockdown shield cover the whole screen, and is what **Screen on** falls back on where the panel ignores the app's wake lock. |
| Modify system settings | Writing the panel's real brightness instead of dimming the app window. |
| All files access | The File Manager's shared storage root. Without it the manager still works on the app's own folder. Android 11+; on older versions the storage permission below is the whole grant. |
| Usage access | Lets the MQTT **Foreground app** sensor name whichever app is on screen. Without it the sensor still reports Kiosk Satellite while the kiosk is frontmost, just never another app. |
| Device admin | The real **Screen off**: powers the panel down instead of only blacking it out. |
| Location | Only used by dashboard pages that ask for the device location. Nothing native uses it, except BLE scanning on Android 11 and older, where the OS requires it (see Nearby devices). |
| Nearby devices | The Bluetooth scan and connect pair behind the [Bluetooth proxy](bluetooth-proxy.md). A runtime prompt on Android 12+; granted at install before that, where Android instead requires Location plus location services on for scan results. |
| System UI guard | An accessibility service that closes the notification shade and recents while kiosk protections hold. See [Kiosk and Lockdown](kiosk.md#required-system-permissions). |
| Media library | Reading the folder the Local Media screensaver was pointed at. |

## Granting everything from adb

The runtime permissions, as one block:

```
adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO
adb shell pm grant me.jxl.kiosk_satellite android.permission.CAMERA
adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION
```

Notifications and the media library are Android-version dependent; run the
lines that match the device and let the others fail (a failed `pm grant`
changes nothing):

```
# Android 12 and later: the Bluetooth proxy's scan/connect pair
adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN
adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_CONNECT

# Android 13 and later
adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_MEDIA_IMAGES
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_MEDIA_VIDEO

# Android 12 and earlier
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE

# Android 10 and earlier: writing in the File Manager's shared root
adb shell pm grant me.jxl.kiosk_satellite android.permission.WRITE_EXTERNAL_STORAGE
```

The special grants, the ones Android puts behind a settings screen instead
of a dialog:

```
adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow
adb shell appops set me.jxl.kiosk_satellite WRITE_SETTINGS allow
adb shell appops set me.jxl.kiosk_satellite MANAGE_EXTERNAL_STORAGE allow
adb shell appops set me.jxl.kiosk_satellite GET_USAGE_STATS allow
adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite
adb shell dpm set-active-admin me.jxl.kiosk_satellite/.KioskAdminReceiver
```

The `MANAGE_EXTERNAL_STORAGE` line is Android 11+ (All files access does
not exist before that; the storage grant above covers older versions).
The `deviceidle whitelist` line is the battery optimization exemption and
survives reboots.

The System UI guard is an accessibility service, so it is enabled with a
settings write rather than a grant. Note that this **replaces** the list of
enabled accessibility services, which is usually empty on a dedicated
panel; if the device uses others (a screen reader, for example), enable
the guard from Android's Accessibility settings instead:

```
adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/me.jxl.kiosk_satellite.KioskAccessibilityService
adb shell settings put secure accessibility_enabled 1
```

After the block runs, open **Settings, Device, Permissions Manager** (or
the same page in the remote admin): every row should read Granted.

## Going further

`dpm set-active-admin` above gives exactly one thing, the device admin
grant behind **Screen off**. Device *ownership* is the bigger tier: full
lock task, the OS keeping the shade and navigation dead, and silent
self-updates on Android 11 and earlier. It has real preconditions and is
deliberately hard to undo, so it lives in its own section of
[Kiosk and Lockdown](kiosk.md#going-further-device-ownership).

Some manufacturers layer their own battery or autostart manager on top of
Android's, which no app can read and no adb command reaches. If the app
keeps being killed with every row granted, look for the vendor's own
battery settings next.
