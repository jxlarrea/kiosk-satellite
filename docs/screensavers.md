# Screensavers

After a period of inactivity the kiosk can become a clock, a photo frame,
a camera wall, a web page, or simply a black panel, and come back the
moment someone touches it, says the wake word, or walks up to it.

One design decision runs through everything here: the screensaver never
turns the display off. Even the Black mode is the backlight at zero
behind a black overlay, with the app alive underneath, so motion wake,
wake word detection, the ESPHome server and the remote admin (including
its live view) all keep working through the night. Real display power is
a separate thing, the Screen light entity in the
[ESPHome integration](esphome.md).

## Setup

Settings, then **Screensaver** (the same tab exists in the remote admin):

| Setting | Default | Notes |
| --- | --- | --- |
| Screensaver | off | The master switch. Turning it off also dismisses a screensaver that is showing. |
| Idle timeout (seconds) | 300 | Inactivity period before the screensaver starts. |
| Screensaver brightness | off | A separate brightness while the screensaver shows. See below. |
| Brightness level | 20% | Applies to every mode except Dim and Black. |
| Brighten for notifications | on | Lift the dimming while a notification is on screen. Shown with Screensaver brightness on. See below. |
| Turn screen off after | 0 (never) | Truly power the panel off once the screensaver has run this long. See below. |
| Pixel shift | off | Nudge the image every minute to protect OLED panels. Not for Black, whose pixels are already off. |
| Screensaver mode | Black | What the screensaver shows. Only the selected mode's settings appear below the picker. |

Below the mode's own settings sits the **Widgets** group, small corner
overlays that ride over the modes. See [Widgets](#widgets).

## The modes

### Dim

Lowers the backlight to the configured **Dim level** and leaves the
dashboard on screen. Because the dashboard stays visible, the **Pause
dashboard during screensaver** optimization cannot apply in this mode,
so the page keeps using CPU, GPU and battery; the settings page says so
next to the slider.

### Black

A fully dark panel that still answers. **Hide all extras** keeps it
truly black: no widgets, no At a Glance row, no overlays of any
kind, and the At a Glance connection is not even opened.

### Clock

A full-screen clock in one of three faces, picked with **Style**:
**Digital Clock**, **Flip Clock** (split-flap cards) or **Roller Clock**
(oversized rolling digits, modeled on the Lenovo Smart Clock 2). Dates
follow the device language.

| Setting | Notes |
| --- | --- |
| Font | All faces. Rubik (the app's own face, the default), Nunito (a rounded face in the style of Apple's StandBy clock), one of the device's own families (System, Serif, Condensed, Monospace, Casual or Cursive, where what each maps to is the device's call) or LCD, a segmented display font in the style of an LED alarm clock that covers the date and AM/PM as well as the digits. |
| 24-hour clock | All faces. |
| Show seconds | Digital only. |
| Show date | Digital only, on by default. |
| Clock size | 50 to 300 percent. |
| Clock color | Digital only; Flip has its own digit, card and background colors (light digits on near-black cards over pure black by default) and Roller its own digit and background colors. |
| Background color | Digital only; the solid color behind the clock, black by default. White here with a black clock color gives the inverted face e-ink panels read best. |
| Background photo | A photo behind the clock instead of the solid color, any face. |

The **Background photo** is picked on the device (the picker copies it
into app storage), or set remotely: the remote admin and the ESPHome
**Clock background** text entity write a device file path into the same
setting, applied live even while the clock is on screen, and an empty
value clears it. The photo gets the same fill treatment as **Smart** in
the photo modes, with a scrim so the clock stays readable.

**Night mode** recolors the digits while the room is dark, the way a
bedside clock stays readable without lighting the room. It uses the
ambient light sensor, so the switch is disabled on devices without one.

| Setting | Notes |
| --- | --- |
| Night mode | Off by default. |
| Light level | 1 to 100 lx, 5 by default. At or below it the digits take the night color; they return a little above it, so a reading hovering on the line cannot flicker the color. |
| Night color | A muted red by default. Applies to the digits on every face, the date and the At a Glance row; the flip cards keep their own color. |
| Night background | The screen behind the clock in the dark, pure black by default, so a face tuned for a lit room does not keep glowing at night. |

