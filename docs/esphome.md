# ESPHome

The kiosk serves itself to Home Assistant as a native ESPHome device: its sensors and controls are entities on a device Home Assistant discovers on its own, with no broker and no custom integration. This is the one integration path for every entity the kiosk offers.

The same connection can carry a **Bluetooth proxy**: BLE advertisements from nearby devices (BTHome sensors, Xiaomi and Govee thermometers, iBeacons, plant sensors, scales) reach Home Assistant as if in range of the server. Home Assistant can also hold connections to locks, buttons and curtain motors through the kiosk. Several kiosks mesh out of the box: Home Assistant uses whichever proxy hears a device best, so room-presence setups like Bermuda get one measuring point per kiosk.

## Setup

1. **Settings, ESPHome, Enable ESPHome.** The first start generates the encryption key and shows it in the same section. Turn on **Enable Bluetooth proxy** below it if the kiosk should relay Bluetooth too.
2. Grant **Nearby devices** and **Location** when prompted (also under **Settings, Device, Permissions Manager**) and keep the device's location switch on. See [Permissions by Android version](#permissions-by-android-version) for why.
3. In Home Assistant, **Settings, Devices & services** shows a discovered ESPHome device named `kiosk-satellite-<id>`. Hit **Configure** and paste the key.

| Situation | What to do |
|---|---|
| Not discovered | **Add integration, ESPHome**, host is the kiosk's IP, port 6053 (or the **API port** setting) |
| Visit link on the device page | Appears with **Remote management** on and an admin password set (**Settings, Device, Remote Administration**). It opens the remote admin page on the address Home Assistant connects to and the remote admin **Server port**. Turning remote management off or changing the port updates the link at the next connection, which the kiosk makes on its own |

## Bluetooth proxy

| Setting | Effect |
|---|---|
| **Enable Bluetooth proxy** | Advertisements are relayed. Broadcast sensors and presence tracking work the moment it is on |
| **Allow device connections** (on by default) | Home Assistant connects to Bluetooth devices through the kiosk: locks, buttons, curtain motors, pairing and cache management included. Off returns the proxy to advertisement-only and tells Home Assistant so. The proxy only ever announces what it serves |
| **Minimum signal for connections** | Connection requests for devices last heard below this level are refused at once, so Home Assistant fails over to a closer proxy instead of leaving the slot with a kiosk that can connect but not hold. Devices the kiosk has never heard are always let through, so pairing keeps working |

Connection budget, which Home Assistant is told so it can route further devices through another proxy:

| Android | Connections at a time |
|---|---|
| 11 and older | 2 |
| 12 and newer | 3 |

Each connection attempt pauses scanning for its handshake (they share the radio), retries the one routine Android failure once and puts a persistently failing device on a cooldown.

## Kiosk entities

Turn on **Expose kiosk entities** and every entity below joins the device. Off by default, so enabling ESPHome for the proxy alone adds nothing else. Rows marked with a requirement are listed only where it holds, so a kiosk without a camera has no camera rows at all rather than dead ones. The ESPHome protocol has no attributes, so hardware detail that would ride on a sensor as attributes is an entity of its own.

### Controls

