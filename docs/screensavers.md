# Screensavers

After a period of inactivity the kiosk can become a clock, a photo frame,
a camera wall, a web page, or simply a black panel, and come back the
moment someone touches it, says the wake word, or walks up to it.

One design decision runs through everything here: the screensaver never
turns the display off. Even the Black mode is the backlight at zero
behind a black overlay, with the app alive underneath, so motion wake,
wake word detection, MQTT and the remote admin (including its live view)
all keep working through the night. Real display power is a separate
thing, the Screen light entity in the [MQTT integration](mqtt.md).

## Setup

Settings, then **Screensaver** (the same tab exists in the remote admin):

| Setting | Default | Notes |
| --- | --- | --- |
| Screensaver | off | The master switch. Turning it off also dismisses a screensaver that is showing. |
| Idle timeout (seconds) | 300 | Inactivity period before the screensaver starts. |
| Screensaver brightness | off | A separate brightness while the screensaver shows. See below. |
| Brightness level | 20% | Applies to every mode except Dim and Black. |
| Pixel shift | off | Nudge the image every minute to protect OLED panels. Not for Black, whose pixels are already off. |
| Small clock | off | A corner clock over the photo and website modes. See below. |
| Screensaver mode | Black | What the screensaver shows. Only the selected mode's settings appear below the picker. |

## The modes

### Dim

Lowers the backlight to the configured **Dim level** and leaves the
dashboard on screen. Because the dashboard stays visible, the **Pause
dashboard during screensaver** optimization cannot apply in this mode,
so the page keeps using CPU, GPU and battery; the settings page says so
next to the slider.

### Black

A fully dark panel that still answers. **Hide all extras** keeps it
truly black: no small clock, no At a Glance row, no overlays of any
kind, and the At a Glance connection is not even opened.

### Clock

A full-screen clock in one of three faces, picked with **Style**:
**Digital Clock**, **Flip Clock** (split-flap cards) or **Roller Clock**
(oversized rolling digits, modeled on the Lenovo Smart Clock 2). Dates
follow the device language.

| Setting | Notes |
| --- | --- |
| 24-hour clock | All faces. |
| Show seconds | Digital only. |
| Show date | Digital only, on by default. |
| Clock size | 50 to 300 percent. |
| Clock color | Digital only; Flip and Roller have their own digit and card or background colors. |
| Background photo | A photo behind the clock instead of the solid color, any face. |

