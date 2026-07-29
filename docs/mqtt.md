# Kiosk Satellite MQTT Integration

Kiosk Satellite can publish itself to an MQTT broker using Home Assistant's
[MQTT discovery](https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery),
turning every tablet into a ready-made Home Assistant device with entities
for the screen, the screensaver, key settings and live diagnostics. No YAML,
no manual configuration in Home Assistant: entities appear on their own as
soon as the app connects to the broker Home Assistant uses.

Like every other control surface (the JavaScript API, the remote admin REST
and WebSocket API), the MQTT layer is a thin adapter over the same internal
command registry: a switch flipped in Home Assistant runs exactly the same
command as the equivalent button in the remote admin, and state changes made
anywhere are reflected everywhere.

## Setup

Settings → **MQTT Settings** on the device, or the MQTT Settings tab in the
remote admin:

| Setting | Default | Notes |
| --- | --- | --- |
| Publish to MQTT | off | The master switch. |
| Server | | Hostname or IP of the broker, e.g. `homeassistant.local` for the Mosquitto add-on. |
| Port | `1883` | `8883` is the usual TLS port. |
| Use TLS | off | Encrypt the broker connection. |
| Username / Password | | Leave empty for anonymous brokers. |
| Discovery prefix | `homeassistant` | Only change it if your Home Assistant MQTT integration uses a custom prefix. |

The broker must be the one your Home Assistant instance's MQTT integration
is connected to, and discovery must be enabled there (it is by default).
**Validate connection**, under the credentials, opens a throwaway connection
and reports what the broker says, so a wrong password or a blocked port is
visible without reading the log.

Any number of tablets can share one broker and one set of credentials. Each
install generates a permanent random id that namespaces its topics and
entity ids, so devices never collide; each appears in Home Assistant as its
own device, named after the **Device name** setting. Each device also
carries a "Visit" link on its Home Assistant device page pointing at the
tablet's remote admin (while remote administration is enabled).

## Entities

