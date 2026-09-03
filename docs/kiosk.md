# Kiosk Mode and Lockdown Mode

Kiosk Satellite offers two distinct layers of protection for a wall mounted device. **Kiosk Mode** is your persistent, everyday setup: it locks the device into the Kiosk Satellite app using a customizable set of protections that survive reboots and remain active until you explicitly disable them. **Lockdown Mode** is a temporary, momentary switch applied on top: a single toggle that completely disables screen interactions. This is ideal for cleaning the screen, protecting it from kids or guests, or securing it while the house is empty. Once Lockdown Mode is lifted, the device returns to its exact previous state.

Everything described here operates within the boundaries of what Android allows a standard app to do. The setting descriptions clearly indicate where the operating system has the final say. For instance, the physical power button cannot be intercepted (the app simply re wakes the screen instead), and the home button is only blocked using standard OS screen pinning, unless you configure the [Home Launcher](home-launcher.md) to make the kiosk the default home destination. If you require a device that is completely escape proof against a determined adult left unattended, see the [Going further](#going-further-device-ownership) section at the bottom of this page.

## Kiosk Mode

Navigate to **Settings**, then **Kiosk Mode**. This same configuration page is available in the remote admin. Turning on the master switch replaces the standard menu swipe with the secure exit gesture, forces the back button to stay inside the kiosk, and arms whichever specific protections you enable below it.

| Setting | What it does |
| --- | --- |
| Enable kiosk mode | The master switch that activates Kiosk Mode. |
| Start on boot | Automatically launches Kiosk Satellite when the device powers on. On Android 10 and newer, this requires the "display over other apps" permission. |
| Kiosk exit gesture | Configures the exit sequence: 5 or 7 fast taps anywhere on screen, either as plain taps or holding the final tap down. You can also disable it entirely, meaning the settings can only be reached via the remote admin. |
| Kiosk mode PIN | Requires a PIN immediately after a successful exit gesture before the menu will open. |
| Disable status bar | Blocks the Android status bar pull down by placing a thin, invisible shield over the top edge of the display. If the System UI guard is also enabled, any notification shade that manages to slip through is immediately forced closed. |
| Disable volume buttons | Intercepts and swallows inputs from the hardware volume keys. |
| Disable power button | Because Android strictly prevents apps from blocking the physical power button, this setting forces the screen to turn right back on immediately if it is pressed. Note that turning the screen off remotely via Home Assistant will still work normally. |
| Disable home button | Pins the app using Android's native screen pinning feature, which effectively blocks both the home and recent apps buttons. |
| Disable context menus | Suppresses standard long press menus and text selection features inside the active web view. |
| Disable pull to refresh | Ignores any pull to refresh swipe gestures while Kiosk Mode is active. |
| Disable Gestures | Keeps all custom mappings from the [Gestures page](gestures.md) dormant for as long as Kiosk Mode is on. |
| Allow menu with quick actions | Opts a restricted version of the menu back in: only the harmless actions you explicitly select below this switch will be visible. Everything else remains hidden behind the exit gesture and PIN. |

### Staying in Front

The **Disable home button** feature relies on Android screen pinning. On a device that is not fully managed by an MDM, Android will present an "App is pinned" consent dialog the very first time it activates. Simply answer **Got it** once, and all future pins will occur silently. On certain devices, this dialog aggressively returns on every single boot. Configuring the [Home Launcher](home-launcher.md) permanently solves this annoyance, because when the kiosk acts as the true home screen, the pin is bypassed entirely and the home button naturally lands on the kiosk. 

However, Kiosk Mode no longer strictly depends on that consent answer. If screen pinning is declined by the user or somehow lost, the app will forcibly pull itself back to the foreground about a second after losing it. Furthermore, attempting to close the app from the recent apps screen will trigger an immediate relaunch. 

The app deliberately ignores two specific situations: apps opened legitimately through the App Launcher (because their auto return feature handles the way back), and the native Android permission screens that the app's own settings pages open.

The App Launcher's **Return automatically** feature operates as an idle clock, not a hard countdown timer. **Return after** tracks how long the launched app goes untouched. Every touch inside the other app resets the clock, ensuring someone actively using it is never rudely pulled back to the kiosk. The app detects these touches by placing a one pixel, invisible, and untouchable window over the other app while the clock runs. This clever technique requires the **display over other apps** permission, which the return feature itself also needs. 

You will see a **Required system permissions** group appear directly under the switch (both on the device and in the remote admin) tracking that specific grant, along with **Unrestricted battery** (since Android pauses clocks for apps lacking battery exemption). If a highly secure app (like some banking apps) actively blocks overlay windows, it keeps its touch events hidden. In that specific scenario, the idle clock runs blindly and will pull the kiosk back after the configured time regardless of user activity.

Both of these aggressive relaunches, as well as recovering from a crash, are handled by the [Kiosk Satellite Service](permissions.md#the-kiosk-satellite-service), the persistent foreground service the app maintains. These recovery paths require the **display over other apps** permission. The [permissions group](#required-system-permissions) at the bottom of the settings page clearly indicates if it is missing.

## Lockdown Mode

Lockdown Mode renders the screen completely untouchable while keeping the active dashboard visible and live. The device remains fully glanceable, but any tap lands harmlessly on a protective shield and briefly displays a "Screen is locked" notice instead of interacting with the page. 

While Lockdown Mode is active, all Kiosk Mode protections are temporarily armed at runtime (without altering your permanently stored kiosk settings), wake word detection is actively muted, and the screensaver is suppressed unless explicitly allowed. Turning Lockdown Mode off instantly reverts the device to the exact protection state configured beforehand.

The setup for this feature lives exclusively in the Remote Administration UI, on the **Lockdown Mode** page. There is no equivalent setup page inside the on device settings menu. However, you can toggle the mode itself from three places: the remote admin page, the dedicated **Lockdown mode** switch exposed to Home Assistant [over ESPHome](esphome.md), or by using the physical exit gesture on the glass.

| Setting | What it does |
| --- | --- |
| Enable Lockdown Mode | Completely disables screen interactions until turned off, either remotely from Home Assistant or physically via the exit gesture. |
| Blackout | Paints the locked screen solid black and completely pauses the dashboard rendering underneath it. This significantly reduces power consumption on a locked device. The panel itself remains lit, and the device stays fully reachable. |
| Allow screensaver | Permits the screensaver to run while the device is locked, accommodating users who prefer to see a clock rather than a live dashboard. The "Dismiss on motion" feature is deactivated while the lock holds, preventing someone walking past from accidentally unlocking the view. Normal motion behavior resumes the moment the lock lifts. |
| Lockdown exit gesture | Offers the exact same options as the standard kiosk exit gesture, but as an independent setting so the two can differ. Entering the fast taps anywhere on screen will turn the mode off (after entering the kiosk PIN, if one is configured). |

The protective shield is a true screen level overlay, not merely a UI page contained inside the app. It covers the entire display at the core system level, meaning it remains active even if another app somehow comes forward. It requires the **display over other apps** permission to function this way (if the permission is missing, it will still cover the app's own window, but nothing else).

Because only one exit gesture can be armed at any given time (the lockdown gesture seamlessly replaces the kiosk gesture while the mode holds), you can safely configure both settings to use the exact same tap count without any collisions.

## Required System Permissions

Both the Kiosk Mode and Lockdown Mode settings pages conclude with a **Required system permissions** section. This displays the two specific grants these protections rely heavily upon, providing a button to initiate the grant process directly on the device (this button works even when clicked from the remote admin).

These specific permission groups only highlight what the currently configured features demand. However, **Settings > Device > Permissions Manager** provides a master list of every single grant the app utilizes in one place, accessible both on the device and in the remote admin. This ensures you can easily find and configure permissions even for features you haven't enabled yet. 

Each row in the master list explains its purpose and reads as Granted, Missing (meaning an active feature requires it but does not have it), or Not granted (meaning nothing currently needs it, but you can grant it proactively). Keep in mind that the actual granting process always occurs on the physical device. Clicking the buttons in the remote admin simply opens the corresponding Android dialog or settings screen on the tablet itself, because Android strictly forbids accepting permissions remotely on a user's behalf. 

Furthermore, some manufacturers overlay their own aggressive battery or autostart managers on top of standard Android, which no app can read or interact with. If Kiosk Satellite is continuously killed despite every permission row showing as granted, those manufacturer specific menus are the next place to investigate. If you are provisioning a panel from a computer, the [Permissions](permissions.md) page provides the exact ADB commands to grant every requirement instantly.

The **Display over other apps** permission is the standard Android system overlay grant. It is the engine behind the screen level lockdown shield, the status bar shield, foreground app reclaim, crash and task removal relaunching, and the Start on boot feature.

The **System UI guard** is an optional Android accessibility service. When Lockdown Mode holds, or while matching Kiosk Mode protections are active, this service violently forces the notification shade closed the instant it attempts to open, and bounces the Android recents screen right back. During normal operation, it sits completely idle. It strictly watches window change events and possesses zero capability to read screen content (the service explicitly declares `canRetrieveWindowContent` as false). For security reasons, Android only allows the person physically at the device to enable this: it must be done once inside Android's Accessibility settings, where the service is listed as Kiosk Satellite.

## Going Further: Device Ownership

Without device ownership, Android forcibly reserves a few UI surfaces that no app can legally claim. For instance, the transient navigation bar may flash briefly before hiding, a highly determined swipe can expose the notification shade for a split second before the System UI guard collapses it, and screen pinning will always ask for user consent at least once. 

For a dedicated, commercial grade device that cannot tolerate these minor gaps, Android's native device owner provisioning completely seals them. Under device ownership, **Disable home button** upgrades from standard screen pinning to a true lock task mode with absolutely zero consent dialogs. While the lock holds, the operating system itself permanently kills the notification shade and navigation buttons, rather than forcing the app to race against the user to close them.

Making Kiosk Satellite the device owner requires executing a single, one time `adb` command on a device **that has absolutely no Google, Samsung, Meta, etc. accounts signed in** (you must remove them first, or perform a factory reset; accounts can usually be safely added back afterward depending on the ROM). The device must also **not already have an owner assigned**. This second strict rule permanently excludes Amazon Fire tablets, which hardwire Parental Controls as a profile owner on the very first boot. See the [Amazon Fire tablets](fire.md) documentation for details.

To assign ownership, run:

```
adb shell dpm set-device-owner me.jxl.kiosk_satellite/.KioskAdminReceiver
```

The absolute only way to undo this command is a complete factory reset of the device (which is exactly the security point of this tier). Treat device ownership as a commitment reserved for permanently installed wall panels, never a daily driver tablet. Securing ownership also grants the app the ability to install its own updates completely silently across every Android version, as detailed in the [Updates](updates.md) documentation.

## Notes

* Both the **Kiosk mode** and **Lockdown mode** switches are fully exposed to Home Assistant [over ESPHome](esphome.md). This allows you to easily script an automation that locks the house panel tight at bedtime and lifts the lockdown automatically in the morning.
* Lockdown Mode only arms the kiosk protections dynamically; it never permanently overwrites them. Toggling Lockdown on and off leaves your actual Kiosk Mode settings completely untouched.
* The remote admin interface remains functional no matter what protections are active on the glass. If you lose your PIN or accidentally disable the exit gesture, you can always recover the device directly from your browser.