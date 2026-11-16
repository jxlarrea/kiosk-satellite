# Adaptive Volume

Navigate to **Settings > Screen & Audio > Adaptive volume**.

Adaptive volume lowers the volume in a quiet room and brings it back in a loud one. Answers are quieter at night and louder while the TV or the kitchen is running, with no manual volume changes. It is off by default.

## How It Works

The room's noise level comes from the device's microphone. Only a level is read, never audio. It is the same level the [Ambient noise](esphome.md#ambient-noise) sensor reports to Home Assistant.

With wake word detection on, the level comes from the capture that is already open. With Voice Satellite or wake word detection off, turning adaptive volume on opens the microphone for the level alone, and Android shows its microphone indicator. The microphone closes again when the switch is turned off. If the microphone permission is missing, the device asks for it.

- **The room is measured only while the device is silent.** The microphone cannot tell the room from the device's own speaker, so any 5 seconds the device played into are dropped. A volume is picked before a sound starts and holds until the sound ends. Changes in the room during playback are not used.
- **The level rises after two loud readings in a row**, which takes about 10 seconds. A slammed door or a cough changes nothing.
- **The level falls by 1 dB every 5 seconds.** A quiet scene in a TV show does not pull the volume down with it. After a minute without a reading, such as after music, the next quieter reading is used as it is.
- **A muted satellite stays closed.** While Voice Satellite is muted the microphone is not opened and the last level is kept. Until the first reading every volume plays at its own slider.
- **Behind another app there may be no reading.** Android can silence the microphone of an app that is not in front. A silenced capture is skipped and the last level is kept.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| Enable adaptive volume | off | Lowers the volume as the room gets quieter. |
| Room noise | | The room's level as the curve follows it, in dBFS. It holds while the device plays. |
| Assistant | on | Voice responses, chimes, the timer sound and Voice Satellite announcements follow the room. |
| Media | off | Music, video and ESPHome announcements follow the room. The volume is set when playback starts and holds until it stops. After about 10 seconds of pause the room is read again. |
| Intercom | off | Calls follow the room. The volume is set when a call starts. The switch shows while the intercom is on. |

## Volume Curve

The curve has four points, from a quiet room to a loud one. Each point holds a room noise level in dBFS and a volume in percent for every volume that follows the room. The chart draws one line per volume through the same four noise levels, and marks the room's level right now.

The percentages on the curve apply to the **Assistant volume**, **Media volume** and **Intercom volume** sliders under **Settings > Screen & Audio**. At 100% a volume plays at its slider's level. At 50% it plays like the slider set to half, so a slider at 80% plays like 40%. The sliders, the volume entities in Home Assistant and the player volume in Music Assistant keep working: they set the level in a loud room and the curve lowers it from there.

- Between two points a volume moves in a straight line. Below the first point and above the last it stays at that point's volume.
- Drag a ring left or right to move its point's noise level for every volume. Drag it up or down to change that one volume.
- Tap a ring or the card under the chart to type the point's noise level and volumes. A noise level has to sit between the points before and after it, and a volume cannot be lower than on the point before or higher than on the point after.
- A new curve starts at 50% in a room at -60 dBFS and reaches 100% at -30 dBFS.

### Test Volume

The **Test volume** group under the curve plays an announcement at the volume the room picks right now. The curve can be changed and tested again without leaving the page.

| Row | What it plays |
| --- | --- |
| Test Assistant volume | A Voice Satellite announcement from Home Assistant at the **Assistant volume**. Needs Voice Satellite set up in Home Assistant. |
| Test Media volume | An [ESPHome announcement](esphome.md#announcements) at the **Media volume**, with the chime set under ESPHome > Announcements. Needs **Enable announcements** turned on there. |

Both are spoken by Home Assistant's text to speech, so they need the kiosk's Home Assistant connection. A button stays disabled until its feature is set up.

### Finding Your Noise Levels

What a quiet room reads depends on the device and its microphone. Read the **Room noise** row while the room is quiet, and again with the TV on or people talking. Put the first point at the quiet reading and the last point at the loud one.

A change to the gain under **Microphone settings** moves the reading, so set the gain first.

## What It Applies To

| Switch | What follows the room |
| --- | --- |
| Assistant | Text to speech, assistant answers, realtime conversations, chimes, the timer sound and Voice Satellite announcements |
| Media | Music from the Sendspin player, AirPlay and plugin players, DLNA audio and [ESPHome announcements](esphome.md#announcements) that play at the media volume |
| Intercom | The other kiosk's voice during a call |

These keep their own volume:

- Alarms, which ring at the **Alarm volume**
- The intercom's ring and the notification sound
- ESPHome announcements with a `volume` set in the action
- Sounds and video a dashboard page plays, touch sounds and audio from other apps

Sound from the last group is not played by Kiosk Satellite's own players, so it counts as room noise. The **Master volume** is never changed.

## Fleet

The **Enable adaptive volume** switch travels with the **Screen & Audio** category, the same as the Adaptive brightness switch. The **Assistant**, **Media** and **Intercom** switches and the curve are excluded from a new profile, because they depend on the device's microphone and the room it is in. A profile can bring any of them back. See [Fleet](fleet.md#excluded-by-default).
