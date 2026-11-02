# Android Broadcasts

Kiosk Satellite sends an Android broadcast whenever a voice turn, a timer, an intercom call, an alarm, a notification card, the screensaver or the screen changes. Apps on the same device, such as Tasker, MacroDroid, Automate or tvQuickActions, can react right away without a round trip through Home Assistant. A common use is bringing your own app back to the front the moment a voice turn ends.

Every action starts with `me.jxl.kiosk_satellite.event.`, so the full name of `VS_ENDED` is `me.jxl.kiosk_satellite.event.VS_ENDED`. Details ride along as intent extras. Strings stay strings, numbers stay numbers and lists arrive as string lists.

Kiosk Satellite also listens for two broadcasts that start and end a voice turn. See [Voice Satellite](voice-satellite.md#android-broadcasts).

Home Assistant gets the same changes as [Home Assistant Events](events.md).

## Voice Satellite

| Action | When | Extras |
| --- | --- | --- |
| `VS_STARTED` | A voice interaction begins: a turn, an announcement, a `vs_show` prompt, a realtime conversation or a ringing timer. | `reason`: `voice`, `announcement`, `show`, `conversation` or `timer` |
| `VS_LISTENING` | The microphone opens for a command. | |
| `VS_THINKING` | The command is in and the assistant is working on it. | |
| `VS_SPEAKING` | The answer starts playing. | |
| `VS_ANNOUNCEMENT` | An announcement starts playing. | |
| `VS_ENDED` | The interaction is over. Audio focus is released and the overlay is gone. | |

`VS_ENDED` fires once per interaction. A follow-up question, an announcement that asks for a reply and a new wake word while the answer is still on screen all stay inside the same interaction. When **Keep the answer on screen** or **Keep results on screen** leaves the answer up, `VS_ENDED` waits for it to go, so the app you bring back never covers it. A double tap ends it early.

These come from the built-in Voice Satellite. The Voice Satellite integration running in a dashboard does not send them.

### Timers

| Action | When |
| --- | --- |
| `VS_TIMER_STARTED` | A timer started. |
| `VS_TIMER_UPDATED` | Time was added or removed, or the timer was paused or resumed. |
| `VS_TIMER_CANCELLED` | A timer was cancelled. |
| `VS_TIMER_FINISHED` | A timer ran out and its alert rings. |
| `VS_TIMER_DISMISSED` | The ringing alert was silenced by a tap, the stop word or `vs_cancel`. |

The extras are the fields of the [`esphome.kiosk_satellite_timer`](voice-satellite.md#timer-events) event: `timer_id`, `name`, `total_seconds`, `seconds_left` and `is_active`.

## Intercom

| Action | When |
| --- | --- |
| `INTERCOM_CALLING` | This kiosk is calling another one. |
| `INTERCOM_RINGING` | Another kiosk is calling this one. |
| `INTERCOM_IN_CALL` | The call connected. |
| `INTERCOM_BROADCASTING` | This kiosk is announcing to all kiosks. |
| `INTERCOM_LISTENING` | Another kiosk's announcement is playing here. |
| `INTERCOM_MISSED` | A call rang out with no answer. |
| `INTERCOM_ENDED` | The call, announcement or ring is over. |

Every intercom broadcast carries `kiosk`, the other kiosk's name when there is one. `INTERCOM_ENDED` fires once at the end of each call, announcement or ring, missed calls included.

## Alarms

| Action | When |
| --- | --- |
| `ALARM_CREATED` | An alarm was added. |
| `ALARM_UPDATED` | An alarm changed or was switched on or off. |
| `ALARM_DELETED` | An alarm was removed. |
| `ALARM_SUNRISE` | An alarm's sunrise started. |
| `ALARM_RINGING` | An alarm rings, again after each snooze. |
| `ALARM_SNOOZED` | An alarm was snoozed. |
| `ALARM_STOPPED` | An alarm was stopped during a ring, a snooze or a sunrise. |
| `ALARM_SILENCED` | Nobody stopped it before **Silence after** ran out. |

The extras are the fields of the [`esphome.kiosk_satellite_alarm`](alarms.md#alarm-events) event: `alarm_id`, `label`, `time`, `days` and `enabled`, plus `snoozed_until` on `ALARM_SNOOZED`. Each alarm sends its own broadcast when several change at once.

## Notifications

| Action | When |
| --- | --- |
| `NOTIFICATION_TAPPED` | Someone tapped a notification card. |
| `NOTIFICATION_EXPIRED` | A card's `duration` ran out. |
| `NOTIFICATION_DISMISSED` | `notification_dismiss`, the **Notifications dismiss all** button or the remote API took a card down. |
| `NOTIFICATION_REPLACED` | A fifth card pushed it off the screen. |

The extras are the fields of the [`esphome.kiosk_satellite_notification`](events.md#notifications) event: `notification_id`, `title`, `message` and `type`.

## Screensaver

| Action | When |
| --- | --- |
| `SCREENSAVER_STARTED` | The screensaver started. |
| `SCREENSAVER_STOPPED` | The screensaver ended. |

## Screen

| Action | When |
| --- | --- |
| `SCREEN_ON` | The screen turned on. |
| `SCREEN_OFF` | The screen turned off. |

Both carry `source`. It reads `app` when Kiosk Satellite moved the screen, such as the screensaver turning it off. It reads `system` when Android did, such as the power button. See [Screen](events.md#screen) for the details.

## Receiving them

Pick the trigger that listens for an intent and enter the full action name:

- **Tasker:** **Event > System > Intent Received**, with the name in **Action**. Extras show up as local variables, such as `%reason` or `%kiosk`.
- **MacroDroid:** the **Intent Received** trigger, with the name in **Action**.
- **Automate:** the **Broadcast receive** block, with the name in **Action**.

To check what the kiosk sends, open the App Logs and look for lines tagged `broadcasts`, one per broadcast.

## Notes

- Any app on the device can receive these broadcasts, including the timer names, alarm labels and kiosk names in their extras.
- Android 8 and later only delivers them to apps that listen while running. Tasker, MacroDroid, Automate and tvQuickActions all do. An app that only declares a receiver in its manifest will not get them.
- They work while Kiosk Satellite is running, even with another app in front.
