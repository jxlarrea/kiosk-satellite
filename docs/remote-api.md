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
field, Settings → Remote on the device (swipe from the left edge → Settings),
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
- WS: `?token=` query parameter.
- Failed logins are rate-limited (exponential backoff per client IP).
- Optional TLS with a self-signed cert (off by default; LAN-only assumption
  documented).

## REST surface

The API is a thin adapter over the internal `CommandRegistry`, the same
commands the JS API and MQTT topics use. Everything administrable in the app
is administrable here by construction.

| Endpoint | Method | Description |
|---|---|---|
| `/api/login` | POST | `{password}` → `{token}` |
| `/api/info` | GET | Device info, app version, battery, screen, current URL |
| `/api/settings` | GET | All setting definitions + current values |
| `/api/settings` | PATCH | `{key: value, ...}` partial update |
| `/api/settings/export` | GET | Full config as JSON (for provisioning) |
| `/api/settings/import` | POST | Apply exported config |
| `/api/config/export` | GET | Full backup: every setting (secrets included) plus the page's localStorage |
| `/api/config/import` | POST | Apply a full backup. Query params: `adoptIdentity` (default on) takes over the backup's device name and MQTT device id, for replacing the original device — pass `0` when cloning a second device so it keeps its own identity; `importLocalStorage` (default on) applies the page's saved data including the Voice Satellite selection — pass `0` so the device answers as its own satellite |
| `/api/commands` | GET | List registered commands + param schemas |
| `/api/commands/<name>` | POST | Execute a command with JSON params |
| `/api/screenshot` | GET | PNG of the current screen |
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
`loadDashboard {dashboard}`, `reload`, `screenOn` / `screenOff`,
`setBrightness {level}`, `startScreensaver` / `stopScreensaver`,
`setWakeWordActive {active}`, `restartApp`, `tts {text}`.

## WebSocket

JSON messages, `{type, ...}`:

- Server → client: `state` (full snapshot on connect, then diffs), `event`
  (bus events: motion, wake word, screen, navigation), `log` (app log lines),
  `console` (`{type: 'console', level, message, time}`, the WebView's
  JavaScript console, streamed live so you can watch a wall-mounted tablet's
  page logs remotely; fetch history first from `GET /api/console`).
- Client → server: `subscribe {topics: ['state','events','logs']}`,
  `command {name, params}` (same registry as REST).

## Remote UI

The admin UI is a single self-contained page (inline CSS + vanilla JS, no
build step) at [app/assets/remote-ui/index.html](../app/assets/remote-ui/index.html),
bundled as a Flutter asset and served at `/`. Tabs: Dashboard (live
screenshot + quick controls + brightness), Settings (rendered from the
declarative setting definitions), Console (live JS console over WS), Logs.
It talks only to the REST/WS API above (no privileged path), so it doubles
as the API's reference client. It can be replaced by a build-based SPA later
without touching the server.
