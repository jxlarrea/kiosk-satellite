# ESPHome

Serves the kiosk to Home Assistant as a native ESPHome device: its
sensors and controls appear as entities on the device Home Assistant
discovers automatically, with no MQTT broker and no custom integration
anywhere. This is the integration path going forward; the MQTT
integration keeps working but will be sunset, so new setups should start
here and existing ones migrate at their own pace.

The same connection optionally carries a full **Bluetooth proxy**: BLE
advertisements from nearby devices (BTHome sensors, Xiaomi and Govee
thermometers, iBeacons, plant sensors, scales) are relayed to Home
Assistant as if they were in range of the server itself, and Home
Assistant can hold active connections to locks, buttons and curtain
motors through the kiosk. Every kiosk on a wall extends Home Assistant's
Bluetooth coverage into that room, with no ESP32 to flash.

Multiple kiosks work as a mesh out of the box. Home Assistant merges all
of its Bluetooth sources and uses whichever proxy hears a device best, so
room-presence setups like Bermuda get one measuring point per kiosk.

## Setup

1. **Settings, ESPHome, Enable ESPHome.** The first start generates the
   encryption key and shows it in the same section. Turn on **Enable
   Bluetooth proxy** in the section below if the kiosk should relay
   Bluetooth too.
2. Grant **Nearby devices** and **Location** when prompted (both also
   available under **Settings, Device, Permissions Manager**), and keep
   the device's own location switch on. Android ties Bluetooth scanning
   to Location on every version and the app never reads the device's
   position; see
   [Permissions by Android version](#permissions-by-android-version) for
   why.
3. In Home Assistant, the device appears under **Settings, Devices &
   services** as a discovered ESPHome device named
   `kiosk-satellite-<id>`. Hit **Configure** and paste the encryption key
   from the kiosk's settings.
4. That is the whole setup. BLE devices in range of the kiosk appear in
   Home Assistant's Bluetooth integration automatically.

If discovery does not surface the device, add it by hand: **Add
integration, ESPHome**, host is the kiosk's IP, port 6053 (or the value of
the **API port** setting).

## What it relays

Advertisements always: broadcast sensors and presence tracking work the
moment the proxy is on. With **Allow device connections** (on by default),
Home Assistant can also connect to Bluetooth devices through the kiosk:
locks, buttons, curtain motors, anything Home Assistant controls over an
active connection, including pairing and cache management. Turning the
switch off returns the proxy to advertisement-only and tells Home
Assistant so; the proxy only ever announces capabilities it actually
serves, because announcing more is how Bluetooth proxies get a reputation
for breaking locks.

Connections are budgeted honestly: two at a time on older devices
(Android 11 and below), three on modern ones, and Home Assistant is told
the budget so it can route further devices through another proxy. Each
connection attempt pauses scanning for its handshake (they compete for
the same radio), retries the one routine Android failure once, and puts a
persistently failing device on a cooldown instead of hammering it.

With several proxies in the house, **Minimum signal for connections**
keeps a distant kiosk from volunteering for devices it can barely hear:
connection requests for devices last heard below the chosen signal level
are refused immediately, and Home Assistant fails over to a closer proxy.
A kiosk at the edge of a device's range can often complete a connection
it cannot hold, and while it holds the slot the closer proxy cannot take
over; the floor ends that tug-of-war. Devices the kiosk has never heard
are always allowed through, so pairing flows keep working.

## Kiosk entities

Turn on **Expose kiosk entities** and the kiosk's sensors and controls
come with the integration, the full catalog the MQTT
integration publishes, under the device Home Assistant
already discovered: the Screen light with brightness, screensaver and
settings switches, volume sliders, the action buttons, the Camera view
and Dashboard view selects, the Update entity with install-from-HA, a
camera streaming real frames, and the complete diagnostics set. Entity
names mirror the MQTT ones, so a migrating automation only swaps the
device half of the entity id. While the MQTT integration is enabled
alongside, entities exist twice, once per integration, and Home
Assistant suffixes whichever registered second; migrate automations to
the ESPHome ones at your own pace, then turn MQTT off. The toggle is off by default so that
enabling ESPHome just for the Bluetooth proxy never creates duplicates
next to an existing MQTT setup; flip it when you are ready to migrate.

