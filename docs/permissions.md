# Permissions

This guide covers every Android permission Kiosk Satellite utilizes, what each grant is for, and the specific `adb` commands to grant them all at once.

In the app, navigating to **Settings > Device > Permissions Manager** displays this exact list with live status tracking. Each row includes a button that opens the correct Android system dialog or settings page (which can also be triggered remotely from the admin interface). That is the standard, everyday setup path.

This documentation covers the alternative approach: provisioning a wall panel from a computer. Tapping through a dozen permission screens on a touchscreen is slow; executing everything over `adb` takes seconds and requires no root access.

## Granted at Install

The following permissions are bundled directly inside the APK and require no user interaction:
* Internet access and network state monitoring
* Wi-Fi multicast (used for SendSpin server discovery)
* Wake locks and audio settings
* Boot completed listeners (used for Start on boot)
* Foreground service types (which power the [Kiosk Satellite Service](#the-kiosk-satellite-service))
* Package installation permissions (which handle in-app updates)

The only update-related permission that requires manual user intervention is **Install unknown apps**, which is covered in detail in the [Updates](updates.md#the-install-unknown-apps-grant) documentation.

## Grants That Require Setup

| Grant | Purpose |
| --- | --- |
| Microphone | Powers wake word detection and speech to text capabilities, as well as any dashboard pages requesting microphone access. |
| Camera | Powers camera motion detection, image snapshots, and dashboard pages requesting camera access. |
| Notifications | Displays the ongoing status notification for the Kiosk Satellite Service. This is a runtime prompt on Android 13 and newer; older versions allow it automatically. The background service functions fine without it, but its status notification will remain hidden. |
| Unrestricted battery | Essential for every installation (voice enabled or not). It prevents Android from killing Home Assistant and ESPHome background connections when the screen is off. |
| Display over other apps | Allows the app to pull itself back to the foreground following a crash, an update, or a wake word trigger while another app is open. It also powers the full screen Lockdown shield, allows the App Launcher's **Return automatically** feature to monitor touches in secondary apps, and serves as a fallback for **Screen on** if the hardware ignores standard wake locks. |
| Modify system settings | Allows the app to adjust the panel's actual hardware brightness rather than simply dimming the application window. |
| All files access | Grants access to the root directory in the built-in File Manager. Without it, the File Manager is restricted to the app's own internal storage folder. This applies to Android 11 and newer; older versions rely on standard storage permissions. |
| Usage access | Enables the ESPHome **Foreground app** sensor to identify whichever application is currently visible on screen. Without it, the sensor will only report Kiosk Satellite while it is in front. |
| Device admin | Enables true **Screen off** functionality, powering down the display panel rather than simply rendering a black overlay. |
| Location | Required for ESPHome [location sensors](esphome.md#gps-sensor) (off by default), dashboard pages requesting location, and Bluetooth scanning across all Android versions (as required by the OS). |
| Nearby devices | Controls the Bluetooth scan and connect operations for the [Bluetooth proxy](esphome.md). This is a runtime prompt on Android 12 and newer. On older versions, it is granted at installation, though Android still requires Location permissions and active location services to return scan results. |
| System UI guard | An optional accessibility service that forcibly closes the notification shade and recent apps screen while kiosk protections are active. See [Kiosk and Lockdown](kiosk.md#required-system-permissions). |
| Media library | Grants read access to local folders selected for the Local Media screensaver. |
| Log access | Specifically for hardware with native person sensors (such as Meta Portals). It reads system logs for the screensaver's Person Detection feature. This can only be granted via `adb` and takes effect after an app restart. See [Meta Portal](portal.md). |

## Granting Everything via ADB

You can execute the standard runtime permissions as a single block:

```
adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO
adb shell pm grant me.jxl.kiosk_satellite android.permission.CAMERA
adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION
```

Because notification and media library permissions vary by Android version, run the commands that correspond to your device version. You can safely ignore any errors from mismatched commands:

```
# Android 12 and newer (Bluetooth proxy scan/connect permissions)
adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN
adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_CONNECT

# Android 13 and newer
adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_MEDIA_IMAGES
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_MEDIA_VIDEO

# Android 12 and older
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE

# Android 10 and older (File Manager shared storage write access)
adb shell pm grant me.jxl.kiosk_satellite android.permission.WRITE_EXTERNAL_STORAGE
```

Special permissions (which Android places behind system settings pages rather than standard pop-up dialogs) can be granted with the following commands:

```
adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow
adb shell appops set me.jxl.kiosk_satellite WRITE_SETTINGS allow
adb shell appops set me.jxl.kiosk_satellite MANAGE_EXTERNAL_STORAGE allow
adb shell appops set me.jxl.kiosk_satellite GET_USAGE_STATS allow
adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite
adb shell dpm set-active-admin me.jxl.kiosk_satellite/.KioskAdminReceiver
```

For Meta Portal devices, enable **Person Detection** for the screensaver using:

```
adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_LOGS
adb shell am force-stop me.jxl.kiosk_satellite
```

Note: The `MANAGE_EXTERNAL_STORAGE` command applies to Android 11 and newer (older versions use the standard storage grants above). The `deviceidle whitelist` command applies the battery optimization exemption permanently and survives reboots.

The System UI guard operates as an accessibility service, so it is enabled by writing directly to system settings. Be aware that this command **overwrites** the existing list of enabled accessibility services. While this is usually empty on a dedicated tablet, if your device relies on existing services (such as a screen reader or Meta's built-in Portal services), you should enable the guard manually inside Android's Accessibility settings or append it to the existing list:

```
adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/me.jxl.kiosk_satellite.KioskAccessibilityService
adb shell settings put secure accessibility_enabled 1
```

After running these command blocks, check **Settings > Device > Permissions Manager** (or open the page in the remote admin). Every row should now display as Granted.

## The Kiosk Satellite Service

Android aggressively freezes cached background processes, and third-party manufacturer battery managers often kill background applications outright. When this happens, your Home Assistant session, ESPHome server, wake word detection, and remote admin interface will all crash together as soon as the screen stays dark or another app takes the foreground.

Running an active foreground service provides an explicit exemption from these OS restrictions. Because of this, Kiosk Satellite runs a persistent background service—the **Kiosk Satellite Service**—by default on every installation, regardless of which features are enabled. The ongoing notification in the status shade is the mandatory trade-off Android requires for running a foreground service, and its text actively details what the service is doing.

Active features add capabilities to what this service declares. On its own, it maintains the core Home Assistant connection. Enabling background listening attaches microphone access, enabling the camera attaches camera access, enabling the Bluetooth proxy attaches Bluetooth scanning, and enabling ESPHome or remote admin options keeps the server processes active. This service is also responsible for automatically relaunching Kiosk Satellite if it crashes or gets closed from the recent apps screen.

The service holds two system locks while the screen is off:
1. A high-performance Wi-Fi lock to maintain network connectivity (see the Android 14 note below).
2. A CPU wake lock while the display is dark, ensuring keepalive timers fire on schedule rather than waiting for OS interrupts.

The CPU wake lock is managed by a single setting: **Keep the CPU awake while the screen is off** (enabled by default). You should only disable this option on devices running strictly on battery power.

Navigating to **Settings > Device > Kiosk Satellite Service** displays live service diagnostics both on the device and in the remote admin. This page indicates whether the service is running, details its foreground exemption status, lists its active foreground service types, tracks both system locks, and displays which permissions are currently required:
* **Unrestricted battery** (always required)
* **Display over other apps** (required for relaunching after crashes)
* **Notifications** (required for the ongoing status notification)
* Microphone, Camera, or Nearby devices grants (required whenever their respective features are enabled)

If a tablet continues to get killed despite every permission showing as granted, the device is likely being terminated by a manufacturer-specific battery manager. These proprietary managers cannot be read or configured by third-party apps, making the tablet's vendor settings menu the next place to troubleshoot.

## Keeping Wi-Fi Awake on Android 14 and Newer

Whenever a feature requiring continuous network reachability is active (such as background voice listening or the ESPHome server), the app holds Android's high-performance Wi-Fi lock to prevent the network card from entering power-saving mode when the screen turns off.

Starting in Android 14, the operating system silently downgrades this lock to a "low latency" state that only remains active while the screen is **on**. On some hardware, this causes the Wi-Fi radio to enter a sleep state a few minutes after the screen goes dark. When this happens, entities temporarily report as unavailable, `adb` over Wi-Fi drops, and the device is hit with a backlog of missed network traffic upon waking.

You can restore the legacy Wi-Fi lock behavior across Android 14+ using a single `adb` command:

```
adb shell device_config put wifi high_perf_lock_deprecated false
```

Restart the app after executing this command so the Wi-Fi lock is re-acquired under the restored system rules. To verify that the fix worked, turn the screen off and run:

```
adb shell dumpsys wifi | grep "ks:screen-off"
```

The output should confirm `type=3` (high performance) rather than `type=4`.

Note: On devices equipped with Google Play services, system configuration flags are periodically synced from the cloud, meaning a background system sync may eventually revert this setting. On a dedicated wall tablet, you can permanently lock all system flags on the device by running:

```
adb shell device_config set_sync_disabled_for_tests persistent
```

Because this is a global system change, weigh the benefits against simply re-running the initial command if network sleeping symptoms ever return.

## Going Further

Running `dpm set-active-admin` grants basic device administration, which powers the native **Screen off** feature. Full **Device Ownership** represents a much deeper level of control, granting complete lock task capabilities, OS-level suppression of the notification shade and navigation bars, and silent self-updates on Android 11 and earlier.

Device ownership has strict prerequisites and is intentionally difficult to reverse, so its setup is covered in detail in the [Kiosk and Lockdown](kiosk.md#going-further-device-ownership) documentation.

Finally, keep in mind that certain hardware vendors layer aggressive, proprietary battery management software on top of standard Android. These vendor utilities cannot be queried by apps or configured via standard `adb` commands. If Kiosk Satellite continues to be killed in the background despite all permissions showing as Granted, inspect the manufacturer's custom power and battery management settings directly on the device.