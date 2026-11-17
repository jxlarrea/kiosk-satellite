# Voice Match

Navigate to **Settings > Voice Satellite > Ground Control Voice Match**.

With Voice Match, the kiosk knows who is talking and ends a voice command at the speaker's last word when the TV or another person keeps talking. Without it, a TV in the background can keep the assistant listening for many seconds after the command is over.

Voice Match runs on [Ground Control](ground-control.md), a Home Assistant app or a Docker container that does the voice work off the kiosk. Voice Match is off by default.

## Setup

1. Set up [Ground Control](ground-control.md) and turn on **Enable Ground Control**.
2. Turn on **Enable Voice Match**.
3. Tap **Open** on the **Ground Control app** row under **Settings > Ground Control** to add people and enroll them.

Voice Match works with Voice Satellite's native runtime and Home Assistant Assist pipelines.

## Only the User's Voice

With **Leave other voices out** on, everything the microphone hears goes to Ground Control, and Home Assistant or the realtime assistant hears only the person who said the wake word:

- **The user is whoever said the wake word.** The kiosk sends the wake word to Ground Control, so a TV talking right after it is never taken for the user. An enrolled person is recognized from it. Without a wake word, such as a conversation started from the screen, the user is whoever of the enrolled people talks.
- **Other voices are left out.** With a TV going before, between and after the user's words, the assistant hears only the user's words, as if the room was quiet.
- **The command ends when the user stops.** The kiosk ends it once the user has been quiet for 0.7 seconds, whatever the TV does, instead of waiting for Home Assistant's or the provider's own silence detection, which a TV keeps open.
- **Who is talking** is known about a second into the command, while the person is still talking.

The assistant hears the user about a second late while they talk, the time Ground Control needs to tell voices apart. The end of the command is not delayed by it.

Two voices at the same moment both reach the assistant: Ground Control can leave out a voice between the user's words, not under them. A guest who is not enrolled and sounds much like the TV voice is harder to tell apart than an enrolled person.

If Ground Control is not reachable, or stops answering mid-command, commands work as they do without it.

## Realtime Conversations

With a [realtime assistant](voice-satellite.md), Leave other voices out works for the whole conversation:

- **Each turn** is the user's speech only, and ends when they stop. OpenAI and xAI take the turns from the kiosk. Gemini keeps its own speech detection, but only ever hears the user.
- **Talking over an answer** stops it only when it is the user. A TV or another voice never interrupts the assistant. The stop word still stops an answer whoever says it.
- **The assistant knows who is talking.** OpenAI and xAI are told the speaker's name, so "my" means them. The conversation also ends after the idle time when only the TV is talking.

If Ground Control goes away mid-conversation, the provider's own speech detection takes over and the conversation goes on.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Voice Match | off | Recognizes who is talking and stops listening when someone else takes over. Needs Ground Control. |
| Answer | Anyone | **Chosen people** ignores the TV, guests and everyone else: a command from anyone not chosen is dropped. |
| People | nobody | With **Chosen people**, who this kiosk answers, picked from everyone enrolled in Ground Control. With nobody chosen, it answers anyone enrolled. |
| Voice not chosen | Stay quiet | With **Chosen people**, what happens when someone else says the wake word: nothing, or the error chime. |
| Leave other voices out | on | Home Assistant and the realtime assistant hear only the person who said the wake word, and the command ends when they stop. Off, Voice Match only says who is talking. |
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

Each recognized voice also fires an [`esphome.kiosk_satellite_speaker`](events.md#speaker) event with the person's name, their Home Assistant person and the score, for automations that react to who is talking.

**In automations**, a sentence trigger gets `trigger.device_id`, the kiosk that heard the command. Read that kiosk's Speaker sensor to act for the person:

```yaml
variables:
  speaker: >-
    {{ device_entities(trigger.device_id)
       | select('match', 'sensor\..*_speaker$')
       | map('states') | first | default('') }}
```

**For LLM conversation agents**, expose each kiosk's Speaker sensor to Assist and add the instructions block from the Ground Control app's Settings page to the agent's instructions. The agent reads the sensor with GetLiveContext on each request, so it knows who is talking even when the conversation continues from an earlier command. The agent needs the Assist API.

## Personal Commands

"Add milk to my list" goes on Ana's list when Ana says it and on Leo's list when Leo does. Set each person's to-do list, calendar and playlist on the People page of the Ground Control app. The kiosk gets them with the voices, so "my" is known on the kiosk with no extra trip to Ground Control. Anyone without a list of their own uses the shared list.

> **Info:** These use the same events as the calendar and music blueprints, so the long-lived token under **Settings, Home Assistant** must belong to a Home Assistant administrator.

**For Home Assistant's own conversation agent**, the personal commands blueprint adds sentences in every language Kiosk Satellite supports. They also work with an LLM agent that has **Prefer handling commands locally** on.

1. Import the blueprint:

    [![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjxlarrea%2Fkiosk-satellite%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fkiosk_satellite_personal_commands.yaml)

2. Create an automation from it and pick the shared list.

| Ask | What happens |
| --- | --- |
| "Add milk to my shopping list" | Milk goes on the speaker's list, or on the shared list when they have none. |
| "What's on my list?" | Reads what is still to do on that list. |
| "What's on my calendar today?" or "What do I have tomorrow?" | Reads that day's events from the speaker's calendar on the kiosk. |
| "Play my playlist" | Plays the speaker's playlist on the speaker this kiosk's Now Playing follows. |

Add your own wording under the blueprint's **More sentences** fields. Those are answered in English.

**For LLM conversation agents**, the to-do blueprint gives the agent "my list" without knowing whose list is whose:

1. Import the blueprint:

    [![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjxlarrea%2Fkiosk-satellite%2Fblob%2Fmain%2Fblueprints%2Fscript%2Fkiosk_satellite_todo.yaml)

2. Create a script from it and pick the shared list.
3. Expose the script to Assist under **Settings, Voice assistants, Expose**.

The agent can then add to, read, check off and remove items. The [calendar](calendar.md#managing-the-calendar-by-voice) and [music](music-library.md#playing-music-by-voice) blueprints take "my calendar" and "my playlist" the same way. Every answer these blueprints get from the kiosk names the person talking in `speaking`.

When someone in the home has a list of their own but the voice is not recognized, the kiosk says it doesn't know who is speaking, so an item never lands on the wrong list.
