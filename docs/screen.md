# Screen

Settings → Screen & Audio → **Screen**.

| Setting | Default | What it does |
| --- | --- | --- |
| Keep screen on | off | Stops the OS display timeout while the app is in front. |
| Set brightness on launch | off | Applies the default brightness whenever the app starts. |
| Default brightness | 80% | The brightness applied at start. Moving the slider applies it at once. |
| Adaptive brightness | off | Dims the screen as the room gets darker, from the device's own ambient light sensor. |
| Dark room level | 15% | How far the screen dims in the dark, as a share of each brightness setting. |
| Dark room | 5 lx | The light level at or below which the screen is fully dimmed. |
| Bright room | 300 lx | The light level at or above which the screen shows its full brightness. |

## Default brightness

Off by default, because a slider with no gate would override every
device's own brightness the moment it upgrades. With the gate on, the app
writes the default brightness to the panel when it starts and whenever
the slider moves. Home Assistant's Screen light and the remote admin's
slider move the panel the same way, at any time.

The app writes the panel's real system brightness, which needs the
"Modify system settings" grant (the page says so under the slider when it
is missing); without it, changes fall back to a window-level dimming that
darkens the kiosk but leaves Android's own slider where it was. Every
write puts Android's brightness mode on manual, since under Android's
own adaptive brightness a written value is only a hint the OS drifts away
from.

## Adaptive brightness

Home Assistant can already map the kiosk's [Ambient light](mqtt.md#entities)
sensor onto its Screen light, but that mapping stops the moment Home
Assistant or the network is away. **Adaptive brightness** does the same
thing on the device, with nothing to reach.

It works as one dimming factor applied to every brightness setting, not
as a brightness of its own. Each slider keeps its meaning as the level in
a bright room: the default brightness, the screensaver brightness, the
Dim screensaver's level, a schedule entry's brightness, all of them. As
the room darkens, the same factor dims whatever is on screen, down to the
**Dark room level** share of it. A screensaver at 20% is 20% by day and
3% at night with no setting moving, which is the whole point for a kiosk
in a bedroom.

The factor follows the log of the light level between **Dark room** and
**Bright room**, because the eye judges light on a log scale: a straight
line would park the panel at the floor for the whole 0..50 lx evening and
then jump. With the defaults, 5 lx and below is the floor, 300 lx and
above is the slider as set, and 40 lx (a lit living room in the evening)
sits halfway.

What the rest of the app and Home Assistant see is the bright-room level,
not the dimmed panel. The Screen light in Home Assistant, the remote
admin's slider and the screensaver's saved restore point all read and
write that level, so a scene setting the screen to 50% means 50% in a
bright room and the room's light takes it from there; the screensaver
restores exactly what it saved however dark it got in between. A
brightness change made in Android's own quick settings is taken as the
new bright-room level.

Steps are small and spaced: the panel moves only when the factor changes
by a few percent and never more often than every couple of seconds, so a
passing shadow or a lamp flicker does not make it pulse. The room's light
reaches the app through the same damped sensor stream that feeds the
Ambient light entity.

The switch is only offered on a device with an ambient light sensor; on
one without it renders disabled with the reason. Where the sensor exists,
the switch is also a Home Assistant entity (**Adaptive brightness**, on
the [ESPHome](esphome.md) and [MQTT](mqtt.md) devices alike), so an
automation can turn it off ahead of a scene that wants the panel exactly
where it puts it. A sensor that registers itself only after the app has
started (some Android Things devices) is picked up on the next app start.
