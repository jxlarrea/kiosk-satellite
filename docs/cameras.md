# Camera Streams

Kiosk Satellite can show up to four low-latency WebRTC cameras in a
full-screen view. Camera streams come from Home Assistant itself, from
Go2RTC, or from a direct WHEP endpoint.

## Import cameras from Home Assistant

Open Settings, then Camera Streams, and select **Import WebRTC cameras from
Home Assistant**. Kiosk Satellite asks the connected Home Assistant for every
`camera.*` entity that can stream WebRTC (Home Assistant 2024.11 or newer)
and adds them as cameras, streaming through Home Assistant's own WebRTC
signaling over the existing connection. No Go2RTC URL, port or WHEP setup is
involved: if a camera streams low-latency video in the Home Assistant
frontend, it works here.

Importing again merges new entities, preserves camera names and view
membership, and marks entities that disappeared (or lost WebRTC support) as
missing. Home Assistant hands the player its ICE server configuration, so
setups that stream through Home Assistant Cloud work too.

## Add a Go2RTC server

Open Settings, then Camera Streams, and select **Add Go2RTC server**.

Enter the base URL of a Go2RTC server that the tablet can reach, such as:

```text
http://192.168.1.10:1984
```

Basic authentication and self-signed TLS certificates are supported. After
saving the server, select **Import streams**. Kiosk Satellite reads the stream
names from `/api/streams`; it does not copy the source URLs into camera views.

The Go2RTC API can control powerful server features. Protect it with
authentication and expose only the paths the kiosk needs when possible:

```yaml
api:
  allow_paths: [/api/streams, /api/webrtc]
```

Imported streams remain in Kiosk Satellite until they are deleted. Importing
again merges new stream names, preserves camera names and view membership, and
marks streams that disappeared from Go2RTC as missing.

## Add a camera manually

A manual camera can reference:

- A stream name on a configured Go2RTC server.
- A direct HTTP or HTTPS WHEP endpoint.
- A Home Assistant `camera.*` entity (streamed through Home Assistant's
  WebRTC signaling, like the import).

Raw RTSP URLs are not supported by the app player. Add the RTSP source to
Go2RTC first, then reference its stream name.

For a Go2RTC camera, an optional fullscreen stream can be configured. Use a
lower-resolution substream for the grid and a higher-resolution stream for
fullscreen focus.

## Create a view

A view contains one to four cameras, in the order you arrange them. In the
view editor the chosen cameras sit in their own list: drag a row by its handle
to reorder it (or use the arrows on a touch screen), and add or remove cameras
from the list below. The view's **Show camera names** option controls whether
labels appear over the video.

- One camera fills the display.
- Two cameras use columns in landscape and rows in portrait.
- Three cameras use a balanced orientation-aware layout.
- Four cameras use a 2 by 2 grid.

Tap a camera in a multi-camera view to focus it. Kiosk Satellite closes the
other peer connections while focused. Press Back, use the back swipe gesture,
or double tap the focused camera to return to the grid. These actions only
close the focused camera.

Press Back, use the back swipe gesture, or double tap a camera in the grid to
close the camera view and return to the Home Assistant dashboard. A voice
interaction temporarily closes the camera view so the Voice Satellite
integration is visible, including follow-up turns that do not start with a new
wake word. The same view and focused camera return when the interaction ends.
Explicitly closing or changing the camera view cancels that return.

## The default view

Every install has a view named **Default**. It cannot be deleted, and it is
allowed to stand empty; emptying it is how you retire it. Once it holds at
least one camera, a **Default Camera View** entry appears in the kiosk menu,
so the cameras are one swipe and one tap away without any automation.

## Camera screensaver

Set the screensaver mode to **WebRTC Camera** to have the screensaver show a
camera view after the idle timeout, then pick which view under it. Touching
the screen wakes the kiosk as it does for every other mode: the grid is
scenery here, so it has no focus or close gestures of its own. The
screensaver's small corner clock stays off in this mode, so nothing sits
over the cameras.

A camera view you opened yourself still holds the screensaver off, and the
screensaver only ever shows the view configured for it, so the two never
fight over the display.

