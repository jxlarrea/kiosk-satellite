# Kiosk Satellite DLNA Renderer

Kiosk Satellite can act as a fully functional DLNA media renderer. By enabling a single switch, your kiosk appears in Home Assistant as a `media_player` entity, ready to display whatever you push to it right over your dashboard. It is the perfect tool for pushing content to the wall: show a live camera feed when the doorbell rings, display a guest WiFi QR code on demand, or stream your favorite music and photos directly from your media library.

## Setup

1. Open **Settings**, navigate to **DLNA Renderer** on the device (or the matching tab in the remote admin), and enable the renderer. That is the entire device side setup; no special permissions are required.
2. If Home Assistant and your device share the same subnet, the built in [DLNA Digital Media Renderer](https://www.home-assistant.io/integrations/dlna_dmr/) integration will discover the kiosk automatically. It will show up under Settings > Devices & Services as a discovered device, named after your kiosk.
3. For segmented networks (where the device and Home Assistant are on different VLANs), multicast discovery will not work. You can add the integration manually using the URL `http://<device-ip>:<port>/device.xml`. You can find the correct port listed under Settings > DLNA Renderer > Server port (this defaults to 2325 unless another service claimed it).

## What Plays

| Media | Notes |
| --- | --- |
| Images | Displays full screen until you stop it or tap the screen. Image entities (like a QR code or a camera snapshot) stay live, meaning when the entity updates in Home Assistant, the wall updates instantly. |
| Video | Supports HLS camera streams from Home Assistant, MP4/MKV/WebM files, and MJPEG cameras. The app uses the native platform player, so codec support exactly matches your specific Android device. |
| Audio | Supports MP3, FLAC, AAC, OGG, and WAV files, displaying a title card while playing. If you enable **Keep audio in the background**, audio will play without interrupting the screen at all. Your dashboard or screensaver stays exactly as it was, which is perfect for TTS announcements or background music. |

Playback fully integrates with Home Assistant. Play, pause, seek, stop, volume, and mute controls all work directly from the entity. A quick tap on the kiosk screen dismisses the media and reports a "stop" state back to Home Assistant. Media that finishes playing dismisses itself automatically, and a loading screen hides the buffering phase of stream startups. While media is actively playing on screen, the screensaver pauses and only returns once playback finishes.

## Automation Examples

Here is how you can show a camera when the doorbell rings, then automatically return to the dashboard thirty seconds later:

```yaml
- trigger:
    - platform: state
      entity_id: binary_sensor.doorbell_pressed
      to: "on"
  action:
    - action: media_player.play_media
      target:
        entity_id: media_player.kitchen_kiosk
      data:
        media_content_type: application/vnd.apple.mpegurl
        media_content_id: media-source://camera/camera.front_door
    - delay: "00:00:30"
    - action: media_player.media_stop
      target:
        entity_id: media_player.kitchen_kiosk
```

You can also cast anything directly from the Home Assistant media browser. Just open the browser, select the kiosk as your playback target, and hit play.

## Troubleshooting

* **The kiosk is not discovered:** Home Assistant and the device are likely on different subnets. You will need to add the DLNA Digital Media Renderer integration manually using `http://<device-ip>:<port>/device.xml`. Grab the correct port from Settings > DLNA Renderer > Server port.
* **The renderer is on a port you did not expect:** Port 2325 was likely taken by another service on your device, so the app stepped up to the next available one. The **Server port** setting always displays the active port. On a plain HTTP instance, this is completely normal because the secure context proxy reserves 2325. You can type a different port to move it manually, or clear the field to let the app pick again.
* **The renderer does not start:** This means no ports were free from your configured port upwards. The App Logs will detail the failure. Simply set a different starting port in the DLNA Renderer settings.
* **A camera takes a long time to appear:** Home Assistant prepares the camera's HLS stream before sending anything to the kiosk, which can take 10 to 15 seconds for a cold start. Enabling **Preload stream** in your Home Assistant camera settings will make casting nearly instantaneous.
* **Camera streams lag behind live:** HLS inherently runs several seconds behind real time. If you need a completely live view, navigate the dashboard to a view containing a WebRTC camera card instead, as the kiosk's browser plays those with near zero latency.
* **Media browser hides items:** The renderer automatically advertises exactly what it can decode, and Home Assistant filters the list accordingly. It is better to hide incompatible media than to let it fail on screen.
* **A video shows an error icon:** The error card will state the reason, and the App Logs will contain the full player error under the `dlna` tag. If it says "This device cannot decode this video", the device's hardware decoder outright refused the file. The app already attempts a retry workaround for devices like the Echo Show 8 or Lenovo tablets; if it still fails, the device genuinely cannot play that specific format.