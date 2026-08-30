# Meta Portal

Verified on a Portal Go (Android 10, `QKQ1.210213.001`). Portal, Portal
Mini and Portal+ run the same OS family on Android 9 or 10 and should
behave the same, but were not tested.

## Install

The APK installs over plain `adb install` like anywhere else. Connect over
the network (`adb connect <ip>:5555`) and accept the debugging prompt on
the Portal's screen the first time. Nothing on the Portal blocks the
install, the app or its foreground service.

## What to know before provisioning

| Quirk | Effect | What to do |
| --- | --- | --- |
| Meta's notification layer drops the service notification (`not_in_allowlist`) | The Kiosk Satellite Service's notification never shows. The service still runs as a foreground service, so nothing is lost | Nothing |
| Two Meta accessibility services are already enabled | The `settings put secure enabled_accessibility_services` line in [Permissions](permissions.md) replaces the list, which would disable Meta's key handling and the presence touch service | Append instead of replacing, see the block below |
| Meta's package verifier rejects every app-initiated install | `com.facebook.appverifier` answers Android's package verification for installs an app starts and refuses any APK not signed by Meta, so the in-app updater ends in `INSTALL_FAILED_VERIFICATION_FAILURE` after the Install tap. The app logs the verifier's refusal. adb installs are exempt | Turn the verifier off once: `adb shell settings put global package_verifier_enable 0`. Reversible with `settings put global package_verifier_enable 1`. Device ownership does not get around it, the verifier runs for owner installs too |
| `pm clear` revokes the runtime grants | A data reset from adb also resets microphone, camera, location and storage | Run the grant block again after a clear |
| Impeller's OpenGLES backend wedges on Activity re-creation | Flutter's default renderer rejects the Portal's Vulkan driver and falls back to OpenGLES, which loses its context when Android destroys and re-creates the app's Activity. On a Portal the Back button in Meta's own bar at the top of the screen does exactly that: it closes the app, and the next tap on the tile re-creates it. From then on the dashboard WebView still shows but nothing Flutter draws does: no screensaver, no drawer, no settings | Nothing: the app switches itself to the Legacy renderer (Skia) on a Portal the first time it starts, and shows that under **Settings, Device**. Leave it on |

Appending the System UI guard to the accessibility list, in one line:

```
adb shell settings put secure enabled_accessibility_services "com.facebook.aloha.system.device/com.facebook.aloha.system.device.accessibility.KeyEventAccessibilityService:com.facebook.alohaservices.presence/com.facebook.aloha.system.presence.touch.TouchEventAccessibilityService:me.jxl.kiosk_satellite/me.jxl.kiosk_satellite.KioskAccessibilityService"
```

Read the current value first with `adb shell settings get secure
enabled_accessibility_services` in case your Portal lists something else.

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

Both are independent of the camera legs: Motion Detection and Face
Detection keep working exactly as they do elsewhere and can run at the
same time.

| | Person Detection | Face Detection |
| --- | --- | --- |
| What runs | Nothing of the app's: it reads the Portal's log | The app's own face model on the camera, during the screensaver |
| Camera light | Never | On while the camera runs |
| Needs | The Log access grant | Camera enabled, camera grant |
| Detects | Anyone the Portal counts as present, any angle | A face turned toward the screen, within the distance Face sensitivity sets |
| Latency | A few seconds when the person moves (the framing director logs every move it tracks), otherwise the next heartbeat, up to 30 seconds. Absence takes 50 seconds without either | Under a second |
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
  while someone stands in front of it plus `boundaryViolatedPct` lines
  whenever they move. With the room empty only `Forcing brake movement`
  lines appear, once a second, which the app ignores. The app logs each
  matched line when presence begins and every five minutes after, under
  the `portal` tag.
