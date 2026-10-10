# Voice Satellite

Kiosk Satellite is a Home Assistant Assist satellite on its own, through its ESPHome server. It hears the wake word, streams your command to Home Assistant, plays the answer and draws the overlay itself. Nothing needs to be installed in Home Assistant and no dashboard has to be loaded for voice to work.

## Why native

Voice used to run inside the dashboard's WebView, through the [Voice Satellite integration](https://github.com/jxlarrea/voice-satellite-card-integration). Its engine loaded with the page, streamed the microphone through it and drew the overlay in HTML. On the wall tablets and Echo Shows most kiosks run on, that WebView was the bottleneck.

| | Voice Satellite integration | Native |
| --- | --- | --- |
| Needs | The integration from HACS and a dashboard running it | ESPHome on in Kiosk Satellite |
| Overlay | HTML and CSS in the WebView | Drawn natively on the GPU |
| Waveform skin on an Echo Show 8 | About 9 fps | 56 fps, the panel's full rate |
| Ink Blobs on an Echo Show 8 | Does not render | Renders |
| Screensaver during a turn | Dismissed | Paused under the overlay |
| Under the overlay | Keeps rendering | Pauses: Weather Mood, slideshows, web pages, camera grids and the dashboard hold |
| In Home Assistant | A satellite of the integration | A standard Assist satellite, like a Voice PE |

## Set up

1. On **Settings > ESPHome**, turn on the ESPHome server.
2. On **Settings > Voice Satellite**, turn on **Enable Voice Satellite**.
3. In Home Assistant, open **Settings > Devices & services**. The kiosk shows up as discovered. Add it.
4. Pick the **Assistant** and the **Wake word** on the Voice Satellite pages. Both are Home Assistant's own selects on the kiosk's device.

Onboarding does all of this for a new kiosk: it turns on Voice Satellite and ESPHome and asks for the Assistant, wake word engine and wake word. They are set on the kiosk's selects as soon as Home Assistant adds it.

The **Status** row under the switch says where the satellite stands:

| Status | Meaning | Fix |
| --- | --- | --- |
| Listening | Waiting for the wake word. | |
| Busy | A voice turn or an announcement is running. | |
| Muted | **Mute microphone** is on. | Turn it off, here or with the VS Mute switch in Home Assistant. |
| Not listening | The wake word engine is not running. | Check the microphone permission and the app log. |
| Not added | Home Assistant has not added the kiosk yet or ESPHome is off. | Follow the row's hint. |

The microphone permission is required. **Keep listening in the background** also needs a permanent notification and **Display over other apps**. The **Required system permissions** group on the page asks for each.

> **Note:** Tool use lines and result panels (weather, stock, images, videos) come from Home Assistant's conversation log, which only an administrator's token can read. With a regular user's token, voice works and those parts do not show.

## Migrate from the Voice Satellite integration

A kiosk that ran the integration keeps running it on the dashboard until you migrate. Nothing migrates on its own.

1. On **Settings > Voice Satellite**, tap **Migrate** on the notice at the top. The remote admin's Overview offers the same.
2. Pick the integration's satellite this kiosk takes over.
3. The wizard checks Home Assistant, the kiosk's ESPHome device, the token and the microphone.
4. Choose the settings to bring over: Voice, Appearance, Conversation, Assistant and Timers.
5. Review the automations and scripts that still point at the old satellite. The wizard lists them and never changes them.
6. Tap **Switch now**. The kiosk takes over the Assistant, wake words and Finished speaking detection picks of the old satellite.

