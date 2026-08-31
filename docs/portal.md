# Meta Portal

Verified on a Portal Go (Android 10, `QKQ1.210213.001`). Portal, Portal
Mini and Portal+ run the same OS family on Android 9 or 10 and should
behave the same, but were not tested.

Once installed, turn on the [Home Launcher](home-launcher.md): it replaces
Meta's launcher as the device's home screen, so the Portal boots straight
into the kiosk and the stock launcher, which wants a Facebook or WhatsApp
login, drops out of the picture entirely.

## Install

The APK installs over plain `adb install` like anywhere else. Connect over
the network (`adb connect <ip>:5555`) and accept the debugging prompt on
the Portal's screen the first time. Nothing on the Portal blocks the
install, the app or its foreground service.

## Setup in one sitting

Everything a Portal needs, from a computer on the same network. The
grants are the Android 10 subset of [Permissions](permissions.md), the
last block is Portal-specific and the reasons are further down this page.

```
adb tcpip 5555                      # over USB, after enabling ADB in the Portal's Settings (see the table below)
adb connect <portal ip>:5555
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
adb shell appops set me.jxl.kiosk_satellite GET_USAGE_STATS allow
adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite
adb shell dpm set-active-admin me.jxl.kiosk_satellite/.KioskAdminReceiver
```

```
# In-app updates: Meta's package verifier would reject them
adb shell settings put global package_verifier_enable 0
# Person Detection: reading the Portal's own person sensor
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_LOGS
# The grant reaches the app at its next start
adb shell am force-stop me.jxl.kiosk_satellite
adb shell monkey -p me.jxl.kiosk_satellite -c android.intent.category.LAUNCHER 1
```

Optional, the System UI guard behind Kiosk Mode's protections. A Portal
already has two Meta accessibility services enabled, so append rather
than run the line from the Permissions doc:

```
adb shell settings put secure enabled_accessibility_services "com.facebook.aloha.system.device/com.facebook.aloha.system.device.accessibility.KeyEventAccessibilityService:com.facebook.alohaservices.presence/com.facebook.aloha.system.presence.touch.TouchEventAccessibilityService:me.jxl.kiosk_satellite/me.jxl.kiosk_satellite.KioskAccessibilityService"
```

Then finish the setup wizard on the Portal or from a browser at
`http://<portal ip>:2324`. The app switches itself to the Legacy renderer
on its first start, see below, and needs nothing else.

## What to know before provisioning

| Quirk | Effect | What to do |
| --- | --- | --- |
| Meta's notification layer drops the service notification (`not_in_allowlist`) | The Kiosk Satellite Service's notification never shows. The service still runs as a foreground service, so nothing is lost | Nothing |
| Two Meta accessibility services are already enabled | The `settings put secure enabled_accessibility_services` line in [Permissions](permissions.md) replaces the list, which would disable Meta's key handling and the presence touch service | Append instead of replacing, the line in the setup block above does |
| adb is off after every reboot, USB included | Meta's own **ADB enabled** switch (Portal Settings, needs the account login to change) is turned back off at boot. It only ever enables USB debugging. Network adb comes from `adb tcpip 5555` over a cable and lives in a runtime property that Android only restores from `persist.adb.tcp.port`, which nothing short of root can write on a Portal | After every reboot: turn **ADB enabled** on again in the Portal's Settings, plug in a cable, run `adb tcpip 5555`. Nothing on the device or in the app can keep adb on across a reboot, so do the setup below in one sitting and keep reboots rare |
| Meta's package verifier rejects every app-initiated install | `com.facebook.appverifier` answers Android's package verification for installs an app starts and refuses any APK not signed by Meta, so the in-app updater ends in `INSTALL_FAILED_VERIFICATION_FAILURE` after the Install tap. The app logs the verifier's refusal. adb installs are exempt | Turn the verifier off once: `adb shell settings put global package_verifier_enable 0`. Reversible with `settings put global package_verifier_enable 1`. Device ownership does not get around it, the verifier runs for owner installs too |
| `pm clear` revokes the runtime grants | A data reset from adb also resets microphone, camera, location and storage | Run the grant block again after a clear |
| Impeller's OpenGLES backend wedges on Activity re-creation | Flutter's default renderer rejects the Portal's Vulkan driver and falls back to OpenGLES, which loses its context when Android destroys and re-creates the app's Activity. On a Portal the Back button in Meta's own bar at the top of the screen does exactly that: it closes the app, and the next tap on the tile re-creates it. From then on the dashboard WebView still shows but nothing Flutter draws does: no screensaver, no drawer, no settings | Nothing: the app switches itself to the Legacy renderer (Skia) on a Portal the first time it starts, and shows that under **Settings, Device**. Leave it on |

Read the current accessibility list first with `adb shell settings get
secure enabled_accessibility_services` in case your Portal lists something
else than the two services in the setup block above.

## Updates

What the in-app updater does on a Portal, in order:

