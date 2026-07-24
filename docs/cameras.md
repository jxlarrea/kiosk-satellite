# WebRTC Cameras

Kiosk Satellite can show up to four low-latency WebRTC cameras in a
full-screen view. Camera streams come from Go2RTC or from a direct WHEP
endpoint.

## Add a Go2RTC server

Open Settings, then WebRTC Cameras, and select **Add Go2RTC server**.

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

Raw RTSP URLs are not supported by the app player. Add the RTSP source to
Go2RTC first, then reference its stream name.

For a Go2RTC camera, an optional fullscreen stream can be configured. Use a
lower-resolution substream for the grid and a higher-resolution stream for
fullscreen focus.

## Create a view

A view contains one to four cameras. Camera order is preserved. The view's
**Show camera names** option controls whether labels appear over the video.

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

## Performance

The camera player is created only while a view is visible. One WebView owns all
peer connections, camera audio is not negotiated, and hidden cameras are
disconnected in focus mode. Streams are released once the page has been hidden
for ten seconds, so a view left open when the panel turns off stops decoding,
and they come back when the screen does.

A brief ICE disconnect is given a few seconds to heal before the session is
renegotiated, so a flaky network costs a stutter rather than a black tile.

Four high-resolution streams can exceed the hardware decoder capacity of older
tablets. Prefer H.264 substreams at 720p or lower, with a reduced frame rate,
for multi-camera grids.