### Home Assistant Media

Anything Home Assistant's media browser can serve: an image, a folder of
them, a video, or a `camera.*` entity, which streams over WebRTC with an
MJPEG fallback. **Media source** opens the browser to pick one; a folder
gets the usual playlist controls (**Seconds per image**, **Shuffle**,
**Include subfolders**, **Transition**), and videos play in full.
**Fill the screen** treats photos the way the other photo modes do (see
[Slideshow behavior](#slideshow-behavior)); videos and camera streams
keep their frame.

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
cache, an optional metadata overlay, and optional pairing of portrait
photos side by side. It has its own page: [Immich](immich.md).

### Website

Any web page, full screen. The page loads as a top-level page in its own
view, not embedded in a frame, and shares the app's cookie jar, so
private URLs that rely on session cookies (a DAKboard private URL, say)
work. Tap-to-dismiss and pixel shift are injected into the
page, so it behaves like every other mode. A page that fails to load, or
whose server answers with an error, is retried every ten seconds instead
of parking an error page for the night.

A page from your own Home Assistant gets two things extra. It signs in
with the session the dashboard already holds, since the login form it
would otherwise show cannot be answered here (the first touch dismisses
the screensaver). And it follows **HA kiosk mode**, so a dashboard put
here shows as the whole screen instead of carrying Home Assistant's
header and sidebar. Both are held to your own Home Assistant: a page
anywhere else is shown exactly as its owner built it.

Voice Satellite does not start on it either. It runs on every Home
Assistant page that loads it, so a dashboard shown here would open a
second microphone and answer as the same satellite the dashboard behind
it is already answering as. The dashboard stays the satellite, and the
screensaver is just a display.

### Camera Streams

One or more configured [camera views](cameras.md) as the screensaver.
Its page lists the views the screensaver cycles through under **Camera
views**, in the order they show, and **Seconds per camera view** sets
how long each one stays up before the next, counted from the moment
the view shows video; with a single view selected nothing rotates. Every
change takes the grid on screen down and starts the next view's streams
from scratch, so the dwell has a floor of 5 seconds and there is a
moment of black between two views. A view whose cameras never come up
moves on after its time plus a 20 second grace. The **Screensaver next
slide** and **Screensaver previous slide** buttons on the
[ESPHome](esphome.md) device step the rotation by one view either way,
and the view they land on holds for its full time. **Mute all views**, on
by default, keeps every view silent even where **Play sound for a single
camera** under [Cameras](cameras.md) would let a one-camera view play
its sound; turn it off to hear that camera from the screensaver too. The grid is
scenery: any touch dismisses the screensaver rather than focusing a
camera, and the small clock stays off so nothing sits over the video.

## Slideshow behavior

The photo modes (Home Assistant Media, Local Media, Photo Gallery, Immich
Media) share one machinery:

- **Transitions**: None, Crossfade, Slide, Zoom, Ken Burns, or Random.
  Ken Burns applies to stills only (videos crossfade), and Random rolls
  one of the real transitions on every change.
- **Fill the screen** (Smart by default): how far a photo may be cropped
  to reach the edges of the panel.

  | Setting | What a photo gets |
  | --- | --- |
  | Off | Its full frame between black bars. |
  | Smart | Enlarged edge to edge if its shape is close enough to the panel's (within about a 25 percent crop along one axis), which covers the common 4:3 and 16:9 camera frames in either orientation. Portrait and square photos keep their full frame over an enlarged, blurred and dimmed copy of themselves instead of black bars. |
  | Always | Enlarged edge to edge whatever its shape, cutting off whatever does not fit. A 4:3 photo on a 2:1 panel loses roughly a third of its height, top and bottom. |

- **Videos** play muted and in full, ignoring the per-image interval; a
  video the device cannot decode is skipped, not looped.
- The playlist is read once per activation, so new photos appear the
  next time the screensaver starts, not mid-session.
- Photos are decoded at panel resolution and shown slides are released,
  so a folder of huge originals does not exhaust a low-RAM tablet.
- **Stepping from Home Assistant**: the **Screensaver next slide** and
  **Screensaver previous slide** buttons on the [ESPHome](esphome.md)
  device move the showing slideshow by one, and the new slide gets a
  full interval of its own. They step a Camera Streams rotation the
  same way. Pressed while any other mode is up, or no screensaver at
  all, they do nothing.

## Widgets

Small overlays in the corners of the screensaver, added from the
**Widgets** group under the mode's settings. Each widget takes one of
the four corners (one widget per corner) and carries its own settings,
picked when adding or editing it. Widgets ride over every mode their
type allows, but never over Black with Hide all extras. The group's
**Widget scaling** slider (50 to 150 percent) sizes every widget for
the screen, and moving it while the screensaver shows previews live.
Every widget sits on a soft vignette, a dark shading in its corner that
keeps the text readable on bright photos. The **Vignette strength**
slider (0 to 100 percent, 80 by default) sets how dark for every
widget, and previews live the same way. 0 turns the shading off for a
clean photo-frame look, at the cost of readability on bright pictures.
The Immich metadata overlay has a slider of its own under its Metadata
settings.
Widgets own their corners: the Immich metadata overlay steps to the
first free corner when a widget claims its spot, and hides only when
every corner is taken. The one exception is a pair of portrait Immich
photos, which needs both bottom corners for its two sets of details: a
widget there hides for as long as the pair is on screen and comes back
with the next single photo.

### Small clock

A corner clock over any mode except Clock (already a clock) and WebRTC
Camera (kept clear so nothing sits over the video):

| Setting | Default | Notes |
| --- | --- | --- |
| Corner | first free corner | The Immich metadata overlay steps out of any corner a widget claims. |
| Color | white | |
| 24-hour clock | off | Its own switch, independent of the Clock mode's. |
| Show date | off | A short date under the time, in the device language. |

It sits on a soft vignette so it stays readable on bright photos, and it
honors pixel shift. A small clock configured before the Widgets group
existed becomes a clock widget automatically, keeping its corner and
settings.

### Weather

Live weather from a Home Assistant `weather` entity, over any mode
except Camera Streams, a clock face with a weather corner is exactly
what the Clock mode wants. The block reads, top to bottom: the
location name, the temperature in a large font with its unit (always
shown, "28°C"), the forecast text with a matching icon, then humidity,
wind speed and visibility, each with its icon. Units come from the
entity, and the icons are monochrome and take the widget's color, like
the text.

| Setting | Default | Notes |
| --- | --- | --- |
| Weather entity | none | Picked from Home Assistant. The widget shows nothing until one is set. |
| Location name | empty | The place shown over the temperature. Weather entities carry no city attribute, so it is named by hand; left empty, the line stays off. |
| Corner | first free corner | |
| Color | white | Text and icons alike. |
| Location, Forecast, Humidity, Wind speed, Visibility | on | One toggle per line. A line also needs the entity to actually carry that reading; whatever the entity lacks is simply left out. |

Readings arrive over a live Home Assistant subscription while the
screensaver shows, so they stay current without polling, and the last
known values survive a short Home Assistant outage.

The forecast line speaks Home Assistant's language: the condition is
written with Home Assistant's own translation of it, so a server set to
Italian reads "Nebbia" where an English one reads "Fog". Nothing to
configure, and nothing changes on an English server. The translations
are fetched from the server once per app start.

### Battery

The device's own battery in a corner, over any mode except Camera Streams:
an icon that follows the charge, a bolt while the device is on external
power, and the percentage beside it.

| Setting | Default | Notes |
| --- | --- | --- |
| Corner | first free corner | |
| Color | white | Icon and text alike. |
| Show percentage | on | Off leaves the icon alone. |
| Only when low | off | Keeps the corner clear until the charge drops to 20 percent, and stays hidden whenever the device is charging. |

The reading is the device's own, not a Home Assistant entity, so it needs
nothing configured and keeps working while Home Assistant is away. It is
read once a minute, and a cable being plugged or pulled shows up at once.
A device without a battery (a mains-powered box) leaves the corner clear:
there is no charge to show, and a bolt burning in the corner forever would
only say the box is plugged in.

### Entity

One Home Assistant entity in a corner, over any mode except Camera
Streams: the At a Glance row's reading in the widget family's look. The
entity's icon and its value share one line (the icon on the corner's
outer edge, like the battery widget) and the name sits under them, all
in the widget's color. A room's temperature sensor in the corner of the
Immich photos, where the At a Glance row cannot go, is what it is for.

| Setting | Default | Notes |
| --- | --- | --- |
| Entity | none | Searched for by name or entity id, the At a Glance picker with room for one. The widget shows nothing until one is set. |
| Name | empty | The name under the value. Left empty, the Home Assistant name shows. |
| Displayed value | State | The state, or one of the entity's attributes, offered with their current values. |
| Corner | first free corner | |
| Color | white | Icon and text alike. |
| Show name | on | Off leaves the icon and value alone. |

The value reads exactly as the At a Glance row would read it: the
entity's own icon when one is set in Home Assistant (a Material Design
Icon, drawn from the bundled set) and a domain default otherwise, a
numeric state rounded to the entity's display precision with its unit,
and slugs written out ("Above horizon"). It arrives over a live Home
Assistant subscription while the screensaver shows, so it stays current
without polling, and the last known value survives a short Home
Assistant outage.