| Step | On a Portal |
| --- | --- |
| Download | Works as anywhere |
| Install unknown apps grant | Asked once, the first time, on Android's own screen |
| Android's install confirmation | Shown on every update: Android 10 never installs silently for an app that is not the device owner |
| The install itself | Fails with `INSTALL_FAILED_VERIFICATION_FAILURE` until Meta's package verifier is turned off, see the table above |
| Relaunch | The app comes back on its own once the install goes through |

So a Portal needs this once, from a computer:

```
adb shell settings put global package_verifier_enable 0
```

There is no hands-free path. Device ownership, which gives silent updates
on Android 11 and older elsewhere, needs a device with no accounts, and a
Portal carries Meta's own (`com.facebook.aloha.*`) that cannot be removed,
so `dpm set-device-owner` refuses. Each update takes one tap on the
confirmation, which the app brings to the front and re-arms the kiosk
after.

## Person detection

Portal OS runs a person detector all the time. It is what the Smart
Camera's auto-framing uses to follow people around the room, it reads a
virtual camera feed that never lights the camera LED and it logs a
heartbeat every 30 seconds while someone is in view, going silent when
the room empties. It detects people, bodies at any angle, not faces:
someone reading at the kiosk with their back to it counts. Kiosk
Satellite reads that sensor as **Settings, Screensaver, Person
Detection**, a page that only exists on a Portal:

- **Dismiss on person**: read the sensor while the screensaver is up and
  wake the screen when someone is in front of the Portal.
- **Postpone screensaver on person**: also read it between screensavers,
  so someone in front of the Portal keeps resetting the idle timer. It
  requires Dismiss on person.

Dismiss acts on someone arriving. With Postpone off, a screensaver that
starts while someone is already there stays up until they leave and come
back.

Both are independent of the camera legs: Motion Detection and Face
Detection keep working exactly as they do elsewhere and can run at the
same time.

| | Person Detection | Face Detection |
| --- | --- | --- |
| What runs | Nothing of the app's: it reads the Portal's log | The app's own face model on the camera, during the screensaver |
| Camera light | Never | On while the camera runs |
| Needs | The Log access grant | Camera enabled, camera grant |
| Detects | Anyone the Portal counts as present, any angle | A face turned toward the screen, within the distance Face sensitivity sets |
| Latency | Arrival: a second or two, from the framing director's tracking lines, otherwise the next heartbeat, up to 30 seconds. Absence: about three seconds once the director reports nobody to follow, 50 seconds without any signal at worst | Under a second |
| In the dark | Meta's detector weakens in low light | Fails |

Presence is a state rather than a sighting: while someone is in view,
Postpone screensaver on person holds the idle clock continuously, so the
screensaver does not start between heartbeats whatever the idle timeout.
Under [Lockdown Mode](kiosk.md) the sensor neither dismisses nor
postpones, like motion.

The **Occupancy** row under Dismiss on person shows what the sensor reports
(Detected or Clear) and the age of the last heartbeat, on the device and
in the remote admin alike. With the grant missing it says so and nothing
wakes the screen.

With Dismiss on person on, the [ESPHome](esphome.md) device also carries
a **Person** occupancy binary sensor with the same state, so Home
Assistant automations get the Portal's detector as a plain occupancy
entity. Turning the switch on or off re-registers the ESPHome device.

### The Log access grant

Reading another app's log lines needs `READ_LOGS`, which Android grants
only over adb and only to a process started after the grant:

```
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_LOGS
adb shell am force-stop me.jxl.kiosk_satellite
adb shell monkey -p me.jxl.kiosk_satellite -c android.intent.category.LAUNCHER 1
```

The **Required system permissions** group at the foot of the Person
Detection page shows the row. While the grant is missing it says that
only adb can grant it and points here for the command (the remote admin
also offers the command with a copy box). Once granted but before the
restart it offers a Restart button. The permission does nothing on
any other device and the app never reads the log unless Dismiss on person
is on.

### What the app cannot do

Meta's presence state also lives in a content provider and goes out as
broadcasts, but both sit behind `signature|privileged` permissions
(`com.facebook.aloha.permission.ACCESS_STATESDB`,
`RECEIVE_PRESENCE_TRANSITION`) that no sideloaded app can hold. The log
is the only door.

### If it stays at Clear

- The grant is in the package manager but not in the process: restart the
  app, the row says so.
- Meta's presence stack is disabled on the Portal
  (`com.facebook.alohaservices.presence`, `com.facebook.portal.aiservice`):
  the page is hidden.
- Check what the Portal writes: `adb shell logcat -v epoch -s
  PresenceManager:I aloha.CameraServiceController:I
  aloha.TrackAndHoldAiDirectorDefaultNudgeMovement:I` should print `Notify
  people presence` and `onNotifyPresence presence updated` every 30 seconds
  while someone stands in front of it plus `Forcing fast track movement`
  and `boundaryViolatedPct` lines while it follows them. With the room
  empty only `Forcing brake movement` lines appear, once a second, which
  is what tells the app the person left. The app logs each
  matched line when presence begins and every five minutes after, under
  the `portal` tag.
