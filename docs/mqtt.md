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
| Screen | light | On/off is real display power; brightness turns the setting that governs the level: Default brightness, or Maximum brightness while [Adaptive brightness](screen.md#adaptive-brightness) is on (then the dimmed panel is the Panel brightness sensor, and a write below Minimum brightness is refused). With adaptive brightness off, brightness is the panel's actual brightness. Unavailable on devices with an always-on display: there the screen-off puts the device to sleep and the ROM lights the lock screen straight back up, which no app can override, so the entity withdraws rather than report an off screen you can plainly see is lit. Turn the always-on display off in Android's display settings ("Always show time and info", under Display near the lock screen options) and the entity returns. The state follows the panel whatever moves it, including the power button, the device's own idle timeout and other apps, not only this entity. Turning the screen off needs the device admin permission (the wizard requests it); without the grant the toggle snaps back and the device shows the grant screen. Turning it off also arms the device's lock screen, so turning it on clears a lock screen that has no PIN, pattern or password; a secured one keeps the kiosk behind it until the device is unlocked, and so does Fire OS 8, which refuses the dismissal to every app but Amazon's own (see [Amazon Fire tablets](fire.md) for the adb switch that turns the lock screen off). |
| Screensaver | switch | The master screensaver enable/disable, the same toggle the Screensaver settings page has. Turning it off keeps the screensaver away until it is turned back on, dismissing one that is showing; turning it on arms the normal idle timeout. This is the switch for automations that hold the screen awake for a while, without the Postpone screensaver button loop. |
| Screensaver active | switch | Whether the screensaver is on screen right now. Turning it on starts the screensaver immediately; turning it off dismisses it until the idle timeout runs out again. |
| Postpone screensaver | button | Resets the screensaver's idle timer as if someone had touched the screen, dismissing the screensaver first if it is showing. Made for automations that keep the display awake from an external sensor — a door contact or a motion sensor elsewhere in the room — the outside-sourced counterpart of the camera-based Postpone on motion setting. |
| Hold mode | switch | Pins whatever is on screen: the screensaver will not start, dashboard view rotation freezes in place, the return to home timer stands down and the display stays awake until the switch turns off. Turning it on dismisses a showing screensaver first. The same live state as the Hold mode toggle in the Home Assistant settings, the gesture action and the drawer notice, so an automation can hold the view for media playback and release it after. An optional auto release timer on the device ends the hold by itself. |
| Dashboard view | select | Navigate the kiosk to any Home Assistant dashboard view, listed by navigation path (`url_path/view-route`; a dashboard whose views cannot be read, like the auto-generated Overview, appears by its bare path). Picking one navigates the kiosk there, dismissing the screensaver and any camera view so the page is actually seen, and holds dashboard rotation for the same grace window a touch does. This is what an automation uses to, say, show the camera dashboard when the doorbell rings and return home after a delay. The state tracks what is on screen, including navigation done by hand on the device; on a page that is no dashboard view at all (HA settings, an external site) it keeps the last known view. The options follow dashboards being added or removed, refreshed every few minutes and on every page load; the entity only appears once the view list has been read from Home Assistant, so it can be missing for the first moments after setup. |
| Volume | number | The MASTER volume: the device's own, as a 0-100% slider. Tracks changes from every side, hardware buttons included. Media and Assistant volume scale under it, mixer style: this is the room-level knob, the other two set the balance. |
| Media volume | number | Music and video (Sendspin, DLNA) play at this share of the master volume. The Sendspin player's volume in Music Assistant is this same fader, so the two sliders always agree. Mirrors the Media volume slider in the Screen & Audio settings. |
| Assistant volume | number | Voice assistant responses and chimes play at this share of the master volume, independent of the media volume, so music can roam loud or quiet without the assistant shouting or whispering along with it. Mirrors the Assistant volume slider in the Screen & Audio settings. |
| Kiosk mode | switch | The kiosk lockdown (exit gesture, blocked buttons). |
| Lockdown mode | switch | Lockdown Mode: disables screen interactions while the dashboard stays visible, arms every Kiosk Mode protection without changing the stored kiosk settings, and mutes wake word detection while it holds. Turning it on also brings the app to the front so nothing sits above the shield. See the [Kiosk and Lockdown doc](kiosk.md). |
| HA kiosk mode | switch | Hides the Home Assistant header and sidebar. What each of the two hides is set on the device, in the Home Assistant settings. |
| Screensaver mode | select | What the screensaver shows after the idle timeout, as a dropdown of the same modes the Screensaver settings page offers (Clock, Immich Media, Website and so on). Handy for automations that, say, switch to a camera at night and back to photos in the morning. |
| Clock style | select | The face of the Clock screensaver: Digital Clock, Flip Clock or Roller Clock. Only takes effect while the screensaver mode is Clock. |
| Clock background | text | The Clock screensaver's background photo, as a file path on the device. Writing a path shows that image behind the clock, overwriting whatever photo was picked on the device; an empty value clears the background back to the solid color. Getting the image onto the device is up to you (the remote admin's File Manager can upload one); a path that does not exist simply shows no background, and starts showing the moment the file appears. Changes apply live, even while the clock is on screen. |
| Keep screen on | switch | The keep-awake setting. |
| Remote management | switch | The embedded admin web server. Turning it off from Home Assistant closes the remote admin. |
| Screensaver brightness, Screensaver brightness level | switch, number | The separate screensaver brightness: the switch enables it, the slider sets the level. Changes apply live while the screensaver is showing. |
| Adaptive brightness | switch | The [Adaptive brightness](screen.md#adaptive-brightness) setting: the device dims its screen from its own ambient light sensor. With it on, the Screen light's brightness is the Maximum brightness setting, the top of the curve. Turn the switch off ahead of a scene that wants the panel exactly where it puts it. Only exists on devices with a light sensor. |
| Panel brightness | sensor | What the panel shows right now, in percent, following every step of the adaptive curve. Diagnostic. Equal to the Screen light's brightness with adaptive brightness off. |
| Camera enabled | switch | The camera master toggle, the same Enable camera switch the Camera settings page has. Camera use costs roughly 10% CPU, so an automation with a room-wide motion sensor can keep it off until someone is around and only then arm the camera features. Turning it off also retracts the camera entities below and the motion sensor. Only exists on devices with a usable camera. |
| Screensaver motion detection | switch | The screensaver's Dismiss on motion toggle: with it on, the camera watches during the screensaver and wakes the screen when someone approaches. Pairs with the Camera enabled switch for staged wake-ups: an external sensor turns the camera on and the approach detection takes over from there. Only exists on devices with a usable camera. |
| Screensaver face detection | switch | The screensaver's Dismiss on face toggle: with it on, the camera watches during the screensaver and wakes the screen only when someone looks at the kiosk. Dismiss on motion keeps precedence on the device, so an automation that wants faces by day and motion by night flips the motion switch, not this one. Only exists on devices with a usable camera. |
| Screensaver proximity detection | switch | The screensaver's Dismiss on proximity toggle: with it on, the device's proximity sensor is watched during the screensaver and wakes the screen when something comes close to it. Only exists on devices with a proximity sensor. |
| Camera facing | select | Which camera the device uses, Front or Back, for every camera feature: snapshots, motion detection and the motion sensor. The same Camera pick the Camera settings page has. Switching it publishes a fresh frame from the newly picked camera to the Camera entity a moment later, so an automation can flip a phone to its back camera as a baby monitor and back again. Like the switches above it works with the camera off, so the facing can be set before an automation enables the camera. Only exists on devices with both a front and a back camera. |
| Reload page | button | Reload the current dashboard. |
| Go to dashboard | button | Navigate back to the configured Start URL, the device's own dashboard. Unlike Reload page, this leaves whatever page is currently shown, so it is the way home after temporarily sending the device to another dashboard. |
| Bring to front | button | Bring Kiosk Satellite back in front of whatever app covers it, typically after the `launchApp` REST command opened another app. Does nothing when already in front, so it is safe to press blind. On Android 10+ it needs the "display over other apps" permission (the setup wizard requests it up front). |
| Open app launcher | button | Open the app launcher overlay with the apps picked under App Launcher settings. Wakes the screen and brings the app to the front first, so the launcher is actually visible when it opens. Refused with a log line when no apps are whitelisted. The entity only exists while the App Launcher is enabled; turning it off retracts the button. |
| Clear cache | button | Clear the WebView cache. |
| Restart app | button | Kill and relaunch the app. The device drops offline for a few seconds and returns on its own. On Android 10+ the relaunch needs the "display over other apps" permission; without it the press is refused and the grant screen opens on the device (the setup wizard requests it up front). |
| Update | update | Shows in Home Assistant's Updates UI when a newer release is on GitHub, with the release notes and a link to the release page. Install triggers the download and installation on the device; it asks GitHub for the latest release first, so a version published after the notice appeared is the one that installs, and no second update is left waiting behind it. On Android 12+ the install is fully hands-free from the second in-app update onward (the first one makes the app its own installer, which is what Android's silent-update rule keys on); before that, and on older Android versions, the device shows its usual install confirmation screen. The app relaunches itself after the install, but on Android 10+ only with the "display over other apps" permission granted (the setup wizard requests it; without it the update still installs and the app stays closed). |
| Battery, Charging | sensor | Polled once a minute. Battery only exists on a device that has one: a mains-powered box without a battery gets Charging alone, which says whether it is on external power. |
| Ambient light | sensor | The device's light sensor in lux, for automating screen brightness from the room's light. Only devices with the hardware get the entity. Readings are damped (small flicker is ignored, big swings publish immediately) so the recorder is not flooded. If you automate brightness from this, turn the Android adaptive brightness off or the two will fight. |
| CPU usage, CPU temperature | sensor | Polled once a minute. Usage is measured from how much of the window the cores actually spent idle, so devices whose governor parks the clocks at full speed no longer read a flat 100%. |
| RAM available, RAM total | sensor | Polled once a minute. |
| Connectivity | binary_sensor | Whether the device currently holds its broker session: on while connected, off the moment the broker's last will fires after a hard death or the app disconnects gracefully. It is the availability signal reread as a state, so it costs no extra traffic at all, and unlike the other entities it does not go unavailable when the device drops; that is the moment it exists to show. Use it as the trigger for offline automations and as a plottable online/offline history timeline; its `last_changed` answers "offline since when" in templates. |
| Last seen | sensor | When the device last came online, as a timestamp: stamped on every broker connect and once more when the app disconnects gracefully (a restart, the feature being turned off), rather than republished every minute, so it costs the recorder one row per real event instead of one a minute. The one entity that does not go unavailable when the device drops, so the timestamp stays readable while the device is gone. After a hard death (power cut, crash) the state keeps the connect-time stamp; the moment of the drop itself is the availability transition, which Home Assistant records on every entity's history when the broker's will fires. |
| Current page | sensor | The URL the kiosk is showing. |
| Device | sensor | The device's model name, with the Android version and the OEM build in the `android_version` and `build` attributes. |
| IPv4 address, IPv6 address | sensor | The device's primary address as the state, every other address in the `other_addresses` attribute, and all of them keyed by network interface in the `interfaces` attribute, so a script can tell whether the device is connected over its wired or its wireless NIC. The IPv6 sensor prefers a routable address over the link-local `fe80::` one when it has both. Addresses are re-checked once a minute and moments after any network change; a family with no address at all reads unknown. |
| App uptime, Network uptime | sensor | When the app process started and when the device's network came up, as timestamps. Home Assistant renders a timestamp entity as a live "n hours ago" and templates get the duration with `now() - states(...)`, while the state itself only changes on a real restart or reconnect, so the recorder logs those moments and nothing in between. Network uptime reads the kernel's own timestamp on the interface's IP address, so it survives app restarts and anchors at when the address was configured; a reconnect or a new DHCP address resets it, a lease renewal does not. On a ROM that refuses the kernel read it falls back to an anchor at app start (the app log says which source a device is using). Unknown while the device is offline. |
| Next alarm | sensor | The device's next alarm clock, as a timestamp, or unknown when none is set. It reads whatever the system considers the next alarm, so any clock app counts, and it follows alarms set, moved, disabled or dismissed outside this app. The `package` attribute names the app that owns it and `local_time` gives the device's own wall-clock reading. |
| Last interaction | sensor | When someone last touched the screen or spoke to the device, as a timestamp, so an automation can tell an idle kiosk from one in use and pick its own idle threshold: `now() - states('sensor...._last_interaction') > timedelta(minutes=5)` in a template, or a Time-based trigger on the entity staying unchanged. Touches, voice turns and waking the screen by hand (the power button, double-tap-to-wake) count; motion, announcements, timers, media playback and the app's own wakes (the wake word, motion, an automation turning the Screen light on) deliberately do not, so someone walking past or a TTS message does not read as the kiosk being used. A device whose ROM lights the screen when a charger is plugged in reads that as a wake by hand too. Under a continuous stream of touches it republishes at most once a minute, and the final touch always lands accurately once the stream stops. Unknown until the first interaction after install. |
| Remote admin | sensor | The remote admin's URL for this device, or `disabled` when remote administration is off. Handy for deep-linking from a dashboard. |
| Foreground app | sensor | Which app is on the device's screen, so an automation can react to the kiosk being left behind another app: the app's package name as the state (stable across languages and renames, so automations match on it safely), its human-readable name in the `label` attribute. Updates within a few seconds of an app opening over the kiosk or the kiosk coming back, and once a minute otherwise. Identifying other apps needs the **Usage access** grant (Permissions Manager, under Device settings); without it the sensor still reports `me.jxl.kiosk_satellite` while the kiosk is frontmost, and `unknown` when it is not. |
| Camera view buttons | button | One **Show &lt;view name&gt;** button per configured camera view, plus **Close camera view**. View buttons keep a stable identity when a view is renamed. |
| Active camera view | sensor | The displayed camera view name, or `none`. Attributes include the stable view ID and focused camera ID. |
| Camera | camera | The device's own camera as a still camera, fed by JPEG snapshots: on demand via the **Take camera snapshot** button below, at a fixed interval with **Continuous snapshots** on (Camera settings), when the screensaver's motion detection spots someone approaching, and once on every broker connect. The frame size follows the Snapshot resolution setting (480p to 1080p on the 4:3 ladder, mapped to the nearest size the device's camera offers). The entity shows the last published frame; nothing streams. It only exists while the camera is enabled in the Camera settings, and it shares the sensor with the screensaver's motion detection, so one never blocks the other. Frames are retained on the broker, so the picture survives a Home Assistant restart. Note that some devices have no camera Android can use even when the hardware has one: a ROM without camera support (LineageOS ports on Echo Show hardware, for example) reports "no camera is available", and the Camera settings say so up front. |
| Take camera snapshot | button | Capture a fresh frame and publish it to the Camera entity. An automation that wants a current picture presses this, then reads the entity a moment later (`camera.snapshot` saves it to a file). |
| Last camera snapshot | sensor | When the Camera entity's frame was captured, as a timestamp. The camera entity's own state never leaves `idle` (nothing streams), so this is what shows, and lets automations react to, a fresh frame arriving. |
| Screenshot | camera | What the device's display is showing, as a still camera fed only by the **Take screenshot** button below. Made for checking on a panel that is not in the same room: press the button, look at the entity. It captures whatever is actually on screen, dashboard, screensaver, kiosk menu and all, scaled down to at most 1080p, and the frame is retained on the broker so it survives a Home Assistant restart. Unlike the Camera entities it needs no camera hardware, so every device gets it. |
| Take screenshot | button | Capture the screen and publish it to the Screenshot entity. |
| Last screenshot | sensor | When the Screenshot entity's frame was captured, as a timestamp; like the camera, the entity's own state never moves, so this is what shows a fresh frame arriving. A capture from the remote admin's overview page counts too and refreshes the Screenshot entity the same way. |
| Motion | binary_sensor | Camera-based motion, with the **Motion sensor** setting on (Camera settings). The app only ever publishes motion; the clearing is Home Assistant's `off_delay`, set from the **Clear after** setting, so a broker reconnect never replays stale motion. See the [Device Camera doc](camera.md). |

All entities carry availability: they go unavailable the moment the tablet
drops off the broker (broker-side last will, so it works however the
connection dies) and recover automatically when it returns. The two
deliberate exceptions are Last seen and Connectivity, which stay readable
while the device is gone; that is their job.

## Topics

Everything lives under `kiosksatellite/<device id>/`; the id is visible in
the discovery payloads and in the app log line `connected as
kiosksatellite_<id>`. For automations outside Home Assistant:

| Topic | Direction | Payload |
| --- | --- | --- |
| `.../availability` | out, retained | `online` / `offline` |
| `.../screen/state`, `.../screen/set` | out / in | `ON` / `OFF` |
| `.../brightness/state`, `.../brightness/set` | out / in | `0`..`255` |
| `.../panel_brightness/state` | out | `0`..`100` |
| `.../screensaver_active/state`, `.../screensaver_active/set` | out / in | `ON` / `OFF` |
| `.../screensaver/…`, `.../kiosk/…`, `.../ha_kiosk/…`, `.../keep_screen_on/…`, `.../remote/…`, `.../screensaver_brightness/…`, `.../adaptive_brightness/…`, `.../hold_mode/…`, `.../camera_enabled/…`, `.../screensaver_motion/…`, `.../screensaver_face/…`, `.../screensaver_proximity/…` | out / in | `ON` / `OFF` (`state` and `set` each) |
| `.../screensaver_brightness_level/state`, `.../screensaver_brightness_level/set` | out / in | `0`..`100` |
| `.../assistant_volume/state`, `.../assistant_volume/set` | out / in | `0`..`100` |
| `.../media_volume/state`, `.../media_volume/set` | out / in | `0`..`100` |
| `.../screensaver_mode/…`, `.../screensaver_clock_style/…`, `.../camera_device/…`, `.../ha_kiosk_method/…` | out / in | the selected option (`state` and `set` each). State carries the display label (e.g. `Immich Media`); `set` accepts the label or the stored value (e.g. `immich`). |
| `.../clock_background/state`, `.../clock_background/set` | out / in | a device-local file path shown behind the Clock screensaver; empty clears it |
| `.../reload/set`, `.../clear_cache/set`, `.../restart/set` | in | any payload presses the button |
| `.../open_launcher/set` | in | Any non-retained payload opens the app launcher overlay |
| `.../update/state`, `.../update/set` | out / in | JSON with `installed_version`, `latest_version`, release info and progress; `install` starts the update |
| `.../battery/state`, `.../cpu/state`, `.../cpu_temp/state`, `.../ram_free/state`, `.../ram_total/state`, `.../illuminance/state` | out, retained | numbers |
| `.../last_seen/state` | out, retained | when the device last came online, ISO 8601 UTC, stamped per connect and graceful disconnect |
| `.../device_info/state` | out, retained | the device model |
| `.../device_info/attributes` | out, retained | JSON with `android_version` and `build` |
| `.../ipv4_address/state`, `.../ipv6_address/state` | out, retained | the primary address of that family, empty when it has none |
| `.../ipv4_address/attributes`, `.../ipv6_address/attributes` | out, retained | JSON with `other_addresses` and `interfaces` (addresses keyed by interface name) |
| `.../app_uptime/state`, `.../network_uptime/state` | out, retained | start moment as ISO 8601 UTC, republished only when it moves; network uptime is `None` while offline |
| `.../url/state` | out, retained | the current URL |
| `.../next_alarm/state` | out, retained | the next alarm as an ISO 8601 UTC timestamp, or `None` when there is no alarm |
| `.../next_alarm/attributes` | out, retained | JSON with `package` and `local_time` |
| `.../last_interaction/state` | out, retained | when someone last touched the screen, spoke to the device or woke the screen by hand, ISO 8601 UTC, at most one publish a minute |
| `.../admin_url/state` | out, retained | the remote admin URL, or `disabled` |
| `.../dashboard_view/state`, `.../dashboard_view/set` | out / in | the navigation path (`url_path/view-route`); `set` navigates the kiosk there |
| `.../camera/view/set` | in | Stable camera view ID; shows that view |
| `.../camera/close/set` | in | Any non-retained payload closes the camera view |
| `.../camera/view/state` | out, retained | Active camera view name, or `none` |
| `.../camera/view/attributes` | out, retained | JSON with active state, view ID, name and focused camera ID |
| `.../camera_snapshot/set` | in | Any non-retained payload captures a fresh frame |
| `.../camera_snapshot/image` | out, retained | The latest snapshot as raw JPEG bytes |
| `.../camera_snapshot/at` | out, retained | When that snapshot was captured, ISO 8601 UTC |
| `.../screenshot/set` | in | Any non-retained payload captures a screenshot of the display |
| `.../screenshot/image` | out, retained | The latest screenshot as raw JPEG bytes, at most 1080p |
| `.../screenshot/at` | out, retained | When that screenshot was captured, ISO 8601 UTC |
| `.../motion/state` | out | `ON` on motion, never retained; clearing is Home Assistant's `off_delay` |

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
  kiosksatellite_<id>` (Settings → Logs), that Home Assistant's MQTT
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
  system settings" (a notice with a Grant button appears in the Screen &
  Audio settings and in the remote admin while it is missing).
