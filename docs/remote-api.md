# Kiosk Satellite Remote Management API

Every device runs an embedded HTTP server (default port **2324**, configurable;
kept for Fully Kiosk familiarity) serving:

1. The **remote admin SPA** (`remote-ui/`, bundled into app assets) at `/`.
2. A **REST API** under `/api/`.
3. A **WebSocket** at `/api/ws` for live state, events, and log tailing.

On iOS the server runs while the app is foreground, which is always true in kiosk use.
Devices advertise over mDNS as `_kiosksatellite._tcp` for discovery (and a
future multi-device fleet view).

## Enabling

The server starts only when `remote.enabled` is on **and** `remote.password`
is set. Three ways to get there: the setup wizard's optional admin-password
field, Settings → Device → Remote Administration on the device (swipe from
the left edge → Settings),
or an Android provisioning intent:

```sh
adb shell am start -n me.jxl.kiosk_satellite/.MainActivity \
  --es ks.provision '"{\"remote.enabled\":true,\"remote.password\":\"secret\"}"'
```

## Authentication

- A device password (set in the wizard; required before the server starts).
- REST: `Authorization: Bearer <token>` obtained from `POST /api/login
  {password}`. Tokens are HMAC-signed (stateless) with a persisted secret and
  expire after 7 days, so a session survives the app/kiosk restarting.
- Automations that cannot redo the login dance pass `ttl_days` to get a
  long-lived token (clamped to 10 years): `POST /api/login
  {password, ttl_days: 3650}`. Tokens are stateless, so changing the admin
  password does not revoke ones already issued — treat a long-lived token
  like a password.
- WS: `?token=` query parameter.
- Failed logins are rate-limited (exponential backoff per client IP).
- `GET /api/health` is the one unauthenticated endpoint: it exists for
  external monitoring to poll, and a monitor cannot do a login dance. It
  serves read-only hardware facts only.
- Optional TLS with a self-signed cert (off by default; LAN-only assumption
  documented).

## REST surface

The API is a thin adapter over the internal `CommandRegistry`, the same
commands the JS API and the ESPHome entities use. Everything administrable in the app
is administrable here by construction.

| Endpoint | Method | Description |
|---|---|---|
| `/api/login` | POST | `{password}` → `{token}`. Optional `ttl_days` for a long-lived automation token (max 3650) |
| `/api/info` | GET | Device info, app version, battery, screen, current URL |
| `/api/health` | GET | The Device Info tab's Hardware section as one JSON object: identity, addresses, battery, screen, RAM, storage, CPU usage and temperature, and uptimes (`uptime.app` and `uptime.network`, seconds; `network` is null while offline and starts counting at app start at the earliest). Meant for external monitoring to poll, so it is the one endpoint that needs no token |
| `/api/settings` | GET | All setting definitions + current values |
| `/api/settings` | PATCH | `{key: value, ...}` partial update |
| `/api/settings/export` | GET | Full config as JSON (for provisioning) |
| `/api/settings/import` | POST | Apply exported config. Query param: `adoptIdentity` (default on) keeps the dump's device name, ESPHome node name and Sendspin player id, for restoring the same device; pass `0` when provisioning a second device from another's dump, so it keeps its own identity (and its own Voice Satellite selection) instead of the two fighting over one ESPHome device and one Sendspin player |
| `/api/config/export` | GET | Full backup: every setting (secrets included) plus the page's localStorage. Also carries `deviceName` and `exportedAt`, which name the downloaded file (`ks-backup_<device>_<YYYYMMDD>_<HHmmss>.json`) and keep it identifiable afterwards |
| `/api/config/import` | POST | Apply a full backup. Query params: `adoptIdentity` (default on) takes over the backup's device name and ESPHome node name, for replacing the original device — pass `0` when cloning a second device so it keeps its own identity; `importLocalStorage` (default on) applies the page's saved data including the Voice Satellite selection — pass `0` so the device answers as its own satellite |
| `/api/commands` | GET | List registered commands + param schemas |
| `/api/commands/<name>` | POST | Execute a command with JSON params |
| `/api/screenshot` | GET | JPEG of the current screen (PNG placeholder while it is off). The capture also feeds the Screenshot entity and Last screenshot over ESPHome and MQTT |
| `/api/camera/snapshot` | GET | The latest device-camera frame as JPEG (404 until one has been captured). `X-Snapshot-At` carries the capture time as ISO 8601 UTC. Serves the cached frame; it never triggers a capture (use the `takeCameraSnapshot` command for that). |
| `/api/files/download` | GET | Stream a device file. Query params: `root` (`shared` or `app`), `path` (relative to the root) |
| `/api/files/upload` | POST | Write the raw request body to a device file, same `root`/`path` query params. Parent folders are created |
| `/api/logs` | GET | Recent app log ring buffer |
| `/api/console` | GET | Current WebView JS console buffer |

The File Manager tab drives these plus the `fileRoots`, `fileList` and
`fileDelete` commands. The `shared` root is the device's shared storage and
needs the "All files access" grant (a settings screen on the device, offered
from the tab); the `app` root is the app's own folder and always works. Paths
are canonicalized against their root, so `..` cannot escape it.

