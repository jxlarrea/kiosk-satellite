# Updating Kiosk Satellite

The app updates itself from the GitHub releases: it notices a new release,
downloads it on the tablet and hands it to Android's installer. How much of
that is hands-free depends on the Android version and on device ownership.

## How the app finds an update

The app checks GitHub 20 seconds after it starts and every 12 hours after
that. A new release shows in three places:

| Where | What it looks like |
| --- | --- |
| The device | An **Update available** row at the foot of the kiosk menu. Not in the restricted quick-actions menu. |
| The remote admin | An **Install version x** button in the Updates card on the Device page. |
| Home Assistant | The **Update** entity of the [ESPHome integration](esphome.md), with release notes and an Install button. Needs **Expose kiosk entities** on. |

Home Assistant cannot force the check, so a release cut this morning may
not show there until tonight and the entity's Install button does nothing
until the app has seen the release. To check right away:

- On the device, tap the version line at the foot of the kiosk menu.
- In the remote admin, tap the app version on the Device page.

## Installing

All three surfaces start the same download on the tablet. Before
downloading, the app asks GitHub once more and takes the newest release, so
nothing is left waiting behind the one that installs. Progress shows where
the download was started and in the Home Assistant entity. The download
can be cancelled from the device or the remote admin.

## What Android asks for

| Device | What happens at install |
| --- | --- |
| Android 12 and newer | The first in-app update shows Android's install confirmation on the tablet screen. Every update after that installs silently. |
| Android 11 and older | Every update shows Android's install confirmation on the tablet screen. |
| App is the device owner | Every update installs silently, on any Android version. |

The Android 12 rule keys on the installer of record. The first in-app
update makes the app its own installer, which is what allows the silent
ones that follow. An `adb install` in between hands the role back to
`adb`, so the next in-app update asks once more.

### The install unknown apps grant

Android 8 and newer needs the **Install unknown apps** grant before the
confirmation can show. The first time, Android's installer stops on a
screen with a Settings button that leads to the toggle. Flip it once and
it sticks. The toggle lives under Settings, Apps, Special app access,
Install unknown apps. Over `adb`, alongside the rest of the
[provisioning commands](permissions.md):

```
adb shell appops set me.jxl.kiosk_satellite REQUEST_INSTALL_PACKAGES allow
```

A stripped-down ROM without that Settings screen (the Meta Portal, for one)
dead-ends here. Device ownership is the way through, since a device owner
needs neither the grant nor the confirmation.

### Confirming inside Kiosk Mode

Screen pinning and the foreground reclaim would hide Android's confirmation
screen, so the app stands the kiosk down before an install that needs
confirming and arms it again when the install is declined, fails or
completes. A moment of unprotected screen there is expected.

## Coming back after the install

Android kills the app as it swaps the code. On Android 10 and newer the
relaunch needs the **Display over other apps** permission. Without it the
update installs and the kiosk stays closed until someone taps the icon.
The setup wizard requests the permission, the update dialog warns when it
is missing and the remote admin's Updates card offers a button that opens
the grant screen on the tablet. Over `adb`:

```
adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow
```

## Hands-free on Android 11 and older: device ownership

A device owner installs its own updates silently on any Android version.
It is also the only working path on ROMs that cannot give the install
unknown apps grant. Ownership also unlocks the strongest Kiosk Mode tier,
see [Kiosk and Lockdown](kiosk.md#going-further-device-ownership).

> [!WARNING]
> **Device ownership can only be removed with a factory reset.** Android
> has no command to take it back and the app cannot give it up on its own.
> While it holds the role, Kiosk Satellite cannot be uninstalled and its
> device admin cannot be deactivated. Everything on the device goes with
> the reset that undoes it. Do this on a tablet that stays on the wall as a
> panel, never on someone's daily driver.

Android refuses the command while any account is signed in on the device
(Google, Samsung, Meta and the like). Remove them first or start from a
factory reset. With the tablet on `adb`:

```
adb shell dpm set-device-owner me.jxl.kiosk_satellite/.KioskAdminReceiver
adb shell dpm list-owners
```

The second command confirms it took. From then on every update installs
without a confirmation screen and **Screen off** works without the separate
device admin grant.

## Sideloading is still fine

`adb install -r kiosk-satellite.apk` keeps working whatever the updater
does. Settings, the Home Assistant connection and the ESPHome pairing
survive it. On Android 12 and newer expect one confirmation on the next
in-app update, since `adb` is now the installer of record.

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| Install in Home Assistant does nothing | The app has not seen the release yet. Tap the version line on the device or the app version in the remote admin to check now. |
| The Update entity still shows the old version after the install | It refreshes when the app reconnects after its relaunch. If the app did not come back, see the next row. |
| The update installed but the app stayed closed | **Display over other apps** is missing. Tap the app icon, then grant it so the next update returns on its own. |
| Nothing happens after the download on Android 11 or older | The confirmation could not show. If it never appears, the ROM may have no way to give the install unknown apps grant (the Portal case). Grant it over `adb` if the toggle exists or make the app the device owner. |
| The download fails or stalls | The tablet cannot reach GitHub or the transfer went quiet and the app gave up. The Logs page of the remote admin shows why. The notice stays up, so the download can be started again. |
| An update on Android 12+ asked for confirmation again | Something else installed the app in between, usually `adb`. One confirmed in-app update makes the following ones silent again. |
