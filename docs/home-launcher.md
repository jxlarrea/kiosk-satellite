# Home Launcher

Kiosk Satellite can register as the device's home screen, replacing the
stock launcher. The system then starts the kiosk at boot itself, so the
screen never flashes the old launcher first, and every press of the home
button lands back on the kiosk with no screen pinning and no consent
dialog. On a device whose stock launcher demands an account, such as a
Meta Portal, this removes the launcher from the picture entirely.

This is a different thing from the [App Launcher](kiosk.md): that one
opens other apps from inside the kiosk, this one makes the kiosk the
screen those apps return to. They compose well, and a device that acts as
the home screen usually wants the App Launcher on too, so there is still a
sanctioned way into other apps.

## Turning it on

Settings, then **Home Launcher**; the same page is in the remote admin.

| Setting | What it does |
| --- | --- |
| Act as the home screen | The master switch. What happens next depends on the device, see below. |
| Keep screen pinning | Pin the screen even while Kiosk Satellite is the home screen. Blocks recents and back natively, but brings back the pinning confirmation dialog on devices without device ownership. |

The **Status** row under the switches tells the live state: whether the
role is held, whether the device is still waiting for a confirmation, and
where to finish it.

What enabling looks like per device:

| Device | What happens |
| --- | --- |
| Android 10 and newer | The system asks once with a small dialog. Android silently refuses the dialog after two denials; past that the Status row opens the system's own home settings instead. |
| Android 7 to 9 | The system's home settings open for you to pick Kiosk Satellite. |
| Amazon Fire tablets | Not supported: Fire OS does not allow replacing its launcher. The switches do not appear on a Fire; the page only says why. |

While the switch is off, Kiosk Satellite has no home-screen footprint at
all: it appears in no launcher chooser and no default-apps list.

## What changes while it holds

- The device boots straight into the kiosk. **Start on boot** becomes
  redundant and stands down its own launch.
- The home button always returns to the kiosk. With Kiosk Mode's
  **Disable home button** on, the pin and its consent dialog are skipped
  on devices without ownership, because the role already covers what the
  pin covered; **Keep screen pinning** opts the pin back in.
- A home press while the kiosk is already on screen closes whatever is
  open, the menu, settings, the app launcher, a screensaver, and lands on
  the dashboard, the way every launcher's home press works.
- **Exit Application** leaves the menu and **Exit app** leaves the remote
  admin overview: killing the home screen only has the system relaunch it,
  so neither could deliver. Turn the home launcher off first to exit.
  **Restart app** stays, it comes back by design.

## Getting back out

Undo never depends on anything remembered: turning the switch off removes
Kiosk Satellite from home duty and Android hands the screen back to the
remaining launcher on its own. The previous launcher is reopened
immediately when it is still installed. Every path works:

- The **Act as the home screen** switch, on the device or in the remote
  admin.
- The `releaseHomeRole` [remote API command](remote-api.md), which works
  even when the kiosk's screen is unusable, as long as the process runs.
- Uninstalling the app: Android re-resolves the home role by itself.

## If the app cannot start

A home screen that crashes on every start would otherwise leave the device
showing a black screen forever, with the system relaunching the same
broken app. Kiosk Satellite carries a native fuse against exactly that:
three starts in a row that never reach a drawn frame, within a few
minutes of each other, hand the home role back to the stock launcher
automatically. The fuse is plain Android code that runs before the app
proper, so it fires even when the app's own engine is what is broken.

After a trip the switch reads off, the Status row and the
[log page](remote-api.md) say what happened, and turning the switch back
on arms everything again. A healthy start resets the count, so ordinary
restarts, updates and reboots never accumulate toward it.