Two switches join the set on a kiosk with a Voice Satellite assigned to
it: **Voice Satellite** starts and stops the engine in the page, the same
thing the Start and Stop buttons on the kiosk's own Voice Satellite
settings do, and **Voice Satellite auto start** decides whether it comes
up by itself with the dashboard. Together they let Home Assistant hold
the voice half back on a device that needs its first seconds for the
dashboard: leave auto start off and have an automation turn the engine on
a minute after the kiosk boots, or turn voice off entirely on a panel
where it is not wanted. Both appear once the kiosk is bound to a
satellite, which the setup wizard and the Voice Satellite settings page
both record; binding or unbinding one re-lists the entities the next time
the server starts.

One deliberate difference from the MQTT catalog: the ESPHome camera
protocol allows exactly one camera per device, so the kiosk serves its
device camera when present and enabled, else the screenshot camera.
The Camera view and Dashboard view option lists are learned when the
server starts; after adding views, toggle ESPHome off and on (or
restart the app) to refresh them. A note on Connectivity: with ESPHome
the entity reads "on" while the kiosk is reachable and "unavailable"
(rather than "off") when it is not, since a lost connection takes every
entity with it.

The ESPHome protocol has no attributes: an entity is its state and
nothing else. The hardware detail the MQTT sensors hang off a sensor as
attributes is therefore an entity of its own here. **Android version**
and **Android build** stand next to **Device**, which carries the model,
and **IPv4 addresses by interface** and **IPv6 addresses by interface**
stand next to the address sensors, each reading
`wlan0: 192.168.1.5; eth0: 10.0.3.2`, so an automation can tell whether
the kiosk is on its wired or its wireless NIC. Like their MQTT twins, the
address sensors lead with a routable IPv6 address over the link-local
`fe80::` one and re-check moments after any network change. The lists
that ride as attributes on the Bluetooth, Foreground app, Next alarm and
Camera view sensors have no ESPHome equivalent yet, and those sensors
carry their state alone.

## Notifications

Home Assistant can push a message at the kiosk and have it appear over
whatever is on screen, the screensaver included: a large card at the top
of the display with a chime, for the things a wall tablet is there to
say ("Washing machine finished", "Front door opened", "Leak detected").
It needs no dashboard card and no browser popup, and it does not disturb
what the kiosk was showing: the screensaver keeps running underneath and
the notification slides away by itself.

This rides an ESPHome action rather than an entity, because an action is
the one thing in the protocol that carries a payload. Turn on **Expose
kiosk entities** and Home Assistant registers
`esphome.<node name>_notification`, where the node name is the kiosk's
own (see Node name below) with underscores in place of hyphens; the
exact name is in Home Assistant's action picker under ESPHome.

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
```

An ESPHome device can call it directly, with no automation in between:

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
```

Every argument is required, because the ESPHome protocol has no optional
ones, so each has a value that means "as you were":

| Argument | Meaning |
|---|---|
| `message` | The text, in the largest type on the card |
| `title` | A heading above it. Empty for a message on its own |
| `duration` | Seconds on screen. `0` stays up until someone taps it or Home Assistant takes it down; a negative number uses the default of 30 |
| `type` | `info`, `success`, `warning` or `error`, which picks the icon and its color. Empty falls back to `info` |
| `chime` | Whether to play the notification chime. It plays through the selected speaker like every other app sound |
| `icon` | A Material Design Icon to draw instead of the one the type picks, named as Home Assistant names it (`mdi:washing-machine`). The full set is bundled, so anything valid in a dashboard works here, and the color still comes from the type. Empty for the type's own icon |
| `scale` | How large to draw it, `1` (the ordinary card) to `4`, decimals allowed. Everything grows together: type, icon, padding and width, so a `3` on a wall panel reads from the far side of a room without taking the screen over. `0` means the ordinary size |

Notifications stack, newest on top, up to four at a time: two things
happening at once is ordinary, and the second one arriving is no reason
to forget the first. Each keeps its own countdown and goes when it is
done. A fifth pushes the oldest out, so a stuck automation cannot paper
over the screen. The same message twice is two notifications: a second
call means it happened again.

