# Bluetooth Proxy

Turns the kiosk into an ESPHome-compatible Bluetooth proxy: BLE
advertisements from nearby devices (BTHome sensors, Xiaomi and Govee
thermometers, iBeacons, plant sensors, scales) are relayed to Home
Assistant as if they were in range of the server itself. Every kiosk on a
wall extends Home Assistant's Bluetooth coverage into that room, with no
ESP32 to flash and no custom integration to install: Home Assistant sees a
standard ESPHome Bluetooth proxy through its own ESPHome integration.

Multiple kiosks work as a mesh out of the box. Home Assistant merges all
of its Bluetooth sources and uses whichever proxy hears a device best, so
room-presence setups like Bermuda get one measuring point per kiosk.

## Setup

1. **Settings, Bluetooth Proxy, Enable Bluetooth proxy.** The first start
   generates the encryption key and shows it in the same section.
2. On Android 12 or later, grant **Nearby devices** when prompted (also
   available under **Settings, Device, Permissions Manager**).
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

This proxy is advertisement-only, deliberately. It announces exactly the
capabilities it has (passive scanning and raw advertisements), so Home
Assistant never routes active GATT connections, pairing, or cache
operations through it. Broadcast sensors and presence tracking work fully;
devices that need Home Assistant to connect to them (some locks and
switches with encrypted GATT control) still need a proxy with connection
support, such as an ESP32. Announcing capabilities a device cannot honor
is how Bluetooth proxies get a reputation for breaking locks; this one
does not.

## Nearby devices

The Bluetooth Proxy settings page lists what the kiosk currently hears,
identified as far as honesty allows: the name a device broadcasts, else
its class from the advertisement (a BTHome sensor, an Apple Find My
device, a Windows PC), else its manufacturer. Devices using rotating
private addresses are marked; their row is an appearance, not a stable
device, and only Home Assistant's Private BLE Device integration (with
the device's IRK) can give those a lasting identity.

The same list reaches Home Assistant as a diagnostic sensor per kiosk,
**Bluetooth devices nearby** (the count as its state, the identified list
as attributes), so a dashboard can show what each room hears.

**Look up device manufacturers online** is off by default. Switched on,
unknown devices with real hardware addresses are named by their
manufacturer prefix using api.macvendors.com. Only the 3-byte prefix is
ever sent, once per manufacturer, and the answer is cached on the device
permanently; nothing else leaves the network, and the relay to Home
Assistant is untouched either way.

## Permissions by Android version

| Android | What scanning needs |
| --- | --- |
| 12+ | The **Nearby devices** runtime pair (scan + connect). Location is not required; the app declares its scans are not used for location. |
| 6 to 11 | Bluetooth is granted at install, but Android requires the **Location** permission and location services switched on for BLE scan results to be delivered. |

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
