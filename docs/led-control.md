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
| Nothing else, with **Light up when idle** on | The idle **Effect**, solid by default | White, at 10% |

With none of these happening and **Light up when idle** off, the lights are off. A realtime conversation shows as listening between answers until it ends.

## Settings

**Enable LED Control** at the top of the page switches all of it on or off. Off, the lights stay dark and the rest of the page is hidden.

**Animate effects**, on by default, moves the arcs and fades the pulses. Off, each effect holds still: the listening arc stays in place, a pulse shows at full brightness and the thinking colors stand side by side, and the lights change only when what they show changes. Turn it off for lights that flicker while they move.

Below it, the page has a group for the idle look and one for each feature: Idle, Voice Satellite, Timers, Alarms, Intercom, Notifications and Media Player. Each group has its own switch, a **Brightness** slider and its colors. Changing any of them shows that group's look on the lights for a few seconds, so a color can be judged on the device itself.

- **Idle** is off by default, and its **Effect** sets how the lights show. The default is **Solid**.

### Idle effects

These effects use the group's **Color**:

| Effect | What the lights do |
| --- | --- |
| **Solid** | Every light stays on |
| **Breathing** | The ring fades slowly in and out |
| **Pulse** | The ring fades quickly in and out |
| **Heartbeat** | Two quick swells and a rest |
| **Wave** | A soft crest of light travels around the ring |
| **Shimmer** | Each light rises and falls slowly at its own pace |
| **Sparkle** | Lights flash at random over a dim glow |
| **Flicker** | Every light wavers like a flame |
| **Comet** | A bright head with a fading tail goes around |
| **Marquee** | Blocks of two lights step around the ring |
| **Sweep** | Two lights start together, go around in opposite directions, meet on the other side and come back |
| **Fan** | Three blades turn around the ring |
| **Fill** | The ring fills up light by light, then empties in the same order |
| **Twin orbit** | Two lights go around in opposite directions |
| **Pendulum** | One light swings back and forth |

These effects have colors of their own, so the **Color** setting has no effect on them:

| Effect | What the lights do |
| --- | --- |
| **Rainbow** | A rainbow turns around the ring |
| **Color cycle** | The whole ring moves slowly through the rainbow |
| **Rainbow comet** | A comet that changes color as it goes |
| **Rainbow sparkle** | Sparkles in every color |
| **Candlelight** | A warm candle flame |
| **Campfire** | Red, orange and yellow flames |
| **Lava** | Reds and oranges drift slowly |
| **Northern lights** | Greens, teals and purples drift slowly |
| **Sunset** | Oranges, pinks and purples drift slowly |
| **Ocean** | Blue waves with light crests |
| **Frost** | Icy whites and blues shimmer |
| **Forest** | Greens shimmer |
| **Candy cane** | Red and white blocks step around |
| **Holiday** | Red and green blocks step around |
| **Neon** | A pink and a cyan light go around in opposite directions |

With **Animate effects** off, each one holds a single still frame.

- **Voice Satellite** also has **Show when muted** and the **Muted color**.
- **Timers** also has **Show the countdown**, off by default, as on an Echo Dot.
- **Media Player** is off by default, as on an Echo Dot, and its **Effect** is **Solid** or **Breathing**.

## Home Assistant

With [ESPHome](esphome.md) on, the Idle group shows up in Home Assistant as two entities while **Enable LED Control** is on:

- **LED Control Idle** is a light. Turning it on or off switches **Light up when idle**, and its brightness and color set the group's **Brightness** and **Color**. The brightness moves in 5% steps and never goes below 5%. Its effect list has every [idle effect](#idle-effects), so an automation can set the color, brightness and effect in one `light.turn_on` action. The effect name is not case sensitive.
- **LED Control Idle Effect** is a select with the same effects.

Turning **Enable LED Control** on or off reconnects ESPHome so Home Assistant gets the updated entity list.

## Supported Devices

| Device | Lights |
| --- | --- |
| [Echo Dot (2nd gen)](echo-dot.md) on its LineageOS build | 12-light ring |
| [Echo Dot (3rd gen)](echo-dot-3rd-gen.md) on its Kiosk Satellite Edition image | 12-light ring |

The device draws its own volume level on the ring when the volume changes. The kiosk's lights come back once it is done.
