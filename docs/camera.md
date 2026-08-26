# Device Camera

The tablet's own camera, put to work for the smart home: a still camera
entity in Home Assistant fed by JPEG snapshots, and an on-device motion
detector that wakes the screensaver, holds it off while someone is around,
or feeds a motion sensor in Home Assistant. Everything is processed on the
device; no video ever streams anywhere.

This is not the [Camera Streams](cameras.md) feature, which shows *other*
cameras on the kiosk. This page is about the camera pointing out of the
kiosk itself.

## Setup

Settings, then **Camera** (the same tab exists in the remote admin). The
whole feature sits behind one master switch, **Enable camera**, off by
default: camera use adds CPU load (roughly 10% while motion detection
runs) and heat, so nothing touches the camera until you opt in.

Turning it on asks for the Android camera permission. While the switch is
on and the grant is missing, a notice with a **Grant** button sits right
under it; if Android has stopped asking, the notice offers the app
settings instead. In the remote admin the notice explains that the grant
dialog appears on the tablet screen.

Devices that were already using **Dismiss on motion** before the Camera
page existed had the camera enabled automatically on upgrade, once.

## Settings

| Setting | Default | Notes |
| --- | --- | --- |
| Enable camera | off | The master switch. Everything below depends on it. |
| Camera | Front | Front or Back. One pick for every camera feature. On single-camera devices the picker becomes a plain label. |
| Snapshot resolution | 480p | 480p, 720p or 1080p on the 4:3 ladder, mapped to the nearest size the hardware offers. A 480p frame is about 30 KB. |
| Continuous snapshots | off | Capture a fresh snapshot for Home Assistant at a fixed interval. |
| Snapshot interval | 60 | Seconds between snapshots, 5 to 300. The first frame fires immediately when the timer starts. |

## Snapshots

A frame is captured and published to the Camera entity:

- On demand: the **Take camera snapshot** button in Home Assistant, or
  **Take snapshot** in the remote admin.
- On the interval, with **Continuous snapshots** on.
- Once per motion session, when motion detection spots someone: one frame
  when they arrive, not a stream of frames while they stand there.
- Whenever Home Assistant asks the camera entity for a picture, so a
  dashboard card or a restart never finds it blank.

One capture runs at a time; an overlapping request reports that a
snapshot is already in progress. The camera is opened for the capture and
released right after, so interval snapshots cost only the captures
themselves, not a permanently running camera. Snapshots need the app in
the foreground; a capture attempted while another app covers the kiosk
reports that the camera is unavailable in the background.

Home Assistant fetches the latest frame from the camera entity whenever it
needs one, and a fetch captures a fresh frame; the entity goes away while
the camera is disabled.

## Motion detection

The same camera session serves six features, and they differ in when
the camera actually runs:

| Feature | Where | Camera runs |
| --- | --- | --- |
| Dismiss on motion | Screensaver settings | Only while the screensaver is showing. |
| Postpone screensaver on motion | Screensaver settings | Permanently while the screen is on. |
| Motion sensor | Camera settings | Permanently while the screen is on, Black screensaver included. |
| Dismiss on face | Screensaver settings | Only while the screensaver is showing. |
| Postpone screensaver on face | Screensaver settings | Permanently while the screen is on. |
| Show fingers gesture | Gestures | Permanently while the screen is on. |

