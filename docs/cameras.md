# Camera Streams

Kiosk Satellite can display up to twelve cameras in a full screen view. Your camera streams can come directly from Home Assistant, a Go2RTC server, or a direct WHEP endpoint. The app supports playback over WebRTC, MSE, HLS, or MJPEG. WebRTC is the top choice because of its near realtime latency. For cameras or devices that do not support WebRTC, the app automatically switches to MSE (for Go2RTC cameras), or HLS and MJPEG (for Home Assistant cameras) so you always get a picture.

## Import Cameras from Home Assistant

Go to **Settings**, then **Camera Streams**, and select **Import cameras from Home Assistant**. Kiosk Satellite will ask your connected Home Assistant instance (version 2024.11 or newer) for every `camera.*` entity and add them automatically. 

Entities that support WebRTC will play using Home Assistant's built in WebRTC signaling over your existing connection. Cameras that only offer HLS (which covers most cameras without a dedicated WebRTC provider) will play [over HLS](#home-assistant-cameras-and-hls). For entities that cannot stream video at all, like UniFi package cameras, the app will play them [over MJPEG](#mjpeg-cameras). There is no need to configure Go2RTC URLs, ports, or WHEP. If you can see the picture in the Home Assistant frontend, it will work here.

If you run the import again later, the app merges any new entities while keeping your custom camera names and view layouts intact. It also updates the available stream types for each entity and flags any cameras that have disappeared or stopped streaming. Because Home Assistant provides its ICE server configuration to the WebRTC player, streams running through Home Assistant Cloud work perfectly as well.

## Add a Go2RTC Server

Go to **Settings**, then **Camera Streams**, and select **Add Go2RTC server**. Enter the base URL of a Go2RTC server that your device can reach on the network, like this:

```text
http://192.168.1.10:1984
```

The app fully supports basic authentication and self-signed TLS certificates. Once you save the server, tap **Import streams**. Kiosk Satellite will read your stream names from `/api/streams` without copying the actual source URLs into the camera views.

The Go2RTC API has access to powerful server features, so it is a good idea to protect it with authentication. Whenever possible, restrict access to just the paths the kiosk actually needs:

```yaml
api:
  allow_paths: [/api/streams, /api/webrtc]
```

Once imported, streams stay in Kiosk Satellite until you manually delete them. Running the import again will pull in new stream names while preserving your existing camera names and view arrangements. Any streams that are no longer available in Go2RTC will simply be marked as missing.

## Add a Camera Manually

If you prefer to add a camera manually, you can reference:
* A specific stream name from a configured Go2RTC server.
* A direct HTTP or HTTPS WHEP endpoint.
* A Home Assistant `camera.*` entity. The app will attempt to stream this via WebRTC if supported, and fall back to HLS if not, just like the automatic import.

Please note that raw RTSP URLs are not supported directly by the app player. To use an RTSP source, add it to Go2RTC first, and then reference that stream name in the app.

For Go2RTC cameras, you can configure an optional full screen stream. This lets you use a lightweight, lower resolution substream for the grid view, but automatically switch to a high resolution stream when you tap to focus on it full screen.

## Create a View

A view holds anywhere from one to twelve cameras, displayed in the exact order you set. In the view editor, your selected cameras appear in a list. You can add or remove cameras, and reorder them by dragging the handles (or tapping the arrows on a touch screen). If you want text labels to appear over the video feeds, toggle the **Show camera names** option.

The layout adapts automatically based on how many cameras you add:
* **One camera** fills the entire display.
* **Two cameras** split into columns in landscape mode, or rows in portrait mode.
* **Three cameras** arrange into a balanced, orientation aware layout.
* **Four cameras** create a perfect 2 by 2 grid.
* **Larger counts** build balanced grids where the first few cameras receive the largest tiles, automatically adjusting for portrait orientation.

If you are looking at a multi-camera grid, tap any camera to focus on it. To save resources, Kiosk Satellite will temporarily close the connections to the other cameras while you are focused on one. To go back to the grid, press Back, use the back swipe gesture, or double tap the focused video. 

To close the grid entirely and return to your Home Assistant dashboard, simply press Back, use the back swipe gesture, or double tap any camera in the grid. 

If you trigger a voice interaction, the app will temporarily hide the camera view so you can see the Voice Satellite interface. This includes any follow up conversation turns. Once the voice interaction finishes, your camera view and any previously focused camera will automatically reappear. However, if you explicitly close or change the view during that time, it cancels the automatic return.

## The Default View