Representative commands (`POST /api/commands/<name>`): `loadUrl {url}`,
`loadDashboard {dashboard}`, `loadStartUrl` (back to the configured
Start URL), `reload`, `screenOn` / `screenOff` / `isScreenOn` (`screenOn {path: "activity"}`
skips the wake lock and wakes through the Activity route only, to tell
which of the two works on a panel that stays dark),
`setBrightness {level}` (the panel itself; `ceiling: true` sets the
bright-room level [adaptive brightness](screen.md#adaptive-brightness)
dims from instead, which is what the screensaver does, and `getBrightness
{ceiling: true}` reads it), `startScreensaver` / `stopScreensaver` /
`isScreensaverActive`,
`postponeScreensaver` (reset the idle timer, dismissing a showing
screensaver first), `nextScreensaverSlide` / `previousScreensaverSlide`
(step a showing photo-mode slideshow; a no-op for other modes, the
result says whether anything stepped),
`setWakeWordActive {active}`, `showCameraView {viewId}`,
`hideCameraView`, `getCameraViewState` (`{active, viewId, viewName,
focusedCameraId}`), `cameraGetConfig`, `restartApp`, `tts {text}`,
`launchApp {package}` (open another Android app over the kiosk),
`bringToFront` (come back in front of it), `installedApps` (every
launchable app as `[{package, label}]`), `showAppLauncher` /
`hideAppLauncher` (the app launcher overlay;
`showAppLauncher` refuses while the App Launcher is disabled in
settings), `showNotification {message, title, duration, type, chime, scale, icon, chime_file, volume, image}` and
`dismissNotification {id}` (a message over whatever is on screen, the
screensaver included; `duration` is seconds, `0` stays until dismissed,
omitted uses 30, `chime` defaults to on, and `scale` draws the card
larger, 1 to 4 with decimals, `icon` takes any Material Design Icon
name (`mdi:washing-machine`) in place of the one the type picks,
`chime_file` names a file in the kiosk's sounds folder (`leak.mp3`, see
[esphome.md](esphome.md#notifications)) to play in place of the one
picked in the kiosk's settings, and `volume` sets how loud it plays, 0
to 1, apart from the media and assistant volumes, with 0 or omitted
meaning the Notification volume setting, and `image` puts a picture
under the text, an http(s) URL or a path on the Home Assistant server
such as `/api/camera_proxy/camera.doorbell`, fetched with the kiosk's
own Home Assistant token. `showNotification` answers
with the `id` to dismiss later, notifications stack newest on top up to
four, and `dismissNotification` without an id clears them all. Home
Assistant setups can push the same thing as an ESPHome action, see
[esphome.md](esphome.md)).

## Calling from Home Assistant automations

The Fully Kiosk pattern — one URL per action, fired from an automation —
maps onto two `rest_command` entries and a token obtained once. Get the
long-lived token from any machine on the LAN:

```sh
curl -X POST http://<device-ip>:2324/api/login \
  -H 'Content-Type: application/json' \
  -d '{"password": "<admin password>", "ttl_days": 3650}'
```

Paste the returned token into `configuration.yaml` (or a `!secret`):

```yaml
rest_command:
  tablet_open_doorbell:
    url: "http://<device-ip>:2324/api/commands/launchApp"
    method: post
    headers:
      authorization: "Bearer <token>"
    content_type: "application/json"
    payload: '{"package": "com.mcu.reolink"}'
  tablet_back_to_dashboard:
    url: "http://<device-ip>:2324/api/commands/bringToFront"
    method: post
    headers:
      authorization: "Bearer <token>"
```

An automation then calls `rest_command.tablet_open_doorbell` when the
doorbell rings and `rest_command.tablet_back_to_dashboard` when done.
`launchApp` leaves the kiosk running behind the other app, so coming back
lands on the live dashboard, not a reload. With [ESPHome](esphome.md)
kiosk entities exposed, the return half needs no REST at all: the device
carries a **Bring to front** button entity.

## WebSocket

JSON messages, `{type, ...}`:

- Server → client: `state` (full snapshot on connect: device identity,
  battery, brightness, plus `screenOn`, `screensaverActive` and
  `cameraView {active, viewId, viewName}`, the same shape `GET /api/info`
  returns), `event` (bus events: motion, face, wake word, screen,
  screensaver, camera view, navigation; `screenon` / `screenoff`, `screensaverstart` /
  `screensaverstop` and `cameraview` are the diffs to the snapshot's three
  states), `log` (app log lines),
  `console` (`{type: 'console', level, message, time}`, the WebView's
  JavaScript console, streamed live so you can watch a wall-mounted tablet's
  page logs remotely; fetch history first from `GET /api/console`).
- Client → server: `subscribe {topics: ['state','events','logs']}`,
  `command {name, params}` (same registry as REST).

## Remote UI

The admin UI is a vanilla-JS single-page app with no build step: the page
at [app/assets/remote-ui/index.html](../app/assets/remote-ui/index.html)
holds the markup, and the stylesheet plus ES modules live under
[app/assets/remote-ui/static/](../app/assets/remote-ui/static/), bundled as
Flutter assets. The server serves the page at `/` and the files at
`/static/<name>`, discovered from the asset manifest, so adding a module is
just adding the file. Tabs: Dashboard (live screenshot + quick controls +
brightness; the screen, screensaver and camera view controls are one tile
each, relabelled by the device's state, **Screen off** while the panel is
lit and **Screen on** once it is dark, **Start screensaver** or **Dismiss
screensaver**, **Show camera view**, which picks a view, or **Dismiss camera
view**), Settings (rendered from the declarative setting definitions),
Console (live JS console over WS), Logs. It talks only to the REST/WS API
above (no privileged path), so it doubles as the API's reference client.

Caching: at startup the server hashes the page and every static file into
one 12-hex version, stamps it into the page's `?v=` references and into
every `from './x.js'` import specifier it serves, and answers static files
with `Cache-Control: immutable` and the page itself with `no-store`. Any
change to any file changes the hash, so browsers cache aggressively yet can
never run a stale mix of modules.