The **Background photo** is picked on the device (the picker copies it
into app storage), or set remotely: the remote admin and the MQTT
**Clock background** text entity write a device file path into the same
setting, applied live even while the clock is on screen, and an empty
value clears it (issue #150). The photo gets the same fill treatment as
the photo modes, with a scrim so the clock stays readable.

### Home Assistant Media

Anything Home Assistant's media browser can serve: an image, a folder of
them, a video, or a `camera.*` entity, which streams over WebRTC with an
MJPEG fallback. **Media source** opens the browser to pick one; a folder
gets the usual playlist controls (**Seconds per image**, **Shuffle**,
**Include subfolders**, **Transition**), and videos play in full.

### Local Media

A folder on the device itself, cycled as a slideshow: **Local folder**
(picked on the device, or the path typed in the remote admin), **Seconds
per photo**, **Shuffle**, **Include subfolders**, **Transition**, and
**Fill the screen**.

### Photo Gallery

Like Local Media, but the selection comes from the system gallery picker
instead of a folder, so no storage permission is involved: **Photos**
(picking again replaces the selection; the chosen items are copied into
app storage so they survive reboots), **Seconds per photo**, **Shuffle**,
**Transition**, and **Fill the screen**.

### Immich Media

An [Immich](https://immich.app/) server as a photo frame, with a local
cache and an optional metadata overlay. It has its own page:
[Immich](immich.md).

### Website

Any web page, full screen. The page loads as a top-level page in its own
view, not embedded in a frame, and shares the app's cookie jar, so
private URLs that rely on session cookies (a DAKboard private URL, say)
work (issue #118). Tap-to-dismiss and pixel shift are injected into the
page, so it behaves like every other mode. A page that fails to load, or
whose server answers with an error, is retried every ten seconds instead
of parking an error page for the night.

### WebRTC Camera

A configured [camera view](cameras.md) as the screensaver, picked with
**Camera view**. The grid is scenery: any touch dismisses the
screensaver rather than focusing a camera, and the small clock stays off
so nothing sits over the video.

## Slideshow behavior

The photo modes (Local Media, Photo Gallery, Immich Media) share one
machinery:

- **Transitions**: None, Crossfade, Slide, Zoom, Ken Burns, or Random.
  Ken Burns applies to stills only (videos crossfade), and Random rolls
  one of the real transitions on every change.
- **Fill the screen** (on by default): a photo shaped close enough to
  the panel (within about a 25 percent crop along one axis) is enlarged
  edge to edge; portrait and square photos keep their full frame over an
  enlarged, blurred and dimmed copy of themselves instead of black bars.
- **Videos** play muted and in full, ignoring the per-image interval; a
  video the device cannot decode is skipped, not looped.
- The playlist is read once per activation, so new photos appear the
  next time the screensaver starts, not mid-session.
- Photos are decoded at panel resolution and shown slides are released,
  so a folder of huge originals does not exhaust a low-RAM tablet.

## The small clock

A corner clock over any mode except Clock (already a clock), WebRTC
Camera (kept clear), and Black with Hide all extras:

| Setting | Default | Notes |
| --- | --- | --- |
| Small clock | off | |
| Clock position | Top right | Which corner. The Immich metadata overlay defaults to the opposite one. |
| Clock color | white | |
| 24-hour clock | off | Its own switch, independent of the Clock mode's. |
| Show date | off | A short date under the time, in the device language. |

It sits on a soft vignette so it stays readable on bright photos, and it
honors pixel shift.

## Brightness

**Screensaver brightness** gives the screensaver its own panel
brightness, applied when it starts and restored when it ends. Dim and
Black ignore it (they have their own levels), and a
[schedule](#schedule) entry's brightness overrides it while that entry
is active. Moving the slider while the screensaver shows applies
immediately, so it can be tuned by eye. The pre-screensaver brightness
is saved persistently, so even an app restart mid-screensaver cannot
make the night level the new normal.

## Schedule

**Scheduled screensavers** switches to a different screensaver at set
times of day. Each entry under **Times** carries a time, a mode, a
brightness, and a motion override; it applies from its time until the
next entry, and the last entry of the day carries over past midnight.
There is no day-of-week dimension, deliberately: the schedule describes
a day, every day.

The typical shape is two entries: photos at a comfortable brightness
from the morning, Black (or Clock, dimmed) from the evening. The motion
override sets **Dismiss on motion** per entry, in either direction, so
an overnight entry can keep the camera off entirely, or a daytime entry
can enable approach wake even though the global switch is off. Editing
the schedule while the screensaver is showing applies live.

## Motion detection

With the [device camera](camera.md) enabled, two switches under Motion
Detection put it to work for the screensaver:

- **Dismiss on motion**: watch the camera while the screensaver is up
  and wake the screen when someone approaches. The camera runs only
  during the screensaver.
- **Postpone screensaver on motion**: also watch between screensavers,
  so movement in the room keeps resetting the idle timer and the
  screensaver waits for the room to empty. This keeps the camera running
  permanently, and it requires Dismiss on motion.

Detection works in the dark, ignores whole-room lighting changes (a TV,
a lamp), and stands down for a couple of seconds around the app's own
light changes, including slide transitions, so a bright photo cannot
wake the screensaver it belongs to. Sensitivity, frame rate and the
camera pick are tuned in the Camera settings; the details are in the
[Device Camera doc](camera.md). Under [Lockdown Mode](kiosk.md), motion
neither dismisses nor postpones, even when the screensaver itself is
allowed to run.

## Starting and dismissing

The idle timeout is the normal path in. On demand, the screensaver can
be started by the kiosk menu's **Start Screensaver** entry (its presence
in restricted kiosk mode is an Allowed Action), a
[gesture](gestures.md) bound to **Start the screensaver**, the MQTT
**Screensaver active** switch, or the `startScreensaver` command on the
[remote](remote-api.md) and [JavaScript](js-api.md) APIs.

Any touch dismisses it and resets the timer. Beyond touch:

- **The wake word** dismisses it immediately, and the idle countdown
  holds for the whole voice interaction, so the screen cannot go dark
  between question and answer.
- **Motion**, with Dismiss on motion (above).
- **Opening a camera view** dismisses it, and the idle timer stays off
  while the view is open.
- **Navigation from Home Assistant** (the Dashboard view select, or
  `haNavigate`) dismisses it so the requested page is actually seen.
- **DLNA media pushed to the kiosk** dismisses it and holds it off while
  playing; DLNA audio kept in the background deliberately does not.
- **Music on the Sendspin player** holds it off, unless the player's
  **"Now Playing" instead of the screensaver** mode is on, in which case
  the screensaver becomes a full-screen now-playing view while music
  plays (see [Sendspin](sendspin.md)).
- The MQTT **Screensaver** switch (the master enable) takes a showing
  screensaver down when turned off; **Screensaver active** turned off
  and the **Postpone screensaver** button dismiss one and re-arm the
  timeout.

## Around the dashboard

While the screensaver covers the page, the **Pause dashboard during
screensaver** optimization (on by default) stops the dashboard from
rendering at all, which is where most of the screensaver's power savings
come from; the numbers are in [Optimizations](optimizations.md). Dim is
the exception, since the dashboard stays visible.

Dashboard rotation freezes in place while the screensaver is up and
resumes where it left off, so the kiosk does not page through views
nobody sees. **Return to home dashboard view**, on the other hand, works
quietly behind a showing screensaver, so the morning starts on the home
view without the screen having lit up at 3 AM to navigate.

With the Voice Satellite integration on the dashboard, **Turn off the
Voice Satellite screensaver** (on by default, Voice Satellite settings)
makes the integration's own screensaver stand down while this app's
screensaver is enabled, so the two never fight.

## At a Glance

**At a glance** puts a row of up to four Home Assistant entity states on
the Black and Clock screensavers, kept live over its own Home Assistant
subscription while the screensaver is up. It has its own page:
[At a Glance](at-a-glance.md).

## Home Assistant

With [MQTT publishing](mqtt.md) enabled, the screensaver is fully
remote-controllable: the **Screensaver** master switch, the
**Screensaver active** switch (start and dismiss), the **Postpone
screensaver** button for automations that keep the display awake from an
external sensor, the **Screensaver mode** and **Clock style** selects,
the **Clock background** text entity, the **Screensaver brightness**
switch and level, and the **Screensaver motion detection** switch. The
full list, with topics, is in the [MQTT doc](mqtt.md).
