# Alarms

Kiosk Satellite has alarms of its own. They live on the kiosk and ring without Home Assistant, a network or the dashboard. You get a list with a switch per alarm, a scroll wheel to pick the time, one page for the details and a full screen with Snooze and Stop when an alarm rings.

Open the list from **Alarms** in the kiosk menu, from **Manage alarms** under **Settings, Alarms**, from the **Next alarm** screensaver widget, from the **Alarms** page of the remote admin or from a dashboard button pointed at `ks://alarms` (see [Dashboard Links](dashboard-links.md)). Point it at `ks://alarms/next` to open the alarm that rings next instead. The **Open the alarm list** and **Open the next alarm** [gesture actions](gestures.md) do the same.

## Setting an alarm

1. Tap **Set an alarm** and pick the time on the wheel. A device set to 24 hour time shows two wheels, otherwise there is an AM or PM wheel too.
2. **Set** saves the alarm, turned on, and a toast says how long until it rings.
3. The details page adds the rest. Tap **Done** to keep the changes or **Delete** to remove the alarm.

| Detail | What it does |
| --- | --- |
| Repeat | The days the alarm rings on. With no day picked it rings once, at the next time the clock reads its time, then turns itself off and stays in the list. |
| Label | A name shown in the list and on the ringing screen. |
| Alarm tone | **Default** follows the Alarm tone setting. **Built-in alarm** is the sound bundled with the app. Any sound in the sounds folder works too. Picking a tone plays it once at the alarm volume. |
| Music | Music from your library rings instead of the tone. **Default** follows the Alarm music setting, **None** keeps to the tone and **Choose music** picks the alarm's own. See [Waking up to music](#waking-up-to-music). The row shows once Music Assistant, Home Assistant or a Sonos speaker is set up. |
| Sunrise | The screen brightens gradually before the alarm rings. See [Sunrise](#sunrise). |
| Ease in the volume | The tone or the music starts quiet and grows to the alarm volume over the **Ease in over** time. An alarm follows the default switch until you flip its own. |
| Speak when it rings | Home Assistant speaks a phrase between the rings. See [Spoken phrase](#spoken-phrase). |
| Phrase | Shows while Speak when it rings is on. It starts as the default phrase, and an alarm left on it follows later changes to the default. |

Tap the time on the details page to change it. The switch in the list turns an alarm on or off without opening it. An alarm turned on or changed after its time has passed waits for its next ring instead of ringing late.

There is one alarm per time and repeat. Setting a time that already has an alarm on the same days opens that alarm, turned on, instead of adding a second one. The remote admin refuses the duplicate the same way.

## When an alarm rings

The alarm wakes the screen, comes in front of the dashboard or another app and plays its tone on the Android alarm stream, so a muted media volume does not silence it. It rings until one of these happens:

- **Stop** ends it. The stop word stops it too, the same way it stops a timer.
- **Snooze** holds it off for the snooze length, then it rings again. In the list a snoozed alarm says until when and carries a **Stop** button.
- **Silence after** runs out and it goes quiet on its own. It counts as stopped, not snoozed.

To stop or snooze without reaching for the screen, map claps or Show fingers to the **Stop the alarm** or **Snooze the alarm** [gesture action](gestures.md).

A tap anywhere else does nothing, so a brush of the hand never ends an alarm. Two alarms set to the same minute ring as one and show both labels. Under Lockdown Mode the screen takes no touch, so the stop word, Home Assistant or the remote admin stop the alarm there.

An alarm rings on its own full screen view, with one exception: when the screensaver is **Clock** or **Weather Mood** and its **Let alarms take over** switch is on (the default), the alarm rings on that screensaver instead. It keeps everything the screensaver is set to, including the font, colors, shadow, background, Night mode and corner widgets. The date line becomes the alarm's label and Snooze and Stop come in under the clock in the screensaver's own colors. A screensaver dimmed by its own brightness setting comes back to normal brightness while the alarm rings and dims again after Stop or Snooze. On Weather Mood the weather bar makes way for the two buttons. If something else is on screen, the alarm starts the screensaver first.

A kiosk that was switched off or restarted through the whole Silence after window skips the alarm rather than ring it late.

## Waking up to music

An alarm can ring with music from your library instead of its tone. Set **Alarm music** under **Settings, Alarms** for every alarm that follows the default, or tap **Music** on an alarm's details page and pick **Choose music** to give it music of its own. Both open the music picker:

- **Music from** picks the source: Music Assistant, Home Assistant or Sonos.
- **Plays on** picks the speaker. It starts on this device where the source can play here: Music Assistant plays through the kiosk's own Sendspin player. Sonos music plays on Sonos speakers only.
- Pick a track, an album, a playlist, an artist, a station or a Home Assistant media folder. The chevron on an album, a playlist, an artist or a folder opens it to pick one track or the whole of it.
- **Random** picks a different track, favorite, playlist, album or station every time the alarm rings.
- **Shuffle** plays an album, a playlist, an artist or a folder in random order.
- **Preview** plays the pick on its speaker. It stops when you close the picker.

**None** on an alarm's Music row keeps that alarm to its tone. The X beside Alarm music takes the default out.

When the alarm rings, Now Playing switches to the alarm's speaker, so the floating player and the volume keys follow the music. The alarm stays on screen, and Now Playing does not take over while it rings. The speaker plays at the alarm volume, easing in when **Ease in the volume** is on, and repeats until you stop the alarm. The alarm does not duck its own music the way it ducks other music under its tone. A voice turn still does. Stop and Snooze stop the music and take it out of the speaker's queue, so no paused track is left for Now Playing and the floating player. They put the speaker's volume, shuffle and repeat back the way they were and switch Now Playing back to the player it followed before. If you pick another player while the alarm rings, that pick stays.

The alarm rings its tone instead when the music cannot play: the source or the speaker is out of reach, or the speaker does not start playing within a few seconds. Speak when it rings only works with the tone.

## Sunrise

A sunrise alarm starts before its time, as long as **Sunrise length** says. On the alarm's own view a glow rises from deep red to warm white while the screen brightens from its lowest level to full, then the alarm rings on the last color. A touch during the sunrise shows a **Stop** button for a few seconds, and Stop skips the ring too.

On a Clock or Weather Mood screensaver that lets alarms take over, the screensaver shows through the sunrise and only the brightness climbs. A touch that dismisses the screensaver ends the sunrise, and the alarm still rings at its time.

## Spoken phrase

An alarm with **Speak when it rings** on plays its tone twice, says its phrase, then plays the tone twice again, the way a timer speaks. The default is `It's {time}. {label}`.

These variables can go in a phrase. Words appear in the kiosk's language.

| Variable | Becomes | Example |
| --- | --- | --- |
| `{label}` | The alarm's label | Gym |
| `{name}` | The name of the Home Assistant user the kiosk's token belongs to | Sam |
| `{time}` | The alarm's time, on the clock **24-hour clock** picks | 7:05 AM |
| `{hour}` | The hour, on the same clock as `{time}` | 7 |
| `{minute}` | The minute, with no leading zero | 5 |
| `{date}` | The full date | November 5, 2026 |
| `{day}` | The day of the week | Thursday |
| `{dayofmonth}` | The day of the month | 5 |
| `{month}` | The month | November |
| `{year}` | The year | 2026 |

Use the separate variables when a text to speech engine reads `{time}` or `{date}` badly, for example `Good morning {name}. It's {hour} hours and {minute} minutes. Today is the {dayofmonth} of {month}, {year}.`

A phrase without a label or a name drops the variable and the punctuation around it, so the default says "It's 7:00 AM." The name comes from Home Assistant when the alarm rings. If Home Assistant does not answer in time, the phrase is spoken without the name.

Home Assistant makes the speech with the **Text to speech engine**, **Language** and **Voice** settings, the same way announcements are spoken, so the kiosk needs its Home Assistant address and token. The tone rings from the first second either way. When Home Assistant is slow or out of reach, the alarm rings without the words.

## Settings, Alarms

| Setting | What it does |
| --- | --- |
| Show in the kiosk menu | Opens [Device > User Interface > Drawer menu items](drawer-menu.md), where the Alarms entry is turned on or off. On by default. |
| 24-hour clock | Shows alarm times as 19:00 instead of 7:00 PM: the alarm list, the time wheel, the ringing screen, the next alarm widget, the alarms page in remote administration and `{time}` and `{hour}` in the spoken phrase. With it off, the time picker in remote administration takes the hour from 1 to 12 with AM or PM. The first start takes Android's clock setting, after that it is set here. |
| Manage alarms | Opens the alarm list. Shows when the next alarm rings. |
| Alarm volume | How loud alarms ring. It sets the Android alarm volume while an alarm rings and puts it back after, apart from the media and assistant volumes. |
| Ease in the volume | The default for new alarms and alarms that never chose: start quiet and grow to the alarm volume. Off by default. |
| Ease in over | How long the volume takes to grow, 5 to 120 seconds. Shows while Ease in the volume is on and applies to every alarm that eases in. |
| Alarm tone | The tone an alarm set to Default plays: the built-in alarm or a sound from the sounds folder. **Add a sound** copies a file into the folder, the same way the notification and announcement sounds work. |
| Alarm music | The music an alarm set to Default rings with instead of the tone, picked in the music picker. None by default. The tone rings when the music cannot play. |
| Snooze length | 5 to 30 minutes. |
| Silence after | How long an alarm rings when nobody stops it, 5 to 30 minutes. |
| Sunrise length | How long the screen takes to brighten before a sunrise alarm, 10 to 30 minutes. |
| Phrase | The default phrase for alarms that speak. |
| Text to speech engine | Under **Text to Speech**, the Home Assistant text to speech entity that speaks alarms. **First available** takes the first one Home Assistant has. |
| Language | The language alarms are spoken in, picked from the ones the engine lists. **Default** leaves it to the engine. Shown once an engine is picked by name. |
| Voice | The voice that speaks alarms, picked from the ones the engine lists for the language. **Default** leaves it to the engine. |

**Alarms** under **Kiosk Mode, Allowed Actions** decides whether the restricted kiosk menu offers the list too.

The screensaver waits while the alarm list is open, so it never cuts off an alarm being set.

[Fleet Management](fleet.md) syncs these defaults under its Alarms category. The drawer menu entries travel with the Device category. The alarms themselves stay on each kiosk.

## Next alarm widget

**Next alarm** is a [screensaver widget](screensavers.md#widgets) that shows the next alarm when it rings within 24 hours, and the snooze while one runs. The corner stays empty the rest of the time. A tap on the widget opens the alarm list, the one spot on a screensaver that does more than dismiss it.

## Setting alarms by voice

Home Assistant has no alarm intent, so voice alarms go through an LLM conversation agent (Qwen, Gemma, Gemini, Claude, OpenAI or any other agent that can control Home Assistant). The agent understands the request in any language it speaks and calls a script that Kiosk Satellite ships as a blueprint.

The built-in **Home Assistant** conversation agent does not work for this. It only matches sentences against Home Assistant's own intents and cannot fill in the script's time, days or label. An LLM agent with **Prefer handling commands locally** turned on works fine: Home Assistant still handles lights, timers and the rest itself and passes alarm requests on to the LLM.

> **Info:** The long-lived token under **Settings, Home Assistant** must belong to a Home Assistant administrator. This applies to every request the script handles, including questions such as "What alarms do I have?". Alarms set on the kiosk work with any user's token. The kiosk listens for the script over its own Home Assistant connection. Home Assistant only lets administrators fire and follow the events the script runs on.

1. Import the blueprint:

    [![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjxlarrea%2Fkiosk-satellite%2Fblob%2Fmain%2Fblueprints%2Fscript%2Fkiosk_satellite_alarms.yaml)

2. Create a script from it. It has no settings.
3. Expose the script to Assist under **Settings, Voice assistants, Expose**.

Then ask the kiosk: "wake me up at 6:30 on weekdays", "set an alarm called Gym for 7 tomorrow", "what alarms do I have?", "turn off the Gym alarm" or "delete my 6:30 alarm". The agent confirms what the kiosk did and when the alarm rings next.

It works in any language your agent speaks, with no sentences to set up per language. Ask in Spanish, German, French, Ukrainian or anything else the same way, like "despiértame a las seis y media de lunes a viernes", and the agent answers in that language.

[Realtime conversations](voice-satellite.md#realtime-conversations) set alarms the same way: with **Tools** on **Home Assistant**, the model sees the exposed script and calls it while the conversation runs.

The alarm goes to the kiosk you are talking to. A request typed into Home Assistant's own chat reaches no kiosk until it names one, as in "set an alarm on the bedroom kiosk", which matches the kiosk's device name or ESPHome name.

Nothing new appears in ESPHome.

### Good to know

- **Countdowns.** "Set an alarm in 20 minutes called Pizza" works as a kitchen countdown. The agent turns it into a clock time, and the alarm rings once, full screen and on the alarm stream, with the label on screen. It is accurate to the minute. For a countdown accurate to the second that you can pause, ask for a timer instead: "set a timer for 20 minutes". [Voice Satellite](voice-satellite.md#timers-announcements-and-conversations) shows it as a pill, and timers work with the built-in Home Assistant agent too.
- **Another room.** Name a kiosk to set its alarm from anywhere: tell the kitchen kiosk "set an alarm on the bedroom kiosk for 6:30 tomorrow" and the bedroom kiosk takes it.
- **One specific day.** A one time alarm rings the next time the clock reads its time, so "set an alarm for Friday at 7" usually becomes an alarm that repeats every Friday. Turn it off or delete it after it rings if you only needed it once.
- **Skipping a morning.** Turning off a repeating alarm stops it on every day until you turn it back on, with "turn my 6:30 alarm back on". There is no skip for one day only.
- **Moving an alarm.** There is no edit, so ask for both steps in one sentence: "delete my 6:30 alarm and set one for 7".
- **Automations.** The script works outside Assist too. Call it from an automation or a script with `kiosk` set, for example to set tomorrow's wake up from a calendar event. With a response variable, `action: list` returns the kiosk's alarms and when each rings next.

    ```yaml
    action: script.kiosk_satellite_alarms
    data:
      action: set
      time: "06:30"
      days: [mon, tue, wed, thu, fri]
      label: Work
      kiosk: Bedroom
    response_variable: result
    ```

**Manage alarms using Voice Satellite** under **Settings, Alarms, Voice Alarms** and on the remote admin's **Alarms** page opens this guide.

Stopping and snoozing a ringing alarm still works with the stop word, the screen and the **Stop alarm** and **Snooze alarm** buttons.

## Remote admin

The **Alarms** page lists every alarm with a switch, an edit button and a delete button. **Set an alarm** and the edit button open one dialog with the time, repeat days, label, tone, music, sunrise, ease in, the speak switch and the phrase. The Music field opens the same music picker as the device. The same defaults as the device follow the list, including an **Upload** button for sounds from your computer. While an alarm rings, sits in its sunrise or is snoozed, the Overview shows a banner with Snooze and Stop.

## Home Assistant

The kiosk's alarms reach Home Assistant through [ESPHome](esphome.md):

| Entity | Type | Notes |
| --- | --- | --- |
| **Next alarm** | timestamp | The next alarm on the device, the kiosk's own alarms included, since they are scheduled as Android alarm clocks. |
| **Alarm ringing** | binary sensor | On while an alarm rings. |
| **Alarm snoozed until** | timestamp | When a snooze runs out, unknown when nothing is snoozed. |
| **Stop alarm**, **Snooze alarm** | button | The same as the buttons on screen. |

A morning routine is an automation that triggers when **Alarm ringing** turns off.

### Alarm events

Every alarm also fires an `esphome.kiosk_satellite_alarm` event on the Home Assistant bus, one per alarm, whenever it changes or rings. Home Assistant only fires device events under `esphome.`, hence the prefix.

```yaml
event_type: esphome.kiosk_satellite_alarm
data:
  device_id: 5f1c...
  event_type: ringing
  alarm_id: k3v9x2qa
  label: Wake up
  time: "07:00"
  days: [mon, tue, wed, thu, fri]
  enabled: true
```

| `event_type` | When |
| --- | --- |
| `created` | An alarm was added, on the kiosk, by voice, in the remote admin or by a settings import. |
| `updated` | An alarm changed or was switched on or off. A one time alarm switches itself off once it rings. |
| `deleted` | An alarm was removed. |
| `sunrise` | Its sunrise started. |
| `ringing` | It rings, again after each snooze. |
| `snoozed` | It was snoozed. `snoozed_until` holds when it rings again, in UTC. |
| `stopped` | It was stopped during a ring, a snooze or a sunrise. |
| `silenced` | Nobody stopped it before **Silence after** ran out. |

`time` is the alarm's local time and `days` lists the days it repeats on, empty for a one time alarm. `device_id` is the kiosk's ESPHome device, added by Home Assistant.

```yaml
# Turn on the bedroom lights when the bedroom kiosk's alarm is stopped.
triggers:
  - trigger: event
    event_type: esphome.kiosk_satellite_alarm
    event_data:
      event_type: stopped
      # The bedroom kiosk's device ID, from its device page URL.
      device_id: 5f1c...
actions:
  - action: light.turn_on
    target:
      entity_id: light.bedroom
```

Apps on the kiosk itself, like Tasker or MacroDroid, get the same events as [Android Broadcasts](android-broadcasts.md#alarms). For the kiosk's other events, see [Home Assistant Events](events.md).
