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
| **Allow device connections** | (On by default) Allows Home Assistant to connect to Bluetooth devices (locks, buttons, curtain motors) through the kiosk, including handling pairing and cache management. Turning this off restricts the proxy to advertisement only mode and informs Home Assistant of the change. The proxy will only announce the capabilities it actively serves. |
| **Minimum signal for connections** | Connection requests for devices last heard below this signal threshold are immediately refused. This forces Home Assistant to fail over to a closer proxy rather than tying up a slot on a kiosk that can connect but not hold the connection reliably. If the kiosk has never heard a device before, it will always allow the connection through so that initial pairing continues to work. |

Connection budget (Home Assistant is informed of this limit so it can route additional devices through another proxy if needed):

| Android Version | Simultaneous Connections |
|---|---|
| 11 and older | 2 |
| 12 and newer | 3 |

Each connection attempt temporarily pauses scanning to perform its handshake (since they share the same radio hardware). It will retry the standard Android failure routine once before placing a persistently failing device on a cooldown timer.

## Kiosk Entities

Turn on **Expose kiosk entities** to add all the entities listed below to the device in Home Assistant. This is off by default, meaning if you only enable ESPHome for the Bluetooth proxy, no extra entities are created. Rows marked with a requirement only appear if that hardware is present; for example, a kiosk with no camera simply will not have camera entities, rather than displaying dead ones. Because the ESPHome protocol does not use attributes, any hardware details that would normally ride on a sensor as an attribute are split into their own distinct entities.

### Controls

