# Screen

Navigate to **Settings > Screen & Audio > Screen**.

| Setting | Default | What it does |
| --- | --- | --- |
| Keep screen on | off | Prevents the operating system's display timeout from turning off the screen while Kiosk Satellite is in the foreground. |
| Set brightness on launch | off | Applies the specified Default brightness value automatically whenever the app starts up. |
| Default brightness | 80% | Sets the display brightness applied on startup. Adjusting this slider changes the screen brightness immediately. This setting is also controlled by Home Assistant's Screen light entity and the remote admin slider. It is automatically disabled while Adaptive brightness is active. |
| Display cutout | Use the cutout area | Decides what the dashboard does with the screen area around a camera cutout or punch hole. Pick Avoid the cutout if the camera sits on top of buttons at the top of the dashboard. |
| Screen orientation | Automatic | Forces the screen into Landscape, Portrait or either of them reversed. Automatic follows the rotation sensor, or the boot orientation on a device without one. Use a forced orientation on a device that has no rotation sensor or is mounted a way the sensor gets wrong. |
| Hide status bar | on | Hides the status bar at the top of the screen. Turn it off to keep the clock and notification icons in view, with the dashboard below them. Swipe down from the top edge to see a hidden status bar for a moment. Kiosk mode and Lockdown always hide it, whatever this says. |
| Hide navigation bar | on | Hides the navigation bar. Turn it off to keep the navigation buttons in view, with the dashboard above them. On a tablet with a taskbar, such as Samsung's One UI taskbar, this keeps the taskbar in view so you can switch to another app with one tap. Swipe up from the bottom edge to see a hidden navigation bar for a moment. Kiosk mode and Lockdown always hide it, whatever this says. |
| Show over lock screen | off | Shows the dashboard on top of a lock screen that has a PIN, pattern or password, so the dashboard comes back when the screen turns on after the app turned it off. Home, Recents and other apps still ask for the PIN, pattern or password. Leave it off if anyone in front of the device should not use the dashboard while it is locked. A lock screen without a PIN, pattern or password is cleared on every wake, so this switch is only needed for a secured one. |

## Default Brightness

This option is disabled by default to prevent a default slider from overriding your device's built in brightness settings upon installation. When enabled, Kiosk Satellite applies the configured Default brightness value directly to the display panel whenever the app starts or when the slider is moved. Adjustments made via Home Assistant's Screen light entity or the remote admin slider update the display panel in real time.

Writing values directly to the system display requires the "Modify system settings" permission (an alert appears beneath the slider if this permission is missing). If this permission is not granted, brightness adjustments fall back to window level dimming, which darkens the app content but leaves the system brightness slider unchanged. Every direct system write automatically switches Android's brightness mode to manual, as system level adaptive brightness would otherwise override the set value over time.

## Adaptive Brightness

Navigate to **Settings > Screen & Audio > Adaptive brightness**. The light level comes from the device's own ambient light sensor, or from a Home Assistant sensor entity in its place. On a device without a sensor, a note under the switch says so, and the entity can drive the curve instead.

| Setting | Default | What it does |
| --- | --- | --- |
| Adaptive brightness | off | Automatically dims or brightens the display based on the room's light level. |
| Ambient light | live | Displays the device sensor's real time reading in lux (lx). |
| Use Home Assistant entity | off | Reads the light level from a Home Assistant sensor instead of the device's own. |
| Light sensor entity | none | The Home Assistant sensor that reports the light level in lux, shown with its live reading. Appears while Use Home Assistant entity is on. |
| Brightness curve | see below | Four points that set the screen brightness for each light level. |

While Home Assistant automations can map the kiosk's ambient light sensor back to its Screen light entity, that mechanism relies on an active network connection. Kiosk Satellite's native Adaptive brightness processes these adjustments directly on the device, ensuring continuous operation even during network outages.

### Home Assistant light sensor

Turn on **Use Home Assistant entity** and pick an illuminance sensor, such as the light level a motion sensor near the tablet reports. The kiosk follows that entity over its own Home Assistant connection while Adaptive brightness is on, and the curve works the same as it does with the device's sensor. The entity's reading shows on the Light sensor entity row and is marked on the curve. The state must be a number in lux. States such as unavailable or unknown are ignored, and the screen stays at the level the last reading gave it. The last reading is kept across restarts, so the screen starts at the right level while the connection comes up. If Home Assistant is unreachable, the screen holds that level and the kiosk reconnects on its own.

