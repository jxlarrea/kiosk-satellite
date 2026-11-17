# Voice Match

Navigate to **Settings > Voice Satellite > Voice Match**.

Voice Match recognizes who is talking to the kiosk and ends a voice command at the speaker's last word when the TV or another person keeps talking. Without it, a TV in the background can keep the assistant listening for many seconds after the command is over.

It needs [Kiosk Satellite Voice Match](https://github.com/jxlarrea/kiosk-satellite-voice-match), a Home Assistant app or a Docker container that does the voice work off the kiosk. Voice Match is off by default.

## Setup

1. Install Kiosk Satellite Voice Match as a Home Assistant app, or run its Docker container.
2. Turn on **Enable Voice Match**. Kiosks on the same network find the service on their own. For a service on another network, enter its address, such as `192.168.1.10:10900`.
3. The kiosk signs in with the Home Assistant token it already has. The status row under the switch shows **Connected** and the people enrolled.
4. Tap **Open** on the **Voice Match app** row to add people and enroll them. As a Home Assistant app, it opens the app's page in Home Assistant. A Docker container opens its own web page.

Voice Match works with Voice Satellite's native runtime and Home Assistant Assist pipelines.

## How a Command Ends

While the kiosk sends a command to Home Assistant, it sends the same audio to Voice Match:

- **Who is talking** is known about a second into the command, while the person is still talking.
- **When the speaker stops**, the kiosk ends the command right away instead of waiting for Home Assistant's own silence detection.
- **When someone else keeps talking**, such as a TV, the command ends at the speaker's last word.

If Voice Match is not reachable, commands work as they do without it.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Voice Match | off | Recognizes who is talking and stops listening when someone else takes over. |
| Address | empty | Empty finds Voice Match on the network. Enter `host:port` for a service on another network. |
| Answer | Anyone | **Enrolled voices only** ignores the TV and guests: a command from a voice that is not enrolled is dropped. |
| Voice not enrolled | Stay quiet | With **Enrolled voices only**, what happens when someone else says the wake word: nothing, or the error chime. |
| End when someone else talks | on | Ends the command at the speaker's last word when another voice keeps talking. |
| Speaker sensor | on | Adds a Speaker sensor to this kiosk in Home Assistant. |
| Show who is talking | on | Puts the speaker's name before the command on the voice overlay, in their color. On a device with a light ring, the listening arc takes the color. |
| Allow enrollment here | on | Lets the Voice Match app record a person's voice with this kiosk's microphone. |

## Enrollment

A voice is recognized best on the kinds of device it was enrolled on, so enrollment always records with a kiosk's own microphone. Enroll each person once on every kind of device they talk to, such as once on an Echo Show and once on an Echo Dot.

1. In the Voice Match app, open **People** and choose **Enroll a person**, or open a person to enroll them on another kind of device.
2. Pick the kiosk to record on. Only kiosks with **Allow enrollment here** on are listed.
3. Read the text aloud for about 45 seconds while walking slowly around the room.

While the person reads:

- **On a kiosk with a screen**, the text to read shows full screen in the kiosk's language, with the progress ring in the person's color, a level meter and **Stop**. The text moves on as speech is counted. When another voice talks, a banner says that part is left out. A card says when the person is enrolled.
- **On a device without a screen**, such as an Echo Dot, the Voice Match app shows the text. The light ring sweeps and the wake chime plays at the start, the lights fill one by one as speech is counted, an amber flash means another voice was left out and two pulses with the done chime mean the voice is saved.

The wake word does not listen during an enrollment, so reading the text never starts a voice command. An announcement or a ringing timer stops the enrollment, the same as **Stop**. What was recorded is kept when it is at least 10 seconds of speech.

## Who Is Talking

With **Show who is talking** on, the name of the person talking shows before their command on the voice overlay, in their color from the Voice Match app, as soon as the voice is recognized. On a device with a light ring, such as an Echo Dot, the listening arc takes the same color.

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

**For LLM conversation agents**, expose each kiosk's Speaker sensor to Assist and add the instructions block from the Voice Match app's Settings page to the agent's instructions. The agent reads the sensor with GetLiveContext on each request, so it knows who is talking even when the conversation continues from an earlier command. The agent needs the Assist API.
