# Equalizer

Navigate to **Settings > Screen & Audio > Equalizer**.

The equalizer shapes the sound of the device's speaker. It is off by default and every band starts at 0 dB.

## Bands

| Band | What it changes |
|---|---|
| **100 Hz** | Bass. Small speakers distort early with a boost here. |
| **300 Hz** | Low mids. A cut takes out a boxy or boomy sound. |
| **1 kHz** | Mids, where most of a voice sits. |
| **3 kHz** | High mids. A boost makes speech clearer. |
| **10 kHz** | Treble. |

Each band moves from -12 to +12 dB. A change applies to what is playing, so you can set the bands by ear while music plays.

## What It Applies To

The equalizer applies to everything Kiosk Satellite plays itself:

- Music from the Sendspin player, AirPlay and plugin players
- Text to speech, assistant answers and realtime conversations
- Chimes, alarms and announcements
- Intercom calls
- DLNA audio

It does not apply to video, sounds a dashboard page plays, touch sounds or audio on a Bluetooth headset's call route. Music that another app or the device itself plays, such as an Echo used as a Bluetooth speaker, is not equalized either.

## Automatic Preamp

A boost makes the signal louder. Most tablets, phones and smart displays have a small speaker and an amplifier that limits near full volume, so a boosted band can distort.

**Automatic preamp** lowers the whole signal by the largest boost the bands add up to. With 100 Hz at +6 dB, everything plays 6 dB lower and the bass comes out at its original level. Cuts need no preamp. It is on by default.

Turn it off only if playback gets too quiet and the speaker handles the boost at the volume you use. Without it, a bass boost at a high master volume is the setting most likely to distort.

## Echo Cancellation

The equalizer does not affect [echo cancellation](microphone.md). It runs before the point where the echo canceller takes its copy of the playback, so the canceller always compares the microphone against the equalized sound. You can move a band while music plays and the wake word keeps working over it.

Distortion in the device's own amplifier is the one thing that does hurt echo cancellation, because the canceller cannot see it. Automatic preamp prevents that as well.

## Fleet Management

The equalizer settings stay on each device. [Fleet Management](fleet.md) does not sync them, since they correct one device's speaker.