| Entity | Type | Notes |
|---|---|---|
| **Screen** | light | Controls the screen state (on or off) along with the panel brightness. |
| **Screensaver active** | switch | Manually starts and stops the screensaver. |
| **Now Playing** | switch | Reads "on" while the full screen Now Playing view is visible. Turning it on brings the view up (paused if the music is paused); turning it off dismisses the view. Requires the setting "Now Playing" instead of the screensaver to be on. |
| **Volume** | number | Controls the media volume percentage. |
| **Voice Satellite** | switch | Starts and stops the voice engine on the page, identical to the Start and Stop buttons found in the kiosk's Voice Satellite settings. Requires a satellite bound to the kiosk (which is handled during the setup wizard or on the Voice Satellite settings page). Binding or unbinding a satellite will refresh the entity list on the next server start. |
| **Postpone screensaver** | button | Restarts the idle countdown timer. |
| **Screensaver next slide**, **Screensaver previous slide** | button | Steps a Home Assistant Media, Local Media, Photo Gallery, or Immich Media slideshow forward or backward by one slide, holding the new slide for its full interval. If Camera Streams are active, it steps between camera views. Pressing this does nothing if any other mode (or no screensaver) is active. |
| **Notifications dismiss all** | button | The button equivalent of the `notification_dismiss` action below: acknowledging a leak on one display can clear the alerts on all the rest. |
| **Reload page**, **Go to dashboard**, **Clear cache**, **Restart app**, **Bring to front** | button | Triggers the exact same actions available in the kiosk's side drawer. |
| **Open app launcher** | button | Requires the App launcher setting to be enabled. |
| **Show Music Assistant** | button | Requires a Music Assistant server address to be configured. |
| **Camera view** | select | Includes a "Closed" option, plus one option for every camera view containing cameras. Requires camera views to be configured. The option list is built when the server starts; if you add new views, simply toggle ESPHome off and on, or restart the app to refresh the list. |
| **Show <view>** (one per camera view), **Close camera view** | button | Opens a specific named view or closes whichever view is currently open. |
| **Active camera view** | text sensor | Displays the name of the view currently on screen, or reads `none` when closed. |
| **Dashboard view** | select | Provides one option per dashboard view (`dashboard/view`). This list re reads when Home Assistant reports that a dashboard was created, deleted, or edited, and when the dashboard connection returns after an outage (it never re reads on a timer). The last read list is saved across restarts, so the selector is available immediately upon the first connection even if Home Assistant is temporarily down. |
| **Update** | update | Displays the latest release and its release notes, which you can install directly from Home Assistant (see [updates.md](updates.md)). |
| **Screenshot** | camera | Exposes the display as a still camera on every kiosk. It is fed by the Take screenshot button or by fetching the entity itself. |
| **Take screenshot** | button | Manually captures the display. |
| **Last screenshot** | timestamp | Updates when the button is pressed or the remote admin preview refreshes, but never on a simple fetch of the camera entity. The value is saved across restarts. |
| **Camera** | camera | Requires physical camera hardware. Because the ESPHome image request protocol does not specify a named camera, fetching either camera triggers a request to both, and each answers on its own specific entity. This strictly follows the physical hardware, not the Camera enabled switch; if the camera is disabled in settings, it will display a "Camera off" frame rather than forcing the device to re register. |
| **Take camera snapshot** | button | Requires physical camera hardware. |
| **Last camera snapshot** | timestamp | Requires physical camera hardware. The value is saved across restarts. |
| **Ambient light** | sensor | Reports light levels in Lux. Requires a physical light sensor. |
| **GPS latitude**, **GPS longitude** | sensor | Reports coordinates in degrees, precise to six decimals. Requires **Report location** to be on and a physical GPS receiver. See the [GPS Sensor](#gps-sensor) section. |
| **GPS accuracy**, **Altitude** | sensor | Reports accuracy and altitude in meters. Requires **Report location** to be on and a physical GPS receiver. |
| **Speed** | sensor | Reports speed in meters per second (Home Assistant will automatically convert this to your preferred unit system). Requires **Report location** to be on and a physical GPS receiver. |
| **Last location fix** | timestamp | Indicates when the GPS receiver last reported. Requires **Report location** to be on and a physical GPS receiver. The value is saved across restarts. |
| **Motion** | binary sensor | Requires physical camera hardware. Will read "unknown" while the camera is toggled off. |
| **Person** | binary sensor | Reports occupancy derived from an on device person sensor (currently supported on Meta Portals). Requires **Dismiss on person** to be on, which triggers a device re registration. Will read "unknown" if the sensor cannot be read. See the [Meta Portal](portal.md) guide. |
| **Next alarm** | timestamp | Displays the next scheduled alarm on the Android device itself. |
| **Last interaction** | timestamp | Records the timestamp of the last touch, spoken voice turn, or gesture based wake. The value is saved across restarts. |
| **Next screensaver** | timestamp | Indicates exactly when the idle clock will trigger the screensaver. This updates on every touch, dismissal, or timeout change, allowing an automation to trigger off it directly, or a template to count down to it without the device needing to push a new value every single second. It reads "unknown" when nothing is actively counting down (e.g., if the screensaver is off, already showing, during a voice turn, in a camera view, in hold mode, or if another app is in front). Under a rapid stream of touches, it republishes at most once a minute, and always before the previously reported moment passes. |

Note: If your Dashboard view list changes, the device will re register, causing every entity to briefly become unavailable for a couple of seconds. This only happens if the list actually shifted.

### Configuration

Every item in this list corresponds directly to a kiosk setting. They are fully readable and writable from Home Assistant and perfectly match the values shown on the settings pages.

| Entity | Type | Notes |
|---|---|---|
| **Screensaver brightness level**, **Assistant volume**, **Media volume** | number | Values in percentage. |
| **Clock background** | text | Defines the background for the Clock screensaver. |
| **Kiosk mode**, **Lockdown mode**, **HA kiosk mode**, **Keep screen on**, **Remote management**, **Screensaver brightness**, **Screensaver**, **Hold mode** | switch | Standard toggle switches. |
| **Adaptive brightness** | switch | Requires a physical light sensor. |
| **Camera enabled**, **Screensaver motion detection**, **Screensaver face detection** | switch | Requires physical camera hardware. The Camera enabled switch can be safely toggled throughout the day; the camera entities will remain listed. |
| **Screensaver proximity detection** | switch | Requires a physical proximity sensor. |
| **Voice Satellite auto start** | switch | Controls whether the voice engine starts automatically with the dashboard. This allows an automation to delay voice services on slower devices that need all their processing power for the initial dashboard load. Requires a bound satellite. |
| **Theme** | select | Options are Auto, Light, or Dark. Selecting Light or Dark forcibly pins the dashboard theme, overriding both the on device schedule and the app theme sync for as long as it is active. If theme sync is enabled, pinning the theme will flip the app's internal screens as well. |
| **Screensaver mode**, **Clock style** | select | Provides the exact same options found on the device settings pages. |
| **Default dashboard** | select | The dashboard the kiosk starts on, returns to with the Go to dashboard button and reloads after a crash or restart. Same `dashboard/view` options as the Dashboard view select. Changing it rewrites the start URL but leaves the page where it is, so an automation can make a night dashboard the one the kiosk always comes back to and use the Dashboard view select when it should show right away. |
| **Camera facing** | select | Requires both a front and back physical camera. |

### Diagnostics

| Entity | Type | Notes |
|---|---|---|
| **Battery** | sensor | Reports battery percentage. Only devices with a physical battery receive this entity; a mains powered device without a battery will only report the Charging status. |
| **Charging** | binary sensor | Indicates if the device is currently receiving power. |
| **CPU usage** | sensor | Reports current CPU load as a percentage. |
| **CPU temperature** | sensor | Only available on devices that report thermal data. |
| **RAM available**, **RAM total** | sensor | Reported in Megabytes (MB). |
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
| `message` | The main text, displayed in the largest font on the card. |
| `title` | A smaller heading positioned above the message. Leave empty if you only want the message itself. |
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

When using the [remote API](remote-api.md), these two commands correspond to `showNotification` (which returns the same `id`) and `dismissNotification` (which takes the ID, or clears the screen if given `0` or nothing).

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

## GPS Sensor

If your device travels (like a tablet mounted in an RV), it can transmit its exact location to Home Assistant using its built in GPS receiver. You must explicitly opt in via **Settings > ESPHome > GPS Sensor**.

| | |
| --- | --- |
| **Report location** | Activates the receiver and begins serving data to the six location sensors detailed above. Off by default. Because toggling this on or off forces the device to re register, all entities will be briefly unavailable for a few seconds during the transition. |
| **Update interval** | Sets the time in seconds between readings, defaulting to 60. The app only pushes a new reading when the receiver actively delivers one, ensuring a parked kiosk costs Home Assistant absolutely zero processing overhead. |
| **Last coordinates** | Displayed directly under the switch, this shows the most recent coordinate reading, including its accuracy and age, or the specific reason why no data is available. |
| No GPS receiver | If the hardware lacks a receiver, the switch is permanently disabled and clearly states the reason. Most standard kiosk style tablets do not include GPS hardware. |
| **Location** grant | This is the only permission requested on this page, but it requires location services to be enabled in the core Android settings as well. Tapping **Grant** will prompt for the permission, or directly open the system location settings if the master switch is what is turned off. |
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

| | |
|---|---|
| Readable | The real MAC address can only be read on Android 9 and older, or on any version where the app is provisioned as the device owner. If it cannot be read, the switch will clearly state the limitation beneath itself, and the generated identity will remain active. |
| Kept | The very first address successfully read is permanently locked in. This ensures the identity survives major OS upgrades that might otherwise close the exploit used to read it. |
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
* Any half open sockets left lingering by a Home Assistant restart or a messy Wi-Fi roam are actively detected and cleaned up within seconds.
* The scanning process reliably survives the screen turning off.

Home Assistant will accurately flag the scanner as "failed" when the kiosk genuinely cannot perform a scan. Using the remote admin's `esphomeStatus` command provides a comprehensive breakdown: it reports if the server is running (and why it failed if it is down), whether a scan is currently active, live advertisement counters, active connections, and a recent dump of the proxy log.

## Hardware Notes

* On the vast majority of devices, Bluetooth and 2.4 GHz Wi-Fi share the exact same physical antenna. A kiosk pulling heavy video streams on a 2.4 GHz network will drop Bluetooth advertisements regardless of how optimized the software is. Strongly prefer a 5 GHz network for a device on proxy duty.
* On specific LineageOS builds designed for Amazon Echo Shows, the system Bluetooth service can enter a crash loop before the radio even powers on. No app can successfully scan in that environment. The proxy gracefully reports the scanner as failed and waits, rather than initiating a destructive retry loop.
* Some builds (like a Facebook Portal on Android 9, or custom LineageOS ports that omit `android.hardware.bluetooth_le`) declare no Bluetooth LE support at all. On these devices, every scan fails the very instant it begins, logging a "code=3 internal error". The app intelligently keeps **Enable Bluetooth proxy** disabled, citing the reason on both settings pages. Home Assistant will see the kiosk's entities, but no scanner will appear. If you build your own ROM, adding the feature declaration at `/vendor/etc/permissions/android.hardware.bluetooth_le.xml` and rebooting will lift this restriction.
* The core encryption key is generated exactly once and safely kept. Because Home Assistant stores this key securely within its own config entry, clearing it on the device will force you to run through the setup process on the Home Assistant side again.