Every installation includes a view named **Default**. This view cannot be deleted, but you are free to leave it empty if you do not want to use it. As soon as you add at least one camera to it, a **Default Camera View** button will appear in the main kiosk menu. This keeps your primary cameras just one swipe and a tap away, completely independent of any Home Assistant automations.

## Camera Screensaver

You can set your screensaver mode to **Camera Streams** to display your cameras after the device goes idle. Once enabled, open the settings page to choose which views to feature. The **Camera views** list dictates the rotation order, and **Seconds per camera view** sets how long each grid stays on screen before transitioning. This timer starts the moment the video actually appears. If you only select one view, it will simply stay on screen without rotating.

To keep performance smooth, the app completely shuts down the current grid before starting the streams for the next one. This ensures two views are never playing simultaneously, though it does result in a brief moment of a blank screen during the transition. 

Just like any other screensaver mode, touching the screen wakes the kiosk up. Because the cameras are acting as background scenery here, you cannot tap to focus or use gestures to close them. The screensaver's small corner clock is also hidden in this mode to ensure nothing obstructs the video feeds. 

By default, the **Mute all views** toggle is turned on. This ensures the screensaver remains completely silent, even if you have audio enabled for single camera views elsewhere. Any sound settings you configured will still apply normally when you open a camera view manually.

If you manually open a camera view, it prevents the screensaver from turning on at all. The screensaver also strictly sticks to its own configured views, ensuring the manual player and the screensaver never fight for control of the display.

## Home Assistant Integration

If you have **Expose kiosk entities** enabled in [ESPHome](esphome.md), every camera view you create generates a corresponding entity on the Kiosk Satellite device in Home Assistant:
* A **Show &lt;view name&gt;** button.
* A **Close camera view** button.
* An **Active camera view** sensor that reports the name of the currently visible view.
* A **Camera view** dropdown selector that lets you open any view by name, or set it to **Closed**.

You can use a standard `button.press` action in your Home Assistant automations to trigger a specific view. Since view buttons use stable internal IDs, renaming a view in the app will not break your existing Home Assistant entities or automations.

## Sound

Camera playback is completely silent by default. If you navigate to **Settings**, then **Camera Streams**, and look under **Playback**, you can enable **Play sound for a single camera**. This allows audio to pass through only when a single camera is on screen. This applies to a view built with only one camera, or when you tap to focus a single camera from a larger grid. This is incredibly useful for baby monitor setups where hearing the room is just as important as seeing it.

Multi-camera grids will always remain silent regardless of this setting, preventing the chaotic noise of several microphones playing over each other. Keep in mind that your camera must publish an audio track the app can actually decode. AAC and Opus are the most reliable choices. If a camera streams no audio, or uses an unsupported codec, it will simply play in silence.

## Zoom

The **Pinch to zoom a single camera** feature (found under **Settings** > **Camera Streams** > **Playback**) is enabled by default. Whenever a single camera fills the display, you can use two fingers to scale the picture up to five times its normal size. Once zoomed in, use one finger to pan around the image, and double tap to reset it. Because this zooming happens entirely on the screen, it places no extra demand on the camera itself and works flawlessly across any transport protocol. It is perfect for wide angle lenses where the subject is tucked away in a corner of the frame.

Zooming only works on single camera views or when you have tapped to focus a specific camera from a grid. It is disabled on multi-camera grids to prevent gesture confusion across different video tiles. 