**Dismiss on motion** wakes the screen when someone approaches the
sleeping kiosk. **Postpone screensaver on motion** extends it: movement in
the room keeps resetting the idle timer, so the screensaver waits until
the room is actually empty; it requires Dismiss on motion. **Motion
sensor** exposes motion as a Home Assistant `binary_sensor` with no
screensaver gate at all. A screensaver [schedule](screensavers.md) entry
can override Dismiss on motion per time window, so an overnight Black
entry can keep the camera off entirely. **Dismiss on face** (the
screensaver's [Face detection](screensavers.md#face-detection)) rides
the same camera session: a small on-device face detector runs on the
frames the motion analyzer already samples, so the frame rate, camera
pick and startup delay below tune it too. The model runs only while the
grid saw something change, a face was recently in view, or the camera
just opened, at most twice a second on one core and paced by the
measured cost of a run so it never takes more than about a fifth of a
core, so an empty room costs no inference. Dismiss on motion takes
precedence while both are on. The [Show fingers](gestures.md#show-fingers)
gesture rides the same session with a palm detector of the same family
and a hand landmark model behind it, under the same gate, whenever the
screen is on and a hand mapping exists.

What a true screen-off does to the camera depends on the Android
version. Older versions leave it alone. Newer ones (observed on Android
16, and rolling in since Android 11's while-in-use rules) revoke camera
access within seconds of the panel powering off from any app that is
not on a visible screen, unless the app holds a camera-type foreground
service. Kiosk Satellite attaches that type to the [background
listening](microphone.md) service whenever the camera permission is granted,
so with background listening enabled all three motion features keep
watching through a real screen-off. Not every vendor honors that
exemption: Samsung's One UI on Android 11 (the Galaxy Tab A 10.1
generation) suspends the camera seconds after the panel powers off even
with background listening on, and does it silently. The app notices the
stalled frames, logs a warning in the Console, and brings the camera
back the moment the screen comes on, but motion cannot wake a truly
dark panel on such devices. Without background listening the revocation
happens everywhere; the camera likewise rebinds on its own at
screen-on. The screen that *looks* off but keeps every camera feature
working everywhere is the **Black screensaver**
(backlight at zero under a black overlay); use it, or a scheduled Black
entry, where Fully Kiosk users would reach for "fake screen off".

The tuning lives under Camera, **Motion Detection**:

| Setting | Default | Notes |
| --- | --- | --- |
| Motion sensor | off | The **Motion** `binary_sensor` on the ESPHome device. |
| Clear after | 5 | Seconds without motion before the sensor reads clear, 1 to 300. |
| Motion frame rate | 2 | Frames per second the camera checks. Lower is lighter on the CPU; 2 is plenty to notice someone approaching. |
| Motion sensitivity | 70 | 1 to 100. Higher trips on smaller movements. |
| Startup delay | 0 | Seconds to ignore motion after the camera starts, 0 to 15. For devices whose camera physically moves as it opens. |

Detection is built to be cheap and to work in the dark. Frames are
analyzed at the camera's smallest resolution, luminance only, on a coarse
grid; each cell learns its own sensor noise, and the camera is asked for
the longest exposures it offers, so a person crossing a dim room still
registers without the detector tripping on noise. Whole-frame light
changes are discounted, and the app suppresses detection for a couple of
seconds around its own light changes (screensaver start and stop, screen
power, brightness moves, slide transitions), so the kiosk does not wake
itself up.

**Startup delay** covers a different problem: hardware whose camera
physically moves as it opens, such as a phone with a pop-up module. The
lens travels through the scene as the motor deploys it, and that sweep is
a real change across the whole frame rather than a lighting shift, so
none of the discounting above can filter it out and the kiosk dismisses
the screensaver that just started the camera. The delay counts from the
first frame and applies to every path that starts the camera, not just a
screensaver, since a schedule boundary, the screen turning on or a tuning
change deploy the same lens. Frames are still tracked as the baseline
while it runs, so detection is fully sensitive the moment it expires.
Leave it at 0 on a device with a fixed camera; a few seconds is enough
for the hardware that needs it.

Two related switches live elsewhere: with **Allow screensaver** on under
[Lockdown Mode](kiosk.md), Dismiss on motion stays deactivated until the
lock lifts, and the Sendspin player's full-screen view only reacts to
motion with its own **Dismiss "Now Playing" on motion** setting on.

## Home Assistant

With [ESPHome](esphome.md) **Expose kiosk entities** on, the camera adds
to the Kiosk Satellite device:

| Entity | Type | Notes |
| --- | --- | --- |
| Camera | camera | The latest snapshot. Nothing streams, so its own state stays `idle`. It takes the device's single ESPHome camera slot, so the Screenshot camera steps aside while it exists. |
| Take camera snapshot | button | Capture a fresh frame and hand it to Home Assistant. |
| Last camera snapshot | sensor | When the current frame was captured, as a timestamp. This is what lets an automation react to a fresh frame arriving. |
| Motion | binary_sensor | Only with **Motion sensor** on. Reads motion for the configured **Clear after** window, then clears itself. |
| Camera enabled | switch | The master toggle, remotely. Exists whenever the hardware does, even with the camera off, so an automation can arm the camera only when a room-wide sensor says someone is home. |
| Screensaver motion detection | switch | The Dismiss on motion toggle, remotely. Pairs with Camera enabled for staged wake-ups. |
| Screensaver face detection | switch | The Dismiss on face toggle, remotely. Motion keeps precedence on the device, so an automation that wants faces by day and motion by night flips the motion switch. |
| Camera facing | select | The **Camera** pick, remotely: Front or Back, for every camera feature at once. Switching it captures a fresh frame from the newly picked camera a moment later, so an automation can flip a phone to its back camera as a baby monitor and back again. Like the switches it works with the camera off. Only on devices with both cameras. |

Disabling the camera retracts the camera and motion entities, and the
Screenshot camera takes the camera slot back; the switches and the facing
select remain, since
they are how you turn it back on and point it the right way first. On
camera-less hardware none of these entities exist.

## Sharing the camera

Android hands the camera to one session at a time, and the app is careful
about whose session that is. While any motion feature is running, motion
holds the camera open and snapshots ride along in the same session, so a
snapshot needs no second open and no exposure resettle (which the motion
detector would read as motion). A few low-end devices cannot run motion
analysis and JPEG capture in one session; there motion wins, and
snapshots report the camera busy while it runs. Another app holding the
camera makes captures fail until it lets go.

## Hardware notes

- **No usable camera**: some ROMs (LineageOS ports on Echo Show hardware,
  for example) have no camera support even when the hardware has one. The
  Camera page says so up front, and no camera entities are published. A
  physical privacy shutter, where the device has one, disconnects the
  camera completely and looks the same.
- **Single camera**: the Front/Back picker becomes a label naming the one
  camera the device has. Devices whose ROM advertises cameras it does not
  have are handled: failed captures report a real error instead of
  hanging.

## The remote admin

The remote admin's Camera tab mirrors every setting and adds a **Latest
snapshot** panel: the newest frame, when it was taken, and a **Take
snapshot** button. The panel shows the cached frame and refreshes itself
while open; viewing it never triggers a capture. The same frame is served
at `GET /api/camera/snapshot` for anything else that wants it (see the
[Remote API](remote-api.md)).

## Privacy

- Motion analysis happens entirely on the device, and motion frames are
  never stored or transmitted; only the fact of motion leaves the app.
- The only picture that leaves the device is the snapshot JPEG handed to
  your own Home Assistant over the ESPHome connection, one frame per
  request.
- The **Enable webcam access** setting under Web Content is unrelated: it
  governs whether the dashboard web page may use the camera, not this
  feature.
