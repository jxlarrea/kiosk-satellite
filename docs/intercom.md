# Intercom

Kiosks on the same network can talk to each other. Pick a kiosk from the kiosk menu and it rings there, or announce to every kiosk at once. Each kiosk decides how it answers: ring, answer on its own after a chime, or not at all. Voice travels straight between the two kiosks through a dedicated intercom listener. Older kiosks use their remote admin port. No server and no Home Assistant sit in the path, and Home Assistant sees the state through ESPHome.

Configure it under **Settings, Intercom** on the kiosk, or the **Intercom** tab in the remote admin. Every kiosk on the intercom needs **Remote management** and **Find other kiosks** on (under Settings, Device, Remote Administration). Kiosks find and reach each other through the remote admin, the same way [Fleet Management](fleet.md) does.

## Setup

1. Turn on **Enable intercom**. The kiosk makes an **Intercom key** the first time.
2. Give every other kiosk the same key. In a fleet the leader syncs it as a credential and nothing needs typing. Outside a fleet, copy the key from the box and paste it on the other kiosk through **Change key**.
3. The **Kiosks** list includes discovered kiosks and saved fleet members with a status word. A kiosk reads **Ready** once its admin endpoint answers with intercom on, the same key and matching encryption settings. Saved fleet members remain listed and are probed even when their mDNS advertisements are missing.

| Status | Meaning |
| --- | --- |
| Ready | The intercom is on there with the same key. |
| Intercom off | The kiosk is on the network but its intercom is off, or it runs a version without one. |
| Different key | Its intercom is on with another key. Paste this kiosk's key there, or the other way around. |
| Encryption mismatch | The kiosks have different encryption settings. Enable **Encrypt communications** on both kiosks for encrypted calls. |
| Do not disturb | It is on the intercom but refuses calls right now. |
| Unreachable | The kiosk is discovered or saved in the fleet but its admin port does not answer from here. It remains listed so later probes can detect its return. |
| Offline | The kiosk is no longer discovered and is not in the saved fleet directory. |

**Change key** opens a dialog to paste a key from another kiosk or **Regenerate** a fresh one. A new key cuts this kiosk off from the others until they get it too.

## Placing a call

The **Intercom** entry in the kiosk menu opens the **Call a kiosk** screen, full screen like the app launcher: **Announce to all** at the top, then every kiosk as a row with its name and status. Press the call button on a Ready kiosk to call it. Kiosks with the intercom off, on Do not disturb, on another key or offline stay on the list dimmed with the reason and have no buttons. The X, back or HOME closes the screen, and so does the screensaver.

The call takes the whole screen: the kiosk's name, Calling and Cancel. Nothing plays until the other side answers. Busy, Do not disturb, no answer and a different key end the call with one line on the screen.

The **Open Call a kiosk** [gesture action](gestures.md) opens the same screen, and **Call a kiosk** rings one kiosk picked when the gesture was set up. Unchecking Intercom under [Device > User Interface > Drawer menu items](drawer-menu.md) takes the entry out of the menu altogether. The restricted menu has its own Intercom switch under **Kiosk Mode, Allowed Actions**, so a wall panel can keep the entry off while a gesture still opens the screen.

## A call coming in

| Answer mode | What happens |
| --- | --- |
| Ring | The ring sound plays every four seconds with Decline and Answer on screen for as long as **Ring for** says. Then the call counts as missed and a toast offers Call back. |
| Answer automatically | One chime, a three second countdown with Decline on screen, then the call opens on its own. The call screen always shows: nobody is listened to without the kiosk saying who is there. |
| Do not disturb | Nothing rings. The caller sees Do not disturb. |

