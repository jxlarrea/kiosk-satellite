# Timers

Timers are set by voice or by hand and show in a full screen Timers view. Home Assistant holds every timer, so the same timer answers to voice, the screen, the remote admin and your automations. A kiosk can also share its timers, so they show and ring on other kiosks.

Open the view from **Timers** in the [drawer menu](drawer-menu.md), from **Manage timers** under **Settings > Timers**, from the **Open the timers** [gesture action](gestures.md), from a dashboard button pointed at `ks://timers` (see [Dashboard Links](dashboard-links.md)) or as a view of the [Compass layout](navigation.md). **Kiosk Mode > Allowed Actions > Timers** decides whether the locked kiosk's menu and Compass offer it.

## The Timers view

A timer that starts opens the full screen Timers view. It opens again when a timer is close to finishing and when it finishes. The timer that ends first shows large at the top with its name, the time left as hours, minutes and seconds, a bar that runs down and **Pause** and **Cancel** buttons. The other timers are listed with the same time and bar, beside it on a wide and short screen such as an Echo Show 5 and under it everywhere else. With more than three, the list scrolls.

A finished timer takes the top in its alert color with **Time's up** and a **Dismiss** button. The stop word dismisses it too.

The X closes the view until the next timer starts, nears its end or finishes. The view closes by itself once the last timer is gone.

### Timers and the screensaver

The view sits under the screensaver, like the alarm list. A timer that starts dismisses the screensaver so the view shows, with **Show Timers view when a timer starts** on. A timer that only runs does not keep the screensaver away, so it comes back on its idle timer, unless **Pause screensaver while a timer runs** is on. The screensaver is dismissed and held back when a timer reaches the **Show Timers view when near completion** mark and when one finishes, so the view shows at full brightness. The screensaver can start again once the view is closed or that timer is gone.

## Setting timers by voice

Ask for a timer the way you would on any Assist satellite:

- "Set a timer for 10 minutes"
- "Set a pasta timer for 8 minutes"
- "Pause the pasta timer"
- "Add 2 minutes to my timer"
- "Cancel my timer"

Home Assistant has timers built in, so this works with the default **Home Assistant** conversation agent. No blueprint or LLM conversation agent is needed.

The kiosk needs [Voice Satellite](voice-satellite.md) enabled. With the Voice Satellite integration running in the dashboard instead, its timers show in the same view. They can then be set by voice only.

A named timer is easier to manage. Home Assistant finds a timer by its name. A timer without a name is found by the length it was started with. Two timers on one kiosk with the same name cannot be told apart.

## Setting and changing timers by hand

Timers can also be set from the Timers view and from the remote admin, with native Voice Satellite enabled on the kiosk. Home Assistant holds them like the ones set by voice.

- **Set a timer:** tap **Set a timer** in the Timers view, beside the view's name while a timer runs. Pick hours, minutes and seconds on the wheels, give it a name if you want one and tap **Start**.
- **Change the time left:** tap a timer's time, move the wheels and tap **Set**. Home Assistant has no way to rename a timer, so the name stays.
- **Delete:** tap a timer's time and then **Delete**. Its **Cancel** button does the same.

