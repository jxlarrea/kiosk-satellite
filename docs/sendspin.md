# Kiosk Satellite Sendspin Player

Kiosk Satellite can act as a [Sendspin](https://www.sendspin-audio.com/)
player: the synchronized multi-room audio protocol native to
[Music Assistant](https://www.music-assistant.io/). Enable it and the
tablet appears as a player in Music Assistant, named after the device
name, playing in sample-accurate sync with every other Sendspin speaker
in the house. Through the Music Assistant integration it also shows up in
Home Assistant as a `media_player` entity with full metadata, artwork and
volume control.

The player is headless by design: browsing and queueing happen in Music
Assistant (or its dashboard card), voice control through Voice Satellite.
While audio plays, the kiosk holds off its screensaver and dashboard view
rotation the same way it does for any other media interaction.

## Setup

Settings → **Sendspin Player** on the device, or the matching tab in the
remote admin:

| Setting | Default | Notes |
| --- | --- | --- |
| Enable Sendspin player | off | The master switch. |
| Server | | `host:port` of the Sendspin server (Music Assistant listens on port 8927). Leave empty to discover the server via mDNS; note that mDNS does not cross subnets, so set the address explicitly when the tablet and the server live on different networks. |
| Preferred audio codec | FLAC | FLAC (lossless), Opus (efficient) or PCM (uncompressed). The server makes the final choice from what the device offers. |

Music Assistant's Sendspin provider is built in and always enabled; no
server-side setup is needed.

## How it works

The player implements `player@v1` of the Sendspin protocol: a WebSocket
carries JSON control messages and timestamped binary audio chunks, a
burst-based NTP-style time exchange feeds a Kalman clock filter, and
chunks are scheduled against the DAC's own timestamps with sample-level
insert/drop drift correction. Decoding uses Android's MediaCodec (no
bundled codec libraries). Volume commands map to the device's media
volume, and hardware volume changes are reported back to the server.

The implementation is adapted from
[SendspinDroid](https://github.com/chrisuthe/SendspinDroid) (MIT), whose
license and attribution ship in the source tree.

## Troubleshooting

- **Player never appears in Music Assistant**: check the app log
  (Settings → App Logs) for `sendspin` lines; `connected as` means the
  handshake worked. If discovery finds nothing, set the server address
  explicitly (mDNS does not cross subnets or VLANs).
- **Audio is out of sync with other speakers**: give it a few seconds
  after connecting; the clock filter needs a moment to converge. A fixed
  per-device offset can be tuned from Music Assistant's player settings
  (sync adjustment), which the player applies as a static delay.
- **Dropouts on weak WiFi**: prefer the Opus codec; it needs a fraction
  of FLAC's bandwidth.