While Adaptive brightness follows a Home Assistant entity, the Clock screensaver's [Night mode](screensavers.md) and plugins read that entity in place of the device's sensor, so they all go by the same light level. On a device without a sensor, this also makes Night mode available. The Ambient light diagnostic entity always reports the device's own sensor.

### Brightness curve

The curve is a chart of screen brightness against the room's light level, with four points you can shape. The first point is the dark room: at or below its light level the screen sits at its brightness, the **Minimum brightness**. The last point is the bright room: at or above its light level the screen sits at its brightness, the **Maximum brightness**. The two points in between set how the screen climbs from one to the other. A smooth curve runs through all four points and never dips where they climb, so a brighter room never dims the screen.

The curve can also run the other way, for a screen that should glow in the dark and dim in daylight, such as an e-ink reader's backlight. Drag the first point above the last one, or type it higher, and the curve turns over: the dark room then sits at the **Maximum brightness** and the bright room at the **Minimum brightness**, and the screen dims as the room gets brighter. Drag it back below the last point to turn the curve back. For a backlight that is fully on in the dark and off in daylight, set the first point to 5 lx at 100% and the last to 6 lx at 0%.

The light level runs on a log scale, because the eye judges light that way. Out of the box the four points sit on a straight line from 5 lx at 15% to 300 lx at 80%, so a typical living room in the evening (around 40 lx) gets roughly half of that range.

Drag a point to move it, or tap it (or its values under the chart) to type an exact light level and brightness. A middle point stays between its neighbors: its light level between theirs and its brightness between theirs. Moving an end brightness takes the middle points with it, so they keep their place along the curve. The live reading is marked on the chart with the brightness it gives right now.

**Shape the curve against live sensor readings rather than an arbitrary scale.** Light sensors vary widely across hardware: an Echo Show 8 may report 50 lx under bright indoor lighting, whereas a tablet near a window can report thousands of lux. Watch the marker under your usual room conditions:
* Put the last point slightly below the reading with all room lights on.
* Put the first point slightly above the reading in your usual nighttime room.
* On a sensor that reads low in the evening, move the middle points to where its evening readings actually land, so the screen does not jump from dim to bright over a few lux.

When Adaptive brightness is enabled, the Default brightness slider is disabled, and the app calculates startup brightness dynamically based on current room conditions. Screensaver brightness and Dim levels scale proportionally based on the active ambient light curve, ensuring a clock screensaver set to 20% during the day automatically drops to a much lower intensity at night. When returning to the dashboard, the screen restores to the appropriate level for the current lighting environment.

**Home Assistant's Screen light entity, the remote admin slider, and the JavaScript API adjust the underlying setting controlling the panel**:
* Adjustments modify **Default brightness** when Adaptive brightness is turned off.
* Adjustments modify **Maximum brightness** when Adaptive brightness is turned on.

Writing a new value updates the stored setting, and the screen adjusts accordingly. For example, setting the brightness to 60% via an automation moves the curve's top point to 60%. The middle points keep their place between the ends, so the whole curve scales with it. Setting requests below the Minimum brightness threshold are rejected to maintain legibility.

The Screen light entity reflects the configured baseline setting. To track the actual output of the display panel as it adjusts along the curve, check the **Panel brightness** diagnostic sensor (reported in percentage). When Adaptive brightness is disabled, the entity setting and diagnostic sensor output remain identical. If you need to temporarily lock the display to a specific static brightness value via Home Assistant, turn off the **Adaptive brightness** switch entity (see [ESPHome](esphome.md)) before sending the brightness command. Manual adjustments made using Android's system quick settings shade modify panel output for the current session without altering app settings.

When a screensaver is active, incoming brightness commands update the stored app settings immediately but leave the active screensaver brightness level untouched. The newly requested setting takes effect as soon as the screensaver is dismissed.

Brightness updates are applied smoothly and gradually: the screen updates only when sensor changes shift the calculated output by several percentage points, and updates are throttled to occur no more than once every few seconds. This prevents screen flickering caused by temporary shadows or lamp fluctuations. Room light data from the device's sensor reaches the app through the same damped sensor stream that feeds the Ambient light diagnostic entity. On specialized devices (such as certain Android Things hardware) where light sensors register after app initialization, the sensor is recognized upon the next app restart.