## Brightness

**Screensaver brightness** gives the screensaver its own panel
brightness, applied when it starts and restored when it ends. Dim and
Black ignore it (they have their own levels), and a
[schedule](#schedule) entry's brightness overrides it while that entry
is active. Moving the slider while the screensaver shows applies
immediately, so it can be tuned by eye. The pre-screensaver brightness
is saved persistently, so even an app restart mid-screensaver cannot
make the night level the new normal.

With [Adaptive brightness](screen.md#adaptive-brightness) on, this level
(and the Dim mode's, and a schedule entry's) is the brightness in a bright
room: the room's light dims the screensaver by the same share it dims the
dashboard from its Maximum brightness, so a clock at 20% by day sits at a
few percent at night with the slider untouched.

**Brighten for notifications** (on, shown under the switch above) lifts
all of that while a
[notification](esphome.md#notifications) is on screen. A kiosk running
its screensaver at a few percent is dark enough that a message arriving
on it cannot be read, so the session borrows back the brightness it
saved when it started, and gives it back when the last card is gone.
Only the backlight moves: the clock, the photo or the black overlay
stays exactly where it was, with the card lit on top of it. Dim and
Black lift too, and so does a schedule entry's own brightness. Turn it
off for a bedroom, where a notification lighting the room at 3am is
worse than missing it until morning.

## Turning the screen off

The screensaver stands down while another app is in front of the kiosk:
the idle clock stops counting the moment the app goes behind (an app
opened from the App Launcher, a gesture or Home Assistant, or Home pressed
on a tablet without kiosk mode), a screensaver already up ends so the
other app gets the brightness back, and the clock starts over from the
moment the kiosk returns. Brightness is a device-wide setting, so a
screensaver dimming it under someone using another app would dim that app.
A dark panel is not another app: the screen going off pauses the kiosk the
same way, and there the session carries on exactly as before.

The screensaver holds the panel awake while it shows, so the OS idle
timeout never fires under it. **Turn screen off after** is the
sanctioned way out: once the screensaver has been up that long, the
panel truly powers off (up to 60 minutes, in 5-minute steps; 0, the
default, never does). Powering the panel off is device-admin territory
on Android, so the setting needs the **Device admin** permission
(Settings, Device, Permissions); without it the timer logs a warning
and leaves the panel on. The same Android call arms the lock screen on
any device that has one, PIN or not, and a panel that wakes onto it
would fall back asleep seconds later with the kiosk paused underneath.
So every wake clears a lock screen that has no PIN, pattern or password
behind it (on Android 10+ that takes the Display over other apps
permission, which the wizard requests). One that is secured is left
alone: the kiosk then waits behind it until someone unlocks the device,
and the log says so. Fire OS 8 refuses the dismissal to every app but
Amazon's own and the kiosk stays behind the lock screen there too, which
the log names along with the fix, an adb switch and a reboot; see
[Amazon Fire tablets](fire.md). A kiosk that powers its panel off is
best set up with no screen lock, or with the lock screen disabled
outright.

The screensaver session stays active behind the dark panel, which is
what makes waking symmetrical: every dismiss source powers the panel
back on. That covers motion (with
[background listening](microphone.md) on, the camera keeps watching
through a real screen-off on most devices; some vendors suspend it
anyway, One UI on Android 11 among them, and there the Black
screensaver is the way to keep motion wake, see [Camera](camera.md)),
the wake word, the
ESPHome **Screensaver active** switch turned off, and a Home Assistant
automation calling `stopScreensaver`. All of them land on the dashboard,
not on the screensaver. The power button and double-tap-to-wake count as
activity like a touch, so they land on the dashboard too and restart the
idle countdown, with or without a screensaver up (under
Lockdown Mode the screensaver stays, as it does for motion).
The one wake that keeps the screensaver is the app switching its own
panel on, the ESPHome **Screen** light: an automation turning a photo
frame on in the morning gets its photos back, with a fresh screen-off
countdown, and can turn **Screensaver active** off when it wants the
dashboard instead.

A day-to-day example: photos during the day, Black in the evening via
the [schedule](#schedule), and Turn screen off after set to 10 minutes.
The display goes fully dark overnight once the room empties, and the
first person walking past in the morning (or "okay nabu") brings the
dashboard straight back.

## Schedule

**Scheduled screensavers** switches to a different screensaver at set
times of day. Each entry under **Times** carries a time, a mode, a
brightness and four overrides — motion, face, widgets and At a glance —
edited by tapping the entry; it applies from its time until the next
entry, and the last entry of the day carries over past midnight.
There is no day-of-week dimension, deliberately: the schedule describes
a day, every day.

The typical shape is two entries: photos at a comfortable brightness
from the morning, Black (or Clock, dimmed) from the evening. The motion
override sets **Dismiss on motion** per entry, in either direction, so
an overnight entry can keep the camera off entirely, or a daytime entry
can enable approach wake even though the global switch is off. The face
override does the same for **Dismiss on face**, and the two together
are how a kiosk wakes on faces by day and on motion by night: face
detection needs a lit face, so a daytime entry sets Face on, and the
evening entry sets Motion on, which takes precedence and carries the
dark hours. The
widgets and At a glance overrides do the same for the
[widgets](#widgets) and the [At a Glance](#at-a-glance) row: leave them
on Default to follow their own settings, or set them to Off on the
night entry for a screen with nothing on it but the mode itself. On
shows what those settings configure, so an override cannot conjure a
widget that was never added. Editing the schedule while the screensaver
is showing applies live.

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

## Face detection

**Dismiss on face**, under Face Detection, wakes the screen only when
someone looks at the kiosk: a person walking through the room leaves
the screensaver up, and the dashboard appears when they turn to the
screen. This is the feature Fully Kiosk calls face detection. It is
detection, not recognition: the app notices that a face is looking at
the camera and nothing more, with nothing identified, stored or sent
anywhere. The camera runs only during the screensaver, exactly like
Dismiss on motion, and every face is looked for on the device.

**Face sensitivity** sets how close a face has to be. It reads as a
distance: 1 wakes only on a face right at the screen, 100 on any face
the camera can make out, which is about two meters through a typical
front camera. The default of 50 lands around arm's length and a step
back. Frame rate, the camera pick and the startup delay are shared with
motion detection and tuned in the Camera settings.

Three rules to know:

- **A voice interaction pauses it.** From the wake word until Voice
  Satellite is listening for it again, no face is looked for (nor any
  motion), so someone talking at the satellite does not dismiss the
  screensaver by turning to it, and the turn has the cores the detector
  would take.
- **Dismiss on motion takes precedence.** With both switches on, motion
  wakes the screen and face detection stays idle; the settings pages say
  so under the switch. Turn Dismiss on motion off to wake on faces.
- **Faces need light.** Motion detection works in the dark; a face
  detector does not, since a face it cannot see is not there. A dim room
  lit by the screensaver itself usually shows a nearby face, but a dark
  room does not. The [schedule](#schedule) is the answer: a daytime entry
  with Face on and an evening entry with Motion on wakes on faces while
  there is light and falls back to motion at night.

**Postpone screensaver on face** extends it the way Postpone screensaver
on motion extends Dismiss on motion: the camera also watches between
screensavers, and someone looking at the kiosk keeps resetting the idle
timer, so the screensaver waits until nobody is reading the dashboard.
It keeps the camera running permanently with face detection on top, it
requires Dismiss on face, and Dismiss on motion keeps precedence over it
too.

The cost is kept in check by running the face model only when there is
something to look at. The motion analyzer's grid, a few hundred byte
reads per frame, decides: the model runs while something in the frame
moved in the last few seconds, while a face was seen in the last few
seconds (so a viewer sitting still keeps it alive), and for the first
seconds after the camera opens, at most twice a second on a single CPU
core, and slower still where a run costs more, so the detector never
takes more than about a fifth of a core on any hardware. An empty room costs no inference at all, which is what makes
face detection, and Postpone on face in particular, affordable on the
low-powered devices most kiosks are.

Under [Lockdown Mode](kiosk.md) a face neither dismisses nor postpones,
like motion.

### Camera preview

**Show camera preview**, in the Camera Preview group of the same page,
leaves a glimpse of what the camera saw behind a face wake: a small
round live view of the camera, white-rimmed, in a corner of the
dashboard for a few seconds, gone on its own. It shows the very frames
the detector looks at, so tuning Face sensitivity, picking a camera or
placing the device gets an answer on the screen, and someone who did not
expect the kiosk to wake can see why it did. The frames are drawn and
dropped, nothing is stored or sent anywhere, and the preview answers no
touch: a tap on the dashboard under it lands on the dashboard.

| Setting | What it does |
| --- | --- |
| Preview duration | 3 to 10 seconds on screen, 5 by default. |
| Preview scaling | 50 to 150 percent of the base size, like Widget scaling. |
| Preview position | Which corner it sits in, top right by default. |

It shows only when a face dismisses the screensaver, not for a face that
postpones the next one, which repeats every second or so for as long as
someone is there. The camera stays on through the preview and is
released after it, unless Postpone screensaver on face keeps it. With
the switch on, the camera's analysis stream runs at 640x480 instead of
320x240 for the sake of the picture, which costs the analysis itself
nothing.

## Proximity detection

Motion Detection's two switches, on the device's proximity sensor
instead of the camera, under Proximity Detection:

- **Dismiss on proximity**: watch the sensor while the screensaver is up
  and wake the screen when something comes close to it.
- **Postpone screensaver on proximity**: also watch between screensavers,
  so something close to the sensor keeps resetting the idle timer. It
  requires Dismiss on proximity. Unlike the camera legs there is no cost
  to speak of: the sensor is a single interrupt line.

No camera, no permission and it works in the dark. The catch is the
sensor itself. Kiosk-class tablets (the Galaxy Tab line, Fire tablets,
the Echo Show) mostly have none, and on those the switch is disabled with
the reason. Modern phones usually have one, but many expose a virtual
sensor made for calls, typically named "palm proximity", that only
reacts to a hand on the screen and never to someone walking up. Because
the name is the only way to tell, a row under the switch shows what
Android reports as the proximity sensor: an infrared or time-of-flight
part named after its chip (STK3310, VCNL4040, TMD2755) detects hover at
a few centimeters, a "palm" or "touch" sensor does not.

Something already resting on the sensor when it starts watching is not
an approach, so a case or a stand that covers it cannot wake the
screensaver every time it begins. While something stays close, the
detection repeats every few seconds, which is what lets the postpone
leg hold the screensaver off. Those repeats never dismiss: only the
approach itself does, so with Postpone off a screensaver that starts
with something already close stays up. Under [Lockdown Mode](kiosk.md) proximity
neither dismisses nor postpones, like motion.

## Person detection

Motion Detection's two switches on a person sensor the device itself
runs, under Person Detection, a page that only exists on devices with
such a sensor like the Meta Portal:

- **Dismiss on person**: read the sensor while the screensaver is up and
  wake the screen when someone is in front of the device.
- **Postpone screensaver on person**: also read it between screensavers,
  so someone in front of the device keeps resetting the idle timer. It
  requires Dismiss on person.

Dismiss acts on someone arriving. A person already there when the
screensaver starts is not an arrival, so with Postpone off that
screensaver stays up until they leave and come back, or until a touch.

On the Portal the sensor is the Smart Camera's people tracker, running
all the time on a feed that never lights the camera LED, so there is no
camera session and no camera light. It detects people at any angle, not
faces, and it needs a one-time adb grant. Independent of the camera legs,
which keep working alongside it. Everything else, the grant included, is
in [Meta Portal](portal.md).

## Starting and dismissing

The idle timeout is the normal path in. On demand, the screensaver can
be started by the kiosk menu's **Start Screensaver** entry (its presence
in restricted kiosk mode is an Allowed Action), a
[gesture](gestures.md) bound to **Start the screensaver**, the ESPHome
**Screensaver active** switch, or the `startScreensaver` command on the
[remote](remote-api.md) and [JavaScript](js-api.md) APIs.

Any touch dismisses it and resets the timer. Beyond touch:

- **The wake word** dismisses it immediately, and the idle countdown
  holds for the whole voice interaction, so the screen cannot go dark
  between question and answer.
- **Motion**, with Dismiss on motion (above).
- **A face looking at the kiosk**, with Dismiss on face (above).
- **Something close to the proximity sensor**, with Dismiss on proximity
  (above).
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
- The ESPHome **Screensaver** switch (the master enable) takes a showing
  screensaver down when turned off; **Screensaver active** turned off
  and the **Postpone screensaver** button dismiss one and re-arm the
  timeout.
- **Hold mode** (Home Assistant settings) pins the current view for as
  long as it is on: the screensaver will not start, dashboard view
  rotation and the return to home timer pause, and the display stays
  awake. Turning it on dismisses a showing screensaver. It is the
  sustained sibling of the one-shot Postpone screensaver button, made
  for keeping a recipe or a video on screen; flip it from the settings,
  the drawer notice, a gesture, the opt-in kiosk menu entry ("Show in
  the kiosk menu", with its own Hold Mode allowed action in Kiosk Mode),
  or the Hold mode switch in Home Assistant, and an optional timer ends
  the hold by itself.

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
the screensaver, every mode but the Camera Streams grid, kept live over
its own Home Assistant subscription while the screensaver is up. It has
its own page: [At a Glance](at-a-glance.md).

## Home Assistant

With [ESPHome](esphome.md) **Expose kiosk entities** on, the screensaver
is fully remote-controllable: the **Screensaver** master switch, the
**Screensaver active** switch (start and dismiss), the **Postpone
screensaver** button for automations that keep the display awake from an
external sensor, the **Screensaver mode** and **Clock style** selects,
the **Clock background** text entity, the **Screensaver brightness**
switch and level, the **Screensaver motion detection** and
**Screensaver face detection** switches, the **Screensaver proximity
detection** switch on devices with the sensor, and the **Screensaver next
slide** and **Screensaver previous slide** buttons that step a showing
photo mode or Camera Streams rotation, all on the same ESPHome device as the rest of the kiosk's
entities.