If you close the view or leave focus mode, the zoom resets automatically. Note that while you are zoomed in, the standard back swipe gesture is repurposed for panning around the image. To back out, you will need to double tap: the first double tap removes the zoom, and the second double tap closes the view or sends you back to the grid. The app prevents you from dragging the picture past its physical edges. Also, zooming is disabled on the [camera screensaver](#camera-screensaver) since those feeds act purely as background scenery.

## Auto-dismiss

The **Auto-dismiss after** setting (located in **Settings** > **Camera Streams** > **Playback**) automatically closes a camera view after a specified amount of time, ranging from 30 seconds to 5 minutes. The default setting is 0, which keeps the view open indefinitely until you close it manually. This is highly recommended for quick check-ins. For example, if a custom clap sequence or corner tap brings up your cameras, auto-dismiss ensures the device naturally returns to your Home Assistant dashboard instead of streaming video forever.

The countdown timer automatically resets if you tap to focus a camera, as that indicates you are actively using the view. This timer applies no matter how the view was opened, whether by gesture, the app menu, Home Assistant automation, or the remote admin. The [camera screensaver](#camera-screensaver) ignores this setting completely, as it is designed to run continuous video loops while idle.

## Stream Codecs

When requesting a stream, Kiosk Satellite specifically asks for H.264, VP8, VP9, or AV1, deliberately excluding H.265. This is because Android WebViews often claim to support H.265 even when the physical hardware cannot decode it. When this happens, the stream connects and receives data, but fails to render a single frame. This results in a permanently blank screen with no errors in the logs to explain why.

By purposefully blocking H.265, a Go2RTC server equipped with `ffmpeg` will automatically transcode the feed to H.264 so it plays properly. If the server lacks `ffmpeg`, it will throw a clear error that Kiosk Satellite records in the App Logs. Alternatively, you can often fix this at the source by switching your camera's output to H.264, or by tapping into a dedicated H.264 substream.

If you are running the app on a newer, high end device that legitimately supports H.265 decoding, you can toggle **Allow H.265 streams** (found under **Settings** > **Camera Streams** > **Playback**). Just be aware that if your device cannot actually handle it, you will get a blank image.

Regardless of your settings, if a stream connects but fails to decode any frames, the app will display a warning directly on the camera tile and write a detailed log entry naming the problematic codec. This makes diagnosing blank cameras incredibly straightforward.

## WebRTC and MSE

Go2RTC cameras always attempt to stream over WebRTC first to take advantage of its near realtime latency. If WebRTC fails, they automatically fall back to MSE. A failure could mean a stream that connects but decodes nothing, a device that lacks WebRTC support entirely (like Amazon Fire tablets), or just repeated connection drops. When the app switches to MSE, it notes the change in the App Logs. MSE plays the video stream using standard buffering, which works on virtually every device, though it does introduce a second or two of delay.

If you are using a device you know struggles with WebRTC, you can enable **Prefer MSE over WebRTC** (**Settings** > **Camera Streams** > **Playback**). This reverses the priority, making MSE the default and WebRTC the fallback. It is also a great tool for testing. Note that this setting does not affect WHEP cameras (which are strictly WebRTC) or Home Assistant cameras (which use [their own fallback method](#home-assistant-cameras-and-hls)).

## Home Assistant Cameras and HLS

Most Home Assistant cameras lack a native WebRTC path unless you have specifically configured a provider like go2rtc. Because of this, they default to streaming over HLS, which is the exact same method the standard Home Assistant dashboard uses. Kiosk Satellite simply requests the stream and plays it using normal video buffering. This approach is highly compatible and works beautifully on almost any device, including Fire tablets. The only downside is a typical HLS latency of a few seconds. For this reason, if a camera supports both protocols, the app will always try WebRTC first and only fall back to HLS if necessary.

Because the app plays whatever stream Home Assistant provides, the H.265 decoding rules mentioned earlier still apply. If the device cannot decode the format, the camera tile will display a clear error message instead of sitting silently blank.

You can toggle **Prefer HLS over WebRTC** (**Settings** > **Camera Streams** > **Playback**) to reverse the default priority for Home Assistant cameras that support both. This is the exact counterpart to the MSE toggle, useful for testing or for older devices that struggle with WebRTC feeds.

To make things easy, every camera listed in your settings menu will clearly display which formats it supports, letting you verify its transport options at a glance.

## MJPEG Cameras

Every camera entity in Home Assistant is capable of serving its picture as an MJPEG stream, regardless of whether it supports true video streaming. Kiosk Satellite uses this as a foolproof transport of last resort. If a camera fails on both WebRTC and HLS, it will automatically switch to MJPEG. For cameras that cannot stream video at all, like UniFi package cameras or other stills only entities, the app will use MJPEG right from the start.

With MJPEG, the frame rate depends entirely on what the camera can push, and there is absolutely no audio support. Because Home Assistant has to transcode the stream on the server side, Kiosk Satellite will always try the more advanced protocols first to save resources.

## Performance

To optimize resources, the camera player is only created when a view is actually visible on screen. A single WebView handles all the peer connections to keep overhead low. Camera audio is completely ignored during negotiation unless [sound is explicitly enabled](#sound) for a single camera, and any hidden cameras in a grid are immediately disconnected when you tap to focus on one. If the camera page is hidden for more than ten seconds (like when the screen turns off), the app releases the streams entirely to save power. They will instantly reconnect the moment the screen turns back on.

If the network connection drops briefly, the app gives it a few seconds to heal before trying to renegotiate the session. This means a spotty network connection might cause a quick stutter instead of a completely black tile.

Keep in mind that displaying four high resolution streams simultaneously can easily overwhelm the hardware decoders on older tablets. For multi-camera grids, it is highly recommended to use H.264 substreams set to 720p or lower, ideally with a reduced frame rate.