# Screen

Settings → Screen & Audio → **Screen**.

| Setting | Default | What it does |
| --- | --- | --- |
| Keep screen on | off | Stops the OS display timeout while the app is in front. |
| Set brightness on launch | off | Applies the default brightness whenever the app starts. |
| Default brightness | 80% | The brightness applied at start. Moving the slider applies it at once. Stands down while adaptive brightness is on. |

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

Settings → Screen & Audio → **Adaptive brightness**. Only offered on a
device with an ambient light sensor; on one without, the switch renders
disabled with the reason.

| Setting | Default | What it does |
| --- | --- | --- |
| Adaptive brightness | off | Dims the screen as the room gets darker, from the device's own ambient light sensor. |
| Ambient light | live | What the sensor reads right now, in lx. |
| Minimum brightness | 15% | Screen brightness in a dark room. |
| Maximum brightness | 80% | Screen brightness in a bright room. |
| Dark room (lx) | 5 | Light level at or below which the screen sits at Minimum brightness. |
| Bright room (lx) | 300 | Light level at or above which the screen sits at Maximum brightness. |

Home Assistant can already map the kiosk's Ambient light sensor onto its
Screen light, but that mapping stops the moment Home Assistant or the
network is away. Adaptive brightness does the same thing on the device,
with nothing to reach.

Between the two light levels the brightness follows the log of the
reading, because the eye judges light on a log scale: a straight line
would park the panel at Minimum for the whole 0..50 lx evening and then
jump. With the defaults, 5 lx and below is Minimum, 300 lx and above is
Maximum, and 40 lx (a lit living room in the evening) sits halfway.

**Set the two light levels against the reading, not against a scale.**
Light sensors disagree wildly about what a lit room reads: an Echo Show 8
reports around 50 lx with every light on, a tablet by a window reports
thousands. That is why the reading is on the page and the levels are
typed rather than slid. Watch the reading with the lights on and put
Bright room a little under it; watch it at night and put Dark room a
little over it. Dark room must stay below Bright room; a value that
would cross the other end is refused with the other end's value in the
message.

While the switch is on, Default brightness stands down (the slider says
so): a session starts at Maximum brightness dimmed for the room as it
is. The screensaver's own brightness and the Dim level keep their
meaning as the level in a bright room and dim by the same share as the
dashboard does, so a clock at 20% by day sits at a few percent at night
with the slider untouched. Its saved restore point is the bright-room
level too, so the dashboard comes back where it belongs however dark it
got in between.

**Home Assistant's Screen light, the remote admin's slider and the JS
API see the panel**, exactly what is on it, and a write from any of them
lands as asked: a scene asking for 30% at night gets 30%. The room's
light then scales it from there, so the morning lifts it with everything
else. For a scene that wants the panel exactly where it puts it and kept
there, turn the switch off first: it is an entity too (**Adaptive
brightness**, on the [ESPHome](esphome.md) and [MQTT](mqtt.md) devices
alike). A change made in Android's own quick settings counts the same
way.

Steps are small and spaced: the panel moves only when the curve moves it
by a few percent and never more often than every couple of seconds, so a
passing shadow or a lamp flicker does not make it pulse. The room's light
reaches the app through the same damped sensor stream that feeds the
Ambient light entity. A sensor that registers itself only after the app
has started (some Android Things devices) is picked up on the next app
start.