| Entity | Type | Notes |
|---|---|---|
| **Screen** | light | Screen on or off, with the panel brightness |
| **Screensaver active** | switch | Starts and stops the screensaver |
| **Volume** | number | Media volume, percent |
| **Voice Satellite** | switch | Starts and stops the engine in the page, the same as the Start and Stop buttons on the kiosk's Voice Satellite settings. Requires a satellite bound to the kiosk (the setup wizard and the Voice Satellite settings page both record that). Binding or unbinding re-lists the entities at the next server start |
| **Postpone screensaver** | button | Restarts the idle countdown |
| **Screensaver next slide**, **Screensaver previous slide** | button | Step a Home Assistant Media, Local Media, Photo Gallery or Immich Media slideshow by one and hold the new slide for its full interval. With Camera Streams up they step camera views. With any other mode or no screensaver the press does nothing |
| **Notifications dismiss all** | button | The button form of `notification_dismiss` below: a leak acknowledged on one display can clear the rest |
| **Reload page**, **Go to dashboard**, **Clear cache**, **Restart app**, **Bring to front** | button | The same actions the kiosk's drawer offers |
| **Open app launcher** | button | Requires the App launcher setting on |
| **Show Music Assistant** | button | Requires a Music Assistant server address set |
| **Camera view** | select | Closed, then one option per camera view that has cameras. Requires camera views configured. The option list is learned when the server starts: after adding views, toggle ESPHome off and on or restart the app |
| **Show <view>** (one per camera view), **Close camera view** | button | Open a named view or close whichever is up |
| **Active camera view** | text sensor | The view on screen, `none` when closed |
| **Dashboard view** | select | One option per dashboard view (`dashboard/view`). Re-read when Home Assistant reports a dashboard created, deleted or edited and when the dashboard's connection comes back after an outage, never on a timer. The last list read is kept across restarts, so the select is there from the first connection even with Home Assistant down |
| **Update** | update | The latest release with its notes, installable from Home Assistant (see [updates.md](updates.md)) |
| **Screenshot** | camera | The display as a still camera, on every kiosk: fed by the Take screenshot button and by a fetch of the entity |
| **Take screenshot** | button | Captures the display |
| **Last screenshot** | timestamp | Moves on the button and the remote admin's preview, never on a fetch of the camera entity. Kept across restarts |
| **Camera** | camera | Requires camera hardware. The ESPHome image request names no camera, so a fetch of either camera asks both and each answers on its own entity. Follows the hardware, not the Camera enabled switch: off, it shows a "Camera off" frame and the device does not re-register |
| **Take camera snapshot** | button | Requires camera hardware |
| **Last camera snapshot** | timestamp | Requires camera hardware. Kept across restarts |
| **Ambient light** | sensor | Lux. Requires a light sensor |
| **Motion** | binary sensor | Requires camera hardware. Reads unknown while the camera is off |
| **Next alarm** | timestamp | The next alarm set on the device |
| **Last interaction** | timestamp | The last touch, spoken turn or hand-made wake. Kept across restarts |

> [!NOTE]
> A changed Dashboard view list re-registers the device, which makes every entity unavailable for a couple of seconds. It only happens for a list that actually moved.

### Configuration

Each of these is a kiosk setting, readable and writable from Home Assistant, the same value the settings pages show.

| Entity | Type | Notes |
|---|---|---|
| **Screensaver brightness level**, **Assistant volume**, **Media volume** | number | Percent |
| **Clock background** | text | The Clock screensaver's background |
| **Kiosk mode**, **Lockdown mode**, **HA kiosk mode**, **Keep screen on**, **Remote management**, **Screensaver brightness**, **Screensaver**, **Hold mode** | switch | |
| **Adaptive brightness** | switch | Requires a light sensor |
| **Camera enabled**, **Screensaver motion detection**, **Screensaver face detection** | switch | Require camera hardware. Camera enabled can be flipped through the day: the camera entities stay listed |
| **Screensaver proximity detection** | switch | Requires a proximity sensor |
| **Voice Satellite auto start** | switch | Whether the engine comes up with the dashboard, so an automation can hold voice back on a device that needs its first seconds for the dashboard. Requires a bound satellite |
| **Theme** | select | Auto, Light or Dark. Light or Dark pins the dashboard and outranks the on-device schedule and the app theme sync while it holds. With the theme sync on, the pin flips the app's own screens too |
| **Screensaver mode**, **Clock style** | select | The same options as the settings pages |
| **Camera facing** | select | Requires a front and a back camera |

### Diagnostics

