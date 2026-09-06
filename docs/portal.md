# Meta Portal

This setup has been verified on a Portal Go (Android 10, `QKQ1.210213.001`). The Portal, Portal Mini, and Portal+ run the same OS family on Android 9 or 10 and are expected to behave identically, though they were not explicitly tested.

Once installed, enable the [Home Launcher](home-launcher.md). It replaces Meta's stock launcher as the device's home screen, ensuring the Portal boots directly into the kiosk. This bypasses the default launcher entirely, removing the need for a Facebook or WhatsApp account login.

## Install

The APK installs via standard `adb install`. Connect over your network using `adb connect <ip>:5555` and accept the debugging authorization prompt on the Portal's screen during the initial connection. Nothing on the Portal blocks the installation, the app itself, or its background foreground service.

## Setup in One Sitting

You can perform the complete setup required for a Portal from a computer on the same network. The grants below represent the Android 10 subset of standard [Permissions](permissions.md). The final block contains Portal-specific configurations, with detailed explanations provided further down this page.

```
adb tcpip 5555                      # Connect over USB after enabling ADB in the Portal's Settings (see table below)
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
# In-app updates: Disable Meta's package verifier to prevent installation blocks
adb shell settings put global package_verifier_enable 0
# Person Detection: Grants permission to read the Portal's built-in person sensor logs
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_LOGS
# Force stop and relaunch so the app recognizes the new permission
adb shell am force-stop me.jxl.kiosk_satellite
adb shell monkey -p me.jxl.kiosk_satellite -c android.intent.category.LAUNCHER 1
```

Optional: Enable the System UI guard behind Kiosk Mode's protections. Because a Portal already has two Meta accessibility services active, append Kiosk Satellite to the existing list rather than overwriting it:

```
adb shell settings put secure enabled_accessibility_services "com.facebook.aloha.system.device/com.facebook.aloha.system.device.accessibility.KeyEventAccessibilityService:com.facebook.alohaservices.presence/com.facebook.aloha.system.presence.touch.TouchEventAccessibilityService:me.jxl.kiosk_satellite/me.jxl.kiosk_satellite.KioskAccessibilityService"
```

Finish the setup wizard on the Portal itself or via a browser at `http://<portal ip>:2324`. The app automatically switches to the Legacy renderer on its first launch (detailed below) and requires no further configuration.

## What to Know Before Provisioning

| Quirk | Effect | What to do |
| --- | --- | --- |
| Meta's notification system drops the background service notification (`not_in_allowlist`). | The status notification for the Kiosk Satellite Service will not display. However, the background process still runs with full foreground privileges. | Nothing required. |
| Two Meta accessibility services are active by default. | Running the standard `settings put secure enabled_accessibility_services` command replaces the entire list, disabling Meta's hardware key handling and touch presence services. | Append Kiosk Satellite to the list instead of replacing it, as shown in the setup commands above. |
| Network ADB turns off after every reboot. | Meta's native **ADB enabled** switch in Portal Settings (which requires an account login to modify) automatically turns off at boot and only controls USB debugging. Network ADB initiated via `adb tcpip 5555` relies on a runtime property that requires root access to persist across reboots. | After every reboot, turn **ADB enabled** back on in Portal Settings, connect a USB cable, and run `adb tcpip 5555`. Because no app setting can force ADB to remain active through a reboot, perform all setup commands in one sitting and minimize reboots. |
| Meta's package verifier blocks app-initiated updates. | The `com.facebook.appverifier` service evaluates package updates requested by applications and rejects any APK not signed by Meta, causing in-app updates to fail with `INSTALL_FAILED_VERIFICATION_FAILURE`. Standard ADB installs bypass this check. | Disable the verifier once using `adb shell settings put global package_verifier_enable 0`. You can re-enable it later using `settings put global package_verifier_enable 1`. Note that device ownership does not bypass this restriction. |
| Running `pm clear` revokes runtime permissions. | Clearing app data via ADB resets granted permissions for the microphone, camera, location, and storage. | Re-run the permission grant commands after performing a data clear. |
| Impeller's OpenGLES backend hangs during Activity re-creation. | Flutter's default rendering engine rejects the Portal's Vulkan driver and falls back to OpenGLES, which loses context when Android destroys and re-creates the Activity. Tapping the Back button in Meta's top system bar triggers this Activity destruction. On subsequent launches, the web view displays, but Flutter elements (screensavers, drawers, and settings menus) fail to render. | Nothing required. The app automatically configures itself to use the Legacy renderer (Skia) on its initial boot on a Portal. This setting can be verified under **Settings > Device**. Leave it set to Legacy. |

Note: Before running the accessibility command, inspect your active accessibility services using `adb shell settings get secure enabled_accessibility_services` to verify if your device lists additional services beyond the two standard Meta entries.

## Updates

The in-app update process functions on a Portal as follows:

| Step | Portal Behavior |
| --- | --- |
| Download | Downloads normally. |
| Install unknown apps permission | Prompts once on Android's system screen during the initial update. |
| Android install confirmation | Requires a tap unless the optional update helper is running. |
| Installation | Fails with `INSTALL_FAILED_VERIFICATION_FAILURE` unless Meta's package verifier is disabled (see table above). |
| Relaunch | The app automatically relaunches once the installation completes. |

To allow in-app updates to proceed, execute this command once from a computer:

