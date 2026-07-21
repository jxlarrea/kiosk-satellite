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

Any number of tablets can share one broker and one set of credentials. Each
install generates a permanent random id that namespaces its topics and
entity ids, so devices never collide; each appears in Home Assistant as its
own device, named after the **Device name** setting.

## Entities

| Entity | Type | Notes |
| --- | --- | --- |
| Screen | light | On/off is real display power; brightness is the panel's actual brightness. Turning the screen off needs the device admin permission (the wizard requests it); without the grant the toggle snaps back and the device shows the grant screen. |
| Screensaver | switch | Start or dismiss the screensaver. |
| Volume | number | The device's media volume as a 0-100% slider. Tracks changes from every side, hardware buttons included. |
| Kiosk mode | switch | The kiosk lockdown (exit gesture, blocked buttons). |
| HA kiosk mode | switch | Hides the Home Assistant header and sidebar. On maps to the `auto` mode; a hand-picked `plugin`/`css` choice is left alone until the switch is actually flipped. |
| Keep screen on | switch | The keep-awake setting. |
| Remote management | switch | The embedded admin web server. Turning it off from Home Assistant closes the remote admin. |
| Reload page | button | Reload the current dashboard. |
| Clear cache | button | Clear the WebView cache. |
| Battery, Charging | sensor | Polled once a minute. |
| CPU usage, CPU temperature | sensor | Polled once a minute. |
| RAM available, RAM total | sensor | Polled once a minute. |
| Current page | sensor | The URL the kiosk is showing. |

All entities carry availability: they go unavailable the moment the tablet
drops off the broker (broker-side last will, so it works however the
connection dies) and recover automatically when it returns.

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
| `.../kiosk/…`, `.../ha_kiosk/…`, `.../keep_screen_on/…`, `.../remote/…` | out / in | `ON` / `OFF` (`state` and `set` each) |
| `.../reload/set`, `.../clear_cache/set` | in | any payload presses the button |
| `.../battery/state`, `.../cpu/state`, `.../cpu_temp/state`, `.../ram_free/state`, `.../ram_total/state` | out, retained | numbers |
| `.../url/state` | out, retained | the current URL |

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
