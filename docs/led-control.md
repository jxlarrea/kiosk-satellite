# LED Control

On a device with status lights Kiosk Satellite can drive, such as the light ring of an [Echo Dot](echo-dot.md), the lights show what the kiosk is doing, the way an Echo device does. The **LED Control** page appears only on such a device.

## What the Lights Show

The lights show one thing at a time, the most urgent first:

| When | Effect | Default color |
| --- | --- | --- |
| An alarm rings | Pulses | Cyan |
| A timer rings | Pulses | Cyan |
| An intercom call rings | Pulses | Green |
| Voice Satellite listens | An arc in the accent color turns around the ring | Blue, cyan arc |
| Voice Satellite thinks | The two colors turn around the ring | Blue and cyan |
| Voice Satellite answers | Fades between the two colors | Blue and cyan |
| An intercom call is live | An arc turns around the ring | Green |
| Voice Satellite is muted | Solid | Red |
| A notification is waiting | Pulses slowly | Yellow |
| A timer runs, with **Show the countdown** on | The lights go out one by one | Cyan |
| Music plays on this device, with **Show music** on | Solid or breathing | White |
| Nothing else, with **Light up when idle** on | Solid or breathing | White, at 10% |

With none of these happening and **Light up when idle** off, the lights are off. A realtime conversation shows as listening between answers until it ends.

## Settings

**Enable LED Control** at the top of the page switches all of it on or off. Off, the lights stay dark and the rest of the page is hidden.

**Animate effects**, on by default, moves the arcs and fades the pulses. Off, each effect holds still: the listening arc stays in place, a pulse shows at full brightness and the thinking colors stand side by side, and the lights change only when what they show changes. Turn it off for lights that flicker while they move.

Below it, the page has a group for the idle look and one for each feature: Idle, Voice Satellite, Timers, Alarms, Intercom, Notifications and Media Player. Each group has its own switch, a **Brightness** slider and its colors. Changing any of them shows that group's look on the lights for a few seconds, so a color can be judged on the device itself.

- **Idle** is off by default, and its **Effect** is **Solid** or **Breathing**.
- **Voice Satellite** also has **Show when muted** and the **Muted color**.
- **Timers** also has **Show the countdown**, off by default, as on an Echo Dot.
- **Media Player** is off by default, as on an Echo Dot, and its **Effect** is **Solid** or **Breathing**.

## Home Assistant

With [ESPHome](esphome.md) on, the Idle group shows up in Home Assistant as two entities while **Enable LED Control** is on:

- **LED Control Idle** is a light. Turning it on or off switches **Light up when idle**, and its brightness and color set the group's **Brightness** and **Color**. The brightness moves in 5% steps and never goes below 5%.
- **LED Control Idle Effect** is a select with **Solid** and **Breathing**.

Turning **Enable LED Control** on or off reconnects ESPHome so Home Assistant gets the updated entity list.

## Supported Devices

| Device | Lights |
| --- | --- |
| [Echo Dot (2nd gen)](echo-dot.md) on its LineageOS build | 12-light ring |
| [Echo Dot (3rd gen)](echo-dot-3rd-gen.md) on its Kiosk Satellite Edition image | 12-light ring |

The device draws its own volume level on the ring when the volume changes. The kiosk's lights come back once it is done.
