# Voice Match

Navigate to **Settings > Voice Satellite > Voice Match**.

With Voice Match, the kiosk knows who is talking and ends a voice command at the speaker's last word when the TV or another person keeps talking. Without it, a TV in the background can keep the assistant listening for many seconds after the command is over.

Voice Match runs on [Ground Control](ground-control.md), a Home Assistant app or a Docker container that does the voice work off the kiosk. Voice Match is off by default.

## Setup

1. Set up [Ground Control](ground-control.md) and turn on **Enable Ground Control**.
2. Turn on **Enable Voice Match**.
3. Tap **Open** on the **Ground Control app** row under **Settings > Ground Control** to add people and enroll them.

Voice Match works with Voice Satellite's native runtime and Home Assistant Assist pipelines.

## How a Command Ends

While the kiosk sends a command to Home Assistant, it sends the same audio to Ground Control:

- **Who is talking** is known about a second into the command, while the person is still talking.
- **When the speaker stops**, the kiosk ends the command right away instead of waiting for Home Assistant's own silence detection.
- **When someone else keeps talking**, such as a TV, the command ends at the speaker's last word.

If Ground Control is not reachable, commands work as they do without it.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Voice Match | off | Recognizes who is talking and stops listening when someone else takes over. Needs Ground Control. |
| Answer | Anyone | **Enrolled voices only** ignores the TV and guests: a command from a voice that is not enrolled is dropped. |
| Voice not enrolled | Stay quiet | With **Enrolled voices only**, what happens when someone else says the wake word: nothing, or the error chime. |
| End when someone else talks | on | Ends the command at the speaker's last word when another voice keeps talking. |
| Speaker sensor | on | Adds a Speaker sensor to this kiosk in Home Assistant. |
| Show who is talking | on | Puts the speaker's name before the command on the voice overlay, in their color. On a device with a light ring, the listening arc takes the color. |
| Allow enrollment here | on | Lets the Ground Control app record a person's voice with this kiosk's microphone. |

## Enrollment

A voice is recognized best on the kinds of device it was enrolled on, so enrollment always records with a kiosk's own microphone. Enroll each person once on every kind of device they talk to, such as once on an Echo Show and once on an Echo Dot.

1. In the Ground Control app, open **People** and choose **Enroll a person**, or open a person to enroll them on another kind of device.
2. Pick the kiosk to record on. Only kiosks with **Allow enrollment here** on are listed.
3. Read the text aloud for about 45 seconds while walking slowly around the room.

While the person reads:

- **On a kiosk with a screen**, the text to read shows full screen in the kiosk's language, with the progress ring in the person's color, a level meter and **Stop**. The text moves on as speech is counted. When another voice talks, a banner says that part is left out. A card says when the person is enrolled.
- **On a device without a screen**, such as an Echo Dot, the Ground Control app shows the text. The light ring sweeps and the wake chime plays at the start, the lights fill one by one as speech is counted, an amber flash means another voice was left out and two pulses with the done chime mean the voice is saved.

The wake word does not listen during an enrollment, so reading the text never starts a voice command. An announcement or a ringing timer stops the enrollment, the same as **Stop**. What was recorded is kept when it is at least 10 seconds of speech.

## Who Is Talking

With **Show who is talking** on, the name of the person talking shows before their command on the voice overlay, in their color from the Ground Control app, as soon as the voice is recognized. On a device with a light ring, such as an Echo Dot, the listening arc takes the same color.

## Speaker Sensor

The **Speaker** sensor on the kiosk's [ESPHome](esphome.md) device holds the name of the person talking. It is set as soon as the voice is recognized, before the command is done, and it is empty when a command starts or the voice is not enrolled.

**In automations**, a sentence trigger gets `trigger.device_id`, the kiosk that heard the command. Read that kiosk's Speaker sensor to act for the person:

```yaml
variables:
  speaker: >-
    {{ device_entities(trigger.device_id)
       | select('match', 'sensor\..*_speaker$')
       | map('states') | first | default('') }}
```

**For LLM conversation agents**, expose each kiosk's Speaker sensor to Assist and add the instructions block from the Ground Control app's Settings page to the agent's instructions. The agent reads the sensor with GetLiveContext on each request, so it knows who is talking even when the conversation continues from an earlier command. The agent needs the Assist API.