| Entity | Type | Notes |
| --- | --- | --- |
| Screen | light | On/off is real display power; brightness is the panel's actual brightness. Unavailable on devices with an always-on display: there the screen-off puts the device to sleep and the ROM lights the lock screen straight back up, which no app can override, so the entity withdraws rather than report an off screen you can plainly see is lit. Turn the always-on display off in Android's display settings ("Always show time and info", under Display near the lock screen options) and the entity returns. The state follows the panel whatever moves it, including the power button, the device's own idle timeout and other apps, not only this entity. Turning the screen off needs the device admin permission (the wizard requests it); without the grant the toggle snaps back and the device shows the grant screen. |
| Screensaver | switch | Start or dismiss the screensaver. |
| Dashboard view | select | Navigate the kiosk to any Home Assistant dashboard view, listed by navigation path (`url_path/view-route`; a dashboard whose views cannot be read, like the auto-generated Overview, appears by its bare path). Picking one navigates the kiosk there, dismissing the screensaver and any camera view so the page is actually seen, and holds dashboard rotation for the same grace window a touch does. This is what an automation uses to, say, show the camera dashboard when the doorbell rings and return home after a delay (discussion #66). The state tracks what is on screen, including navigation done by hand on the device; on a page that is no dashboard view at all (HA settings, an external site) it keeps the last known view. The options follow dashboards being added or removed, refreshed every few minutes and on every page load; the entity only appears once the view list has been read from Home Assistant, so it can be missing for the first moments after setup. |
| Volume | number | The device's media volume as a 0-100% slider. Tracks changes from every side, hardware buttons included. |
| Assistant volume | number | The volume of voice assistant responses and chimes, independent of the media volume (issue #69), so music can play loud without the assistant shouting over it. It is a scale applied on top of the media volume: 100% means "as loud as media", lower values speak quieter. Mirrors the same slider in the Voice Satellite settings. |
| Kiosk mode | switch | The kiosk lockdown (exit gesture, blocked buttons). |
| HA kiosk mode | switch | Hides the Home Assistant header and sidebar. On maps to the `auto` mode; a hand-picked `plugin`/`css` choice is left alone until the switch is actually flipped. The HA kiosk method select below is where a specific strategy can be picked. |
| Screensaver mode | select | What the screensaver shows after the idle timeout, as a dropdown of the same modes the Screensaver settings page offers (Clock, Immich Media, Website and so on). Handy for automations that, say, switch to a camera at night and back to photos in the morning. |
| Clock style | select | The face of the Clock screensaver: Digital Clock, Flip Clock or Roller Clock. Only takes effect while the screensaver mode is Clock. |
| HA kiosk method | select | The full HA kiosk mode choice (Off, Auto, Plugin, CSS). The HA kiosk mode switch is the simple toggle; this is the dropdown for picking a specific strategy. |
| Keep screen on | switch | The keep-awake setting. |
| Remote management | switch | The embedded admin web server. Turning it off from Home Assistant closes the remote admin. |
| Screensaver brightness, Screensaver brightness level | switch, number | The separate screensaver brightness (issue #31): the switch enables it, the slider sets the level. Changes apply live while the screensaver is showing. |
| Reload page | button | Reload the current dashboard. |
| Clear cache | button | Clear the WebView cache. |
| Restart app | button | Kill and relaunch the app. The device drops offline for a few seconds and returns on its own. On Android 10+ the relaunch needs the "display over other apps" permission; without it the press is refused and the grant screen opens on the device (the setup wizard requests it up front). |
| Update | update | Shows in Home Assistant's Updates UI when a newer release is on GitHub, with the release notes and a link to the release page. Install triggers the download and installation on the device. On Android 12+ the install is fully hands-free from the second in-app update onward (the first one makes the app its own installer, which is what Android's silent-update rule keys on); before that, and on older Android versions, the device shows its usual install confirmation screen. The app relaunches itself after the install, but on Android 10+ only with the "display over other apps" permission granted (the setup wizard requests it; without it the update still installs and the app stays closed). |
| Battery, Charging | sensor | Polled once a minute. |
| Ambient light | sensor | The device's light sensor in lux, for automating screen brightness from the room's light. Only devices with the hardware get the entity. Readings are damped (small flicker is ignored, big swings publish immediately) so the recorder is not flooded. If you automate brightness from this, turn the Android adaptive brightness off or the two will fight. |
| CPU usage, CPU temperature | sensor | Polled once a minute. Usage is measured from how much of the window the cores actually spent idle, so devices whose governor parks the clocks at full speed no longer read a flat 100%. |
| RAM available, RAM total | sensor | Polled once a minute. |
| Last seen | sensor | When the device last reported in, as a timestamp, republished once a minute. The one entity that does not go unavailable when the device drops: it exists so the drop shows up in history and the timestamp stays readable while the device is gone (issue #75). |
| Current page | sensor | The URL the kiosk is showing. |
| Next alarm | sensor | The device's next alarm clock, as a timestamp, or unknown when none is set. It reads whatever the system considers the next alarm, so any clock app counts, and it follows alarms set, moved, disabled or dismissed outside this app. The `package` attribute names the app that owns it and `local_time` gives the device's own wall-clock reading. |
| Remote admin | sensor | The remote admin's URL for this device, or `disabled` when remote administration is off. Handy for deep-linking from a dashboard. |
| Camera view buttons | button | One **Show &lt;view name&gt;** button per configured camera view, plus **Close camera view**. View buttons keep a stable identity when a view is renamed. |
| Active camera view | sensor | The displayed camera view name, or `none`. Attributes include the stable view ID and focused camera ID. |
| Camera | camera | The device's own camera as a still camera (discussion #72), fed by JPEG snapshots: on demand via the **Take camera snapshot** button below, at a fixed interval with **Continuous snapshots** on (Camera settings), when the screensaver's motion detection spots someone approaching, and once on every broker connect. The frame size follows the Snapshot resolution setting (480p to 1080p on the 4:3 ladder, mapped to the nearest size the device's camera offers). The entity shows the last published frame; nothing streams. It only exists while the camera is enabled in the Camera settings, and it shares the sensor with the screensaver's motion detection, so one never blocks the other. Frames are retained on the broker, so the picture survives a Home Assistant restart. Note that some devices have no camera Android can use even when the hardware has one: a ROM without camera support (LineageOS ports on Echo Show hardware, for example) reports "no camera is available", and the Camera settings say so up front. |
| Take camera snapshot | button | Capture a fresh frame and publish it to the Camera entity. An automation that wants a current picture presses this, then reads the entity a moment later (`camera.snapshot` saves it to a file). |
| Last camera snapshot | sensor | When the Camera entity's frame was captured, as a timestamp. The camera entity's own state never leaves `idle` (nothing streams), so this is what shows, and lets automations react to, a fresh frame arriving. |

All entities carry availability: they go unavailable the moment the tablet
drops off the broker (broker-side last will, so it works however the
connection dies) and recover automatically when it returns. The one
deliberate exception is Last seen, which stays readable while the device
is gone; that is its job.

## Topics

Everything lives under `kiosksatellite/<device id>/`; the id is visible in
the discovery payloads and in the app log line `connected as
kiosksatellite_<id>`. For automations outside Home Assistant:

| Topic | Direction | Payload |
| --- | --- | --- |
| `.../availability` | out, retained | `online` / `offline` |
| `.../screen/state`, `.../screen/set` | out / in | `ON` / `OFF` |
| `.../brightness/state`, `.../brightness/set` | out / in | `0`..`255` |
| `.../screensaver/state`, `.../screensaver/set` | out / in | `ON` / `OFF` |
| `.../kiosk/…`, `.../ha_kiosk/…`, `.../keep_screen_on/…`, `.../remote/…`, `.../screensaver_brightness/…` | out / in | `ON` / `OFF` (`state` and `set` each) |
| `.../screensaver_brightness_level/state`, `.../screensaver_brightness_level/set` | out / in | `0`..`100` |
| `.../assistant_volume/state`, `.../assistant_volume/set` | out / in | `0`..`100` |
| `.../screensaver_mode/…`, `.../screensaver_clock_style/…`, `.../ha_kiosk_method/…` | out / in | the selected option (`state` and `set` each). State carries the display label (e.g. `Immich Media`); `set` accepts the label or the stored value (e.g. `immich`). |
| `.../reload/set`, `.../clear_cache/set`, `.../restart/set` | in | any payload presses the button |
| `.../update/state`, `.../update/set` | out / in | JSON with `installed_version`, `latest_version`, release info and progress; `install` starts the update |
| `.../battery/state`, `.../cpu/state`, `.../cpu_temp/state`, `.../ram_free/state`, `.../ram_total/state`, `.../illuminance/state` | out, retained | numbers |
| `.../last_seen/state` | out, retained | when the device last reported in, ISO 8601 UTC, once a minute |
| `.../url/state` | out, retained | the current URL |
| `.../next_alarm/state` | out, retained | the next alarm as an ISO 8601 UTC timestamp, or `None` when there is no alarm |
| `.../next_alarm/attributes` | out, retained | JSON with `package` and `local_time` |
| `.../admin_url/state` | out, retained | the remote admin URL, or `disabled` |
| `.../dashboard_view/state`, `.../dashboard_view/set` | out / in | the navigation path (`url_path/view-route`); `set` navigates the kiosk there |
| `.../camera/view/set` | in | Stable camera view ID; shows that view |
| `.../camera/close/set` | in | Any non-retained payload closes the camera view |
| `.../camera/view/state` | out, retained | Active camera view name, or `none` |
| `.../camera/view/attributes` | out, retained | JSON with active state, view ID, name and focused camera ID |
| `.../camera_snapshot/set` | in | Any non-retained payload captures a fresh frame |
| `.../camera_snapshot/image` | out, retained | The latest snapshot as raw JPEG bytes |
| `.../camera_snapshot/at` | out, retained | When that snapshot was captured, ISO 8601 UTC |

Discovery configs are published retained under
`<prefix>/<component>/ks_<device id>/<object>/config` and are retracted
automatically when the feature is turned off.

## Permissions

Two Android grants affect what the Screen light can do; both are requested
by the setup wizard and surfaced in Settings when missing:

- **Device admin** ("Screen control"): required to turn the display off.
- **Modify system settings** ("Screen brightness"): required to write the
  panel's real system brightness. Without it, brightness changes fall back
  to dimming the app window: the kiosk still dims visibly, but Android's
  own brightness value does not move.

## Troubleshooting

- **Entities never appear**: confirm the app log shows `connected as
  kiosksatellite_<id>` (Settings → App Logs), that Home Assistant's MQTT
  integration is connected to the same broker, and that the discovery
  prefix matches.
- **Two tablets keep knocking each other offline**: your broker only allows
  one session per username. Kiosk Satellite already uses a unique client id
  per device, so this is broker policy, not id collision. On EMQX the
  culprit is the "Use Username as Client ID" option (`clientid_override`);
  turn it off, or give each tablet its own broker login. The app detects
  the resulting reconnect storm and backs off for 30 seconds at a time, so
  the log will show `MQTT reconnect storm; backing off` while this is
  happening.
- **Brightness in Home Assistant does not match the panel**: grant "Modify
  system settings" (a notice with a Grant button appears in Screen settings
  and in the remote admin while it is missing).
