# Home Launcher

Kiosk Satellite can register as your device's home screen, completely replacing the stock launcher. The system will start the kiosk immediately at boot, so the screen never flashes the old launcher first. Every press of the home button lands you right back on the kiosk with no screen pinning and no annoying consent dialogs. On a device where the stock launcher demands an account, like a Meta Portal, this removes the default launcher from the picture entirely.

This is completely different from the App Launcher. The App Launcher opens other apps from inside the kiosk, whereas the Home Launcher makes the kiosk the primary screen those apps return to. They work beautifully together, and a device acting as the home screen usually needs the App Launcher enabled too, ensuring you still have a designated way to access other apps.

## Turning It On

Navigate to **Settings**, then **Home Launcher**. This same page is available in the remote admin.

| Setting | What it does |
| --- | --- |
| Act as the home screen | The master switch. What happens next depends on your specific device (see below). |
| Keep screen pinning | Pins the screen even while Kiosk Satellite acts as the home screen. This blocks recent apps and back button natively, but it will bring back the pinning confirmation dialog on devices that do not have device ownership. |

The **Status** row located under the switches shows the live state: whether the role is currently held, whether the device is waiting for confirmation, and where to finish the process.

Here is what enabling looks like per device:

| Device | What happens |
| --- | --- |
| Android 10 and newer | The system asks once using a small dialog. Android silently refuses the dialog after two denials; after that, the Status row will open the system's own home settings instead. |
| Android 7 to 9 | The system's home settings open automatically so you can pick Kiosk Satellite. |
| Amazon Fire tablets | Not supported: Fire OS strictly forbids replacing its launcher. The switches will not appear on a Fire tablet; the page simply explains why. |

While the switch is off, Kiosk Satellite has zero home screen footprint. It will not appear in any launcher chooser or default apps list.

## What Changes While It Holds

* The device boots straight into the kiosk. **Start on boot** becomes redundant and cancels its own launch sequence.
* The home button always returns to the kiosk. If Kiosk Mode's **Disable home button** is turned on, the pin and its consent dialog are skipped entirely on devices without ownership, because the home role already covers what the pin covered. **Keep screen pinning** opts the pin back in.
* Pressing home while the kiosk is already on screen closes whatever is currently open (the menu, settings, the app launcher, or a screensaver) and lands you safely on the dashboard, exactly how every launcher's home press works.
* **Exit Application** leaves the menu, and **Exit app** leaves the remote admin overview. Since killing the home screen just forces the system to relaunch it, neither option will actually exit the app. You must turn the home launcher off first to exit. **Restart app** remains available, as it comes back by design.

## Getting Back Out

Undoing this setup never depends on anything remembered by the app. Turning the switch off simply removes Kiosk Satellite from home duty, and Android hands the screen back to the remaining launcher on its own. The previous launcher reopens immediately as long as it is still installed. Every path works:

* Flipping the **Act as the home screen** switch on the device or in the remote admin.
* Running the `releaseHomeRole` remote API command, which works even if the kiosk's screen is unresponsive, as long as the process is running.
* Uninstalling the app entirely: Android will resolve the home role by itself.

## If the App Cannot Start

A home screen that crashes on every startup would normally leave the device displaying a black screen forever, with the system infinitely relaunching a broken app. Kiosk Satellite includes a native fuse to prevent exactly that. If the app experiences three consecutive starts that never reach a drawn frame within a few minutes of each other, it hands the home role back to the stock launcher automatically. This fuse is written in plain Android code that runs before the app itself, ensuring it fires even if the app's own core engine is completely broken.

After tripping, the switch will read as off, and the Status row and the log page will explain exactly what happened. Turning the switch back on re-arms everything. A successful healthy start resets the count, so normal restarts, updates, and reboots will never accidentally trigger the fuse.