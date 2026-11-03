# Calendar

Kiosk Satellite shows your Home Assistant calendars as a family calendar on the kiosk. Each calendar gets a color and an optional person, and an event that is on more than one calendar is drawn once with its background split on a diagonal between their colors. Turn on [Editing](#adding-and-changing-events) to add, change and delete events on the touch screen. They can also be changed in Home Assistant, in the calendar apps it syncs with or [by voice](#managing-the-calendar-by-voice).

Open it from **Calendar** in the kiosk menu, from **Open calendar** under **Settings, Calendar**, from the **Up next** screensaver widget, from an **Open the calendar** [gesture](gestures.md), from a dashboard button pointed at `ks://calendar` (see [Dashboard Links](dashboard-links.md)), from Home Assistant with the ESPHome **Calendar view** select (see [ESPHome](esphome.md)) or [by voice](#managing-the-calendar-by-voice). Pick **Calendar** under **Screensaver mode** to make it the [screensaver](screensavers.md#calendar) too.

## Adding calendars

1. Open **Settings, Calendar** on the kiosk or the **Calendar** page of the remote admin.
2. Choose **Add a calendar** and pick a calendar entity. Any Home Assistant calendar works, such as Google Calendar, CalDAV, Local Calendar or a holiday calendar.
3. The calendar takes the next free color and opens its editor:

| Field | What it does |
| --- | --- |
| Name | The name on its chip and in the Day view. It starts as the entity's name. |
| Color | One of eight colors, or Custom for any other. |
| Person | A Home Assistant person. Their picture replaces the initial on the calendar's chips and avatars. |

Tap a calendar in the list to change it. **Remove** takes it off the list. The switch next to each calendar turns it off without removing it.

## Views

The calendar opens on the view set under **Default view**. **Today** returns to the current day, the arrows move by a day, a week or a month, and a swipe left or right does the same.

| View | What it shows |
| --- | --- |
| Day | One lane per calendar with its avatar and name, an all-day row, then the hours with a line at the current time. Events that overlap in a lane sit side by side. |
| Week | Seven columns of events, all-day events first. Today is raised with its date in a filled circle. Tap a day's header to open it in the Day view. |
| Month | As many events per day as fit, then "+N more". Tap a day to open it. |
| Schedule | Today on the left with the date, the weather, the next event and the rest of today. The coming two weeks are on the right. |

Tap any event to see its details: who it is for, the date and time, how it repeats, the location and the description. With [Editing](#adding-and-changing-events) on, the details also have **Edit** and **Delete**.

The chips centered in the top bar show one calendar each. Tap a chip to hide that calendar on this kiosk. Hidden calendars stay hidden until you tap the chip again, and the Up next widget leaves them out too. An event shared with a calendar that is still showing stays, without the hidden calendar's color.

On a short screen such as the Echo Show 5 and on a phone the chips show only each calendar's avatar. More calendars than fit scroll sideways. On a phone the Week view becomes a strip of the seven days over the chosen day's events, and the Month view a grid of dots over the chosen day's events.

## Adding and changing events

The calendar is read only until you turn on **Allow adding and editing events** or **Allow deleting events** under **Settings, Calendar, Editing** or on the remote admin's **Calendar** page. Both are off by default. Turn on only the first to let people add events without deleting any.

With **Allow adding and editing events** on:

- **New event** is in the top bar on a tablet and a + button there on a short screen such as the Echo Show 5. On a phone it is at the bottom right.
- In the Day view, tap an empty hour to place a new event slot in that calendar's lane, then tap the slot to start an event there at that hour.
- The event details have **Edit**.

The form has the title, the calendars it goes on, **All day**, the start and the end, **Repeat**, the location and notes. Pick two or more calendars to put the event on each of them. It shows once, split between their colors, like any [shared event](#shared-events). Changing the calendars of an event you edit adds it to the new ones and takes it off the ones you clear. On a tablet the form is a dialog. On the Echo Show 5 it fills the screen in two columns, with **Cancel** and **Save** at the top. On a phone it is a full page.

**Repeat** offers every day, every weekday and every week, month or year on the start's day. An event that repeats in a way these choices cannot say, such as every Monday and Thursday, keeps its own rule as the first choice.

With **Allow deleting events** on, the event details have **Delete**. It asks before the event goes, and an event on several calendars comes off all of them.

Saving a change to a repeating event asks whether it covers **This event** or **This and following events**. A new **Repeat** can only start from that day. Deleting one asks for **This event**, **This and following events** or **All events**.

Only calendars whose integration takes changes can be edited, such as Local Calendar, Google Calendar and CalDAV. New event leaves out the others, and their events have no **Edit** or **Delete**. The Calendar screensaver is always read only.

## Shared events

An event that appears on more than one of your calendars, such as an invitation sent to two people, is drawn once. Its background is split on a diagonal, one band per calendar, in the order the calendars are listed in Settings. The details show every calendar it is on. Two copies count as the same event when Home Assistant gives them the same event ID, which Google Calendar, CalDAV and Local Calendar do for invitations. Otherwise they match when the title, start and end are the same.

## Weather

Pick a weather entity under **Weather** to add the daily forecast to each day in the Week view, the Schedule view and the phone's day heading. The kiosk subscribes to the forecast only while the calendar is open.

## Settings

| Setting | Default | Notes |
| --- | --- | --- |
| Default view | Week | The view the calendar opens on. |
| Week starts on | Language default | Sunday, Monday or Saturday, or the first day the device language uses. |
| Weather | None | The weather entity for the daily forecast. |
| Allow adding and editing events | Off | Adds **New event** and **Edit**. See [Adding and changing events](#adding-and-changing-events). |
| Allow deleting events | Off | Adds **Delete** to each event. |
| Close when idle | 2 minutes | Returns to the dashboard after no touch for this long. Never keeps it open. The screensaver also closes it when it starts. It does not apply to the Calendar screensaver. |
| Show in the kiosk menu | On | Opens [Device > User Interface > Drawer menu items](drawer-menu.md), where the Calendar entry is turned on or off. The restricted menu also needs **Calendar** under **Kiosk Mode, Allowed Actions**. |

## How it reads Home Assistant

The kiosk reads the calendars only while something on screen needs them: the calendar while it is open, and the Up next widget while the screensaver shows it. It uses the Home Assistant token from **Settings, Home Assistant**. A token for a user who is not an administrator works for showing the calendar and for changing it on the screen. [Managing it by voice](#managing-the-calendar-by-voice) needs an administrator's token.

On Home Assistant 2026.5 and later each calendar is a live subscription, so a change in Home Assistant shows on the kiosk within seconds. Older versions are asked for the events every five minutes and when the view moves. Recurring events come from Home Assistant already expanded.

If Home Assistant is not reachable, the calendar keeps the events it has and says when they were last updated.

## Managing the calendar by voice

Home Assistant can only list events by voice, for today or the coming week, and has no way to add, move or cancel them. Kiosk Satellite ships a blueprint for an LLM conversation agent (Qwen, Gemma, Gemini, Claude, OpenAI or any other agent that can control Home Assistant) that does all of it on the calendars added to the kiosk. The agent understands the request in any language it speaks.

The built-in **Home Assistant** conversation agent does not work for this. It only matches sentences against Home Assistant's own intents and cannot fill in the script's title, times or people. An LLM agent with **Prefer handling commands locally** turned on works fine.

> **Info:** The long-lived token under **Settings, Home Assistant** must belong to a Home Assistant administrator. This applies to every request the script handles, including questions such as "When is the dentist?". Showing the calendar on the kiosk works with any user's token. The kiosk listens for the script over its own Home Assistant connection. Home Assistant only lets administrators fire and follow the events the script runs on.

1. Import the blueprint:

    [![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjxlarrea%2Fkiosk-satellite%2Fblob%2Fmain%2Fblueprints%2Fscript%2Fkiosk_satellite_calendar.yaml)

2. Create a script from it. Turn off **Show on the kiosk** if the calendar should stay closed while you ask.
3. Expose the script to Assist under **Settings, Voice assistants, Expose**.

Then ask the kiosk:

| Ask | What happens |
| --- | --- |
| "Add soccer practice for Leo on Thursday at 4" | A new event on Leo's calendar, an hour long unless you say when it ends. |
| "Add dinner with Sam and Maya on Friday at 7" | The event goes on both calendars and shows once, split between their colors. |
| "Add a camping trip for everyone from Friday to Sunday" | An all-day event of three days on every calendar. |
| "What's on tomorrow?" or "What does Leo have next week?" | The agent reads out the events, with whose they are. |
| "When is the dentist?" | It looks up to six months ahead. |
| "Move the dentist to 3" or "Move the dentist to Friday" | A new time keeps the day, a new day keeps the time, and the length stays the same. |
| "Rename Friday's dinner to pizza night" | A new title. A new place works the same way. |
| "Cancel Leo's soccer practice on Thursday" | That day only. Say "every time" to cancel the whole series, or "from Thursday on" to end it there. |
| "Show me next week" | The calendar opens on that week. |

[Realtime conversations](voice-satellite.md#realtime-conversations) manage the calendar the same way: with **Tools** on **Home Assistant**, the model sees the exposed script and calls it while the conversation runs.

The kiosk you are talking to opens the calendar on the day the request is about, and an event it added, found or changed has a ring around it for a few seconds. Any touch clears the ring.

The kiosk finds the people by the names of its calendars, their entities and their people, so "Leo" finds a calendar named Leo or one linked to `person.leo`. Everyone, all or family (with no calendar called that) means every calendar. An event added for no one in particular goes on the first calendar in the list. If the agent names someone with no calendar, it asks which one to use.

When more than one event matches a change or a cancel, or the event repeats and you did not say which day, the agent asks which one. An event on several calendars changes or goes on all of them. Only calendars whose integration can take new events, change them or delete them can be changed by voice, such as Local Calendar, Google Calendar and CalDAV. A holiday calendar is read only. The agent says so when a calendar cannot do what you asked.

A request typed into Home Assistant's own chat reaches no kiosk until it names one, as in "add the dentist on the kitchen kiosk", which matches the kiosk's device name or ESPHome name. A kiosk named that way changes the calendar but does not open it.

**Manage the calendar using Voice Satellite** under **Settings, Calendar, Voice Calendar** and on the remote admin's **Calendar** page opens this guide.

## Fleet

The Calendar category carries the calendars with their names, colors and people, and the Display, Editing and Kiosk settings. The calendars hidden with their chips stay on each kiosk. See [Fleet Management](fleet.md).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| The agent waits about 20 seconds, then says it cannot reach the calendar or that no kiosk answered | The kiosk never took the request. Check that the token under **Settings, Home Assistant** belongs to an administrator. With any other token the kiosk does not listen for the script. The app log says "voice alarms, calls, calendar and music need an administrator token, not listening". A request typed into Home Assistant's own chat also has to name a kiosk. |