The remote admin does the same from its **Timers** page. See [Remote admin](#remote-admin).

A timer another kiosk shares can be changed and cancelled the same way. The change is made on the kiosk that owns it.

## When a timer finishes

The timer sound repeats until the timer is dismissed with **Dismiss** or the stop word. **Timer sound** picks the sound, built in or from the sounds folder. **Timer sound volume** sets its level under the assistant volume. **Mute timer alerts** shows the alert without the sound.

With **Speak when a timer ends** on, Home Assistant says a phrase between the sounds: "Your timer is up." or, for a named timer, "Your pasta timer is up." Both phrases can be changed. The **Text to Speech** group picks the engine, the language and the voice. With no engine picked, the first one Home Assistant has speaks it.

## Pills

To get the floating pills back, turn on **Show timers as pills** under **Settings > Timers**. Tap a pill to pause it and double tap it to cancel. The full screen view then opens only from the menu, a gesture, a link or Compass.

## Shared timers

Home Assistant keeps a timer on the satellite it was started on. Shared timers show and ring it on other kiosks as well.

1. On the kiosk where timers are started, open **Settings > Timers** and turn on **Share timers**.
2. Tap **Share with** and pick the kiosks that should run its timers.

Each kiosk has its own list. The bedroom kiosk can share with the office, the kitchen and the living room while the kitchen kiosk shares only with the living room.

On the kiosks picked, the timer shows in the Timers view or as a pill, with the name of the kiosk it comes from. The countdown and the alert stay in step with the kiosk that owns the timer. Pause, Cancel and Dismiss work from any of them and apply everywhere. Mute timer alerts, Speak when a timer ends and the pill settings are each kiosk's own.

The timer stays in Home Assistant as before. Voice commands, the `vs_` actions, the timer sensors and the `esphome.kiosk_satellite_timer` event work only on the kiosk that owns it.

Requirements:

- **Remote admin** and **Find other kiosks** must be on for every kiosk involved. The requests between kiosks use the remote admin port.
- **Show shared timers**, on by default, must be on for the kiosks picked. Shared timers are refused on a kiosk with it off.
- The sharing kiosk runs Voice Satellite in the app. The kiosks picked do not need Voice Satellite.

> **Note:** Shared timers need no password or key. Any device on the network can send a timer to a kiosk while **Show shared timers** is on. Turn it off for a kiosk on a network you do not trust.

The timer list is sent again every 30 seconds while timers run, which covers an update that got lost. Timers from a kiosk that sends nothing for 100 seconds are dropped.

## Timer settings

**Settings > Timers** holds everything about timers:

| Group | Setting | What it does |
|---|---|---|
| | Show Timers view when a timer starts | On by default. Off, starting a timer leaves the screen as it is and the view waits for the near completion mark or the finish. Not shown with **Show timers as pills** on. |
| | Show Timers view when near completion | From 30 seconds to 5 minutes, 1 minute by default. The Timers view opens again once a running timer has that long left, if it was closed or another view was opened after the timer started. The screensaver is dismissed and held. Each timer does it once. Not shown with **Show timers as pills** on. |
| | Pause screensaver while a timer runs | Off by default. Keeps the screensaver from starting while the Timers view is open with a running timer on it. A paused timer does not count. The screensaver starts as usual once the view is closed or another view is in front. Not shown with **Show timers as pills** on. |
| | Show in the kiosk menu | Opens **Drawer menu items**, where the **Timers** row is turned on or off. |
| Timers | Manage timers | Opens the Timers view. In the remote admin, the list of timers itself. |
| Shared timers | Share timers, Share with, Show shared timers | Run this kiosk's timers on other kiosks too. See [Shared timers](#shared-timers). |
| When a timer ends | Timer sound, Timer sound volume | The sound that repeats until the timer is dismissed, built in or from the sounds folder. Its volume is set under the assistant volume. |
| | Mute timer alerts, Speak when a timer ends | **Mute timer alerts** shows the alert without the sound. **Speak when a timer ends** says a phrase between the alert sounds. |
| Text to Speech | Text to speech engine, Language, Voice | Shown with **Speak when a timer ends** on. The Home Assistant text to speech entity that speaks the phrase, with its language and voice. With no engine picked, the first one Home Assistant has speaks it. |
| Pills | Show timers as pills | Off by default. Timers float over the screen instead of opening the full screen view and can be dragged anywhere. The rows below show only with it on. |
| | Show the timer name, Timer pill scale | The name beside the time and the size of the pills. |
| | Show finished timer pills, Show the name on the alert | Whether a finished timer shows a pill and its name. Without the pill, the stop word still ends the alert. The full screen view always shows a finished timer with its name. |
| Voice timers | Manage timers using Voice Satellite | Opens [Setting timers by voice](#setting-timers-by-voice). |

Most rows show only with Voice Satellite enabled on the kiosk. Fleet profiles sync these settings with the **Timers** category. **Share with** and the timer sound stay on each kiosk.

## Remote admin

The **Timers** page lists the kiosk's timers with their time left, counting down. **Set a timer** starts one, a row or its edit button opens the time left and the bin cancels it. The same settings as on the kiosk follow the list.

## Home Assistant

The kiosk's timers reach Home Assistant three ways:

- **Entities.** **VS Timers** counts the timers that are running or paused. **VS Next timer** is a timestamp of when the soonest running timer ends. **VS Mute timers** is the **Mute timer alerts** switch. See [Home Assistant entities and actions](voice-satellite.md#home-assistant-entities-and-actions).
- **Actions.** `vs_start_timer`, `vs_list_timers`, pause, resume, cancel and add or remove time, for automations and dashboard buttons. They are listed in the same section.
- **Events.** Every timer fires an `esphome.kiosk_satellite_timer` event when it starts, changes, is cancelled, finishes or its alert is dismissed. See [Timer events](voice-satellite.md#timer-events).

## Fleets

A [fleet](fleet.md) profile syncs the timer settings with its **Timers** category. **Share with** and the timer sound stay on each kiosk.