## Home Assistant

When MQTT publishing is enabled, every camera view creates a button on the
Kiosk Satellite device:

- **Show &lt;view name&gt;**
- **Close camera view**
- **Active camera view**, a sensor with the current view name and stable view
  ID attributes

Use the normal `button.press` action in a Home Assistant automation to show a
specific view. View buttons use stable internal IDs, so renaming a view does
not replace its Home Assistant entity.

## Sound

Playback is silent by default. **Play sound for a single camera** (Settings,
then Camera Streams, then Playback) plays a camera's audio when it is the
only one on screen: a view with one camera, or the camera focused with a tap
in a larger view. Made for the baby-monitor case, where the picture matters
less than the sound.

Grids with several cameras always stay silent, whatever the setting, since
several microphones playing over each other is noise rather than audio. The
camera also has to publish an audio track Kiosk Satellite can play: AAC and
Opus are the safe choices, while a camera that streams no audio, or a codec
the device cannot decode, simply plays silently.

## Auto-dismiss

**Auto-dismiss after** (Settings, then Camera Streams, then Playback) closes
an opened camera view on its own after the chosen time, from 30 seconds to 5
minutes. The default, 0, keeps a view up until something closes it. Made for
views opened in passing: a clap sequence or a corner tap brings the cameras
up for a look, and the dashboard comes back on its own instead of the grid
streaming until someone touches the screen.

The countdown restarts when a camera is focused, since a tap on the view is
someone using it, and it applies however the view was opened: a gesture, the
menu, MQTT, or the remote admin. The [camera screensaver](#camera-screensaver)
is unaffected, since it is the screensaver showing cameras rather than a view
over the dashboard.

## Stream codecs

Kiosk Satellite asks for H.264 (and VP8, VP9, AV1) and deliberately leaves
H.265 out of the request. Android WebViews advertise H.265 support whether or
not the device can decode it: the stream connects, video data arrives, and not
a single frame is ever decoded, which looks like a permanently blank camera
with nothing in the logs.

With H.265 out of the way, a Go2RTC server that has `ffmpeg` available
transcodes an H.265 camera to H.264 on its own and the camera plays. A server
without `ffmpeg` answers with an error instead, which the App Logs record. The
other fix is at the camera: many models can be switched to H.264, or expose an
H.264 substream that can be used in the view.

**Allow H.265 streams** (Settings, then Camera Streams, then Playback) turns
the restriction off for devices that really do decode H.265, such as recent
high-end tablets. A device that cannot decode it shows a blank image instead.

Whatever the setting, a stream that connects but decodes nothing says so on
the tile and writes a warning to the App Logs naming the codec, so a camera
that stays blank can be diagnosed from the logs alone.

## WebRTC and MSE

Go2RTC cameras stream over WebRTC first, for its near-realtime latency, and
fall back to MSE on their own when WebRTC does not work out: a stream that
connects and decodes nothing, a WebView that cannot do WebRTC at all (Fire
tablets), or repeated failed connections all switch the tile over
automatically, and the App Logs say so. MSE plays the same stream through
ordinary video buffering, which nearly every WebView handles, at the cost of
a second or two of delay.

**Prefer MSE over WebRTC** (Settings, then Camera Streams, then Playback)
flips the order for devices known to lack WebRTC, and is also the switch to
force MSE when testing. WebRTC then becomes the fallback. WHEP and Home
Assistant cameras are WebRTC by definition and are not affected.

## Performance

The camera player is created only while a view is visible. One WebView owns all
peer connections, camera audio is not negotiated unless
[a single camera's sound](#sound) is enabled, and hidden cameras are
disconnected in focus mode. Streams are released once the page has been hidden
for ten seconds, so a view left open when the panel turns off stops decoding,
and they come back when the screen does.

A brief ICE disconnect is given a few seconds to heal before the session is
renegotiated, so a flaky network costs a stutter rather than a black tile.

Four high-resolution streams can exceed the hardware decoder capacity of older
tablets. Prefer H.264 substreams at 720p or lower, with a reduced frame rate,
for multi-camera grids.
