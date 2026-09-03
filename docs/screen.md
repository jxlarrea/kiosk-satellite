# Screen

Navigate to **Settings > Screen & Audio > Screen**.

| Setting | Default | What it does |
| --- | --- | --- |
| Keep screen on | off | Prevents the operating system's display timeout from turning off the screen while Kiosk Satellite is in the foreground. |
| Set brightness on launch | off | Applies the specified Default brightness value automatically whenever the app starts up. |
| Default brightness | 80% | Sets the display brightness applied on startup. Adjusting this slider changes the screen brightness immediately. This setting is also controlled by Home Assistant's Screen light entity and the remote admin slider. It is automatically disabled while Adaptive brightness is active. |

## Default Brightness

This option is disabled by default to prevent a default slider from overriding your device's built in brightness settings upon installation. When enabled, Kiosk Satellite applies the configured Default brightness value directly to the display panel whenever the app starts or when the slider is moved. Adjustments made via Home Assistant's Screen light entity or the remote admin slider update the display panel in real time.

Writing values directly to the system display requires the "Modify system settings" permission (an alert appears beneath the slider if this permission is missing). If this permission is not granted, brightness adjustments fall back to window level dimming, which darkens the app content but leaves the system brightness slider unchanged. Every direct system write automatically switches Android's brightness mode to manual, as system level adaptive brightness would otherwise override the set value over time.

## Adaptive Brightness

Navigate to **Settings > Screen & Audio > Adaptive brightness**. This menu option is available only on devices equipped with a physical ambient light sensor. If no sensor is detected, the setting appears disabled with an explanatory note.

| Setting | Default | What it does |
| --- | --- | --- |
| Adaptive brightness | off | Automatically dims or brightens the display based on ambient light levels read by the device's sensor. |
| Ambient light | live | Displays the real time ambient light reading in lux (lx). |
| Minimum brightness | 15% | Sets the minimum screen brightness level for a completely dark room. |
| Maximum brightness | 80% | Sets the maximum screen brightness level for a fully lit room. |
| Dark room (lx) | 5 | Defines the ambient light threshold (in lux) at or below which the screen stays at Minimum brightness. |
| Bright room (lx) | 300 | Defines the ambient light threshold (in lux) at or above which the screen stays at Maximum brightness. |

While Home Assistant automations can map the kiosk's ambient light sensor back to its Screen light entity, that mechanism relies on an active network connection. Kiosk Satellite's native Adaptive brightness processes these adjustments directly on the device, ensuring continuous operation even during network outages.

Brightness scaling between the dark and bright room thresholds follows a logarithmic curve to match human eye perception. A linear scale would keep the display at Minimum brightness for most typical evening light levels before stepping up sharply. With the default configuration (5 lx dark, 300 lx bright), a typical living room in the evening (around 40 lx) sets the screen to roughly half of its configured brightness range.

**Calibrate the light level thresholds against live sensor readings rather than an arbitrary scale.** Light sensors vary widely across hardware: an Echo Show 8 may report 50 lx under bright indoor lighting, whereas a tablet near a window can report thousands of lux. Observe the live Ambient light reading on the settings page under your typical room conditions:
* Set **Bright room (lx)** slightly below the reading obtained with all room lights turned on.
* Set **Dark room (lx)** slightly above the reading obtained in your typical nighttime environment.
* The Dark room threshold must remain below the Bright room threshold, and Minimum brightness must remain below Maximum brightness. Entering conflicting values will trigger a validation error.

When Adaptive brightness is enabled, the Default brightness slider is disabled, and the app calculates startup brightness dynamically based on current room conditions. Screensaver brightness and Dim levels scale proportionally based on the active ambient light curve, ensuring a clock screensaver set to 20% during the day automatically drops to a much lower intensity at night. When returning to the dashboard, the screen restores to the appropriate level for the current lighting environment.

**Home Assistant's Screen light entity, the remote admin slider, and the JavaScript API adjust the underlying setting controlling the panel**:
* Adjustments modify **Default brightness** when Adaptive brightness is turned off.
* Adjustments modify **Maximum brightness** when Adaptive brightness is turned on.

Writing a new value updates the stored setting, and the screen adjusts accordingly. For example, setting the brightness to 60% via an automation sets the Maximum brightness baseline to 60%, allowing ambient dimming to calculate downwards from that new peak at night. Setting requests below the Minimum brightness threshold are rejected to maintain legibility.

The Screen light entity reflects the configured baseline setting. To track the actual output of the display panel as it adjusts along the logarithmic curve, check the **Panel brightness** diagnostic sensor (reported in percentage). When Adaptive brightness is disabled, the entity setting and diagnostic sensor output remain identical. If you need to temporarily lock the display to a specific static brightness value via Home Assistant, turn off the **Adaptive brightness** switch entity (available on both [ESPHome](esphome.md) and [MQTT](mqtt.md) devices) before sending the brightness command. Manual adjustments made using Android's system quick settings shade modify panel output for the current session without altering app settings.

When a screensaver is active, incoming brightness commands update the stored app settings immediately but leave the active screensaver brightness level untouched. The newly requested setting takes effect as soon as the screensaver is dismissed.

Brightness updates are applied smoothly and gradually: the screen updates only when sensor changes shift the calculated output by several percentage points, and updates are throttled to occur no more than once every few seconds. This prevents screen flickering caused by temporary shadows or lamp fluctuations. Room light data reaches the app through the same damped sensor stream that feeds the Ambient light diagnostic entity. On specialized devices (such as certain Android Things hardware) where light sensors register after app initialization, the sensor is recognized upon the next app restart.