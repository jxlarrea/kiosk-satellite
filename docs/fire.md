# Amazon Fire Tablets

This setup has been verified on a Fire HD 10 (`KFTUWI`, Fire OS 8, Android 11) and, for the lock screen functionality, on a Fire HD 8 (`KFONWI`, Fire OS 7, Android 9). Note that Fire OS 5 tablets (Android 5.1) fall below the app's Android 7 minimum requirement; if you attempt an `adb install` on one, it will refuse the action with an `INSTALL_FAILED_OLDER_SDK` error.

## Install

Install the APK using `adb install` just like any other sideloaded app. Once installed, the app's built-in updater handles future updates.

You can find ADB settings under **Settings > Device Options > Developer Options** (this menu appears after tapping your device's serial number seven times). Fire OS 8 also includes a **Wireless debugging** feature. However, it assigns a new port on every reboot and turns itself off after a single use, so anything requiring a reboot is much easier to handle using a physical USB cable.

## Setup in One Sitting

You can perform the entire setup a Fire tablet requires from a computer on the same network. The following grants represent the Android 11 subset of the standard [Permissions](permissions.md). The final block is specific to Fire OS, and the reasons for it are explained further down this page.

```
adb connect <fire ip>:<port>       # Use the port shown in Wireless debugging, or connect via USB cable
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
# Fire OS 8 only. This addresses the lock screen: without it, a screen turned off by the app wakes onto the lock screen and goes dark again seconds later (see details below)
adb shell locksettings set-disabled true
adb reboot
```

Optional: To enable the System UI guard behind Kiosk Mode's protections (as detailed in [Permissions](permissions.md)), run this:

```
adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/me.jxl.kiosk_satellite.KioskAccessibilityService
adb shell settings put secure accessibility_enabled 1
```

Finally, finish the setup wizard directly on the device or from a browser using `http://<fire ip>:2324`.

## The Lock Screen

Turning the screen off (whether triggered by the Home Assistant **Screen** entity or the screensaver's **Turn screen off after** setting) utilizes Android's device admin lock. This call automatically arms the lock screen on any device that has one. A Fire tablet has one regardless of whether a passcode is set; if no passcode exists, it simply acts as a swipe away screen. 

Standard Android allows an app to clear an unsecured lock screen when it wakes the panel, and Kiosk Satellite attempts to do so. On Fire OS 7, this works perfectly: the wake command lands cleanly on the kiosk with the lock screen gone, and the rest of this section does not apply to you. 

However, Fire OS 8 strictly refuses this request from any app other than Amazon's own software, generating this internal error:

```
AmazonWindowManager: me.jxl.kiosk_satellite cannot dismissKeyguard without com.amazon.permission.ENABLE_KEYGUARD_FLAGS permission.
```

The `ENABLE_KEYGUARD_FLAGS` permission is a signature level permission that no installed app can hold, and the system issues the refusal without a callback. Displaying content *over* the lock screen is blocked in the exact same manner, meaning the re wake function built into Kiosk Mode's **Disable power button** protection cannot bypass it either.

Here is what that looks like if left unattended: the screen turns on displaying the lock screen, the kiosk remains paused underneath, the screensaver stands down because another window has taken the foreground, and the lock screen's native timeout forces the panel back to sleep about fifteen seconds later. You will see this sequence in the app log: `the panel lit on the lock screen; dismissing it`, followed by `the lock screen refused to go`, and finally `screen off (system)` on every wake attempt. If you swipe the lock screen away manually, the device lands on the kiosk and the panel stays on.

Fire OS completely removes the option to turn the lock screen off within its UI Settings. Its **Lock Screen Passcode** page only allows you to set or remove a passcode, and removing one just leaves you with the swipe screen. However, the system switch Android uses for this is still reachable via ADB:

```
adb shell locksettings set-disabled true
adb reboot
```

Running the switch command alone changes nothing immediately. The lock screen reads that status when it is first created, so while running the command reports success and `locksettings get-disabled` returns `true`, the very next screen off will still raise the lock screen. You must reboot the device to recreate the lock screen. 

Alternatively, you can restart the System UI service, which keeps ADB alive on a wall mounted device, provided the screen is currently on and unlocked (if you restart it while the lock screen is visible, it comes back showing and the switch appears to fail). This has been verified on both Fire OS 7 and 8:

```
adb shell locksettings set-disabled true
adb shell am force-stop com.android.systemui
```

Give the System UI a few seconds to initialize before triggering the next screen off. After using either route, the kiosk will maintain control of the screen through the entire cycle, and a screen off command will still power the panel down properly. If you ever need it back, running `locksettings set-disabled false` followed by the same restart will restore the lock screen.

Note: A Fire tablet that never turns its panel completely off (for example, one that runs a screensaver all night instead) never encounters the lock screen and requires none of these steps.

## The Microphone After a Reboot

On Fire OS 8, a sideloaded app retains its microphone permission only until the device reboots, losing it completely on the way back up. The app will ask for it again the very next time it attempts to open the microphone. This means the standard Android permission prompt will reappear exactly once after each reboot (triggered by a wake word, a page calling `getUserMedia`, or a gesture that listens). Tapping "Allow" resolves it completely. Simply restarting the app itself never triggers this; only a full system reboot does.

This happens because Fire OS runs a boot time service called `AudioRecordPermissionEnforcer` (located in `/system/framework/fosservices.jar`). This service walks through every installed app on boot and forcibly revokes `android.permission.RECORD_AUDIO` from any app it does not trust. Its internal allowlist only passes an app if it is a system app, or if it was installed through an Amazon source (the Appstore, `com.amazon.venezia`) *and* Amazon's own remote config (delivered over Arcus) explicitly names it. Because a sideloaded APK meets neither criteria, its microphone grant is aggressively stripped at every boot. `RECORD_AUDIO` is the only permission singled out this way; camera and location grants survive the reboot completely untouched.

There is currently no way to stop this behavior. Spoofing the installer package to `com.amazon.venezia` does not work because the Arcus allowlist handles the second half of the test, and there is no method to insert an app onto that list. If a device could be provisioned as a device owner, the grant would be set through a persistent policy and outlast the enforcer, but no Fire tablet can be provisioned that way (see the final row in the table below). A Fire tablet that never reboots never encounters the enforcer, and one that does simply requires you to tap "Allow" once on the next microphone request.

## What to Know Before Provisioning

| Quirk | Effect | What to do |
| --- | --- | --- |
| Fire OS 8 blocks apps from clearing the lock screen | A screen turned off by the app wakes onto the lock screen and goes to sleep again seconds later (see above). Fire OS 7 is not affected by this. | Run `adb shell locksettings set-disabled true` and either reboot or restart the System UI once. |
| Fire OS revokes the microphone from sideloaded apps at every boot | The microphone permission holds perfectly until the device reboots. A boot time enforcer strips `RECORD_AUDIO` from any app not installed through Amazon, forcing the app to ask again on the next mic open (see above). Camera and location permissions are completely untouched. | Simply tap "Allow" on the prompt when it reappears after a reboot. There is no way to pre empt this. |
| Wireless debugging disables itself after every reboot, generating a new port | A setup process that ends in a reboot will instantly sever your ADB connection. | Use a physical cable, or turn Wireless debugging back on manually afterward and read the new port from the device's settings page. |
| Amazon's WebView lacks WebRTC support | Go2RTC camera streams absolutely cannot play over WebRTC. | Do nothing: the app detects this, falls back to MSE on its own, and records the switch in the App Logs. Toggling **Prefer MSE over WebRTC** (under Settings > Camera Streams > Playback) skips the initial failed attempt entirely. See [Cameras](cameras.md). |
| Bluetooth scanning requires location services | Fire OS 8 is based on Android 11, where a scanner lacking the Location permission and Location Based Services runs but hears nothing. | Grant the location permission via the ADB block above and ensure **Location Based Services** is on in the device's Settings. The "Nearby devices" row on the Bluetooth Proxy page clearly indicates if this is blocking scans. See [ESPHome](esphome.md). |
| Sticky services restart slowly | A crashed kiosk on standard Android devices is back up in about a second; Fire OS takes considerably more time to restart the guard service. | Do nothing: the crash self heal mechanism has a dedicated heartbeat alarm to handle this. Keep the "Display over other apps" permission granted, as the relaunch requires it. |
| Amazon's WebView can crash the process in its audio path | A native crash in `libaaudio` during the WebView's audio playback will take the entire app down. | There is nothing you can do to prevent it; the app's crash self heal will automatically relaunch the kiosk. |
| The [Home Launcher](home-launcher.md) feature is unsupported | Fire OS firmly prohibits replacing its default launcher, preventing Kiosk Satellite from registering as the home screen. The Home Launcher page explicitly states this on a Fire tablet. The OS lock runs deep: Fire OS advertises the home role as available but silently denies every request, its default home settings screen forcefully closes itself the moment it opens, and even granting the role via ADB (`cmd role add-role-holder`) changes nothing (the physical home button still forces you to the Fire launcher). | Use **Start on boot** and rely on Kiosk Mode's protections instead. |
| Fire OS already acts as its own device policy owner | Device ownership (which grants silent updates and true lock task mode on Android 11) cannot be applied to any Fire tablet. Amazon's Parental Controls are hard provisioned as the profile owner on user 0 during the very first boot. Because Android strictly allows only one owner per user, `dpm set-device-owner` will always answer "the user already has a profile owner". Since it is a core system package, it cannot be removed. Furthermore, ownership requires a device with absolutely no registered accounts, and a logged in Fire tablet carries several Amazon ones. | Each app update will require one physical tap on Android's confirmation dialog, which the app will bring to the front and automatically re arm the kiosk after. See [Updates](updates.md). |