Not carried over: custom CSS, the browser's microphone processing and the conversation memory length. Automations that trigger on the integration's `voice_satellite_timer` event move to [`esphome.kiosk_satellite_timer`](#timer-events), which carries the same `event_type`, `timer_id`, `name`, `total_seconds`, `seconds_left` and `is_active` fields. The old satellite stays in Home Assistant, unused. Once no other device uses the integration, uninstall it from HACS.

**Run from the dashboard again**, at the bottom of the page while the integration is still installed, switches back. The settings made here stay for next time.

When Home Assistant runs the integration, onboarding offers the same migration instead of the basic setup. Its selects are set once Home Assistant adds the kiosk.

## Settings

| Page | Setting | What it does |
| --- | --- | --- |
| Voice Satellite | Mute microphone | Stops listening for the wake word. |
| | Keep listening in the background | Hears the wake word while another app is in front and comes back on a detection. **Return to the previous app** goes back when the turn ends. |
| Assistant | Assistant 1 and 2, Finished speaking detection | Home Assistant's selects: the pipeline that answers each wake word and how long a pause ends a command. Every validated realtime provider is one more choice. See [Realtime conversations](#realtime-conversations). |
| | Talk right after the wake word | Skips the wake sound and keeps what you say right after the wake word. |
| | Follow-up delay, Chime before a follow-up | A pause and a chime before listening for the answer to a question. |
| | Play sounds on, Play as | Where answers and chimes play. See [below](#play-sounds-on-a-media-player). |
| Realtime | Providers | A row per provider with its status. **Configure** opens its API key, model, voice and endpoint, plus **Reasoning effort** for OpenAI and Gemini, xAI's **Web Search** and **X Search** switches and Gemini's **Google Search** and **Ignore talk not meant for it** switches, and **Save & Validate** stores them once the provider connects. |
| | Instructions, End after silence, Speech speed, Session duration, Talk over answers | How the conversation behaves, sounds, ends and carries over, for every provider. |
| | Tools | What the model can control. See [Realtime conversations](#realtime-conversations). |
| Wake Word | Wake word engine | vsWakeWord (default), microWakeWord or openWakeWord. All models ship with the app. |
| | Wake word 1 and 2 | Home Assistant's selects. Wake word 2 is answered by Assistant 2. |
| | Wake word sensitivity, Wake word noise gate | How easily the wake word triggers. The noise gate skips inference while the room is quiet to save CPU. |
| | Stop word interruption | Say "stop" to cut off an answer, a timer alert or an announcement. It also closes a result panel. |
| | Wake Word Arbitration | When several kiosks hear the wake word, only the closest one answers. See [Wake word arbitration](#wake-word-arbitration). |
| | Custom Models | Your own wake word models. See [Custom wake word models](custom-wake-words.md). |
| Appearance | Skin | Kiosk Satellite, Default, Google Home, Home Assistant, Alexa, Siri, Retro Terminal, Waveform, Lens Flares, Ink Blobs, Jarvis or Voice Only. Jarvis draws a holographic HUD reactor that turns and pulses with your voice and the answer, and docked it sits beside the conversation's text. Voice Only shows no text, only the Kiosk Satellite logo with its bars moving to your voice and the answer, for screens too small to read. **Preview** shows it for five seconds. |
| | Theme, Background, Text size, Reactive activity bar | Light or dark, how much of the dashboard shows through, the text size and the bar that follows your voice and the answer. |
| Conversation | Show what you said, Show the answer, Show tool use, Hide sentiment tags | What the overlay shows. |
| | Keep the answer on screen, Keep results on screen, Announcement time | How long each stays. Results at 0 stay until dismissed. |
| Timers | Show timer pills, Show the timer name, Timer pill scale | Running timers float over the screen. Drag them anywhere. |
| | Show finished timer pills, Mute timer alerts, Show the name on the alert, Speak when a timer ends | What a finished timer does. Without its pill, the stop word still ends the alert. |
| Chimes | Play chimes, per-event sounds | The wake, done, error, timer and announcement sounds, built in or from the sounds folder. |

The **Wake Word Tester** and **Wake word diagnostics** are covered in [Microphone settings](microphone.md).

## Wake word arbitration

Kiosks in the same room or in open spaces often hear the same wake word. Without arbitration, Home Assistant answers whichever kiosk reaches it first, which is the fastest one and not always the one you spoke to. Turn on **Enable wake word arbitration** on every kiosk that should take part, under **Wake Word > Wake Word Arbitration**.

Home Assistant only settles duplicates for Assist pipelines. A wake word that starts a [realtime conversation](#realtime-conversations) goes straight to the provider, so without arbitration every kiosk that heard it opens its own conversation.

When a kiosk hears the wake word, it broadcasts how loud the wake word reached it over its own background noise and waits for the **Arbitration window**. If another kiosk heard the same wake word louder, it goes back to listening without a chime or anything on screen. The loudest one answers. Each kiosk compares against its own noise floor, so a hot microphone does not win just for being loud, but very different microphones can still favor one model over another.

| Setting | What it does |
| --- | --- |
| Enable wake word arbitration | Takes part in arbitration with the other kiosks on the network. |
| Arbitration window | How long a kiosk waits to hear from the others, 100 to 500 ms (400 by default). It has to cover how much later a slow device detects the wake word plus the trip over Wi-Fi, where access points can hold broadcast traffic for a few hundred milliseconds. Raise it if a closer kiosk sometimes loses or both answer. Every wake waits this long, and nothing you say during the wait is lost. |

The kiosks talk over UDP broadcast on port 2330 and need nothing else turned on: no fleet, intercom or remote admin. They have to be on the same network segment, and an access point that blocks broadcast traffic between wireless clients stops arbitration. When a claim does not arrive, each kiosk answers as it would without arbitration. A muted kiosk does not take part.

## Realtime conversations

A wake word answered by a realtime provider starts a conversation with a speech to speech model instead of a Home Assistant pipeline. The model listens while it talks, so you can interrupt it, and the answers start as soon as you stop speaking. OpenAI, xAI Grok and Google Gemini are supported.

1. Under **Realtime**, tap **Configure** on the provider you use and paste its **API key**. You can set up more than one.
2. Tap **Save & Validate**. The kiosk connects once with those settings and saves them only if the provider accepts the connection. Otherwise the dialog stays open and shows the error. The provider's row then reads **Connection validated**, or shows what went wrong with the connection or the Home Assistant tools.
3. Under **Assistant**, pick the provider (for example **OpenAI Realtime**) for **Assistant 1** or **Assistant 2**. Each wake word can use a different provider or keep its pipeline.

**Model** and **Voice** list what each provider offers. With your key, the kiosk asks the provider for them (OpenAI's and Gemini's realtime models, xAI's voices). Through a relay it shows the ones built in. A provider whose key or endpoint changed outside its dialog, for example through a settings import, reads **Not validated** until you save it again. Until then its wake word answers with its Home Assistant pipeline.

**Getting a Gemini API key.** Sign in to [Google AI Studio](https://aistudio.google.com/apikey) with a Google account, click **Create API key**, pick or create a Google Cloud project and copy the key into the Gemini provider's **API key**. The free tier covers the Live models with lower rate limits, so you can try realtime conversations without a billing account. Google may use what is sent on the free tier to improve its products. Turn on billing for the project to lift the limits and keep your conversations out of that. **Model** defaults to `gemini-3.8-live`.

**Controlling your home.** With **Tools** on **Home Assistant**, the model uses Home Assistant's **Model Context Protocol Server** integration. Add it under **Settings > Devices & services** in Home Assistant. The model can use the entities exposed to Assist, and the scripts exposed to Assist become tools too. Timers work as they do with Assist on Home Assistant 2026.10 or later. Older versions leave the timer tools out of realtime conversations. **Custom MCP server** points at another server that speaks Streamable HTTP. **None** leaves the tools to a relay that adds its own.

**Which room.** Each conversation starts with the kiosk's name and its area in Home Assistant, so "turn on the lights" means the lights in the kiosk's area unless you name another one. Set the area on the kiosk's device in Home Assistant. The Assist satellite entity stays idle during a conversation, so automations that need to know which kiosk is talking should check the kiosk's [Voice Satellite](#home-assistant-entities-and-actions) sensor.

**Picking up where you left off.** **Session duration** keeps what was said for 30 minutes up to 12 hours and gives it to the next conversation, so you can refer back to something after a conversation ended. Older exchanges are dropped, and nothing is kept across an app restart.

**Started from Home Assistant.** With a provider on **Assistant 1**, `assist_satellite.start_conversation` opens a realtime conversation instead of an Assist turn. The model says the `start_message` in its own voice, word for word, and then listens for the reply. Home Assistant's own speech of the message is not played. `extra_system_prompt` does not reach the model, because Home Assistant does not send it to the kiosk. An automation that plays `start_media_id` with no message still gets an Assist turn.

**Kiosks without internet access.** Set a provider's **Endpoint** to a relay on your network that speaks its realtime protocol. The kiosk only talks to the relay, and the API key can live there instead of on the kiosk.

**OpenAI on Azure.** The bubble shows what you said through a separate transcription model, `gpt-4o-mini-transcribe`. On Azure it needs its own deployment, named exactly that, in the same resource as the realtime model. Without it the model still hears you and answers, but your words never show and the kiosk logs `transcription failed: DeploymentNotFound`.

**On screen.** A conversation docks at the bottom of the screen in a bubble with the current exchange and the skin's bar along its bottom edge. It stays up until the conversation ends, and the dashboard stays visible and usable underneath. The bar drains in the last seconds before **End after silence** ends the conversation. Saying goodbye ends it too, and so does the close button. "Stop" cuts off an answer and keeps the conversation going.

**Reasoning effort** (OpenAI and Gemini) sets how much the model reasons before it answers. More effort gets harder questions right more often. **Model default** leaves it to the model. With OpenAI it goes from Minimal to Extra high, only the gpt-realtime-2 models support it and Save & Validate fails with "Unsupported option for this model" on the others. With Gemini it goes from Minimal to High: `gemini-3.8-live-extended-thinking` takes Low to High, `gemini-3.1-flash-live-preview` takes all four, and `gemini-3.8-live` refuses it. Save & Validate shows Google's error for a level the model does not take.

**Speech speed** sets how fast the model talks, from 0.5x to 1.5x. OpenAI does not go faster than 1.5x. Gemini has no such setting and always talks at its own pace.

**Google Search** (Gemini only) lets the model look things up on the web, next to the Home Assistant tools. It needs billing turned on for the key's Google Cloud project: on the free tier, Save & Validate fails with "You exceeded your current quota".

**Web Search** and **X Search** (xAI only) let the model look things up on the web and in posts on X, next to the Home Assistant tools. xAI runs the searches itself and bills them as part of the conversation, with no extra setup on the key.

**Ignore talk not meant for it** (Gemini only) turns on Gemini's proactive audio: the model stays quiet when what it hears is not addressed to it, such as a TV or people talking to each other. Google offers it only on its experimental API, which the kiosk connects to while the switch is on, so it may change or go away.

**Gemini** picks the language from what you say, decides on its own when you finished talking and stops an answer when it hears you over it. "Stop" cuts off the answer on the kiosk, but Gemini cannot be told how much of it you heard.

**Talk over answers** keeps the microphone open while the model speaks, so you can interrupt it. It relies on the kiosk's echo canceller. If the model keeps interrupting itself, turn it off: the microphone then closes while the model speaks and "stop" interrupts it when **Stop word interruption** is on.

> **Note:** The model's voice always plays on the kiosk, even with **Play sounds on** set to a media player. Only the chimes follow that setting. Providers bill realtime models by the minute of audio, and a conversation ends after nine minutes at most.

## Play sounds on a media player

**Play sounds on** picks where the answers, chimes, announcements and timer alerts play: this kiosk or any Home Assistant media player. **Play as** picks how:

| Play as | Behavior |
| --- | --- |
| Announcement | The speaker pauses its music for the sound and resumes it after. |
| Normal playback | Plays the sound as media, then starts the music again. For speakers that ignore announcements. |

The speaker fetches the answer from Home Assistant and the chimes from the kiosk, over HTTP on port **2329**.

> **Warning:** A speaker that cannot reach the kiosk on port 2329 plays the answers but stays silent for the chimes. Speakers on a separate VLAN need a firewall rule from the speaker to the kiosk on that port.

## Timers, announcements and conversations

These come from Home Assistant through the kiosk's satellite entity, as they do on any Assist satellite.

| Feature | How |
| --- | --- |
| Timers | Ask for one by voice. Pills show while it runs and an alert when it ends. Tap a pill to pause it, double tap to cancel. |
| Announcements | `assist_satellite.announce` on the kiosk's satellite. |
| Start a conversation | `assist_satellite.start_conversation`: the kiosk speaks, then listens for the reply. With a realtime provider on Assistant 1, the provider takes the conversation. See [Realtime conversations](#realtime-conversations). |
| Ask a question | `assist_satellite.ask_question`: the kiosk speaks, listens and hands the reply to Home Assistant, as a Voice PE does. |

Double tap the overlay to end a turn or close what lingers. With **Stop word interruption** on, "stop" does the same while an answer, alert, announcement or result panel is up.

## Home Assistant entities and actions

Home Assistant adds these to the kiosk's device on its own:

| Entity | Type |
| --- | --- |
| Assist satellite | assist_satellite |
| Assistant, Assistant 2 | select |
| Wake word, Wake word 2 | select |
| Finished speaking detection | select |

With **Expose kiosk entities** on under **Settings > ESPHome**, the kiosk adds its own:

| Entity | Type | Setting |
| --- | --- | --- |
| VS Mute | switch | Mute microphone |
| VS Chimes | switch | Play chimes |
| VS Stop word | switch | Stop word interruption |
| VS Noise gate | switch | Wake word noise gate |
| VS Mute timers | switch | Mute timer alerts |
| VS Wake word engine | select | Wake word engine |
| VS Wake word sensitivity | select | Wake word sensitivity |
| VS Answer linger | number | Keep the answer on screen |
| VS Announcement linger | number | Announcement time |

The kiosk also adds a **Voice Satellite** text sensor. It reads `idle`, `listening`, `processing` or `responding`, the same states as the Assist satellite entity, and it follows realtime conversations too. A realtime conversation runs no Home Assistant pipeline, so the Assist satellite entity stays idle through it. Check the sensor instead when an automation or script needs to know which kiosk is talking.

Two more sensors follow the kiosk's timers. **VS Timers** counts the timers that are running or paused. **VS Next timer** is a timestamp of when the soonest running timer ends, so a tile or entity card counts down to it on its own. It reads unknown while no timer runs.

And these actions, named after the kiosk's [node name](esphome.md#node-name):

```yaml
# Listen as if the wake word fired. Slot 2 runs Assistant 2.
action: esphome.kitchen_tablet_vs_wake
data:
  slot: 1
```

```yaml
# End the turn on screen, as a double tap does.
action: esphome.kitchen_tablet_vs_cancel
```

`vs_cancel` stops listening or speaking, takes down a lingering answer and silences a ringing timer.

```yaml
# Ask the assistant and show the answer and results on the kiosk.
action: esphome.kitchen_tablet_vs_show
data:
  prompt: What is the weather this week?
  speak: false
  pipeline: 1
  duration: 0
```

`speak: true` also says the answer. `pipeline` picks Assistant 1 or 2. `duration` is how long the answer stays in seconds, 0 until dismissed.

```yaml
# Start a timer on the kiosk, kept in Home Assistant like a spoken one.
action: esphome.kitchen_tablet_vs_start_timer
data:
  name: Pasta
  hours: 0
  minutes: 10
  seconds: 0
```

```yaml
# List the kiosk's timers.
action: esphome.kitchen_tablet_vs_list_timers
response_variable: result
```

The response holds a `timers` list with one entry per timer: running and paused ones first, then any that are ringing.

```yaml
timers:
  - timer_id: 01K6...
    name: pasta
    total_seconds: 600
    seconds_left: 412
    is_active: true
    ends_at: "2026-10-08T22:42:10.000Z"
    finished: false
```

`seconds_left` is the time left when the action ran. `ends_at` is when a running timer ends, in UTC, and is null while it is paused or ringing. `finished` is true while a timer rings and until its alert is dismissed.

ESPHome entities cannot carry attributes, so the list comes from the action. To keep it on an entity for a dashboard card, refresh a template sensor from the [timer event](#timer-events):

```yaml
template:
  - triggers:
      - trigger: homeassistant
        event: start
      - trigger: event
        event_type: esphome.kiosk_satellite_timer
    actions:
      - action: esphome.kitchen_tablet_vs_list_timers
        response_variable: result
    sensor:
      - name: Kitchen timers
        state: "{{ result.timers | length }}"
        attributes:
          timers: "{{ result.timers }}"
```

The event fires for every kiosk, so a sensor for one kiosk can add `event_data` with that kiosk's `device_id` to skip the others.

```yaml
# Pause, resume or cancel a timer by its ID.
action: esphome.kitchen_tablet_vs_pause_timer
data:
  timer_id: 01K6...
```

```yaml
# Add time to a timer. vs_remove_time takes the same fields.
action: esphome.kitchen_tablet_vs_add_time
data:
  timer_id: 01K6...
  hours: 0
  minutes: 5
  seconds: 0
```

`vs_pause_timer`, `vs_resume_timer`, `vs_cancel_timer`, `vs_add_time` and `vs_remove_time` take the `timer_id` from `vs_list_timers` or from the [timer event](#timer-events). An empty `timer_id` picks the kiosk's only timer and fails when it has several. Pausing a paused timer or resuming a running one does nothing.

Home Assistant's timer intents do the change, and they cannot find a timer by its ID. The kiosk looks the timer up and asks for it by name, or by the duration it started with when it has no name. Two timers on the same kiosk with the same name, or two unnamed timers that started with the same duration, look the same to Home Assistant, and the action fails with an error that says so. Give timers names to keep them apart.

The entities and actions appear only while Voice Satellite runs natively and is on.

## Timer events

Every timer on the kiosk fires an `esphome.kiosk_satellite_timer` event on the Home Assistant bus when it starts, changes, is cancelled, finishes or its alert is dismissed. That covers spoken timers, timers from a realtime conversation and timers from `vs_start_timer`. Use it to flash a light or announce a kitchen timer in another room. Home Assistant only fires device events under `esphome.`, hence the prefix.

```yaml
event_type: esphome.kiosk_satellite_timer
data:
  device_id: 5f1c...
  event_type: finished
  timer_id: 01K6...
  name: pasta
  total_seconds: 600
  seconds_left: 0
  is_active: false
```

| Field | Type | Description |
| --- | --- | --- |
| `device_id` | string | The kiosk's ESPHome device, added by Home Assistant. |
| `event_type` | string | `started`, `updated`, `cancelled`, `finished` or `dismissed`. |
| `timer_id` | string | Home Assistant's timer ID, the same across a timer's events. |
| `name` | string | The timer's name, empty when it has none. |
| `total_seconds` | integer | The duration it was started with. Added time does not change it. |
| `seconds_left` | integer | Seconds left when the event fired. |
| `is_active` | boolean | False while paused. `updated` covers added time, pause and resume, so this tells them apart. |

`dismissed` fires when the ringing alert is silenced on the kiosk, by a tap, the stop word or `vs_cancel`.

```yaml
# Flash the living room lamps when any kiosk's timer ends.
triggers:
  - trigger: event
    event_type: esphome.kiosk_satellite_timer
    event_data:
      event_type: finished
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_room
    data:
      flash: long
  - action: tts.speak
    target:
      entity_id: tts.home_assistant_cloud
    data:
      media_player_entity_id: media_player.living_room_sonos
      message: >
        The {{ trigger.event.data.name or 'timer' }} on the
        {{ device_attr(trigger.event.data.device_id, 'name') }} is done.
```

Events need the kiosk connected to Home Assistant through ESPHome.

## Android broadcasts

Apps on the device can start and end a turn with a broadcast, without going through Home Assistant. This suits a remote's button mapper, Tasker, Automate or ADB:

```sh
# Listen as if the wake word fired. Slot 2 runs Assistant 2.
adb shell am broadcast -a me.jxl.kiosk_satellite.action.VOICE_WAKE --ei slot 1

# End the turn on screen, as a double tap does.
adb shell am broadcast -a me.jxl.kiosk_satellite.action.VOICE_CANCEL
```

`slot` is optional and defaults to 1. The broadcasts work while Kiosk Satellite is running, even with another app in front, and do nothing while Voice Satellite is off.

## Fleets

A fleet leader passes its Voice Satellite settings to followers whose profile syncs **Voice Satellite**, along with its custom wake word models and its Assistant, Wake word and Finished speaking detection picks. Each follower sets those picks on its own device in Home Assistant. A profile can exclude each pick like any other setting. Mute and Play sounds on stay per kiosk by default. See [Fleet Management](fleet.md).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Status says Not added | Turn on ESPHome, then add the kiosk under **Settings > Devices & services** in Home Assistant. |
| The wake word never triggers | Check the level on the [Wake Word Tester](microphone.md) and the permissions group. Try another sensitivity. |
| No tool lines or result panels | The Home Assistant token is a regular user's. Use an administrator's. |
| Assistant and Wake word say Reload needed | Home Assistant added the satellite but not its selects, and the kiosk's token is not an administrator's, so it cannot reload the ESPHome entry itself. Reload the kiosk's entry under **Settings > Devices & services > ESPHome** or restart Home Assistant. |
| Chimes silent on a media player | The speaker cannot reach the kiosk on port 2329. |
| The overlay shows a notice | It names what failed: the microphone, the wake word, the connection, text to speech or the pipeline. Each turn's steps are in the app log. |
