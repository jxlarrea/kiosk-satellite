# Kiosk Satellite — Remote Management API

Every device runs an embedded HTTP server (default port **2323**, configurable —
kept for Fully Kiosk familiarity) serving:

1. The **remote admin SPA** (`remote-ui/`, bundled into app assets) at `/`.
2. A **REST API** under `/api/`.
3. A **WebSocket** at `/api/ws` for live state, events, and log tailing.

On iOS the server runs while the app is foreground — always true in kiosk use.
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
  {password}`. Tokens are random, in-memory, expire after inactivity.
- WS: `?token=` query parameter.
- Failed logins are rate-limited (exponential backoff per client IP).
- Optional TLS with a self-signed cert (off by default; LAN-only assumption
  documented).

## REST surface

The API is a thin adapter over the internal `CommandRegistry` — the same
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
| `/api/commands` | GET | List registered commands + param schemas |
| `/api/commands/<name>` | POST | Execute a command with JSON params |
| `/api/screenshot` | GET | PNG of the current screen |
| `/api/logs` | GET | Recent log ring buffer |

Representative commands (`POST /api/commands/<name>`): `loadUrl {url}`,
`loadDashboard {dashboard}`, `reload`, `screenOn` / `screenOff`,
`setBrightness {level}`, `startScreensaver` / `stopScreensaver`,
`setWakeWordActive {active}`, `restartApp`, `tts {text}`.

## WebSocket

JSON messages, `{type, ...}`:

- Server → client: `state` (full snapshot on connect, then diffs), `event`
  (bus events: motion, wake word, screen, navigation), `log` (when subscribed).
- Client → server: `subscribe {topics: ['state','events','logs']}`,
  `command {name, params}` (same registry as REST).

## Remote UI

`remote-ui/` is a small Svelte + Vite SPA compiled to static assets and bundled
into the app. Pages: Dashboard (live state + screenshot), Settings (rendered
from the declarative setting definitions), Commands, Logs. Talks only to the
REST/WS API above — no privileged path — so it doubles as the API's reference
client.