| Entity | Type | Notes |
|---|---|---|
| **Battery** | sensor | Percent |
| **Charging** | binary sensor | |
| **CPU usage** | sensor | Percent |
| **CPU temperature** | sensor | Requires a device that reports one |
| **RAM available**, **RAM total** | sensor | MB |
| **Current page** | text sensor | The URL on screen, SPA navigations included |
| **Foreground app** | text sensor | The package in front |
| **Bluetooth devices nearby** | sensor | Requires the Bluetooth proxy on. See [Nearby devices](#nearby-devices) |
| **Bluetooth max connections** | sensor | Requires the proxy on with device connections allowed |
| **Bluetooth devices connected** | sensor | Requires the proxy on and an Android that reports links (an adapter, plus the Nearby devices grant on Android 12 and newer) |
| **Device** | text sensor | The model |
| **Panel brightness** | sensor | Percent, as the panel reads it |
| **Android version**, **Android build** | text sensor | |
| **IPv4 address**, **IPv6 address** | text sensor | The primary address. IPv6 leads with a routable address over the link-local `fe80::` one |
| **IPv4 addresses by interface**, **IPv6 addresses by interface** | text sensor | `wlan0: 192.168.1.5; eth0: 10.0.3.2`, so an automation can tell wired from wireless. Re-checked moments after any network change |
| **App uptime**, **Network uptime** | timestamp | When the app started and when the network last came up |
| **Last seen** | timestamp | Every completed poll |
| **Connectivity** | binary sensor | Reads "on" while the kiosk is reachable and "unavailable" (not "off") when it is not, since a lost connection takes every entity with it |
| **Remote admin** | text sensor | The remote admin page's URL, `disabled` while remote management is off |

## Notifications

Home Assistant can push a message at the kiosk: a large card at the top of the display with a chime, over whatever is on screen, the screensaver included. Nothing underneath is disturbed and the card slides away by itself.

It is an ESPHome action, the one thing in the protocol that carries a payload. With **Expose kiosk entities** on, Home Assistant registers `esphome.<node name>_notification`, the node name with underscores in place of hyphens (see [Node name](#node-name)). The exact name is in the action picker under ESPHome.

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

An ESPHome device can call it directly:

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

Every argument is required (ESPHome has no optional ones), so each has a value that means "as you were":

| Argument | Meaning |
|---|---|
| `message` | The text, in the largest type on the card |
| `title` | A heading above it. Empty for a message on its own |
| `duration` | Seconds on screen. `0` stays up until someone taps it or Home Assistant takes it down. Negative uses the default of 30 |
| `type` | `info`, `success`, `warning` or `error`, which picks the icon and its color. Empty falls back to `info` |
| `chime` | Whether to play the notification sound, through the selected speaker like every other app sound |
| `icon` | A Material Design Icon in place of the type's own, named as Home Assistant names it (`mdi:washing-machine`). The full set is bundled. The color still comes from the type. Empty for the type's icon |
| `scale` | Card size, `1` (ordinary) to `4`, decimals allowed. Type, icon, padding and width grow together, so a `3` reads from across a room. `0` means ordinary |
| `chime_file` | A sound of this notification's own: the name of a file in the kiosk's sounds folder (`leak.mp3`), not a path or URL. Empty plays the sound from the settings. So does a name with no file behind it, with a line in the app's log |
| `volume` | `0` to `1`, apart from the media and assistant volumes (the device's master volume still applies). `0` or negative uses the **Notification volume** setting. A silent notification is `chime: false` |
| `image` | A picture under the text. An `http(s)` URL the kiosk can reach or a path on the Home Assistant server: `/api/camera_proxy/camera.doorbell` fetches a fresh frame as the card goes up, `/local/doorbell.jpg` a file under `/config/www`. Paths and URLs on the Home Assistant server are fetched with the kiosk's own token. The words show at once and the picture joins when it arrives, within 10 seconds and up to 8 MB. A picture that cannot be fetched is a log line and a card without one. Empty for none |

Behavior:

- Cards stack newest on top, four at a time, each with its own countdown. A fifth pushes the oldest out.
- The same message twice is two cards.
- A tap on a card dismisses that card and leaves the rest.
- A card arriving over a running screensaver brings the panel to ordinary brightness while any card is up (**Brighten for notifications**, see [screensavers.md](screensavers.md#brightness)).

The action answers with the card's id, `{"id": 7}`, which `response_variable` hands to `esphome.<node name>_notification_dismiss` to take that card down. `id: 0` clears the screen. Each kiosk answers with its own id, so an alert fanned out to several kiosks keeps one id per kiosk. Action responses need Home Assistant 2026.1 or newer. Older versions run the action and get no answer.

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

Over the [remote API](remote-api.md) the same two are `showNotification` (answers with the same `id`) and `dismissNotification` (takes it, `0` or nothing to clear the screen).

### Sounds

| | |
|---|---|
| Folder | `Android/data/me.jxl.kiosk_satellite/files/sounds`, the app folder the File Manager shows. No permission needed. Survives restarts and updates, goes with an uninstall |
| Ways in | **Add a sound** on the Notifications settings page (**Browse** on the device, **Upload** in the remote admin), the File Manager's upload, USB or adb |
| Formats | MP3, OGG (Vorbis), WAV, FLAC, M4A and AAC. No video files and no Opus |
| **Notification sound** | Dropdown over that folder, **Built-in chime** first. Stores the file name, so a backup restored onto another kiosk means the same file. A missing file shows as missing and plays the built-in chime until it is back |
| **Notification volume** | 70% by default, apart from the media and assistant faders |
| **Test** | Sends a notification through this kiosk's action so sound and volume can be judged in place |

Give each kind of notification (a leak, a delivery, the laundry) its own `chime_file` in the automation and keep the settings as the default for the rest.

## Node name

The node name is the mDNS name Home Assistant discovers (`<node name>.local`) and the stem of the device's action names: `kitchen-tablet` makes `esphome.kitchen_tablet_notification`. A fresh install names itself after its device name. A kiosk already discovered keeps the generated `kiosk-satellite-<id>`.

Change it under **Settings, ESPHome, Node name**. Anything typed is reduced to lower case, digits and single hyphens ("Kitchen Tablet" becomes `kitchen-tablet`) and must be unique among the kiosks on the network.

| After a rename | |
|---|---|
| Entities, history, entity ids | Survive: Home Assistant keys them on the hardware address |
| Action names | Change: update automations calling `esphome.old_name_notification` |
| Home Assistant | Reload the kiosk's entry (**Settings, Devices and services, ESPHome**, three dot menu, **Reload**) and the action appears under the new name. The old name stays in the picker until Home Assistant restarts and does nothing |

## Device identity

The kiosk identifies itself with a generated hardware address, because Android hides the real one from apps, which keeps the ESPHome device apart from the entries router and network integrations (UniFi, OPNsense, DHCP tracking) register for the same hardware. **Use real Wi-Fi MAC address** (under **Advanced settings** on the ESPHome page) reports the real one where it can be read and Home Assistant merges those entries into one device.

| | |
|---|---|
| Readable | Android 9 and older, plus any version with the app as device owner. Elsewhere the switch says so right below itself and the generated identity stays |
| Kept | The first address read is kept for good, so the identity survives OS upgrades that close the door it came through |
| **Spoof Wi-Fi MAC address** | Offered under the switch only while the hardware read fails. Type the address (Android shows it under About > Status, the router's client list has it too) in colons, dashes or twelve bare hex digits. A working read always wins |

> [!WARNING]
> A new identity (the switch, a typed address or any change to it) makes the existing ESPHome entry refuse the kiosk with "Unexpected device found". Delete the entry and let discovery re-add the kiosk. Turning the switch back off restores the old identity, but Home Assistant has stopped retrying: reload the kiosk's entry or restart Home Assistant.

## Nearby devices

The Bluetooth Proxy settings page lists what the kiosk hears: the name a device broadcasts, else its class from the advertisement (a BTHome sensor, an Apple Find My device, a Windows PC), else its manufacturer. Rotating private addresses are marked: the row is an appearance, not a stable device. Only the Private BLE Device integration (with the device's IRK) gives those a lasting identity.

| Sensor | Reads |
|---|---|
| **Bluetooth devices nearby** | The count of that list, so a dashboard can show how much each room hears |
| **Bluetooth devices connected** | Every link the adapter holds right now, the proxy's own included, updated as links come and go rather than on a poll |
| **Bluetooth max connections** | The proxy's budget, the ceiling that count runs into |

The two connection sensors come and go with the Bluetooth proxy switch and are left out where Android will not report links at all (no adapter or no Nearby devices grant on Android 12 and newer).

**Look up device manufacturers online** is off by default. On, unknown devices with real hardware addresses are named by their manufacturer prefix through api.macvendors.com: only the 3-byte prefix is sent, once per manufacturer and the answer is cached for good. The relay to Home Assistant is untouched either way.

## Permissions by Android version

| Android | What scanning needs |
| --- | --- |
| 12+ | The **Nearby devices** runtime pair (scan + connect), plus the **Location** permission and location services switched on. |
| 6 to 11 | Bluetooth is granted at install. The **Location** permission and location services must be on. |

Location is required on every version because Android treats beacons as location-inferable: an app that scans with location detached never receives iBeacon or Eddystone frames on Android 12 and newer, which is exactly what a Bermuda or iBeacon presence setup needs relayed. The app never reads the device's position. On Fire tablets the device switch is under **Location Based Services**.

Symptom of a missing half: the proxy reports itself scanning, the phone (on old Android every device) never appears and Home Assistant sees a proxy that delivers little or nothing. The permission rows on the settings pages name whichever half is blocking. **Grant** asks in order or opens the system's location settings when the switch is what is off.

## Reliability

- A watchdog restarts the scan when advertisements stop arriving. A home with any BLE device in it is never silent for long. Some chipsets (MediaTek in particular) stall silently after hours of scanning.
- Bluetooth off and on, an airplane-mode toggle or a Bluetooth stack crash suspends the proxy. It resumes when the adapter comes back.
- Scan restarts are budgeted under Android's silent throttle of 5 starts per 30 seconds.
- Half-open sockets left by a Home Assistant restart or a Wi-Fi roam are detected and cleaned up within seconds.
- Scanning survives the screen turning off.

Home Assistant shows the scanner as failed when the kiosk genuinely cannot scan. The remote admin's `esphomeStatus` command reports whether the server is running and why not if it is down, whether a scan is active, advertisement counters, active connections and the recent proxy log.

## Hardware notes

- Bluetooth and 2.4 GHz Wi-Fi share an antenna on most tablets. A kiosk streaming heavily on 2.4 GHz misses advertisements whatever the software does. Prefer 5 GHz on proxy duty.
- On the LineageOS builds for Amazon Echo Shows the Bluetooth service can crash-loop before the radio powers on. No app can scan there. The proxy reports the scanner as failed and waits instead of retry-looping.
- Some builds declare no Bluetooth LE support at all (a Facebook Portal on Android 9, LineageOS ports that leave `android.hardware.bluetooth_le` out): every scan fails the instant it starts ("code=3 internal error"). The app keeps **Enable Bluetooth proxy** off there, disabled with the reason on both settings pages. Home Assistant sees the kiosk's entities but no scanner. On a ROM you build yourself, adding the feature declaration at `/vendor/etc/permissions/android.hardware.bluetooth_le.xml` and rebooting lifts the gate.
- The encryption key is generated once and kept. Home Assistant stores it in its config entry, so clearing it forces a re-setup on the Home Assistant side.
