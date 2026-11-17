# Voice Match

Navigate to **Settings > Voice Satellite > Voice Match**.

Voice Match recognizes who is talking to the kiosk and ends a voice command at the speaker's last word when the TV or another person keeps talking. Without it, a TV in the background can keep the assistant listening for many seconds after the command is over.

It needs [Kiosk Satellite Voice Match](https://github.com/jxlarrea/kiosk-satellite-voice-match), a Home Assistant app or a Docker container that does the voice work off the kiosk. Voice Match is off by default.

## Setup

1. Install Kiosk Satellite Voice Match as a Home Assistant app, or run its Docker container.
2. Turn on **Enable Voice Match**. Kiosks on the same network find the service on their own. For a service on another network, enter its address, such as `192.168.1.10:10900`.
3. The kiosk signs in with the Home Assistant token it already has. The status row under the switch shows **Connected** and the people enrolled.

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
