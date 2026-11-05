# ESPHome

Kiosk Satellite presents itself to Home Assistant as a fully native ESPHome device. Its sensors and controls appear as entities on a device that Home Assistant discovers automatically, with no broker or custom integration required. This is the single integration path for every entity the kiosk provides.

The exact same connection can run a **Bluetooth proxy**: Bluetooth Low Energy (BLE) advertisements from nearby devices (like BTHome sensors, Xiaomi and Govee thermometers, iBeacons, plant sensors, and smart scales) are relayed to Home Assistant exactly as if they were in range of the main server. Home Assistant can also establish active connections to locks, buttons, and curtain motors directly through the kiosk. Multiple kiosks automatically mesh together out of the box; Home Assistant simply uses whichever proxy hears a device best. This makes it incredibly easy to set up room level presence detection (like Bermuda), as each kiosk acts as a distinct measuring point.

## Setup

1. Go to **Settings**, then **ESPHome**, and turn on **Enable ESPHome**. The very first time you start it, the app generates an encryption key and displays it on this page. If you want the kiosk to act as a Bluetooth relay, turn on **Enable Bluetooth proxy** directly beneath it.
2. When prompted, grant the **Nearby devices** and **Location** permissions (these are also found under **Settings > Device > Permissions Manager**). Ensure the device's system level location switch remains on. (See the [Permissions by Android version](#permissions-by-android-version) section to understand why this is necessary).
3. Open Home Assistant and navigate to **Settings > Devices & services**. You will see a newly discovered ESPHome device named something like `ks-<device name>` (for example, a Fire HD 10 left at its default model name would appear as `ks-amazon-kftuwi`. See the [Node name](#node-name) section for details). Click **Configure** and paste your encryption key.

| Situation | Solution |
|---|---|
| Device not discovered | Go to **Add integration**, select **ESPHome**, and use the kiosk's IP address for the host, along with port 6053 (or whatever you set under **API port**). |
| Visit link on the device page | This link appears if **Remote management** is on and an admin password is set (**Settings > Device > Remote Administration**). Clicking it opens the remote admin page using the address Home Assistant connects to and the remote admin **Server port**. If you turn remote management off or change the port, the link updates automatically on the next connection cycle. |

## Bluetooth Proxy

| Setting | Effect |
|---|---|
| **Enable Bluetooth proxy** | Advertisements are actively relayed. Broadcast sensors and presence tracking will begin working the moment this is enabled. |
| **Scan intensity** | Determines how frequently the radio listens. **Balanced** (the default) listens about a fifth of the time. **Low power** drops this to a tenth, and **Continuous** listens constantly. The same devices are detected at all levels; if a device broadcasts rarely, it might take longer to appear on lower settings, and its signal readings will update less frequently. The primary difference is CPU usage, which relies heavily on the specific device's Bluetooth stack rather than the kiosk software itself. For example, a Meta Portal on Continuous mode logs a line per packet and consumes a third of a CPU core in a busy home, whereas Balanced uses only a few percent. Reserve Continuous for critical beacons that must be detected instantly. Changes apply immediately without dropping the Home Assistant connection. |
| **Keep scanning with the screen off** | (Off by default, Android 13 and newer) Turn this on if the proxy stops relaying while the screen is off. Android only keeps a Bluetooth scan running on a dark screen when the scan is filtered, and some devices, such as a Samsung Galaxy Tab S8 on Android 16, do not count the proxy's usual match everything filter as one. This switch uses a filter list those devices accept. The cost is CPU: Android then checks every advertisement in software, which on a Tab S8 in a busy home takes about 6% of one core while the screen is off. Changes apply immediately without dropping the Home Assistant connection. |
| **Allow device connections** | (On by default) Allows Home Assistant to connect to Bluetooth devices (locks, buttons, curtain motors) through the kiosk, including handling pairing and cache management. Turning this off restricts the proxy to advertisement only mode and informs Home Assistant of the change. The proxy will only announce the capabilities it actively serves. |
| **Minimum signal for connections** | Connection requests for devices last heard below this signal threshold are immediately refused. This forces Home Assistant to fail over to a closer proxy rather than tying up a slot on a kiosk that can connect but not hold the connection reliably. If the kiosk has never heard a device before, it will always allow the connection through so that initial pairing continues to work. |

Connection budget (Home Assistant is informed of this limit so it can route additional devices through another proxy if needed):

| Android Version | Simultaneous Connections |
|---|---|
| 11 and older | 2 |
| 12 and newer | 3 |

Each connection attempt temporarily pauses scanning to perform its handshake (since they share the same radio hardware). It will retry the standard Android failure routine once before placing a persistently failing device on a cooldown timer.

## Kiosk Entities

**Expose kiosk entities** adds all the entities listed below to the device in Home Assistant. It is on by default. Turn it off if you only enable ESPHome for the Bluetooth proxy, and no extra entities are created. A kiosk set up before this default keeps the choice it had. Rows marked with a requirement only appear if that hardware is present; for example, a kiosk with no camera simply will not have camera entities, rather than displaying dead ones. Because the ESPHome protocol does not use attributes, any hardware details that would normally ride on a sensor as an attribute are split into their own distinct entities.

Native Voice Satellite adds its own VS entities and actions, listed in [Voice Satellite](voice-satellite.md#home-assistant-entities-and-actions).

Use **Settings > ESPHome > Excluded entities** to pick entities that should stay out of Home Assistant. All available entities are exposed unless you select them here. Clear an entity's checkbox to expose it again or use **Clear** to expose all available entities. **Select all** selects every entity for exclusion, including entities outside the current search results. Saving reconnects ESPHome so Home Assistant receives the updated entity list. Each row shows its Home Assistant category before its entity type. You can search by name, category or type. The same picker is available in the remote admin.

### Controls

| Entity | Type | Notes |
|---|---|---|
| **Screen** | light | Controls the screen state (on or off) along with the panel brightness. |
| **Screensaver active** | switch | Manually starts and stops the screensaver. |
| **Now Playing** | switch | Reads "on" while the full screen Now Playing view is visible. Turning it on brings the view up (paused if the music is paused); turning it off dismisses the view. Requires the setting "Now Playing" instead of the screensaver to be on. |
| **Volume** | number | Controls the media volume percentage. |
| **Voice Satellite** | switch | Voice Satellite integration on the dashboard only. Starts and stops the voice engine on the page, identical to the Start and Stop buttons found in the kiosk's Voice Satellite settings. Requires a satellite bound to the kiosk (which is handled during the setup wizard or on the Voice Satellite settings page). Binding or unbinding a satellite will refresh the entity list on the next server start. |
| **Postpone screensaver** | button | Restarts the idle countdown timer. |
| **Screensaver next slide**, **Screensaver previous slide** | button | Steps a Home Assistant Media, Local Media, Photo Gallery, Image URL or Immich Media slideshow forward or backward by one slide, holding the new slide for its full interval. If Camera Streams are active, it steps between camera views. Pressing this does nothing if any other mode (or no screensaver) is active. |
| **Notifications dismiss all** | button | The button equivalent of the `notification_dismiss` action below: acknowledging a leak on one display can clear the alerts on all the rest. |
| **Reload page**, **Go to dashboard**, **Clear cache**, **Restart app**, **Bring to front** | button | Triggers the exact same actions available in the kiosk's side drawer. |
| **Restart device** | button | Restarts the whole device, not just the app. Listed only where the restart can land: with Kiosk Satellite provisioned as the [device owner](kiosk.md#going-further-device-ownership), or with a granted [Shizuku](shizuku.md) connection. A Shizuku started over ADB stops at the reboot, so on such a kiosk the button is gone until Shizuku runs again. |
| **Open app launcher** | button | Requires the App launcher setting to be enabled. |
| **Show Music Assistant** | button | Requires a Music Assistant server address to be configured. |
| **Show Music Library** | button | Opens the [Music Library](music-library.md). Listed once Music Assistant, Home Assistant or a Sonos speaker is set up. |
| **Media play**, **Media pause**, **Media next**, **Media previous** | button | Transport for the player the Media Player page follows: the Sendspin player, a Home Assistant, Music Assistant or Sonos player, or the [Local Media Session](sendspin.md#local-media-session). Requires **Expose ESPHome entities** on the Media Player page. |
| **Media state**, **Media title**, **Media artist**, **Media source** | text sensor | What that player is doing: `playing`, `paused` or `idle`, the track, the artist and the player's name. For the Local Media Session the source is the app that plays, such as YouTube. Requires **Expose ESPHome entities** on the Media Player page. |
| **Camera view** | select | Includes a "Closed" option, plus one option for every camera view containing cameras. Requires camera views to be configured. The option list is built when the server starts; if you add new views, simply toggle ESPHome off and on, or restart the app to refresh the list. |
| **Calendar view** | select | Shows which [calendar](calendar.md) view is up, or "Closed". Pick Day, Week, Month or Schedule to open the calendar on that view, or Closed to close it. |
| **Show <view>** (one per camera view), **Close camera view** | button | Opens a specific named view or closes whichever view is currently open. |
| **Active camera view** | text sensor | Displays the name of the view currently on screen, or reads `none` when closed. |
| **Intercom**, **Intercom kiosk** | text sensor | The [intercom's](intercom.md#home-assistant) state (`idle`, `calling`, `ringing`, `in_call`, `broadcasting`, `listening`, `missed` for a minute after a call nobody answered) and the other kiosk's name. Listed while the intercom is on. |
| **Dashboard view** | select | Provides one option per dashboard view (`dashboard/view`), then one per app in the Home Assistant sidebar (`1e25efb6_panalume`), then one per Home Assistant page such as Energy (`energy`), followed by your [custom pages](custom-pages.md) (`local/page.html`). This list re reads when Home Assistant reports that a dashboard or sidebar panel was created, deleted, or edited, and when the dashboard connection returns after an outage (it never re reads on a timer). The last read list is saved across restarts, so the selector is available immediately upon the first connection even if Home Assistant is temporarily down. |
| **Update** | update | Displays the latest release and its release notes, which you can install directly from Home Assistant (see [updates.md](updates.md)). Calling `homeassistant.update_entity` on it checks the release source right away instead of waiting for the next scheduled check. |
| **Firmware** | update | Only on the Kiosk Satellite Edition images for the Echo Dot, the Echo Show 5 and the Echo Show 8. Displays the newest release of the image and its release notes, which you can install from Home Assistant. The device restarts to install it. Calling `homeassistant.update_entity` on it checks for a newer release right away (see [Echo Dot](echo-dot.md#system-updates), [Echo Show 5](echo-show-5.md#system-updates) and [Echo Show 8](echo-show-8.md#system-updates)). |
| **Screenshot** | camera | Exposes the display as a still camera on every kiosk. It is fed by the Take screenshot button or by fetching the entity itself. |
| **Take screenshot** | button | Manually captures the display. |
| **Last screenshot** | timestamp | Updates when the button is pressed or the remote admin preview refreshes, but never on a simple fetch of the camera entity. The value is saved across restarts. |
| **Camera** | camera | Requires physical camera hardware. Because the ESPHome image request protocol does not specify a named camera, fetching either camera triggers a request to both, and each answers on its own specific entity. This strictly follows the physical hardware, not the Camera enabled switch; if the camera is disabled in settings, it will display a "Camera off" frame rather than forcing the device to re register. |
| **Take camera snapshot** | button | Requires physical camera hardware. |
| **Last camera snapshot** | timestamp | Requires physical camera hardware. The value is saved across restarts. |
| **Ambient light** | sensor | Reports light levels in Lux. Requires a physical light sensor. A real change reaches Home Assistant at once. A sensor that keeps flapping between values is held to one update every 30 seconds so it cannot flood the recorder. |
| **Ambient noise** | sensor | Reports how loud the room is in dBFS, averaged over 5 seconds. Reads unknown while wake word detection is off or muted. A real change reaches Home Assistant at once. A level that keeps moving is held to one update every 30 seconds, the same as Ambient light. See the [Ambient Noise](#ambient-noise) section. |
| **GPS latitude**, **GPS longitude** | sensor | Reports coordinates in degrees, precise to six decimals. Requires **Report location** to be on and a physical GPS receiver. See the [GPS Sensor](#gps-sensor) section. |
| **GPS accuracy**, **Altitude** | sensor | Reports accuracy and altitude in meters. Requires **Report location** to be on and a physical GPS receiver. |
| **Speed** | sensor | Reports speed in meters per second (Home Assistant will automatically convert this to your preferred unit system). Requires **Report location** to be on and a physical GPS receiver. |
| **Last location fix** | timestamp | Indicates when the GPS receiver last reported. Requires **Report location** to be on and a physical GPS receiver. The value is saved across restarts. |
| **Motion** | binary sensor | Requires physical camera hardware. Will read "unknown" while the camera is toggled off. |
| **Person** | binary sensor | Reports occupancy derived from an on device person sensor (currently supported on Meta Portals). Requires **Enable person sensor** under **Camera > Person Sensor** to be on, which triggers a device re registration. Will read "unknown" if the sensor cannot be read. See the [Meta Portal](portal.md) guide. |
| **Next alarm** | timestamp | Displays the next scheduled alarm on the Android device itself, the kiosk's own [alarms](alarms.md) included. |
| **Alarm ringing** | binary sensor | On while one of the kiosk's [alarms](alarms.md) rings. |
| **Alarm snoozed until** | timestamp | When a snoozed alarm rings again. Reads unknown when nothing is snoozed. |
| **Stop alarm**, **Snooze alarm** | button | Stop the ringing, snoozed or sunrise alarm, or snooze a ringing one. |
| **Last interaction** | timestamp | Records the timestamp of the last touch, spoken voice turn, or gesture based wake. The value is saved across restarts. |
| **Next screensaver** | timestamp | Indicates exactly when the idle clock will trigger the screensaver. This updates on every touch, dismissal, or timeout change, allowing an automation to trigger off it directly, or a template to count down to it without the device needing to push a new value every single second. It reads "unknown" when nothing is actively counting down (e.g., if the screensaver is off, already showing, during a voice turn, in a camera view, in hold mode, or if another app is in front). Under a rapid stream of touches, it republishes at most once a minute, and always before the previously reported moment passes. |

Note: If your Dashboard view list changes, the device will re register, causing every entity to briefly become unavailable for a couple of seconds. This only happens if the list actually shifted.

### Configuration

Every item in this list corresponds directly to a kiosk setting. They are fully readable and writable from Home Assistant and perfectly match the values shown on the settings pages.

| Entity | Type | Notes |
|---|---|---|
| **Screensaver brightness level**, **Assistant volume**, **Media volume** | number | Values in percentage. |
| **Screensaver timeout** | number | The idle timeout in seconds, the same value as **Idle timeout** on the Screensaver page. A write restarts the idle clock at the new value right away, so an automation can shorten it at night and stretch it back in the morning. `0` turns the idle clock off, so the screensaver only starts from the switch, a schedule or a gesture. |
| **Screensaver screen off after** | number | Minutes the screensaver runs before the display powers off, the same value as **Turn screen off after** on the Screensaver page. `0` keeps the screen on. A write under a running screensaver restarts the countdown at the new value. An active [schedule](screensavers.md#schedule) entry with its own screen off time takes precedence. |
| **Clock background** | text | The Clock screensaver's background photo: a path to an image on the device or an image URL the device fetches. Every write reloads the image, an unchanged value included. |
| **Kiosk mode**, **Lockdown mode**, **HA kiosk mode**, **Keep screen on**, **Remote management**, **Screensaver brightness**, **Screensaver**, **Hold mode** | switch | Standard toggle switches. |
| **Dashboard rotation** | switch | Turns dashboard view rotation on or off, the same as **Enable dashboard view rotation** on the device. Unlike **Hold mode**, the screensaver and screen off still run while it is off. The Dashboard view select then keeps the view it picks, so an automation can turn rotation off, show a Now Playing view and turn it back on when playback stops. Rotation starts again from the first view. |
| **Adaptive brightness** | switch | Follows the device's light sensor or the Home Assistant entity picked in its settings. |
| **Camera enabled**, **Screensaver motion detection**, **Screensaver face detection** | switch | Requires physical camera hardware. The Camera enabled switch can be safely toggled throughout the day; the camera entities will remain listed. |
| **RTSP Streaming** | switch | Enables or disables the RTSP server using the saved stream settings. Requires physical camera hardware. Camera enabled and Android camera permission must also be on. Changes sync with the local and remote settings pages without reconnecting ESPHome. |
| **Screensaver proximity detection** | switch | Requires a physical proximity sensor. |
| **Screensaver schedule** | switch | Turns [scheduled screensavers](screensavers.md#schedule) on or off, the same as **Enable scheduled screensavers** on the device. The times themselves are set on the device. |
| **Screensaver widgets** | switch | Shows or hides all [screensaver widgets](screensavers.md#widgets), the same as **Enable screensaver widgets** on the device. A running screensaver updates right away and the widget list stays as it is. |
| **Intercom enabled** | switch | The [intercom's](intercom.md) master switch. Its state sensors and the answer mode appear while it is on. |
| **Voice Satellite auto start** | switch | Voice Satellite integration on the dashboard only. Controls whether the voice engine starts automatically with the dashboard. This allows an automation to delay voice services on slower devices that need all their processing power for the initial dashboard load. Requires a bound satellite. |
| **Theme** | select | Options are Auto, Light, or Dark. Selecting Light or Dark forcibly pins the dashboard theme, overriding both the on device schedule and the app theme sync for as long as it is active. If theme sync is enabled, pinning the theme will flip the app's internal screens as well. |
| **Screensaver mode**, **Clock style** | select | Provides the exact same options found on the device settings pages. |
| **Default dashboard** | select | The dashboard the kiosk starts on, returns to with the Go to dashboard button and reloads after a crash or restart. Same `dashboard/view` options as the Dashboard view select. Changing it rewrites the start URL but leaves the page where it is, so an automation can make a night dashboard the one the kiosk always comes back to and use the Dashboard view select when it should show right away. |
| **Camera facing** | select | Requires both a front and back physical camera. |
| **Intercom do not disturb** | switch | The [intercom's](intercom.md) answer mode as Do not disturb, on or off. Listed while the intercom is on. |
| **Intercom answer mode** | select | Ring, Answer automatically or Do not disturb. Listed while the intercom is on. |
| **LED Control Idle** | light | Turns **Light up when idle** on the [LED Control](led-control.md) page on or off and sets its brightness and color. Listed on devices with lights Kiosk Satellite can drive, such as the Echo Dot, while **Enable LED Control** is on. |
| **LED Control Idle Effect** | select | Solid or Breathing, the idle **Effect** on the [LED Control](led-control.md) page. Listed with the **LED Control Idle** light. |
| **Intercom volume** | number | The share of the master volume the other kiosk's voice and announcements play at, in percentage. Listed while the intercom is on. |

### Diagnostics

| Entity | Type | Notes |
|---|---|---|
| **Battery** | sensor | Reports battery percentage. Only devices with a physical battery receive this entity; a mains powered device without a battery will only report the Charging status. |
| **Charging** | binary sensor | Indicates if the device is currently receiving power. |
| **CPU usage** | sensor | Reports how busy the CPU is as a percentage. Only available on devices that let an app measure CPU load. |
| **CPU clock** | sensor | Reports the average clock speed of the active CPU cores in MHz. |
| **CPU temperature** | sensor | Only available on devices that report thermal data. |
| **Battery temperature** | sensor | Reports the battery temperature in °C from Android's battery report. Only devices with a battery that has a temperature sensor receive this entity. |
| **RAM available**, **RAM total** | sensor | Reported in Megabytes (MB). |
| **Internal storage free**, **Internal storage total** | sensor | Available space and capacity of Android's internal data partition in mebibytes (MiB). Refresh every minute. Free space includes a valid zero when the partition is full. |
| **Current page** | text sensor | Displays the URL currently on screen, perfectly tracking Single Page Application (SPA) navigations. |
| **Foreground app** | text sensor | Identifies the package name of the app currently running in front. |
| **Bluetooth devices nearby** | sensor | Requires the Bluetooth proxy to be enabled. See the [Nearby devices](#nearby-devices) section. |
| **Bluetooth max connections** | sensor | Requires the proxy to be enabled with device connections allowed. |
| **Bluetooth devices connected** | sensor | Requires the proxy to be enabled on an Android version that reports links (this requires an adapter and the Nearby devices permission on Android 12 and newer). |
| **Device** | text sensor | Displays the specific hardware model. |
| **Panel brightness** | sensor | Reports the actual brightness level as read directly from the panel, in percentage. |
| **Android version**, **Android build** | text sensor | System software identifiers. |
| **App version** | text sensor | Reports the specific release of Kiosk Satellite running on the device. This is excellent for sorting a fleet of kiosks by version. |
| **IPv4 address**, **IPv6 address** | text sensor | Displays the primary network address. For IPv6, it prioritizes a routable address over a link local `fe80::` address. |
| **IPv4 addresses by interface**, **IPv6 addresses by interface** | text sensor | Displays addresses broken down by interface (e.g., `wlan0: 192.168.1.5; eth0: 10.0.3.2`), allowing automations to easily distinguish wired from wireless connections. Re checks moments after any network change. |
| **App uptime**, **Network uptime** | timestamp | Records exactly when the app launched and when the network connection was established. |
| **Last seen** | timestamp | Updates on every completed poll. |
| **Connectivity** | binary sensor | Reads "on" while the kiosk is reachable on the network and "unavailable" (not "off") when it drops, because losing the connection takes every single entity with it. |
| **Remote admin** | text sensor | Displays the full URL to the remote admin page. Reads `disabled` while remote management is turned off. |

## Notifications

Home Assistant can push a notification directly to the kiosk screen. This appears as a large card at the top of the display accompanied by a chime, rendering smoothly over whatever is currently on screen (including the screensaver). Nothing underneath is interrupted, and the card simply slides away on its own.

This is executed as an ESPHome action, which is the singular feature in the protocol capable of carrying a payload. When **Expose kiosk entities** is enabled, Home Assistant registers `esphome.<node name>_notification` (replacing hyphens in the node name with underscores; see the [Node name](#node-name) section). You can find the exact name in the action picker under ESPHome.

```yaml
action: esphome.kitchen_tablet_notification
data:
  message: Washing machine finished
  title: Utility room
  duration: 30
  type: info
  chime: true
  scale: 1
  icon: mdi:washing-machine
  chime_file: ""
  volume: 0
  image: ""
```

Another ESPHome device can also call this action directly:

```yaml
binary_sensor:
  - platform: gpio
    pin: GPIO4
    on_press:
      - homeassistant.action:
          action: esphome.kitchen_tablet_notification
          data:
            message: Front door opened
            title: ""
            duration: "20"
            type: warning
            chime: "true"
            scale: "2"
            icon: mdi:door-open
            chime_file: ""
            volume: "0"
            image: ""
```

Every argument in the data block is strictly required (the ESPHome protocol does not support optional arguments). To bypass an argument, provide the value that means "leave as default":

| Argument | Meaning |
|---|---|
| `message` | The main text, displayed in the largest font on the card. Markdown is rendered; see [Formatting](#formatting). |
| `title` | A heading positioned above the message. Inline Markdown (bold, italic, code) is rendered. Leave empty if you only want the message itself. |
| `duration` | Time in seconds the card stays on screen. Setting it to `0` keeps it up indefinitely until tapped or cleared by Home Assistant. Negative numbers revert to the default 30 seconds. |
| `type` | Accepts `info`, `success`, `warning`, or `error`. This automatically picks the base icon and its color. If left empty, it defaults to `info`. |
| `chime` | A boolean indicating whether to play the notification sound. It plays through the selected speaker just like any other app audio. |
| `icon` | Specify a Material Design Icon to override the type's default (e.g., `mdi:washing-machine`). The full set is bundled. The color will still match the `type`. Leave empty to use the default icon. |
| `scale` | Adjusts the card size on a scale from `1` (normal) to `4` (decimals are allowed). The text type, icon size, padding, and total width all scale proportionally, so a `3` is highly readable from across a room. A `0` will default to normal scale. |
| `chime_file` | Triggers a specific sound unique to this notification. This requires the exact file name (e.g., `leak.mp3`) located in the kiosk's sounds folder, not a full path or URL. Leave empty to play the standard notification sound set in settings. If you provide a name but the file is missing, it will play the default sound and log the error. |
| `volume` | A value from `0` to `1`, operating independently from the media and assistant volumes (though the device's main system volume still applies). Setting it to `0` or a negative number defaults to the **Notification volume** specified in settings. For a completely silent notification, use `chime: false`. |
| `image` | Displays a picture directly under the text. You can use an `http(s)` URL reachable by the kiosk, or a local path on your Home Assistant server. For example, `/api/camera_proxy/camera.doorbell` will fetch a fresh frame as the card renders, while `/local/doorbell.jpg` pulls a static file from `/config/www`. Paths and URLs targeting the Home Assistant server authenticate automatically using the kiosk's own token. The text renders instantly, and the picture pops in once it arrives (it allows up to 10 seconds and 8 MB). If the picture fails to fetch, it logs the error and displays the card without it. Leave empty for no picture. |

Behavior notes:
* Cards stack with the newest on top, allowing up to four simultaneously, each tracking its own countdown timer. A fifth card will automatically push the oldest one off the screen.
* Sending the exact same message twice generates two distinct cards.
* Tapping a card dismisses only that specific card, leaving the others untouched.
* If a card arrives while a screensaver is active, the panel will temporarily return to its normal brightness for as long as any card remains visible (**Brighten for notifications**, see [screensavers.md](screensavers.md#brightness)).

The action returns the card's specific ID (e.g., `{"id": 7}`). Using `response_variable`, you can pass this ID to `esphome.<node name>_notification_dismiss` to remove that exact card later. Sending `id: 0` will instantly clear all notifications from the screen. Because each kiosk manages its own IDs, an alert fanned out to several displays maintains a separate ID per kiosk. Handling action responses requires Home Assistant 2026.1 or newer. On older versions, the action will execute normally but yield no response data.

```yaml
- action: esphome.kitchen_tablet_notification
  data:
    message: Front door left open
    title: ""
    duration: 0
    type: warning
    chime: true
    scale: 1
    icon: mdi:door-open
    chime_file: ""
    volume: 0
    image: ""
  response_variable: card
- wait_for_trigger:
    - trigger: state
      entity_id: binary_sensor.front_door
      to: "off"
- action: esphome.kitchen_tablet_notification_dismiss
  data:
    id: "{{ card.id }}"
```

Every card that leaves the screen fires an `esphome.kiosk_satellite_notification` [event](events.md#notifications) with its `id` and whether it was tapped, expired, dismissed or pushed off by a newer card. An automation can use it to show a card again that someone tapped away too soon.

When using the [remote API](remote-api.md), these two commands correspond to `showNotification` (which returns the same `id`) and `dismissNotification` (which takes the ID, or clears the screen if given `0` or nothing).

### Formatting

The message is read as Markdown, so a number can carry weight and a daily summary can be a list rather than a wall of text. The subset is deliberately small and anything outside it displays as typed.

| Syntax | Renders as |
|---|---|
| `**bold**`, `*italic*`, `***both***` | Bold, italic, or both. |
| `` `code` `` | Monospace on a faint tint, for entity ids and commands. |
| `~~struck~~` | Strikethrough. |
| `[label](url)` | The label only. Nothing on a card can open a link. |
| A newline | A line break. A blank line separates paragraphs. |
| `# Heading` | A bolder line above what follows. Every heading level looks the same. |
| `- item`, `* item`, `+ item` | A bullet, hanging in its own gutter so a wrapped item keeps its left edge. Indent by two spaces to nest. |
| `1. item` | A numbered item. The number is shown as written. |
| `\*`, `` \` ``, `\-`, `\#` | The character itself. |

Underscores never emphasize, so `sensor.living_room_temp` or `__init__` reads as typed. A `*` followed by a space, or one with no partner on the same line, is a star, so `2 * 3` and `4* hotel` survive. The title takes the inline syntax only.

```yaml
action: esphome.kitchen_tablet_notification
data:
  message: |
    Battery: **15%**
    - Charger: `unplugged`
    - Time left: about an hour
  title: Tablet battery low
  duration: 0
  type: warning
  chime: true
  scale: 1
  icon: ""
  chime_file: ""
  volume: 0
  image: ""
```

From another ESPHome device, where every value in the data block is a string, put the line breaks in as `\n` inside a double-quoted string. A message built from the device's own sensors goes through `data_template` and `variables` the way the ESPHome documentation shows for any action.

```yaml
binary_sensor:
  - platform: gpio
    pin: GPIO4
    on_press:
      - homeassistant.action:
          action: esphome.kitchen_tablet_notification
          data:
            message: "**Leak detected**\n- Location: `utility room`\n- Valve: closed automatically"
            title: "Water sensor"
            duration: "0"
            type: error
            chime: "true"
            scale: "2"
            icon: mdi:water-alert
            chime_file: ""
            volume: "0"
            image: ""
```

### Appearance

| | |
|---|---|
| **Transparency** | Allows the screen content beneath to show through the cards. This ensures that a notification layered over a screensaver leaves the clock readable. It defaults to 20%; setting it to 0% creates a fully opaque card. The text and icons always remain solid, regardless of the setting. |
| **Background blur** | Applies a frosted glass effect to whatever shows through a transparent card, ensuring text remains highly legible even over a complex, busy photo. It defaults to 30%; a 0% setting removes the blur entirely, and the top end creates a heavy frost effect. This setting does nothing if the cards are fully opaque, and cannot be rendered over the active Home Assistant dashboard surface (cards over the dashboard will be transparent but unblurred). |

### Sounds

| | |
|---|---|
| Folder | Located at `Android/data/me.jxl.kiosk_satellite/files/sounds`, which is the standard app folder visible in any File Manager. No special permissions are required. Files here survive device restarts and app updates, but will be deleted if you uninstall the app. |
| Ways in | You can add files via **Add a sound** on the Notifications settings page (**Browse** on the device itself, **Upload** via remote admin), the File Manager's upload tool, a USB connection, or standard ADB commands. |
| Formats | MP3, OGG (Vorbis), WAV, FLAC, M4A, and AAC are fully supported. Do not use video files or the Opus codec. |
| **Notification sound** | Provides a dropdown menu mapping to the sounds folder, always listing **Built-in chime** first. Because it stores the file name itself, restoring a backup onto another kiosk will reference the exact same file. If the file is missing, it clearly indicates the missing status and falls back to the built in chime until the file is restored. |
| **Notification volume** | Defaults to 70%, operating independently from the media and assistant volume sliders. |
| **Test** | Fires a live notification directly through this kiosk's action, allowing you to perfectly judge the sound and volume in place. |

For best results, assign unique `chime_file` names within your automations for distinct alerts (like a leak, a delivery, or the laundry finishing) and rely on the default settings for everything else.


## Launch an app

`esphome.<node name>_launch_app` opens an installed Android app by its package name from a Home Assistant automation or script. Enable **Expose kiosk entities** under **Settings > ESPHome** to make the action available. The App launcher overlay does not need to be enabled.

```yaml
- action: esphome.kitchen_tablet_launch_app
  data:
    package_name: com.android.deskclock
```

Replace `kitchen_tablet` with your kiosk's node name, using underscores in place of hyphens. `package_name` is required and must identify an installed app with a launchable activity. An empty package name or a failed launch reports an action error to Home Assistant.

The action uses the same launch behavior as the App launcher and gestures, including unpinning before launch and the configured auto-return behavior. On the [remote API](remote-api.md), the equivalent command is `launchApp` with a `package` argument.

## Set brightness

`esphome.<node name>_set_brightness` sets **Default brightness** from 0% to 100%, including 0% for devices that can turn off their backlight. Enable **Expose kiosk entities** under **Settings > ESPHome** to make the action available.

```yaml
action: esphome.kitchen_tablet_set_brightness
data:
  brightness: 0
```

Replace `kitchen_tablet` with your kiosk's node name, using underscores in place of hyphens. `brightness` is a required percentage from 0 to 100 and accepts decimals. Adaptive brightness must be off. The action reports an error if adaptive brightness is on or the value is outside that range.

The value is saved as **Default brightness** and follows the same behavior as its slider. If a screensaver controls the brightness, the new value applies when it ends. Setting 0% changes brightness without turning the screen off.

## Set screensaver brightness

`esphome.<node name>_set_screensaver_brightness` sets **Screensaver > Brightness level** from 0% to 100%, including decimals. It requires **Expose kiosk entities** to be enabled and adaptive brightness to be off, just like `set_brightness`.

```yaml
action: esphome.kitchen_tablet_set_screensaver_brightness
data:
  brightness: 0
```

The action saves the level without enabling **Screensaver brightness**. When that switch is on, the level applies to content screensavers and updates one already showing. Dim and Black keep their own brightness behavior and schedule entries with their own brightness keep that override. Default brightness stays unchanged.

## Media player actions

Two actions follow a player from an automation, the way the Media Player page's Player source and Player rows do by hand. Both come with **Expose kiosk entities**, under the same device as the notification action.

`esphome.<node name>_media_player_list` takes no arguments and answers with every player the kiosk can follow, read through `response_variable`: each with its `source` (`device`, `home_assistant`, `music_assistant` or `sonos`), its `name`, its `id` and whether it is `available`, plus `current`, the pick in force. A Sonos room's id is the serial the Sonos page shows under its address.

`esphome.<node name>_media_player_set` takes a `source` and a `player`, the player by its name as listed or by its id, and answers with what it picked. The `device` source puts the kiosk back on its own Sendspin player, or with `player` set to `media_session` on the Local Media Session and `airplay` on the AirPlay receiver. Any other `player` picks the Sendspin player, but one must still be given, since no ESPHome action argument is optional.

```yaml
- action: esphome.kitchen_tablet_media_player_set
  data:
    source: sonos
    player: Office
- action: esphome.kitchen_tablet_media_player_set
  data:
    source: device
    player: ""
```

A name that two players share goes to the available one. On the [remote API](remote-api.md) the same two are the `mediaPlayers` and `mediaPlayerSet` commands.

The followed player's buttons and sensors (see [Controls](#controls)) have remote API twins too: `sendspinControl` with a `command` of `play`, `pause`, `toggle`, `next` or `previous`, and `mediaPlayerState` for the state, title, artist and source.

## Announcements

Home Assistant can speak on the kiosk. `esphome.<node name>_announce` plays a `message` through Home Assistant's text to speech, or an audio `url` (MP3, WAV, OGG or AAC), on this kiosk with a chime first. Each kiosk is addressed through its own ESPHome device, so an announcement to several kiosks is one action per kiosk, and no other kiosk is involved. The kiosk asks Home Assistant for the audio, decodes it and plays it at the media volume, or at the `volume` the action names, holding the screensaver and ducking the music the way a voice turn does, with a card that shows the spoken text while it plays. Listed with **Expose kiosk entities**.

The **Announcements** page under Settings, ESPHome holds:

| Setting | What it does |
| --- | --- |
| Enable announcements | On by default. Off, the action is refused. |
| Text to speech engine | Under **Text to Speech**, picked from the text to speech entities Home Assistant has. First available, the default, uses the first one. |
| Language | The language the engine speaks, picked from the ones it lists. Default leaves it to the engine. Shown once an engine is picked by name. |
| Voice | The voice the engine speaks with, picked from the ones it lists for the language, or for the Home Assistant language when Language is Default. Default leaves it to the engine. Engines with no voices to pick, like Google Translate, only offer Default. |
| Chime first | Plays a chime before the words, on by default. |
| Chime sound | The built-in two note chime, or a file from the sounds folder like the [notification sound](#sounds), put there with the Add a sound row. Plays as loud as the announcement: at the media volume, or at the `volume` the action names. |

```yaml
- action: esphome.kitchen_tablet_announce
  data:
    message: Dinner is ready
    url: ""
    volume: 0
    repeat: 0
    repeat_pause: 0
    chime: true
    chime_file: ""
    tts_engine: ""
    tts_language: ""
    tts_voice: ""
    audio_only: false
```

Leave `url` empty to speak the message, or leave `message` empty and give a `url` to play a file. `volume` is a share of the master volume from 0 to 1 for this one announcement; 0 keeps the media volume. `repeat` plays it that many times, up to ten; 0 is once. `repeat_pause` is the silence between plays in seconds, up to 30; 0 is 0.6. The chime plays once, before the first. The action answers with the clip's length in milliseconds through `response_variable`, and reports an error when announcements are off, the kiosk is in an intercom call, or Home Assistant could not speak the message. A message needs the kiosk's Home Assistant connection. On the [remote API](remote-api.md), the equivalent command is `announce` with the same arguments.

A new announcement replaces the one playing, so an automation can cut an alarm loop short with its own message. If two arrive close together, the newer one plays and the older one reports an error.

`esphome.<node name>_announce_stop` takes no arguments and stops the announcement playing on this kiosk, along with one still fetching its audio. It answers with `stopped` through `response_variable`, `true` when an announcement was playing, and never reports an error when nothing was. Intercom calls and Announce to all are not affected. On the remote API the command is `announceStop`.

```yaml
- action: esphome.kitchen_tablet_announce_stop
```

Each announcement can override these options without changing the kiosk's settings:

| Parameter | What it does |
| --- | --- |
| `chime` | `true` plays a chime before the first play. `false` skips it. Overrides **Chime first** for this announcement. If omitted through the remote API, the setting applies. |
| `chime_file` | A file name in the kiosk's sounds folder, such as `dinner.mp3`. Empty uses **Chime sound**. A missing or invalid file falls back to that sound, then to the built-in chime. Ignored when `chime` is `false`. |
| `tts_engine` | A Home Assistant text to speech entity, such as `tts.piper`. Empty uses **Text to speech engine** from the UI. Ignored when playing a `url`. |
| `tts_language` | A language the engine speaks, spelled exactly as the engine lists it, such as `en_US` for Piper or `en-US` for Home Assistant Cloud. The **Language** picker shows each one under its name. Empty uses **Language** from the UI when the announcement uses that engine, or the engine's default otherwise. Ignored when playing a `url`. |
| `tts_voice` | The ID of a voice the engine has, such as `en_US-amy-medium` for Piper, not its name. The **Voice** picker shows each ID under the voice's name. Empty uses **Voice** from the UI when the announcement uses that engine, or the engine's default otherwise. When Home Assistant cannot speak with the language or voice, the kiosk speaks the message with the engine's defaults instead. Ignored when playing a `url`. |
| `audio_only` | `true` plays the audio without the on-device announcement modal or bringing the kiosk to the front. `false` shows the modal as usual. The chime still follows `chime`, so set it to `false` to hear only the speech. |

## Intercom actions

Four actions run the [intercom](intercom.md#home-assistant) from an automation or a dashboard button, listed with **Expose kiosk entities**. `esphome.<node name>_intercom_call` rings another kiosk from this one, its `kiosk` argument the other kiosk's name, any case, or its IP address, and answers with the `id` and `kiosk` it rang. `esphome.<node name>_intercom_hangup` takes no arguments and ends the call, cancels one still ringing or closes an announcement. `esphome.<node name>_intercom_answer` and `esphome.<node name>_intercom_decline` take no arguments and answer or decline the call ringing on this kiosk. All four report an error when the intercom is off, the kiosk is unknown, this kiosk is already in a call, the other kiosk refused, there is no call to end or nothing is ringing.

```yaml
- action: esphome.kitchen_tablet_intercom_call
  data:
    kiosk: Bedroom
```

## Open a web page

`esphome.<node name>_open_url` shows a web page over the dashboard from an automation or script, on the same surface a tapped dashboard link or the Music Assistant menu entry gets: a page with a close button that slides up over the dashboard, which stays loaded underneath with its wake word listening. The `url` must be an http or https address. Before the page shows, the kiosk stops a running screensaver and wakes the screen, so the page is seen rather than loaded behind a black screen. `esphome.<node name>_close_url` takes no arguments and drops the page again. Both are listed with **Expose kiosk entities**.

The page has the same footing as any other link the kiosk opens: it follows the **Ignore SSL errors** switch, it runs the **Inject JavaScript on external pages** script and a page on your Home Assistant origin signs in with the dashboard's session. A page open this way counts as activity while it is being touched, but the idle clock keeps running under it, so on a quiet kiosk the screensaver returns after the usual idle time and covers the page. For a page that should stay up for as long as it takes to read it, set `hold_mode` to true: the kiosk turns [hold mode](screensavers.md#starting-and-dismissing) on with the page and off again when the page goes, whether through `close_url`, the close button, the back button or the HOME key. A hold you already had on is left alone and stays after the page. The hold's own auto release timer still applies, so a page left up on a busy kitchen counter does not pin the kiosk forever.

```yaml
- action: esphome.kitchen_tablet_open_url
  data:
    url: https://www.example.com/recipes/chocolate-chip-cookies
    hold_mode: true
```

On the [remote API](remote-api.md) the same two are the `showLinkPage` and `hideOverlayPage` commands, `showLinkPage` with the same `hold` flag.

## Run a Shizuku command

`esphome.<node name>_shizuku_command` runs a shell command on the kiosk through [Shizuku](shizuku.md), the same way `adb shell` would. It is listed with **Expose kiosk entities** and needs Shizuku running with Kiosk Satellite allowed under **Settings > Device > Shizuku**. The command runs as the user Shizuku runs as, which is Android's shell user when Shizuku was started over ADB and root when it was started as root.

```yaml
- action: esphome.kitchen_tablet_shizuku_command
  data:
    command: settings put system screen_off_timeout 600000
    timeout: 0
  response_variable: result
```

`command` is one command line and can use pipes, `&&` and redirects. `timeout` is how many seconds to wait for it, up to 25. Set it to 0 for the default of 10. A command that runs past its timeout is stopped.

The action answers through `response_variable` with `exit_code`, `stdout`, `stderr`, `timed_out` and `truncated`. A command that runs and fails still answers, so check `exit_code` in the automation. Output longer than about 48 KB is cut and `truncated` is true. The action reports an error to Home Assistant when the command could not run at all: Shizuku is not installed, not running, older than version 13 or Kiosk Satellite is not allowed in it. Commands run one at a time in the order they arrive.

Anyone who can run actions on this device in Home Assistant can run commands on the kiosk with the same access as `adb shell`. Turn off **Expose kiosk entities** or revoke Kiosk Satellite in the Shizuku app if that is more access than you want to give Home Assistant. On the [remote API](remote-api.md), the equivalent command is `runShizukuCommand` with the same `command` and `timeout` arguments.

## Ambient Noise

The **Ambient noise** sensor reports how loud the room is as one number in dBFS. A typical use is an automation that lowers the assistant's volume when the house is quiet at night and raises it when the TV is on. Plugins that declare the `noise` capability read the same level.

Only the level leaves the microphone, never audio:

* The figure is the average over 5 seconds, rounded to a whole dB. Home Assistant hears about it when it moves by 2 dB or more.
* It comes from the capture the wake word engine already has open, so it never opens the microphone. With wake word detection off or the satellite muted there is no level and the sensor reads unknown.
* It holds its last value through voice turns, announcements, timers, alarms, media playback and intercom calls, so speech never shows up in it. Any 5 seconds in which the kiosk played a sound of its own are dropped as well. The value stays held until a clean reading replaces it.

dBFS is relative to the loudest sound the microphone can record, which reads 0. It is not a calibrated sound level. Quieter rooms read lower. **Microphone gain** shifts the reading by the same number of dB, so set the gain first and then watch the sensor for a day to find your room's quiet and loud levels. Sound from the dashboard's web pages and the DLNA video player can't be told apart from the room, so it counts as noise.

To keep the sensor out of Home Assistant, add it to **Settings > ESPHome > Excluded entities**.

## GPS Sensor

If your device travels (like a tablet mounted in an RV), it can transmit its exact location to Home Assistant using its built in GPS receiver. You must explicitly opt in via **Settings > ESPHome > GPS Sensor**.

| | |
| --- | --- |
| **Report location** | Activates the receiver and begins serving data to the six location sensors detailed above. Off by default. Because toggling this on or off forces the device to re register, all entities will be briefly unavailable for a few seconds during the transition. |
| **Update interval** | Sets the time in seconds between readings, defaulting to 60. The app only pushes a new reading when the receiver actively delivers one, ensuring a parked kiosk costs Home Assistant absolutely zero processing overhead. |
| **Last coordinates** | Displayed directly under the switch, this shows the most recent coordinate reading, including its accuracy and age, or the specific reason why no data is available. |
| No GPS receiver | If the hardware lacks a receiver, the switch is permanently disabled and clearly states the reason. Most standard kiosk style tablets do not include GPS hardware. |
| **Location** grant | This is the only permission requested on this page, but it requires location services to be enabled in the core Android settings as well. Tapping **Grant** will prompt for the permission, or directly open the system location settings if the master switch is what is turned off. The receiver needs precise location: on Android 12 and later, allowing only approximate location leaves the grant missing, and **Grant** asks to change it to precise. Once Android stops asking, after two refusals, **Grant** opens the app's page in the Android settings instead. |
| Screen off | The Kiosk Satellite Service explicitly attaches Android's location foreground type while the switch is on. This ensures location readings continue arriving flawlessly even if the panel powers off or another app takes the foreground. |
| Cold start | The first reading after booting typically relies on the receiver's last known position. Securing a fresh fix under an open sky can take several minutes. The most recent reading is always preserved across device restarts. |

The app strictly utilizes the hardware GPS receiver, completely ignoring network based location guessing. In a moving vehicle, a Wi-Fi derived position is often wildly inaccurate. To create a reliable `device_tracker` for the kiosk (essential for zones and border crossings), simply create one automation targeting the two coordinate sensors:

```yaml
triggers:
  - trigger: state
    entity_id: sensor.kitchen_tablet_last_location_fix
actions:
  - action: device_tracker.see
    data:
      dev_id: rv_tablet
      gps:
        - "{{ states('sensor.kitchen_tablet_gps_latitude') }}"
        - "{{ states('sensor.kitchen_tablet_gps_longitude') }}"
      gps_accuracy: "{{ states('sensor.kitchen_tablet_gps_accuracy') }}"
```

## Node Name

The node name serves as the mDNS name discovered by Home Assistant (e.g., `<node name>.local`) and acts as the root prefix for the device's action names. For instance, `kitchen-tablet` generates the action `esphome.kitchen_tablet_notification`. 

A fresh installation automatically names itself using `ks-` appended to the device name (which is pulled from the **Device name** field on the very first page of the setup wizard). This usually starts out as the raw device model, like `ks-amazon-kftuwi`, but if you named your kiosk "Kitchen Tablet", it becomes `ks-kitchen-tablet`. If your chosen device name already starts with "KS", the prefix is not doubled. A kiosk that has already been discovered retains its generated `kiosk-satellite-<id>`.

You can manually change it under **Settings > ESPHome > Node name**. Whatever you type is taken literally (without adding a prefix), converted to lowercase, restricted to numbers and single hyphens ("Kitchen Tablet" becomes `kitchen-tablet`), and must be completely unique among all kiosks on your network.

| What Happens After a Rename | |
|---|---|
| Entities, history, and entity IDs | These all survive seamlessly because Home Assistant keys them securely to the hardware address. |
| Action names | These will change immediately. You must update any automations calling `esphome.old_name_notification`. |
| Home Assistant | You must reload the kiosk's entry (**Settings > Devices and services > ESPHome**, click the three dot menu, and hit **Reload**) for the action to appear under the new name. The old name will linger in the picker until Home Assistant restarts, but calling it will do nothing. |

## Device Identity

To keep the ESPHome device distinctly separated from the entries generated by router and network integrations (like UniFi, OPNsense, or DHCP tracking) for the exact same hardware, the kiosk identifies itself using a generated hardware address. This is necessary because modern Android versions actively hide the real MAC address from apps. 

If you prefer to merge them, enabling **Use real Wi-Fi MAC address** (located under **Advanced settings** on the ESPHome page) will force the app to report the genuine address whenever possible, allowing Home Assistant to merge those entries into a single device profile.

A fresh install on the [Echo images](https://github.com/jxlarrea/lineageos-echo-kiosk-satellite) turns this switch on by itself. Those images always join Wi-Fi with the factory address, so it is the one your router already knows. An upgrade, a restored backup or an imported configuration keeps the value it had.

| | |
|---|---|
| Readable | The real MAC address can only be read on Android 9 and older, or on any version where the app is provisioned as the device owner. If it cannot be read, the switch will clearly state the limitation beneath itself, and the generated identity will remain active. |
| Kept | The very first address successfully read is locked in. This ensures the identity survives major OS upgrades that might otherwise close the exploit used to read it. Turn the switch off and back on to read the address again, for example after a ROM update starts reporting the real address in place of a placeholder. |
| **Spoof Wi-Fi MAC address** | This option only appears below the switch if the hardware read fails. You can manually type the address (you can find it in Android under About > Status, or in your router's client list) using colons, dashes, or just twelve raw hex digits. If a successful hardware read occurs, it will always override the spoofed address. |

Note: Generating a new identity (whether by flipping the switch, typing an address, or altering it in any way) will immediately cause the existing ESPHome entry to reject the kiosk with an "Unexpected device found" error. You must delete the broken entry and allow discovery to re add the kiosk cleanly. Flipping the switch back to its original state restores the old identity, but because Home Assistant stops retrying after a hard failure, you must manually reload the kiosk's entry or reboot Home Assistant entirely to restore connection.

## Nearby Devices

The Bluetooth Proxy settings page provides a live list of what the kiosk is currently hearing. It displays the broadcasted name of the device, or if none is available, it pulls the class from the advertisement data (such as a BTHome sensor, an Apple Find My device, or a Windows PC). If all else fails, it displays the manufacturer. Devices using rotating private addresses are clearly marked; these rows represent a brief appearance rather than a stable, trackable device. Only the dedicated Private BLE Device integration (which utilizes the device's IRK) can assign a lasting identity to rotating addresses.

| Sensor | Reads |
|---|---|
| **Bluetooth devices nearby** | Displays the raw count of the list, allowing a dashboard to visualize exactly how much traffic each room hears. |
| **Bluetooth devices connected** | Lists every active link the adapter currently holds, including the proxy's own connections. This updates instantly as links come and go, rather than waiting for a slow polling cycle. |
| **Bluetooth max connections** | Displays the proxy's connection budget, representing the hard ceiling that the connection count will run into. |

The two connection based sensors appear and disappear in tandem with the main Bluetooth proxy switch. They are also automatically excluded on Android versions that refuse to report active links (which occurs if there is no physical adapter, or if the Nearby devices permission is missing on Android 12 and newer).

The **Look up device manufacturers online** setting is off by default. When enabled, unknown devices with genuine hardware addresses will be identified by their manufacturer prefix using api.macvendors.com. To protect privacy, only the 3 byte prefix is transmitted. It only checks each manufacturer once, caching the answer permanently. Regardless of this setting, the actual relay of data to Home Assistant remains completely untouched.

## Permissions by Android Version

| Android Version | What Scanning Requires |
| --- | --- |
| 12+ | Requires the **Nearby devices** runtime pair (scan and connect), the **Location** permission, and system location services to be switched on. |
| 6 to 11 | Bluetooth permissions are granted at the time of installation. It still requires the **Location** permission and for system location services to be on. |

Location is an absolute requirement across every Android version because the operating system correctly treats Bluetooth beacons as location inferable data. If an app attempts to scan while location permissions are detached on Android 12 and newer, it will never receive iBeacon or Eddystone frames. This is the exact data that a Bermuda or iBeacon presence setup requires to function. 

Crucially, the proxy itself never actively reads the device's physical position; only the [GPS sensor](#gps-sensor) does that, and only when explicitly enabled. (On Fire tablets, you will find the system device switch tucked under **Location Based Services**).

If half of the required permissions are missing, the symptoms are clear: the proxy will report that it is scanning, the phone (or on older Android builds, every device) will never appear on the list, and Home Assistant will see a proxy that delivers little to no data. The permission rows clearly displayed on the settings pages will specifically name whichever half is blocking the scan. Tapping **Grant** will prompt for the missing permission in order, or direct you straight to the system location settings if the master switch is the culprit.

## Reliability

* A robust watchdog monitors the feed and automatically restarts the scan if advertisements suddenly stop arriving. A normal home containing any BLE devices is never completely silent for long. This is essential for some chipsets (particularly MediaTek) that are known to silently stall after several hours of continuous scanning.
* Toggling Bluetooth off and on, flipping airplane mode, or a total crash of the Bluetooth stack will automatically suspend the proxy. It instantly resumes function the moment the adapter comes back online.
* Scan restarts are carefully budgeted to stay under Android's strict, silent throttle limit of 5 starts per 30 seconds.
* If Android repeatedly fails to register a scan, the Bluetooth adapter restarts to clear the stack. This is possible on Android 12L and older. After a restart that brought advertisements back, another can follow after 30 minutes if the problem returns. Each restart drops the proxy's active connections.
* On Android 8.0 to 9, one scan registration that answers after Android's 2 second limit leaves the scan running with no advertisements and no error until the adapter restarts. The adapter now restarts if a scan goes silent after such a failure. If registration gets slow on these versions, scan sessions rotate every 30 minutes instead of every 2 minutes until it speeds up.
* Any half open sockets left lingering by a Home Assistant restart or a messy Wi-Fi roam are actively detected and cleaned up within seconds.
* The scanning process reliably survives the screen turning off.

Home Assistant will accurately flag the scanner as "failed" when the kiosk genuinely cannot perform a scan. Using the remote admin's `esphomeStatus` command provides a comprehensive breakdown: it reports if the server is running (and why it failed if it is down), whether a scan is currently active, live advertisement counters, active connections, and a recent dump of the proxy log.

## Hardware Notes

* On the vast majority of devices, Bluetooth and 2.4 GHz Wi-Fi share the exact same physical antenna. A kiosk pulling heavy video streams on a 2.4 GHz network will drop Bluetooth advertisements regardless of how optimized the software is. Strongly prefer a 5 GHz network for a device on proxy duty.
* On specific LineageOS builds designed for Amazon Echo Shows, the system Bluetooth service can enter a crash loop before the radio even powers on. No app can successfully scan in that environment. The proxy gracefully reports the scanner as failed and waits, rather than initiating a destructive retry loop.
* Some builds (like a Facebook Portal on Android 9, or custom LineageOS ports that omit `android.hardware.bluetooth_le`) declare no Bluetooth LE support at all. On these devices, every scan fails the very instant it begins, logging a "code=3 internal error". The app intelligently keeps **Enable Bluetooth proxy** disabled, citing the reason on both settings pages. Home Assistant will see the kiosk's entities, but no scanner will appear. If you build your own ROM, adding the feature declaration at `/vendor/etc/permissions/android.hardware.bluetooth_le.xml` and rebooting will lift this restriction.
* The core encryption key is generated exactly once and safely kept. Because Home Assistant stores this key securely within its own config entry, clearing it on the device will force you to run through the setup process on the Home Assistant side again.
