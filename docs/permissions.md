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
completed (Start on boot), the foreground service types behind the
[Kiosk Satellite Service](#the-kiosk-satellite-service), and the install
permissions behind in-app updates. Nothing to do. The one update-related
grant that does need a human, **Install unknown apps**, is covered in
[Updates](updates.md#the-install-unknown-apps-grant).

## The grants that need a human

| Grant | What it is for |
| --- | --- |
| Microphone | Wake word detection and speech to text, plus any dashboard page that asks for the microphone. |
| Camera | Motion detection, camera snapshots, and pages that ask for the camera. |
| Notifications | The Kiosk Satellite Service's ongoing notification. Only a runtime prompt on Android 13+; older versions allow it by default. The service runs without it; its notification just is not shown. |
| Unrestricted battery | Keeps the Home Assistant and ESPHome connections alive with the screen off. Matters on every install, voice or not. |
| Display over other apps | Lets the app bring itself back to the front after a crash, an update, or a wake word heard behind another app, lets the lockdown shield cover the whole screen, lets the App Launcher's **Return automatically** see touches in the other app so it only returns from an idle one, and is what **Screen on** falls back on where the panel ignores the app's wake lock. |
| Modify system settings | Writing the panel's real brightness instead of dimming the app window. |
| All files access | The File Manager's shared storage root. Without it the manager still works on the app's own folder. Android 11+; on older versions the storage permission below is the whole grant. |
| Usage access | Lets the ESPHome **Foreground app** sensor name whichever app is on screen. Without it the sensor still reports Kiosk Satellite while the kiosk is frontmost, just never another app. |
| Device admin | The real **Screen off**: powers the panel down instead of only blacking it out. |
| Location | The ESPHome [location sensors](esphome.md#gps-sensor) (off by default), dashboard pages that ask for the device location, and BLE scanning, where the OS requires it on every version (see Nearby devices). |
| Nearby devices | The Bluetooth scan and connect pair behind the [Bluetooth proxy](esphome.md). A runtime prompt on Android 12+; granted at install before that, where Android instead requires Location plus location services on for scan results. |
| System UI guard | An accessibility service that closes the notification shade and recents while kiosk protections hold. See [Kiosk and Lockdown](kiosk.md#required-system-permissions). |
| Media library | Reading the folder the Local Media screensaver was pointed at. |
| Log access | Devices with a person sensor of their own (today the Meta Portal): reading it for the screensaver's Person Detection. adb only and only in effect after the app restarts. See [Meta Portal](portal.md). |

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

On a Meta Portal, the grant behind the screensaver's **Person Detection**,
which reaches the app at its next start:

```
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_LOGS
adb shell am force-stop me.jxl.kiosk_satellite
```

The `MANAGE_EXTERNAL_STORAGE` line is Android 11+ (All files access does
not exist before that; the storage grant above covers older versions).
The `deviceidle whitelist` line is the battery optimization exemption and
survives reboots.

The System UI guard is an accessibility service, so it is enabled with a
settings write rather than a grant. Note that this **replaces** the list of
enabled accessibility services, which is usually empty on a dedicated
panel; if the device uses others (a screen reader, for example, or the two
Meta services a [Portal](portal.md) ships with), enable the guard from
Android's Accessibility settings instead, or append to the list:

```
adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/me.jxl.kiosk_satellite.KioskAccessibilityService
adb shell settings put secure accessibility_enabled 1
```

After the block runs, open **Settings, Device, Permissions Manager** (or
the same page in the remote admin): every row should read Granted.

## The Kiosk Satellite Service

Android freezes a cached process whole, and the battery managers some
manufacturers add kill a backgrounded app outright. Either way the Home
Assistant session, the ESPHome server, the wake word engine and the
remote admin all stop together the moment the screen has been off for a
while or another app is in front. A running foreground service is the
exemption from both, so the app runs one, the **Kiosk Satellite Service**,
from its first start and on every install, whatever features are on. Its
notification in the shade is the price Android asks for that, and its text
says what the service is doing.

The features only add to what it declares. On its own it keeps the Home
Assistant connection; background listening adds the microphone, an enabled
camera adds the camera, the Bluetooth proxy adds Bluetooth scanning, and
the ESPHome server, remote administration and the kiosk protections are
listed so the page below says why the process is being held up. The
service is also what relaunches the kiosk after a crash or a close from
the recents screen.

It holds two locks through screen-off: the high-performance Wi-Fi lock
(see the Android 14 note below) for as long as it runs, and a CPU wake
lock while the panel is dark, so the timers behind the keepalives fire on
time instead of waiting for the next interrupt. The wake lock is the
service's one setting, **Keep the CPU awake while the screen is off**, on
by default; turn it off on a device that runs on battery.

**Settings, Device, Kiosk Satellite Service** shows the service on the
device and in the remote admin alike: whether it is running and holds its
foreground exemption, the foreground service types it declares, the two
locks, the notification, what it is keeping the process alive for, and
the grants that matter for that: **Unrestricted battery** always,
**Display over other apps** for the relaunch after a crash,
**Notifications** for the notification itself, and the microphone, camera
or Nearby devices grant while the feature that needs it is on. A kiosk
that still gets killed with every row granted is being killed by a
manufacturer's own battery manager, which no app can read or request;
that is the next place to look.

## Keeping Wi-Fi awake through screen off on Android 14+

Whenever anything that must stay reachable is running (background
listening, the ESPHome server), the app holds Android's
high-performance Wi-Fi lock, which keeps the radio out of power saving
while the screen is off. From Android 14 the OS silently downgrades that
lock to a "low latency" type that is only in effect while the screen is
**on**, so on some devices the Wi-Fi radio starts napping minutes into a
dark spell: entities flap unavailable for a moment, adb over Wi-Fi drops,
and a wall of missed traffic greets the next wake. A one-time shell
command restores the old behavior:

```
adb shell device_config put wifi high_perf_lock_deprecated false
```

Restart the app afterwards so the lock is re-acquired under the restored
rules. To verify, turn the screen off and run
`adb shell dumpsys wifi | grep "ks:screen-off"`: the lock should show
`type=3` (high performance) rather than `type=4`.

One caveat: on devices with Google Play services this flag is one of the
remotely synced ones, so a background sync can quietly flip it back. If
the kiosk is a dedicated panel, `adb shell device_config
set_sync_disabled_for_tests persistent` pins every flag on the device,
this one included; that is a blunt instrument, so weigh it against simply
re-running the command if the symptom returns.

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
