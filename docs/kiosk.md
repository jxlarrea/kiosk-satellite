# Kiosk Mode and Lockdown Mode

Two layers of protection for the tablet on the wall. **Kiosk Mode** is the
persistent setup: it locks the device into Kiosk Satellite, with a
configurable set of protections that survive reboots and stay on until you
turn them off. **Lockdown Mode** is the momentary switch on top: one toggle
that disables screen interactions entirely, for cleaning the screen, kids,
guests, or an empty house, and hands the device back exactly as it was when
it lifts.

Everything here is what Android lets an ordinary app do, and the setting
descriptions say honestly where the OS keeps the last word: the power
button cannot be intercepted (the screen is re-woken instead), and the home
button is only blocked through OS screen pinning. For a device that must be
escape-proof against a determined adult with time alone, see
[Going further](#going-further-device-ownership) at the end.

## Kiosk Mode

Settings, then **Kiosk Mode**; the same page is in the remote admin. The
master switch replaces the menu swipe with the exit gesture, keeps the back
button inside the kiosk, and arms whichever protections are enabled below
it.

| Setting | What it does |
| --- | --- |
| Enable kiosk mode | The master switch. |
| Start on boot | Launch Kiosk Satellite when the device powers on. On Android 10+ this needs the display over other apps permission. |
| Kiosk exit gesture | 5 or 7 fast taps anywhere, plain or holding the last tap down, or disabled entirely so only the remote admin can reach settings. |
| Kiosk mode PIN | Asked after the exit gesture before the menu opens. |
| Disable status bar | Blocks the status bar pull-down with a thin shield over the top display edge; with the System UI guard enabled, a shade that slips through is closed again immediately. |
| Disable volume buttons | Swallows the hardware volume keys. |
| Disable power button | Android cannot block the power button, so the screen turns right back on when it is pressed. Turning the screen off remotely still works. |
| Disable home button | Pins the app with Android screen pinning, which blocks the home and recents buttons. |
| Disable context menus | Suppresses long-press menus and text selection inside the web view. |
| Disable pull to refresh | Ignores the pull-to-refresh gesture while kiosk mode is on. |
| Disable Gestures | Keeps the mappings from the [Gestures page](gestures.md) dormant while kiosk mode is on. |
| Allow menu with quick actions | Opts a restricted menu back in: only the harmless actions picked below it, everything else stays behind the exit gesture and PIN. |

### Staying in front

**Disable home button** works through Android screen pinning, and on a
device that is not fully managed, Android asks for consent with an "App is
pinned" dialog the first time. Answer **Got it** once and later pins are
silent. Kiosk Mode no longer depends on that answer, though: if pinning was
declined or ever lost, the app pulls itself back to the front about a
second after losing the foreground, and closing it from the recents screen
relaunches it immediately. Two situations are deliberately left alone: apps
opened through the App Launcher (their auto-return owns the way back), and
the Android permission screens the settings pages open.

The App Launcher's **Return automatically** is an idle clock, not a
countdown: **Return after** counts the time the other app goes untouched,
and every touch in it starts the count over, so someone in the middle of
something is never pulled back to the kiosk. The touches are seen through
a one-pixel, invisible, untouchable window the app keeps over the other
app while the clock runs, which needs the same **display over other apps**
permission the return itself does; a **Required system permissions** group
appears under the switch, on the device and in the remote admin alike,
with that grant and **Unrestricted battery** (a paused app has no clock).
An app that hides overlay windows, as some banking apps do, keeps its
touches to itself, and there the clock runs plain and the kiosk comes back
after the time regardless.

Both relaunches, and the one after a crash, come from the
[Kiosk Satellite Service](permissions.md#the-kiosk-satellite-service), the
foreground service the app always runs. The recovery paths need the
**display over other apps** permission; the
[permissions group](#required-system-permissions) at the end of the page
says when it is missing.

## Lockdown Mode

Lockdown Mode makes the screen untouchable while the
dashboard stays visible and live: the tablet remains glanceable, but every
tap lands on the shield and shows a brief "Screen is locked" notice instead
of reaching the page. While the mode holds, every Kiosk Mode protection
arms at runtime without changing the stored kiosk settings, wake word
detection is muted, and the screensaver stays out of the way unless invited
back in. Turning the mode off returns the device to exactly the protections
that were configured before.

Its setup lives only in the Remote Administration UI, on the **Lockdown
Mode** page; there is no page for it in the on-device settings. The mode
itself toggles from three places: that page, the **Lockdown mode** switch
every device gets in Home Assistant [over ESPHome](esphome.md), and the exit
gesture on the glass.

| Setting | What it does |
| --- | --- |
| Enable Lockdown Mode | Disables screen interactions until turned off either from Home Assistant or with the exit gesture. |
| Blackout | Paints the locked screen solid black and pauses the dashboard's rendering underneath, so a locked tablet also costs less power. The panel stays lit and the device stays reachable. |
| Allow screensaver | Lets the screensaver keep running while locked, for whoever prefers the clock over a live dashboard. Dismiss on motion stays deactivated while the mode holds, so someone walking past never unlocks the view; normal behavior returns when the lock lifts. |
| Lockdown exit gesture | The same options as the kiosk exit gesture, its own setting so the two can differ. Fast taps anywhere turn the mode off, after the kiosk PIN if one is set. |

The shield is a screen-level overlay, not a page inside the app: it covers
the entire display at the system level, so it stays up even if another app
comes forward, and it needs the **display over other apps** permission to
do so (without the grant it still covers the app window itself).

Since only one exit gesture is armed at a time (lockdown's replaces the
kiosk one while the mode holds), the two settings can share the same tap
count without colliding.

## Required system permissions

The Kiosk Mode and Lockdown Mode settings both end with a **Required system
permissions** group showing the two grants the protections lean on, each
with a button that starts the grant on the device, including from the
remote admin.

These per-feature groups only cover what the feature being configured
needs. **Settings, Device, Permissions Manager** lists every grant the app can use
in one place, on the device and in the remote admin alike, so a permission
no enabled feature happens to ask for is still findable. Each row says
what it is for and reads Granted, Missing (something switched on needs it
and does not have it) or Not granted (nothing needs it yet, and it can
still be given ahead of time). Note that granting always happens on the
device: the buttons there and in the remote admin both open an Android
dialog or settings screen on the tablet, because Android has no way to
accept a permission on someone's behalf. Some manufacturers also add their
own battery or autostart manager on top of Android's, which no app can
read or request; if the app keeps being killed with every row granted,
that is the next place to look. For provisioning a panel from a computer,
[Permissions](permissions.md) lists every grant with the adb commands to
give them all at once.

**Display over other apps** is the standard Android overlay permission. It
powers the screen-level lockdown shield, the status bar shield, the
foreground reclaim, the relaunch after a crash or a task removal, and Start
on boot.

**System UI guard** is an optional accessibility service. While Lockdown
Mode holds, or while the matching Kiosk Mode protections are on, it closes
the notification shade the moment it opens and bounces the recents screen
right back; the rest of the time it does nothing. It watches only
window-change events and cannot read screen content (the service declares
`canRetrieveWindowContent` false). Android only lets the person at the
device enable it: once, under Android's Accessibility settings, where the
service appears as Kiosk Satellite.

## Going further: device ownership

Without device ownership, Android reserves a few surfaces no app can claim:
the transient navigation bar can flash briefly before it is re-hidden, a
determined swipe can show the notification shade for an instant before the
System UI guard collapses it, and screen pinning asks for consent once.
For a dedicated device that must not have those gaps, Android's own device
owner provisioning closes them: **Disable home button** upgrades from
screen pinning to full lock task, with no consent dialog, and while the
lock holds the OS itself keeps the shade and the navigation buttons dead
rather than an app racing to close them.

Making Kiosk Satellite the device owner is a one-time `adb` command on a
device **without any Google or Samsung accounts signed in** (remove them
first, or factory reset; accounts can be added back afterwards on most
ROMs):

```
adb shell dpm set-device-owner me.jxl.kiosk_satellite/.KioskAdminReceiver
```

The only way to undo it is a factory reset (that is the point of the
tier); treat it as something for permanently installed panels, not a daily
driver. Ownership also makes the app's own updates install silently on
every Android version, covered in [Updates](updates.md).

## Notes

- The **Kiosk mode** and **Lockdown mode** switches are both available in
  Home Assistant [over ESPHome](esphome.md), so an automation can lock the house
  panel at bedtime and lift it in the morning.
- Lockdown arms the kiosk protections but never writes them: flipping it on
  and off leaves the Kiosk Mode settings untouched.
- The remote admin always works, whatever the protections say: a lost PIN
  or a disabled exit gesture is recovered from the browser, not the glass.