```
adb shell settings put global package_verifier_enable 0
```

For updates without a confirmation tap, start the bundled helper:

```sh
adb shell "content read --uri content://me.jxl.kiosk_satellite.update-helper/start | sh"
```

The helper runs on the Portal and survives app restarts and self-updates. It stops at reboot, so restore ADB access and rerun the command afterward. When it is unavailable, the app brings Android's confirmation screen forward and re-arms kiosk protections when the attempt ends. See [Optional Update Helper](updates.md#optional-update-helper) for status, setup instructions and installation behavior.

Device ownership remains unavailable because the Portal carries Meta system accounts (`com.facebook.aloha.*`) that prevent provisioning. The helper does not require device ownership or accessibility access.

## Person Detection

Portal OS runs a continuous background person detection service. This powers the Smart Camera's auto-framing feature, utilizing a virtual camera feed that does not illuminate the hardware camera LED. It logs a heartbeat every 30 seconds when someone is in view and goes silent when the room is empty. The sensor detects bodies at any angle rather than strictly facing forward, meaning a person sitting with their back to the device still registers. 

Kiosk Satellite exposes this hardware feature under **Settings > Screensaver > Person Detection** (a menu exclusive to Portal devices):

* **Dismiss on person**: Reads the sensor while the screensaver is active and wakes the display when a person is detected.
* **Postpone screensaver on person**: Monitors the sensor between screensaver sessions, continuously resetting the idle timer while someone remains in front of the device. This setting requires Dismiss on person to be enabled.

Dismiss activates when a person arrives. If Postpone is disabled, a screensaver that activates while someone is already present will remain active until that person leaves and approaches again.

Person detection operates independently of camera-based Motion Detection and Face Detection, allowing both systems to run simultaneously.

| Feature | Person Detection | Face Detection |
| --- | --- | --- |
| Operation | Reads Portal system logs without running internal models. | Runs the app's internal face detection model on camera frames during screensavers. |
| Camera LED | Never illuminates. | Illuminates while the camera is active. |
| Requirements | `READ_LOGS` permission grant. | Camera enabled in settings and camera permission granted. |
| Detection Scope | Detects any person present in the room at any angle. | Detects faces oriented toward the screen within the defined Face Sensitivity range. |
| Response Time | Arrival: 1 to 2 seconds via tracking lines, or up to 30 seconds on the next log heartbeat. Departure: ~3 seconds after tracking stops, or up to 50 seconds worst-case. | Under 1 second. |
| Low Light | Accuracy degrades in low ambient light. | Fails completely in the dark. |

Person detection represents an ongoing state rather than a single event. While a person remains in view, **Postpone screensaver on person** holds the idle clock continuously, preventing the screensaver from triggering between heartbeats regardless of your idle timeout settings. Under [Lockdown Mode](kiosk.md), person detection will neither dismiss nor postpone the screensaver.

The **Occupancy** indicator beneath the Dismiss on person setting displays real-time status (Detected or Clear) along with the timestamp of the last heartbeat, both on the device and within the remote admin interface. If the required permission is missing, an error notice displays and presence events will not wake the display.

When Dismiss on person is enabled, the [ESPHome](esphome.md) integration exposes a **Person** binary occupancy sensor, allowing Home Assistant automations to utilize the Portal's built-in detector directly. Toggling this switch re-registers the ESPHome device.

### The Log Access Grant

Reading the Portal's presence logs requires the `READ_LOGS` permission. Android strictly requires this permission to be granted via ADB to a process launched after the grant is applied:

```
adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO
adb shell am force-stop me.jxl.kiosk_satellite
adb shell monkey -p me.jxl.kiosk_satellite -c android.intent.category.LAUNCHER 1
```

The **Required system permissions** section at the bottom of the Person Detection settings page displays the status of this grant. If missing, it indicates that ADB is required and displays the exact command. Once granted, a Restart button appears to relaunch the app. This permission has no effect on non-Portal devices, and the app does not read system logs unless Dismiss on person is toggled on.

### System Limitations

Meta's presence data also exists within a system content provider and system broadcasts. However, both interfaces are protected by `signature|privileged` permissions (`com.facebook.aloha.permission.ACCESS_STATESDB` and `RECEIVE_PRESENCE_TRANSITION`) that sideloaded applications cannot obtain. System log parsing remains the only functional integration path.

### Troubleshooting Clear Status

If person detection remains stuck on Clear:

* **Permission not active in running process**: If `READ_LOGS` was granted while the app was running, force stop and restart the application using the button in settings or ADB.
* **Disabled presence service**: If Meta's internal presence services (`com.facebook.alohaservices.presence` or `com.facebook.portal.aiservice`) have been disabled, the Person Detection configuration page will be hidden entirely.
* **Verify system log output**: Run the following command to verify if the Portal is generating presence logs:

```
adb shell logcat -v epoch -s PresenceManager:I aloha.CameraServiceController:I aloha.TrackAndHoldAiDirectorDefaultNudgeMovement:I
```

When a person is in front of the device, logcat should output `Notify people presence` and `onNotifyPresence presence updated` every 30 seconds, alongside `Forcing fast track movement` and `boundaryViolatedPct` lines as the camera tracks movement. When the room is empty, `Forcing brake movement` logs display once per second to signal departure. Kiosk Satellite logs these matched entries under the `portal` log tag when presence begins and every five minutes thereafter.
