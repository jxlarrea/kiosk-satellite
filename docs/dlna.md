# Kiosk Satellite DLNA Renderer

Kiosk Satellite can act as a DLNA media renderer: enable one switch and
the kiosk appears in Home Assistant as a `media_player` entity that
displays whatever you push to it, full screen over the dashboard. Images,
video, audio, live camera streams, the media browser's library, all of it
driven by ordinary `media_player.play_media` calls from automations, or
by any DLNA controller app on the network.

This is the "push content to the wall" feature: a doorbell automation
that shows the camera, a dashboard button that puts the guest WiFi QR
code on screen, photos from the HA media library.

## Setup

1. Settings → **DLNA Renderer** on the device (or the matching tab in the
   remote admin) → enable the renderer. That is the whole device side; no
   permissions are involved.
2. In Home Assistant, the kiosk is discovered automatically by the
   built-in [DLNA Digital Media Renderer](https://www.home-assistant.io/integrations/dlna_dmr/)
   integration when Home Assistant and the tablet share a subnet, and
   appears under Settings → Devices & Services as a discovered device
   named after the kiosk's device name.
3. On segmented networks (the tablet and Home Assistant on different
   VLANs), discovery multicast does not cross over: add the integration
   manually instead, with the URL `http://<device-ip>:2325/device.xml`.

## What plays

| Media | Notes |
| --- | --- |
| Images | Shown full screen until stopped or tapped. Image entities (a QR code, a snapshot) stay live: when the entity updates, the wall updates. |
| Video | HLS camera streams from Home Assistant, MP4/MKV/WebM files, MJPEG cameras. Decoding is the platform player's, so codec support matches the device. |
| Audio | MP3, FLAC, AAC, OGG, WAV; shown as a title card while playing. |

Playback answers to Home Assistant: play, pause, seek, stop, volume and
mute all work from the entity. A tap on the kiosk screen dismisses the
media (reported back to HA as a stop), media that ends dismisses itself,
and a loading screen covers stream startup. While something plays, the
screensaver stands down and returns afterwards.

## Automation examples

Show a camera when the doorbell rings, then return to the dashboard:

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

Anything browsable in Home Assistant's media browser can also be sent
directly: open the media browser, pick the kiosk as the playback target,
and play.

## Troubleshooting

- **The kiosk is not discovered**: Home Assistant and the tablet are
  probably on different subnets. Add the DLNA Digital Media Renderer
  integration manually with `http://<device-ip>:2325/device.xml`.
- **A camera takes long to appear**: Home Assistant prepares the camera's
  HLS stream before anything reaches the kiosk, which can take 10 to 15
  seconds for a cold stream. Enabling **Preload stream** in the camera's
  Home Assistant settings makes casting it near-instant.
- **Camera streams lag behind live**: HLS runs several seconds behind by
  nature. For a real-time view, navigate the dashboard to a view with a
  WebRTC camera card instead; the kiosk's browser plays those live.
- **Media browser hides items** as incompatible: the renderer advertises
  what it can decode, and Home Assistant filters accordingly. Anything
  the device genuinely cannot play is better hidden than failing.
