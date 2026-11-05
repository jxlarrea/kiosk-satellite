# Device Camera

The device's physical camera supplies Home Assistant snapshots, motion detection and an optional RTSP video stream. Motion analysis stays on the device. RTSP lets go2rtc, Frigate or VLC watch the same camera over your network.

Note: This is different from the [Camera Streams](cameras.md) feature, which displays *other* cameras on your kiosk screen. This documentation covers the physical camera pointing out of the kiosk itself.

## Setup

Navigate to **Settings**, then **Camera** (this same tab is available in the remote admin). This entire feature sits behind a single master switch called **Enable camera**, which is off by default. Using the camera adds CPU load (roughly 10% while motion detection runs) and generates heat, so the app will not touch the camera until you explicitly opt in.

When you turn the switch on, the app will ask for the Android camera permission. If the switch is on but the permission is missing, a notice with a **Grant** button will appear right beneath it. If Android has blocked the app from asking for permissions, the notice will direct you to the system app settings instead. In the remote admin, the notice clarifies that the permission dialog will appear on the device screen itself.

For devices that were already using the **Dismiss on motion** feature before the Camera page existed, the camera was enabled automatically during the upgrade.

## Settings

| Setting | Default | Notes |
| --- | --- | --- |
| Enable camera | off | The master switch. All settings below depend on this being turned on. |
| Camera | Front | Choose Front or Back. This single choice applies to every camera feature. On devices with only one camera, this picker acts as a plain label. A USB or monitor webcam that is the only camera shows as External. |
| Snapshot resolution | 480p | Choose 480p, 720p, or 1080p on the 4:3 ladder. This maps to the nearest resolution the hardware offers. A single 480p frame is approximately 30 KB. |
| Disable snapshots on detection | off | Prevent automatic snapshots triggered by detection while keeping motion, face, presence and gesture detection working. Manual requests and continuous snapshots can still capture images. |
| Continuous snapshots | off | Capture a new snapshot for Home Assistant at a fixed, recurring interval. |
| Snapshot interval | 60 | The time in seconds between snapshots, ranging from 5 to 300. The first frame is captured immediately when the timer starts. |

## Snapshots

A frame is captured and published to the Camera entity under the following conditions:

* **On demand:** When you press the **Take camera snapshot** button in Home Assistant, or **Take snapshot** in the remote admin.
* **On an interval:** If **Continuous snapshots** is turned on.
* **On motion:** Once per motion session, unless **Disable snapshots on detection** is turned on. When motion is detected, it captures a single frame upon arrival, rather than a continuous stream of frames while someone stands there.
* **When requested:** Whenever Home Assistant asks the camera entity for a picture, such as when a dashboard card or the entity's more-info dialog shows it.
* **On a camera switch:** When you change **Camera** between front and back, so the entity shows what the new camera sees.

When Home Assistant connects, it needs one frame to mark the Camera entity available. KS sends a black frame without opening the camera, so the entity stays black until something requests a snapshot.

**Disable snapshots on detection** applies to automatic detection captures only. It leaves detection running and does not remove previously captured images. Continuous snapshots, Home Assistant image requests, manual snapshots and RTSP streaming have their own controls.

Only one capture can run at a time; if requests overlap, the system reports that a snapshot is already in progress. The camera is opened solely for the capture and is released immediately afterward. This means interval snapshots only use resources for the capture itself, rather than keeping the camera running permanently. 

Capturing a snapshot requires the app to be in the foreground. If a capture is attempted while another app is covering the kiosk, it will report that the camera is unavailable in the background.

Home Assistant fetches the latest frame from the camera entity whenever it needs one, and a fetch triggers a fresh capture. If the camera is disabled, the entity remains active but returns a "Camera off" frame.

## Motion Detection

The same camera session powers six different features, differing primarily in when the camera is actively running:

| Feature | Where it is found | When the camera runs |
| --- | --- | --- |
| Dismiss on motion | Screensaver settings | Only while the screensaver is showing. |
| Postpone screensaver on motion | Screensaver settings | Permanently while the screen is on. |
| Motion sensor | Camera settings | Permanently while the screen is on, including the Black screensaver. |
| Dismiss on face | Screensaver settings | Only while the screensaver is showing. |
| Postpone screensaver on face | Screensaver settings | Permanently while the screen is on. |
| Show fingers gesture | Gestures | Permanently while the screen is on. |