A notification arriving over a running screensaver brings the panel back
to its ordinary brightness for as long as a card is up, so a kiosk
sitting at five percent overnight is readable the moment something
happens, and dims again when the last card goes. The screensaver itself
is not disturbed, and the behavior has a switch of its own (**Brighten
for notifications**, see [screensavers.md](screensavers.md#brightness)).

A tap anywhere on a card dismisses that card and leaves the rest. To take
one down from Home Assistant, call the kiosk's `dismissNotification`
command over the [remote API](remote-api.md), with the id
`showNotification` returned for a single card or nothing at all to clear
the screen; `showNotification` is that same command the action calls, for
setups driving the kiosk over REST instead.

## Node name

The kiosk answers to a node name on the network: it is the mDNS name
Home Assistant discovers (`<node name>.local`), and Home Assistant builds
this device's action names from it, so
`kitchen-tablet` is what makes the notification action read
`esphome.kitchen_tablet_notification`. A kiosk set up from scratch names
itself after its device name, and one that has already been discovered
keeps the generated `kiosk-satellite-<id>` name it was found under.

Either way the name is in **Settings, ESPHome, Node name**, and it can be
changed there. Anything typed is reduced to what a network name allows:
lower case, digits and single hyphens, so "Kitchen Tablet" becomes
`kitchen-tablet`. It has to be unique among the kiosks on the network.

Renaming is cheap but not free. Home Assistant keys the device and every
entity on the hardware address, not on this, so entities, their history
and their entity ids all survive a rename. What does not survive is the
action names built from it: automations calling
`esphome.old_name_notification` need updating to the new one.

Home Assistant also needs a nudge to notice. It reads the name when it
sets the device up, so after a rename, reload the kiosk's entry
(**Settings, Devices and services, ESPHome**, the kiosk's three dot menu,
**Reload**) and the action appears under its new name. The old name stays
in the action list until Home Assistant restarts; it does nothing.

## Device identity

The kiosk normally identifies itself to Home Assistant with a generated
hardware address, because Android hides the real one from apps. That
keeps the ESPHome device separate from the entries router and network
integrations (UniFi, OPNsense, DHCP tracking) register for the same
hardware, which all carry the real Wi-Fi MAC. Turn on **Use real Wi-Fi
MAC address** (under **Advanced settings** on the ESPHome page) and,
where the address can be read at all, the kiosk reports it instead and
Home Assistant merges those entries into one device.

The address is readable on Android 9 and older, and on any version when
the app is the device owner. Elsewhere the switch says so right below
itself and the generated identity stays in use. The first address read
is kept for good, so the identity survives OS upgrades that close the
door it came through. Flip the switch only when you are prepared to re-add the kiosk in Home
Assistant: an existing ESPHome entry is keyed on the old identity and
refuses the connection ("Unexpected device found") until you delete the
entry and let discovery re-add the kiosk. Turning the switch back off
restores the old identity, but Home Assistant stops retrying after the
mismatch: reload the kiosk's entry (or restart Home Assistant) and the
old device comes back as it was. The MQTT integration's
device follows the same switch, so both integrations land on the same
merged device.

Where Android will not reveal the address, the switch's status row says
so and offers a **Spoof Wi-Fi MAC address** field right under it: type
the address in yourself and the kiosk reports that one instead. Android
shows it under About > Status in its settings, and your router's client
list has it too. The field accepts the usual spellings (colons, dashes,
or twelve bare hex digits) and refuses anything that could not be an
interface address. The field only appears while the hardware read has
failed; a working read always wins, so on a device that later lets the
app read the address (an app made device owner, say) the read address
takes over, which changes nothing when the typed one was right. The same
re-add caveat applies: a typed address, and any later change to it, is a
new identity to Home Assistant.

## Nearby devices

The Bluetooth Proxy settings page lists what the kiosk currently hears,
identified as far as honesty allows: the name a device broadcasts, else
its class from the advertisement (a BTHome sensor, an Apple Find My
device, a Windows PC), else its manufacturer. Devices using rotating
private addresses are marked; their row is an appearance, not a stable
device, and only Home Assistant's Private BLE Device integration (with
the device's IRK) can give those a lasting identity.

The same list reaches Home Assistant as a diagnostic sensor per kiosk,
**Bluetooth devices nearby** (the count as its state, and over the MQTT
integration the identified list as attributes), so a dashboard can show
what each room hears.

Alongside it, **Bluetooth devices connected** counts the devices this
kiosk itself is linked to right now, with their names as attributes over
the MQTT integration, so a dashboard can answer "is the room's speaker
still on the panel" without walking over to it. It counts every link the adapter holds, including any
the proxy has open for Home Assistant, which is what a connection count
means from the device's side. Beside it, **Bluetooth max connections**
reports the proxy's own budget, the ceiling that count runs into, so a
dashboard can put the two numbers next to each other. Both follow the
links as they happen rather than on a poll, so a device Home Assistant
connects to for a few seconds (a lock taking a command through the proxy)
shows up for as long as the link lasts. Both
sensors come and go with the Bluetooth Proxy switch, and both are
published by the MQTT integration too. Devices whose Android will not
report their Bluetooth links at all (no adapter, or the Nearby devices
permission not granted on Android 12 and newer) get no sensor rather than
one stuck on unknown.

**Look up device manufacturers online** is off by default. Switched on,
unknown devices with real hardware addresses are named by their
manufacturer prefix using api.macvendors.com. Only the 3-byte prefix is
ever sent, once per manufacturer, and the answer is cached on the device
permanently; nothing else leaves the network, and the relay to Home
Assistant is untouched either way.

## Permissions by Android version

| Android | What scanning needs |
| --- | --- |
| 12+ | The **Nearby devices** runtime pair (scan + connect), plus the **Location** permission and location services switched on. |
| 6 to 11 | Bluetooth is granted at install; the **Location** permission and location services must be on. |

The Location requirement surprises people, because nothing about it looks
like Bluetooth, but it applies on every Android version and it is
deliberate. Android considers Bluetooth beacons location-inferable, and an
app that scans with location detached (the `neverForLocation` flag) never
receives iBeacon or Eddystone frames at all on Android 12 and newer, which
is precisely the traffic a Bermuda or iBeacon presence setup needs
relayed: phones become invisible to the proxy while everything else shows
up. The proxy therefore scans with location attached, and Android in turn
requires the **Location** permission and the device-wide location switch
(on Fire tablets under **Location Based Services**) on every version. The
app never reads the device's position; the grant only unlocks scan
delivery.

The symptom of a missing half is always the same: the proxy reports
itself as scanning, the phone (or on old Android every device) never
appears, and Home Assistant sees a proxy that delivers little or nothing.
The permission rows on the settings pages read the real gate and name
whichever half is blocking scanning; the Grant button asks for the right
permissions in order, and opens the system's location settings screen
when the switch is what is off.

## Reliability

Android BLE scanning fails in creative ways, and the proxy is built to
notice and recover on its own:

- A watchdog restarts the scan when advertisements stop arriving; a home
  with any BLE device in it is never silent for long, so silence means
  the scanner stalled. Some chipsets (MediaTek in particular) stall
  silently after hours of continuous scanning.
- Turning Bluetooth off and on, an airplane-mode toggle, or an Android
  Bluetooth stack crash suspends the proxy; it resumes by itself the
  moment the adapter comes back.
- Scan restarts are budgeted so Android's own silent scan throttling (5
  starts per 30 seconds) is never tripped.
- The connection to Home Assistant is watched from both ends: half-open
  sockets left by a Home Assistant restart or a Wi-Fi roam are detected
  and cleaned up within seconds.
- Scanning survives the screen turning off. No extra setting needed.

The state is visible end to end: Home Assistant shows the scanner as
failed when the kiosk genuinely cannot scan, and the remote admin's
`btProxyStatus` command reports whether the proxy is running, whether a
scan is active, advertisement counters, and the recent proxy log.

## Hardware notes

- Bluetooth and 2.4 GHz Wi-Fi share an antenna on most tablets. A kiosk
  doing heavy streaming on 2.4 GHz Wi-Fi will miss advertisements no
  matter what the software does; prefer 5 GHz Wi-Fi on proxy duty.
- Some repurposed devices have Bluetooth stacks that are broken at the
  operating system level. On the LineageOS builds for Amazon Echo Shows,
  the Bluetooth service can crash-loop before the radio ever powers on;
  no app can scan on such a device. The proxy detects this, reports the
  scanner as failed to Home Assistant, and waits instead of retry-looping.
- The encryption key is generated once and kept: Home Assistant stores it
  in its config entry, so clearing it forces a re-setup on the Home
  Assistant side.