A kiosk in [Lockdown Mode](kiosk.md#lockdown-mode) answers as Do not disturb. A kiosk already in a call answers Busy. A call wakes a dark screen and draws over the screensaver, which picks up where it was once the call ends.

The **Ring sound** is a built-in telephone ring by default, or a file from the same sounds folder as the [notification sound](esphome.md#sounds), put there with the Add a sound row on the device or the remote admin. Either plays at the notification volume.

## In a call

| Talk mode | How it works |
| --- | --- |
| Push to talk | The default. One wide **Hold to talk** button and End. Held, this kiosk sends and the far kiosk hears you. Released, this kiosk listens. It never needs echo cancellation to work, so it is the safe choice on every device. |
| Hands free | The microphone stays open for the whole call with a Mute button. It leans on the kiosk's echo canceller, the same one the wake word listens through. Sound near this kiosk can come through quieter while the other side talks, more so at a high intercom volume. If the other kiosk hears itself back, use push to talk. |

Each kiosk picks its own talk mode. **Intercom volume** under Screen & Audio, beside the media and assistant volumes, is the share of the master volume the other kiosk's voice and announcements play at, 60% by default. Hands free calls work better at a lower intercom volume: the other side's voice leaves less echo for this kiosk to remove.

During a call the kiosk holds the screensaver, the dashboard rotation and the return to home timer the way a voice turn does, ducks the music the same way and pauses wake word detection, so neither voice triggers the assistant. End on either side closes both. The screen shows the call's length for ten seconds with Call again and Close.

**Maximum call duration** ends a live call or announcement after 1 to 60 minutes, Unlimited by default. Each kiosk counts on its own, so the shorter limit ends the call for both, and the call screen reads Maximum call duration reached.

**Hang up call when pressing this button** picks a hardware button that ends the call: Volume up, Volume down, Mute or Help. It ends a call being placed, a live call and either end of an announcement. Outside a call the button keeps its usual job. It is a pick of this device's hardware, so Fleet Management never syncs it.

**Hang up button while ringing** shows once a button is picked and sets what the button does while a call rings here: **Accept** answers the call, **Decline** declines it and **Ignore**, the default, leaves the button its usual job until the call is live. With Accept, a single button handles the whole call: press to answer, press again to hang up. A button only works when Android sees it: `adb shell getevent -l` lists the keys a device reports, and a key the device's key layout leaves unmapped never reaches the app.

Voice is raw 16 kHz audio over one WebSocket per call, about 256 kbit/s each way on the local network, and reaches the other kiosk in roughly a quarter of a second.

## Video calls

**Video calls** under **Settings > Intercom > Video** is on by default. To send video a kiosk also needs **Enable camera** on. A kiosk with that off, or without a camera, still shows video from others but sends none. Turn off **Video calls** to keep a kiosk to voice only. A device without a screen never takes video.

On the roster, a kiosk that takes video has a video button beside its call button. Press it to call with your camera on. You see your own picture while the call rings, and so does the person at the other kiosk. They can answer with **Voice only** or **Video**, or decline.

Your camera goes on when you press video on the roster, **Video** on a ringing call or **Camera** during a call. A hardware button, Home Assistant and the remote admin always answer with the camera off. **Answer automatically** does too unless you turn on **Answer with camera on**.

**Answer with camera on** appears under **Settings > Intercom > Answer** when **Answer mode** is **Answer automatically**. It is off by default. With it on, a call from a kiosk with its camera on opens with this kiosk's camera on as well, so people at the other kiosk can see the room with nobody at this kiosk pressing anything. The countdown reads **Camera on in 3 s**, and pressing **Voice only** or **Decline** stops the camera from turning on. A voice call stays voice only. The setting needs **Enable camera** and is never synced by Fleet Management.

Any call can add video later: press **Camera** while you talk.

On a device with a front and a back camera, **Switch camera** appears under the kiosk's name while the camera sends. Tap the screen to show it. The picture pauses for a moment while the camera changes. If the other camera does not start, the call goes back to the one it was using. The next call starts on the camera picked under **Settings > Camera**. Motion detection and the other camera features use the same camera as the call until it ends. While the camera sends, your own picture stays in the corner of the screen.

The other kiosk's picture fills the screen on a black background. The controls, the kiosk's name and the call's length show when the call connects, then hide after 3 seconds. Tap the screen or press a button to see them again. A tap on a hidden button only brings the controls back. With **Push to talk**, tap the screen to show **Hold to talk**, which stays up for as long as you hold it. They stay on screen while a call rings. If the other kiosk turns its camera off, the call goes back to the voice screen. If the picture stops arriving, the last frame dims and the screen says the video is reconnecting. The voice carries on.

**Video quality** sets what this kiosk sends: Low is 640 x 480 at 15 frames a second, Medium is 640 x 480 at 24 and High is 1280 x 720 at 30. Higher quality uses more CPU. Motion detection and the other camera features keep running during a call.

RTSP and ONVIF streaming stop while this kiosk's camera is sending in a call, and start again when it stops. Connected viewers are dropped and have to reconnect, which most clients do on their own. The **RTSP Streaming** setting stays on throughout. A kiosk that only receives video, or is on a voice call, keeps streaming.

Turn a kiosk during a call and its picture restarts at the new shape, with a short gap in the video.

The dashboard stops drawing during a video call and picks up where it was when the call ends. Video is not available in announcements.

## Announce to all

**Announce to all** is one way: every Ready kiosk gets your voice at once, whatever its own talk mode, and nothing comes back. With push to talk you hold, speak and let go, and the line under the name says who hears you. With hands free the microphone stays open, with Mute, until Done. Kiosks on Do not disturb, with Accept announcements off or in a call are skipped and the screen names who is getting it.

On the receiving kiosks the screen says who is announcing. The ring plays once before the voice. **Reply** calls the sender back as a normal call, **Dismiss** closes it, and it also closes on its own a few seconds after the sender is done. Receivers do not hear each other: an announcement is not a group call.

**Accept announcements** under Answer, on by default, is the receiver's switch. Off, the kiosk refuses Announce to all. Spoken announcements from Home Assistant are a feature of their own under [ESPHome, Announcements](esphome.md#announcements), and need no other kiosk.

## The remote admin

The Intercom tab carries the same settings and the Kiosks card, without Call buttons. While a call is live a card at the top names the other kiosk with the length and **End call**. A video call adds a Video tag. The remote admin cannot see the picture or turn a camera on. The remote admin never answers a call: a browser only opens the microphone on a secure origin, and the remote admin is plain http. The Overview gets a **Do not disturb** tile that flips the answer mode and back.

## Home Assistant

The [ESPHome](esphome.md) device carries an **Intercom enabled** switch, and with the intercom on five more entities.

| Entity | Type | Values |
| --- | --- | --- |
| **Intercom** | text sensor | `idle`, `calling`, `ringing`, `in_call`, `broadcasting`, `listening`, `missed`. Missed holds for a minute after a call nobody answered, so an automation can flash a light when the bedroom does not pick up. |
| **Intercom kiosk** | text sensor | The other kiosk's name during a call and the caller's during the minute of missed, else empty. |
| **Intercom do not disturb** | switch | The answer mode's Do not disturb as a switch. |
| **Intercom answer mode** | select | Ring, Answer automatically, Do not disturb. |
| **Intercom volume** | number | 0 to 100%, the same slider as **Intercom volume** under Screen & Audio. A change during a call takes effect right away. |

ESPHome actions put a call through from an automation or a dashboard button. `esphome.<node name>_intercom_call` rings another kiosk from this one, named by its `kiosk` argument, the kiosk's name as the Kiosks card lists it, any case, or its IP address. The call then runs the way one placed from the kiosk menu does: this kiosk's Talk mode, the other kiosk's Answer mode, and the Intercom sensor follows it. The action answers with the `id` and `kiosk` it rang through `response_variable`, and reports an error when the intercom is off here, no kiosk goes by that name, this kiosk is already in a call or the other kiosk refused with its reason (off, on another key, Do not disturb or busy). `esphome.<node name>_intercom_hangup` ends the call, cancels one still ringing or closes an announcement, and reports an error when there is none. `esphome.<node name>_intercom_answer` and `esphome.<node name>_intercom_decline` answer or decline the call ringing on this kiosk, the same as its on-screen buttons, so a kiosk without a screen can be picked up from Home Assistant. Both report an error when nothing is ringing.

```yaml
- action: esphome.kitchen_tablet_intercom_call
  data:
    kiosk: Bedroom
```

Home Assistant cannot talk on a call: the kiosks hold the microphones. To speak on a kiosk from Home Assistant, use the [announce action](esphome.md#announcements) under ESPHome. On the [remote API](remote-api.md) the same two are `intercomCall {kiosk}` and `intercomHangup`.

Automations can follow calls through the `esphome.kiosk_satellite_intercom` [event](events.md#intercom). Apps on the kiosk itself, like Tasker or MacroDroid, can use [Android Broadcasts](android-broadcasts.md#intercom) instead.

## Calling by voice

Ask the kiosk you are talking to for a call, like "call the kitchen" or "call the Echo Show 8", and it rings that kiosk. This goes through an LLM conversation agent (Qwen, Gemma, Gemini, Claude, OpenAI or any other agent that can control Home Assistant) and a script that Kiosk Satellite ships as a blueprint, so it works in any language the agent speaks.

The built-in **Home Assistant** conversation agent does not work for this, since it cannot fill in the script's fields. An LLM agent with **Prefer handling commands locally** turned on works fine.

> **Info:** The long-lived token under **Settings, Home Assistant** must belong to a Home Assistant administrator. This applies to every request the script handles, including questions such as "Which kiosks can I call?". Calls started on the kiosk work with any user's token. The kiosk listens for the script over its own Home Assistant connection. Home Assistant only lets administrators fire and follow the events the script runs on.

1. Import the blueprint:

    [![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjxlarrea%2Fkiosk-satellite%2Fblob%2Fmain%2Fblueprints%2Fscript%2Fkiosk_satellite_intercom.yaml)

2. Create a script from it. It has no settings.
3. Expose the script to Assist under **Settings, Voice assistants, Expose**.

Name the kiosk the way you think of it: its name, the name its device has in Home Assistant or the area Home Assistant puts it in. "Call the master bedroom" finds the kiosk in the Master Bedroom area. The kiosk checks the other kiosk first, and the agent tells you when it is on Do not disturb, has its intercom off or cannot be reached. When the name fits several kiosks, like two kiosks in one room, the agent asks which one, and "which kiosks can I call?" lists them with their areas. The call rings once the agent has finished its answer, so the reply is never cut off. A [realtime conversation](voice-satellite.md#realtime-conversations) ends right after its answer instead of waiting out its closing silence.

Wake word detection pauses for the whole call, so the kiosk cannot hear "hang up". To end a call without touching the screen, map claps or Show fingers to the **End the intercom call** [gesture action](gestures.md), or pick a hardware button under **Hang up call when pressing this button**. The **Accept intercom call** and **Decline intercom call** gesture actions answer a ringing call the same way.

The call goes out from the kiosk you are talking to. A request typed into Home Assistant's own chat reaches no kiosk until it names the one that should call, as in "call the kitchen from the bedroom kiosk", which matches the kiosk's device name or ESPHome name.

The script works from automations too. Set `caller` to the kiosk that should place the call, and the call rings at once:

```yaml
action: script.kiosk_satellite_intercom
data:
  action: call
  kiosk: Kitchen
  caller: Bedroom
response_variable: result
```

## Fleet Management

The Intercom category syncs like the others. The key travels only as a credential, on by default in new profiles, so a fleet shares one key without anyone typing it. The intercom volume stays out of new profiles like the other volumes. So does the answer mode, so Do not disturb on one kiosk never mutes the rest of the fleet. Add **Answer mode** back to a profile to share it.

## Remote API

The intercom's routes sit in front of the admin login. Every one of them except the identity carries a bearer token signed with the intercom key for that one call, good for a minute and once.

| Endpoint | Method | Description |
| --- | --- | --- |
| `/api/intercom/identity` | GET | `{id, name, version, enabled, key, dnd, video, endpoint: {port, tls}}`. `key` is the first eight hex digits of the key's SHA-256, what the status words compare. Public, one probe a second per client. |
| `/api/intercom/call` | POST | `{call, kind: call or broadcast, from: {id, name, address, port, version, tls}, video: {camera}}` answers `{status, video}`: `ringing`, `auto`, `listening`, `busy`, `dnd`, `off`, 409 with `status: tls` for incompatible encryption or 403 for another key. Plaintext requests are refused with 426 when encryption is required. |
| `/api/intercom/call/<id>` | POST | `{action}`: `answer`, `decline`, `missed` from the callee, `cancel` and `hangup` from the caller. |
| `/api/intercom/audio/<id>` | WebSocket | `?token=` as above. Binary frames are 80 ms of PCM16 mono 16 kHz from the sender's microphone. Text frames: `{"type": "talk", "on": true}` and `{"type": "end"}`. |
| `/api/intercom/video/<id>` | WebSocket | `?token=` as above. Opened by the caller as soon as the call rings, when both kiosks take video. Binary frames carry one H.264 frame in Annex B form after a 9 byte header: flags (bit 0 marks a key frame, which carries its SPS and PPS), width and height as 16 bit values and the capture time in milliseconds as a 32 bit value, all big endian. Text frames: `{"type": "camera", "on": true}`, `{"type": "ack", "n": 12}` for each frame received and `{"type": "key"}` to ask for a key frame. A sender with six frames unacknowledged drops frames until the next key frame. |

Both pages use the commands `intercomStatus`, `intercomKiosks`, `intercomCall {id}` or `{kiosk}` (a name or address), `intercomBroadcast`, `intercomHangup`, `intercomTalk {on}`, `intercomMute {on}`, `intercomSwitchCamera`, `intercomOpen`, `intercomSetDnd {on}`, `intercomSetKey {key}` or `{regenerate: true}` and `intercomDismiss`. `intercomAnswer`, `intercomDecline`, `intercomVideoCall {id}` and `intercomCamera {on}` are refused over the remote API: only the kiosk screen answers or turns the camera on. The WebSocket feed carries an `intercom` event with the whole status on every change.

## Notes

- One call at a time per kiosk. A second caller gets Busy. A broadcast reaching a kiosk in a call skips that kiosk.
- Without the microphone permission a kiosk still takes calls and hears the other side. The screen says it is listening only.
- A dashboard that holds the microphone itself, such as Voice Satellite streaming to Home Assistant for its wake word, is asked to let go for the call and gets it back when the call ends. Voice Satellite 2026.9.7 and later do that. An older one keeps it and the call is listen only, which the screen says. A page that takes the microphone during a call ends the call.
- Voice is not compressed in this version. That keeps every Android the app runs on, Android 7 included, on the same footing.

## Encryption

Turn on **Encrypt communications** under **Settings > Intercom > TLS** on each participating kiosk. This uses a separate HTTPS and WSS listener without changing Remote Administration. Kiosks discover its port automatically. Changing this setting ends active calls. See [TLS encryption](tls.md) for connection behavior, network requirements and certificate management.

Kiosks with different intercom encryption settings show **Encryption mismatch** and cannot call each other. Enable **Encrypt communications** on all participating kiosks for encrypted calls. **Announce to all** skips kiosks with incompatible encryption settings. The app never sends intercom credentials or audio over plaintext when encryption is enabled. Home Assistant announcements that play only on this kiosk keep their existing behavior.
