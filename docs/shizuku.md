# Shizuku

**Settings > Device > Shizuku** lets Kiosk Satellite request Android permissions and self update through a running Shizuku service.

## Connect

1. Install and start Shizuku using its [official setup guide](https://shizuku.rikka.app/guide/setup/).
2. Open **Settings > Device > Shizuku** and tap **Shizuku access**.
3. Approve the request on the kiosk. If you previously denied access permanently, allow Kiosk Satellite in the Shizuku app.
4. Tap **Test connection** to read the helper's process identity. This test does not change device settings.

KS supports Shizuku server API 13 and later. A service started through ADB normally runs as Android's shell user and must be started again after a reboot. Root access requires a rooted device and Shizuku running as root. KS does not root the device or start Shizuku automatically.

## Updates

The **Install updates through Shizuku** toggle sits below Connection. Enable it to install KS updates without tapping Allow or Install on the kiosk. It is off by default and saves immediately on both the device and Remote Admin. Fleet management does not sync this preference.

Shizuku must be running and authorized when you start an update. If the connection is unavailable or the installation fails, KS reports the error without opening a confirmation prompt. Turn the toggle off to restore regular installation and optional update helper behavior. It does not change when KS checks for releases or automatically start installing them. See [Shizuku updates](updates.md#shizuku-updates) for installation and relaunch details.

## Permission actions

Each action runs only when tapped and targets Kiosk Satellite's own package. Opening the page does not grant permissions or execute commands.

| Action | Purpose |
| --- | --- |
| Grant all permissions | Grant every missing permission listed in Permissions Manager, including permissions for features that are currently off. Existing grants are skipped. |
| Microphone | Allow microphone usage for wake word detection and speech to text. |
| Unrestricted battery | Let the process run in the background without being paused or killed. |
| Camera | Let motion detection and snapshots use the camera. |
| Nearby devices | Allow Bluetooth scanning and connections. |
| Notifications | Allow the Kiosk Satellite Service's ongoing notification. |
| Display over other apps | Let KS bring itself back to the foreground. |
| Modify system settings | Let brightness changes adjust the real display brightness. |
| System UI guard | Enable KS's accessibility service while preserving the other enabled accessibility services. |
| Device admin | Activate KS's existing device admin receiver so it can turn the screen off. This does not make KS a device owner. |
| All files access | Let File Manager browse shared storage. |
| Usage access | Let the Foreground app sensor identify other apps. |
| Location | Let pages, Bluetooth scanning and location sensors use the device position. |

KS checks Android's permission state after each request. A successful command alone is not treated as proof that Android granted access. Use **Permissions Manager** to review current grants or finish requests that the device rejected. Disabled location services and manufacturer-specific restrictions may still require manual setup. A rejected grant does not stop the batch from attempting the remaining permissions. System UI guard updates Android's [enabled accessibility services setting](https://developer.android.com/reference/android/provider/Settings.Secure#ENABLED_ACCESSIBILITY_SERVICES). Device admin uses Android's [`dpm set-active-admin` command](https://developer.android.com/tools/adb#dpm).

The Device page offers predefined actions. It does not accept arbitrary command text or commands targeting other apps. Permission changes take effect immediately and are not synchronized by fleet management.

## Plugins

SDK 1 plugins can declare the optional `shizuku` capability and use the same authorized connection. See the [SDK Shizuku reference and example](https://github.com/jxlarrea/kiosk-satellite-plugin-hello-world/blob/main/docs/shizuku.md).

The Shizuku permission belongs to KS. Installed plugins run inside KS and are not isolated from its privileges. Grant access only if you trust KS and your installed plugins. A plugin's own commands can do more than the predefined Device actions.

## Remote API

Authenticated admin clients can use these commands:

| Command | Parameters | Result |
| --- | --- | --- |
| `getShizukuState` | None | Availability, permission status and backend UID/version when connected. |
| `requestShizukuPermission` | None | Requests the approval prompt on the kiosk and returns the current state. Read the state again after approval. |
| `runShizukuAction` | `action` | Runs one of the actions below. |

Allowed action IDs are `identity`, `grantAll`, `microphone`, `batteryUnrestricted`, `camera`, `bluetooth`, `notification`, `displayOverOtherApps`, `writeSettings`, `uiGuard`, `deviceAdmin`, `allFiles`, `usageAccess` and `location`. The batch includes all 12 permissions regardless of feature settings and skips existing grants. Callers cannot supply package names or shell commands.

`identity` returns `exitCode`, `stdout`, `stderr`, `timedOut` and `truncated`. Permission actions return a `results` list with `key`, `ok` and `error` for each requested permission. An empty list means all permissions were already held. Inspect individual results because Android can reject some grants while accepting others. Fleet credentials cannot invoke these commands.