Here is how the detection features work:
* **Dismiss on motion** wakes the screen when someone approaches the sleeping kiosk. 
* **Postpone screensaver on motion** extends the wake time: movement in the room resets the idle timer, ensuring the screensaver waits until the room is actually empty (this requires Dismiss on motion to be active). 
* **Motion sensor** exposes motion directly as a Home Assistant `binary_sensor`, with no screensaver restrictions. A screensaver [schedule](screensavers.md) entry can override Dismiss on motion per time window, allowing an overnight Black entry to keep the camera completely off.
* **Dismiss on face** (the screensaver's [Face detection](screensavers.md#face-detection)) shares the same camera session. A lightweight on-device face detector analyzes the frames already sampled by the motion analyzer. This means the frame rate, camera selection, and startup delay settings apply to it as well. To save resources, the face model only runs when the motion grid detects a change, a face was recently seen, or the camera just opened. It runs at most twice a second on a single core, paced to ensure it never consumes more than about a fifth of a core, meaning an empty room costs zero inference processing. If both motion and face detection are on, motion takes precedence.
* The [Show fingers](gestures.md#show-fingers) gesture also shares this session, utilizing MediaPipe's hand landmarker under the same conditions, active whenever the screen is on and a hand mapping exists.

All six of these features pause during a voice interaction. From the moment a wake word is heard until Voice Satellite returns to listening mode, the camera remains open but the analyzer emits nothing and runs no models. During a voice turn, there are no motion ticks, no face sightings, and no hand reports. This ensures that someone talking to the satellite won't wake or postpone the screensaver, trip the motion sensor, or accidentally fire a hand gesture. It also frees up CPU cores for the voice processing. If a hand was tracked when the turn started, it is considered gone and must be raised again afterward. If a voice turn gets stuck and never ends on the page side, it releases the camera after three minutes.

What happens to the camera during a true screen off depends heavily on your Android version. Older versions generally leave the camera alone. Newer versions (observed on Android 16, and gradually rolling out since Android 11's while in use rules) will actively revoke camera access within seconds of the panel powering off from any app that is not currently visible on screen, unless that app holds a camera type foreground service. 

Kiosk Satellite attaches this specific service type to the [background listening](microphone.md) service whenever the camera permission is granted. Therefore, with background listening enabled, all three motion features can keep watching even through a true screen off. 

However, not every vendor respects this exemption. Samsung's One UI on Android 11 (such as the Galaxy Tab A 10.1 generation) will silently suspend the camera seconds after the panel powers off, even if background listening is on. The app detects the stalled frames, logs a warning in the Console, and brings the camera back online the moment the screen turns on, but motion cannot wake a truly dark panel on these specific devices. 

This same watchdog monitors a lit screen: if a camera opens but delivers no frames for ten seconds (this same Samsung generation can refuse a reopen at wake when racing the app's return to the foreground, again without an error), the app logs it and attempts to reopen after a short backoff rather than sitting dead. Without background listening enabled, camera revocation happens everywhere, and the camera will automatically rebind at screen on. 

To achieve a screen that *looks* off but keeps every camera feature working perfectly across all devices, use the **Black screensaver** (which sets the backlight to zero under a black overlay). Use this, or a scheduled Black entry, in situations where Fully Kiosk users would normally use a "fake screen off" feature.

The tuning for these features lives under **Camera > Motion Sensor**:

| Setting | Default | Notes |
| --- | --- | --- |
| Motion sensor | off | The **Motion** `binary_sensor` on the ESPHome device. |
| Clear after | 5 | The time in seconds without motion before the sensor reads as clear, ranging from 1 to 300. |
| Motion frame rate | 2 | The number of frames per second the camera analyzes. A lower number is lighter on the CPU; 2 is plenty to notice someone approaching. |
| Motion sensitivity | 70 | Ranges from 1 to 100. A higher number will trip on smaller movements. |
| Startup delay | 0 | The time in seconds to ignore motion immediately after the camera starts, ranging from 0 to 15. This is designed for devices whose physical camera moves as it opens. |

Detection is engineered to be CPU efficient and to work effectively in the dark. Frames are analyzed at the camera's lowest resolution, checking luminance only, on a coarse grid. Each cell learns its own baseline sensor noise, and the app requests the longest exposures the camera offers. This ensures a person crossing a dim room registers without the detector falsely tripping on camera noise. Whole frame light changes are discounted entirely, and the app temporarily suppresses detection for a couple of seconds around its own internal light changes (like screensaver start and stop, screen power toggles, brightness adjustments, and slide transitions) to prevent the kiosk from waking itself up.

**Startup delay** solves a specific hardware problem: devices whose camera physically moves as it opens (like a phone with a motorized pop up module). As the lens travels into position, that sweeping movement registers as a massive change across the whole frame, rather than a simple lighting shift. None of the standard discounting algorithms can filter it out, which causes the kiosk to immediately dismiss the screensaver that just started the camera. The delay counts from the very first frame and applies to every single path that starts the camera, not just screensavers. Schedule boundaries, the screen turning on, or a tuning change all trigger the same lens deployment. Frames are still tracked as a baseline while the delay runs, ensuring detection is fully sensitive the very second the delay expires. Leave it at 0 on a device with a fixed camera; a few seconds is usually enough for the hardware that requires it.

A Home Assistant occupancy, motion or presence sensor can stand in for the camera on the screensaver's motion settings. See [External Motion Sensor](screensavers.md#external-motion-sensor).

Two related switches are located elsewhere: with **Allow screensaver** turned on under [Lockdown Mode](kiosk.md), Dismiss on motion remains deactivated until the lock lifts. Additionally, the Sendspin player's full screen view only reacts to motion if its own **Dismiss "Now Playing" on motion** setting is enabled.

## Person Sensor

On a Meta Portal, **Camera > Person Sensor** exposes the Portal's built-in person detector to Home Assistant as a **Person** occupancy sensor. It does not use the app's camera or the Camera switch. See [Meta Portal](portal.md#person-sensor).

## RTSP & ONVIF Streaming

Open **Settings -> Camera -> RTSP & ONVIF Streaming**, after **Motion Sensor**, then turn on **Enable camera streaming**. The page reveals the stream settings and its URL. The Camera master switch and Android camera permission must also be enabled.

Tap the **Stream URL** or **ONVIF URL** field below **Port** to copy it. Only the URL for the selected protocol appears. **Stream Status** shows a green icon while streaming and a gray icon while idle. **Connected Clients** lists each viewer's IP address, player name when available, connection port, transport and connection duration. The status and client list refresh every two seconds.

| Setting | Default | Notes |
| --- | --- | --- |
| Streaming protocol | RTSP | Choose RTSP or ONVIF. Each protocol remembers its own port. Video, audio and authentication settings are shared. |
| Port | RTSP: 8554, ONVIF: 8080 | The port for the selected protocol. Choose a free port from 1024 to 65535. Switching protocols restores its saved port. |
| Resolution | 640 × 480, or the closest available size | Sizes supported by the camera capture mode and H.264 encoder at the selected frame rate and bitrate. Video follows the device orientation. Stream Status reports the actual video size. |
| Motion analysis while streaming | on | Turning this off pauses camera detection during streaming and takes snapshots from video frames. The notice under Resolution lists any additional sizes this allows. |
| Frame rate | 10 fps | Target rate from 5 to 30 fps. Actual delivery depends on the hardware and lighting. |
| Bitrate | 500 kbps | Target H.264 bitrate from 100 to 8000 kbps. |
| Encrypt stream | off | Encrypt commands, video and audio with RTSPS and ONVIF HTTPS on the selected streaming port. Requires a compatible client. |
| Include microphone audio | off | Add 16 kHz mono AAC audio at 32 kbps. Continues when Voice Satellite is muted or Lockdown Mode is on. |
| Require authentication | off | Reveals Username and Password. Both must be set before an authenticated listener starts. |

**Overlays** contains **Show date and time**, off by default. It adds the device date and time, including seconds, to the upper-left corner of the video using the device date format and 12/24-hour setting. Enabling it reveals **Black background**, also off by default, for a solid background that starts at the top-left corner with padding around the text. Both switches apply to a live stream without reconnecting viewers. Video-frame snapshots include the overlay. Separate camera snapshots and detection images do not.

Resolution stays local to each device because cameras in a fleet can support different sizes. Existing preset values and imported sizes map to the closest supported streaming size.

Use RTSP over TCP in your viewer. The stream contains H.264 video and optional AAC microphone audio. For go2rtc, add the URL as a stream source. Frigate can record the H.264 stream without transcoding it. Authentication uses RTSP Digest. Enter the credentials in your client or use `rtsp://USERNAME:PASSWORD@DEVICE_IP:8554/camera`, with URL encoding for special characters.

Choose **ONVIF** to let compatible clients discover the camera on your local network. The page shows the **ONVIF URL**, `http://DEVICE_IP:8080/onvif/device_service`. Use the selected port if you changed it. ONVIF exposes device information and a read-only media profile that points to the same RTSP stream. Configure video and audio in Kiosk Satellite settings. ONVIF requests use WS-Security UsernameToken authentication with the same credentials when authentication is enabled. Discovery uses WS-Discovery on multicast UDP port 3702. The camera announces when streaming starts and withdraws when it stops. ONVIF device information, discovery and stream profiles use the configured **Device name**. In Home Assistant, add the ONVIF integration and enable its automatic device search. This search uses WS-Discovery while the kiosk's `.local` name uses mDNS. Automatic discovery requires the client and camera to share a subnet or a WS-Discovery relay between their VLANs. An mDNS relay does not forward WS-Discovery traffic. If multicast discovery is unavailable, connect with the ONVIF URL. PTZ and ONVIF snapshots are not provided.

### Motion Events

**Motion Events** appears when the protocol is ONVIF. It reports motion to ONVIF clients, so NVRs such as UniFi Protect can record on motion instead of all the time.

| Setting | Default | Notes |
| --- | --- | --- |
| Send motion events | off | Report motion to ONVIF clients. |
| Motion source | Camera motion sensor | The sensor that reports motion: **Camera motion sensor**, **Person sensor** or **Home Assistant sensor**. Person sensor is listed only on devices that have one, such as the Meta Portal. |
| Motion sensor entity | none | Shown for **Home Assistant sensor**. Pick an occupancy, motion or presence sensor. Motion lasts while it reads on. |

Picking a source does not turn its sensor on. Turn on **Motion sensor** under **Camera > Motion Sensor** for the camera. Turn on **Enable person sensor** under **Camera > Person Sensor** for the person sensor. A note under **Motion source** says when the picked sensor is off. Camera motion clears after the motion sensor's **Clear after** delay, the same as its Home Assistant sensor.

An NVR keeps the stream open, so the camera only sees motion with **Motion analysis while streaming** on. A note under **Motion source** says when it is off.

Clients receive motion through ONVIF PullPoint subscriptions on two topics, `tns1:RuleEngine/CellMotionDetector/Motion` and `tns1:VideoSource/MotionAlarm`. The event service is listed in GetServices and GetCapabilities only while **Send motion events** is on. If a client added the camera before you turned it on, add the camera again so the client finds the event service.

One H.264 encoder serves up to four connected viewers. Hardware encoding is preferred. If no compatible hardware encoder can start, the app tries software encoding, which can use more CPU. It starts when the first authenticated viewer requests video and stops shortly after the last viewer disconnects. Enabling the listener alone does not open the camera or encode video. A recorder that stays connected keeps the encoder running. Slow viewers are disconnected instead of blocking the camera or growing an unlimited queue.

The camera sends video to a SurfaceTexture. A dedicated graphics worker draws those frames upright and unmirrored, matching snapshots, and limits video to the requested frame rate while motion analysis keeps its own cadence. A stream started in portrait uses portrait dimensions. Rotating during a stream fits the image inside its existing dimensions without stretching or cropping. Detection and snapshots continue sharing the camera session. Encoder selection and graphics failures appear in App Logs.

Microphone audio shares the capture used by native wake word detection and voice interactions, including the selected device, channel, gain and echo cancellation. The AAC encoder runs on a separate worker only while a viewer requests the audio track. Video-only viewers do not start it. Audio encoding and slow viewers cannot block microphone capture.

RTSP audio is independent of Voice Satellite mute and Lockdown Mode. Turn off **Include microphone audio** or RTSP Streaming to stop broadcasting the microphone. Android microphone permission still applies. While the dashboard captures audio through the browser, native capture yields and RTSP audio pauses. It resumes after the browser releases its last microphone track. Native voice interactions continue sharing capture without pausing RTSP audio. **Stream Status** reports audio activity, browser pauses and audio errors separately from video.

Motion and face detection keep their own analysis rates. A voice interaction pauses that analysis while video continues. Snapshots share the same camera session. Capture recovery can reduce the video size or use analysis frames for snapshots if the camera fails to start. Changing the camera or video settings disconnects viewers so they can reconnect with the new configuration.

The resolution list includes sizes the camera can supply in the selected capture mode and an H.264 encoder can handle at the current frame rate and bitrate. Checking these combinations does not open another camera session or interrupt a live stream. The notice below Resolution explains encoder exclusions and lists any additional sizes available with **Motion analysis while streaming** turned off. Camera sensor sizes alone do not guarantee that the device can encode video at those sizes.

**Motion analysis while streaming** is on by default. Turning it off pauses motion detection, face detection and hand gestures while viewers are connected. KS uses a single video output and takes snapshots from those video frames at the streaming resolution. Detection resumes after the streaming session ends. This can unlock larger resolutions on devices whose encoders support them. It does not bypass encoder limits. Changing this mode refreshes the choices and maps an unavailable saved resolution to the closest supported size. Resolution and analysis mode are local to each device and excluded from fleet sync.

The status row reports startup errors and the actual encoded resolution. Screen-off support follows the device's Android camera restrictions. A device that refuses camera access while dark may need to wake before a new viewer can connect.

## Home Assistant

With [ESPHome](esphome.md) **Expose kiosk entities** turned on, the camera adds several features to the Kiosk Satellite device:

| Entity | Type | Notes |
| --- | --- | --- |
| Camera | camera | Displays the latest snapshot. This snapshot entity stays `idle` even while the separate RTSP stream is active (read the **Camera enabled** switch for the camera status). While the camera is off, it displays a "Camera off" frame. The Screenshot camera exists alongside it on every device. |
| Take camera snapshot | button | Captures a fresh frame and hands it directly to Home Assistant. |
| Last camera snapshot | sensor | Shows exactly when the current frame was captured, formatted as a timestamp. This allows an automation to react to a fresh frame arriving. |
| Motion | binary_sensor | Reads motion for the duration of the configured **Clear after** window, then clears itself. Shows as unknown while the **Motion sensor** or the camera is off. |
| Camera enabled | switch | The remote master toggle. This exists whenever the hardware does, even with the camera off, allowing an automation to arm the camera only when a room wide sensor indicates someone is home. |
| RTSP Streaming | switch | Enables or disables RTSP using the saved stream settings. Appears under Configuration. |
| Screensaver motion detection | switch | The remote Dismiss on motion toggle. Pairs nicely with the Camera enabled switch for staged wake ups. |
| Screensaver face detection | switch | The remote Dismiss on face toggle. Motion maintains precedence on the device, allowing an automation to flip the motion switch to use faces by day and raw motion by night. |
| Camera facing | select | The remote **Camera** pick: Front or Back, applying to every camera feature at once. Switching it captures a fresh frame from the newly selected camera a moment later, allowing an automation to flip a phone to its back camera for use as a baby monitor, and back again. Like the switches, it functions even with the camera off. Only available on devices with both cameras. |

Disabling the camera keeps every one of these entities in place: the camera simply shows a "Camera off" frame, and the Motion sensor reads unknown until the camera is re-enabled. The entity list only changes if the hardware itself changes. This means an automation that arms the camera when someone is home and disarms it when they leave will never force the device to re-register with Home Assistant. On camera-less hardware, none of these entities will exist, though the Screenshot camera will be available either way.

The **RTSP Streaming** switch appears under **Configuration** and controls the same setting as the local and remote settings pages. Turning it off disconnects viewers and stops the RTSP server. Turning it on starts the listener using the saved settings. The Camera master switch and Android camera permission still apply.

To display the RTSP video in Home Assistant, add the [Generic Camera integration](https://www.home-assistant.io/integrations/generic/). Set **Stream Source** to the copied RTSP URL and **RTSP transport protocol** to **TCP**. Enter the RTSP username and password if authentication is enabled. You can leave **Still Image URL** empty when Home Assistant's stream integration is loaded. This creates a separate camera entity. The ESPHome Camera entity continues to provide JPEG snapshots because Home Assistant's ESPHome camera integration does not accept an RTSP stream source.

## Sharing the Camera

Android gives one session camera access at a time. Motion detection, snapshots and RTSP share that session so taking a snapshot does not reopen the camera or reset exposure. RTSP and ONVIF streaming stop while the camera sends in an [intercom video call](intercom.md#video-calls) and start again afterward.

Plugins with the `camera` capability receive frames from the same session. One plugin holds the camera at a time, and motion detection and the other camera features keep running while it does. A plugin with the `barcode` capability opens a full screen scanner that takes the camera for itself. Motion detection, face detection, hand gestures and RTSP pause while it is open, and snapshots fail. They resume when it closes. Both capabilities need **Enable camera** on. See [Camera and barcodes](https://github.com/jxlarrea/kiosk-satellite-plugins/blob/main/docs/camera.md) in the plugin SDK.

A few extremely low end devices cannot run motion analysis and JPEG capture in the same session. On those devices, motion wins, and snapshots will report the camera as busy while motion is running. If another app entirely is holding the camera open, captures will fail until that app lets go.

Some camera drivers never answer a JPEG capture and can leave the camera unusable until the device restarts. If a capture goes unanswered, KS stops requesting JPEGs from that camera and takes snapshots from its analysis frames instead. Restart the device if the camera still does not work. The rule stays until the system is updated.

## Hardware Notes

* **No usable camera:** Some custom ROMs (such as LineageOS ports on Echo Show hardware) have no camera support at all, even if the physical hardware is present. The Camera page will state this up front, and no camera entities will be published. If a device has a physical privacy shutter, closing it disconnects the camera completely and looks identical to the app.
* **Single camera:** The Front/Back picker turns into a simple label naming the one camera the device has. A USB or monitor webcam, like the one built into a monitor on a Raspberry Pi, is named External. The app checks for cameras when it starts, so restart it after connecting one. The app automatically handles devices whose ROM falsely advertises cameras they do not possess. It also handles camera HALs that pad their lists with a phantom camera whose lens facing cannot be read (common on cheap Unisoc tablets) by skipping the phantom and using the real camera. Failed captures will report a real error instead of simply hanging.

## The Remote Admin

The remote admin's Camera tab mirrors every setting available on the device and adds a **Latest snapshot** panel. This panel shows the newest frame, when it was taken, and provides a **Take snapshot** button. The panel displays the cached frame and refreshes itself automatically while open; merely viewing the panel never triggers a new capture. The same frame is available at `GET /api/camera/snapshot` for anything else that might want it (see the [Remote API](remote-api.md)).

## Privacy

* Motion analysis happens entirely locally on the device. Motion frames are never stored or transmitted; only the fact that motion occurred leaves the app.
* A plugin with the `camera` capability receives camera frames and can do anything with them that its code does. Install only plugins you trust. The barcode scanner names the plugin that opened it.
* Snapshots go to Home Assistant over ESPHome and to authorized remote admin clients. RTSP video is available only when enabled and requested by a viewer. Plain RTSP traffic is not encrypted, even with authentication enabled. Enable **Encrypt stream** to use RTSPS.
* The **Enable webcam access** setting located under Web Content is completely unrelated. That setting governs whether the dashboard web page itself may use the camera, not this specific feature.

## Encrypted streaming

In RTSP mode, **Encrypt stream** under **Camera > RTSP & ONVIF Streaming** changes the stream URL to `rtsps://DEVICE_IP:8554/camera`, using your configured port. Commands and interleaved video and audio all travel through TLS. Keep the viewer configured for TCP. Authentication remains a separate setting. Without authentication, anyone who can connect can still request the encrypted stream.

VLC 3.0.x supports the unencrypted RTSP stream but cannot open RTSPS URLs. See [TLS viewer compatibility](tls.md#camera-streaming) for an encrypted playback example with FFplay.

HTTPS and RTSPS use the same certificate. Manage it under **Device > TLS**, even when remote administration is off. Clients must support RTSPS and trust the certificate or verify its fingerprint. Certificate renewal or replacement disconnects encrypted viewers so they can reconnect with the new certificate. A certificate failure stops encrypted streaming instead of falling back to RTSP.

In ONVIF mode, the same switch enables HTTPS for the ONVIF service and RTSPS for its media stream. Both use the configured ONVIF port, 8080 by default. Discovery advertises the HTTPS service address. WS-Discovery metadata remains unencrypted on UDP port 3702. The viewer must support HTTPS ONVIF and RTSPS and accept the device certificate. RTSP tunneling over HTTP or HTTPS is not supported. The stream status and copied URL show the active protocol.

See [TLS encryption](tls.md) for the feature switches and certificate lifecycle.
