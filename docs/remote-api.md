# Kiosk Satellite Remote Management API

Every device runs an embedded HTTP server (default port **2324**, configurable;
kept for Fully Kiosk familiarity) serving:

1. The **remote admin SPA** (`remote-ui/`, bundled into app assets) at `/`.
2. A **REST API** under `/api/`.
3. A **WebSocket** at `/api/ws` for live state, events, and log tailing.

On iOS the server runs while the app is foreground, which is always true in kiosk use.
Devices advertise over mDNS as `_kiosk-satellite._tcp` while the server runs,
which is how the kiosk switcher below finds them.

## Enabling

The server starts only when `remote.enabled` is on **and** `remote.password`
is set. Three ways to get there: the setup wizard's optional admin-password
field, Settings → Device → Remote Administration on the device (swipe from
the left edge → Settings),
or an Android provisioning intent:

```sh
adb shell am start -n me.jxl.kiosk_satellite/.ProvisionActivity \
  --es ks.provision '"{\"remote.enabled\":true,\"remote.password\":\"secret\"}"'
```

The payload takes any setting, in the same JSON the settings import
accepts. Only the adb shell can send it: Android refuses the intent from
other apps on the device. Older builds took the extra on
`.MainActivity`, which now ignores it.

## Reaching a kiosk by name

Every kiosk with its remote admin on answers to a hostname on the local
network, so the admin opens at `http://<hostname>.local:2324` from a laptop
with no IP address to remember. The **mDNS name** setting under Settings →
Device, right under Device name, holds it. It is filled in from the device
name as a DNS label under `ks-` (the device name "Kitchen Tablet" becomes
`ks-kitchen-tablet`, answering to `ks-kitchen-tablet.local`), the same name
the ESPHome node takes on a fresh install, so the field holds the real name
to copy. Renaming the device leaves it alone; clear the field to take the
device name again. A typed name is slugified the same way: lowercase
letters, digits and hyphens. The Access card under Remote Administration, on the device and
in the remote admin, shows the address by name next to the one by IP.
Over HTTPS with an imported certificate it shows the first DNS name that
certificate covers instead, since the browser rejects that certificate
under `.local`. The kiosk still answers to its `.local` name.

| | |
| --- | --- |
| How | The kiosk announces an A record for `<hostname>.local` over mDNS every 30 seconds and answers queries for it with that record alone. A query that asks for a unicast reply (the first one macOS and iOS send) gets one straight back, and a plain DNS query sent to the multicast group from an ordinary port (Android's own resolver, `dig @224.0.0.251 -p 5353`) gets a matching unicast reply too. That is what makes the name resolve on a Wi-Fi network that filters multicast toward its clients: the queries still reach the kiosk, and the reply comes back unicast. |
| When | While **Remote management** is on with a password set, with or without **Find other kiosks**. |
| Where it resolves | Any machine that resolves `.local` over mDNS: macOS, iOS, Android with system mDNS support, Windows 10 and later and Linux with Avahi (or systemd-resolved with mDNS turned on). Android versions without system mDNS support still need the IP. Multicast does not cross VLANs without a reflector. |
| Two kiosks, one name | Both answer, and a browser lands on either. The log warns when another device announces this name at a different IPv4 address, even with **Find other kiosks** off on either kiosk. Give one of them a different mDNS name. |
| Port 5353 | Answering queries takes the mDNS port. Where something on the device holds it exclusively the kiosk still announces, and only resolvers that cache announcements they did not ask for (Avahi does) find it. |
| Per device | The mDNS name never syncs from a fleet leader, and a settings import that clones a kiosk drops it. |

## Kiosk switcher

With several kiosks on one network, the device name under the logo in the
remote admin becomes a dropdown. It opens **Switch kiosk**, a list of every
kiosk discovered or saved in the fleet: this device first, then the others by name, each
with its address and version. Picking one opens that kiosk's remote admin in
the same tab, on the page you were on. A second-level page the other kiosk
does not have (gated off by its own settings) lands on its parent tab. Its
own login card shows first if its password differs.

| | |
| --- | --- |
| How they find each other | Each kiosk announces `ks-<id>._kiosk-satellite._tcp.local` over mDNS with its name, version and admin port, every 30 seconds and on a query, and listens for the others. Raw multicast packets, not NsdManager, which never calls back on Fire OS and some LineageOS builds. |
| What is listed | Kiosks with **Remote management** on, a password set and **Find other kiosks** on, on the same network segment. Multicast does not cross VLANs by itself. Through an mDNS reflector on the router it does, and each kiosk is listed under the address its own announcement carries, not the router's, so calls and the switcher reach it as long as the VLANs route to each other. |
| Saved fleet members | Accepted members remain listed without multicast. Leaders store their followers and send the member directory to each follower. Discovery refreshes known addresses. Opening another kiosk still requires a reachable admin endpoint. |
| HTTPS with an imported certificate | A kiosk serving HTTPS with an imported certificate also announces the first DNS name that certificate covers, skipping wildcard and `.local` names. The switcher opens it by that name instead of its IP address, so the browser accepts the certificate. The name has to resolve to the kiosk on your network. A kiosk with only a wildcard certificate or the generated one is opened by its IP address. |
| Behind a reverse proxy | **Admin URL** under Settings → Device → Remote Administration takes an address such as `https://kiosk.example.com`, with an optional port and no path. The kiosk announces it, and the switcher opens it ahead of the certificate's name and the IP address. Blank by default. Fleet sync and the intercom keep using the IP address. It never syncs from a fleet leader. |
| Switch | **Find other kiosks** under Settings → Device → Remote Administration, on by default. Off, the kiosk neither announces nor listens, and the dropdown stays plain text. |
| Command | `fleet` answers the same list: `{enabled, devices: [{id, name, version, address, port, url, self}]}`, plus `adminUrl` on a kiosk that has one. The WebSocket carries a `fleet` event on every change. |
| Port 5353 | Hearing the others needs the mDNS port. Where something on the device holds it exclusively the kiosk still announces, and the log says the others will not be heard. |

## Fleet Management

With the switcher in place, one kiosk can lead the others: it pushes the settings categories each follower was given to it, holds off while their versions differ and can update the fleet. The page, the sync rules and the fleet endpoints are in [Fleet Management](fleet.md).

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
  serves read-only hardware facts only. It sends
  `Access-Control-Allow-Origin: *`, so a web page on any origin can read it.
- Optional HTTPS with a device certificate. Off by default. Plain HTTP is intended for a trusted LAN.

## HTTPS and certificates

Turn on **Use HTTPS** in **Device > Remote Administration** to encrypt the admin page, REST API and WebSocket on the existing admin port. A confirmation dialog shows the new address in a copyable box before either protocol change. **Confirm** applies it and reloads the browser at that address. **Cancel** keeps the current protocol. A self-signed certificate produces a browser warning until you trust it. You may need to log in again because HTTP and HTTPS have separate browser storage. The WebSocket uses `wss://` automatically. The Home Assistant Admin URL sensor reports HTTPS. The ESPHome Visit link is omitted because that link assumes HTTP.

The **Device > TLS** page manages the device certificate. Encryption switches live on their feature pages. See [TLS encryption](tls.md) for Remote Administration, camera and intercom setup:

- **Download public certificate** in the remote admin or **Copy public certificate** on the device exports only the public certificate.
- **Renew certificate** renews the built-in certificate with the same private key and current hostname and IP addresses. Browsers that trust a specific certificate may need the renewed certificate installed.
- **Import certificate** accepts a PEM server certificate chain and its matching unencrypted EC or RSA private key. Import from the device screen or through HTTPS. The app validates the material before replacing the current identity. Imported certificates are renewed by their issuer and must be imported again before they expire.
- **Replace certificate** generates a new private key and certificate. Browsers may ask you to accept the new certificate. Other kiosks reconnect automatically.

On Android, private keys are encrypted with an Android Keystore key and stored outside Android backup. They are never returned by the remote API or included in configuration exports. Each device keeps its own identity when a configuration is cloned. The generated certificate lasts one year. While any TLS setting is on, the app checks every six hours and renews generated certificates within 30 days of expiration. Renew manually after changing the hostname or when you need a new IP address included in the certificate.

Certificate changes restart encrypted listeners and disconnect active encrypted viewers. Plain listeners are unaffected. Failed certificate loading leaves the encrypted listener stopped with an error. It never opens a plaintext replacement. The device's local settings remain available for recovery.

The authenticated command API exposes `tlsCertificate`, `renewTlsCertificate`, `replaceTlsIdentity` and `importTlsCertificate`. Certificate status includes the PEM certificate, SHA-256 certificate fingerprint and expiration. Import accepts `certificate` and `privateKey`.

## REST surface

The API is a thin adapter over the internal `CommandRegistry`, the same
commands the JS API and the ESPHome entities use. Everything administrable in the app
is administrable here by construction.

| Endpoint | Method | Description |
|---|---|---|
| `/api/login` | POST | `{password}` → `{token}`. Optional `ttl_days` for a long-lived automation token (max 3650) |
| `/api/info` | GET | Device info, app version, battery, screen, current URL |
| `/api/health` | GET | The Device Info tab's Hardware section as one JSON object: identity, addresses, battery (null on a device without one), screen (`width`, `height`, `density`, `orientation` and `rotation` in degrees from the panel's natural orientation), RAM, storage, CPU usage, clock (`cpu.clock`, MHz) and temperature, the system WebView (`webview.package` and `webview.version`), the network link and uptimes. `link.type` is `ethernet`, `wifi`, `cellular`, `vpn` or `other`, and on Wi-Fi `link` adds `rssi` (dBm), `speedMbps` and `frequencyMhz`, each null when Android does not know it. `link` is null while offline and never carries the network name, which needs a location permission. `uptime.app`, `uptime.device` and `uptime.network` are in seconds since the app started, the device booted and the network came up. `network` is null while offline and starts counting at app start at the earliest. `leader` is true when the kiosk leads a fleet, and `follows` is the name of the leader it follows, null when it follows none. Meant for external monitoring to poll, so it is the one endpoint that needs no token. Any web page can read it, so a page of your own can list your kiosks by name and version |
| `/api/settings` | GET | All setting definitions + current values |
| `/api/settings` | PATCH | `{key: value, ...}` partial update |
| `/api/settings/export` | GET | Full config as JSON (for provisioning) |
| `/api/settings/import` | POST | Apply exported config. Query param: `adoptIdentity` (default on) keeps the dump's device name, ESPHome node name and Sendspin player id, for restoring the same device; pass `0` when provisioning a second device from another's dump, so it keeps its own identity (and its own Voice Satellite selection) instead of the two fighting over one ESPHome device and one Sendspin player |
| `/api/config/export` | GET | Full backup: every setting (secrets included) plus the page's localStorage. Also carries `deviceName` and `exportedAt`, which name the downloaded file (`ks-backup_<device>_<YYYYMMDD>_<HHmmss>.json`) and keep it identifiable afterwards |
| `/api/config/import` | POST | Apply a full backup. Query params: `adoptIdentity` (default on) takes over the backup's device name and ESPHome node name, for replacing the original device — pass `0` when cloning a second device so it keeps its own identity; `importLocalStorage` (default on) applies the page's saved data including the Voice Satellite selection — pass `0` so the device answers as its own satellite |
| `/api/fleet/export` | GET | The full backup of this kiosk and every follower it leads, in one file. See [Fleet Management](fleet.md#remote-api) |
| `/api/commands` | GET | List registered commands + param schemas |
| `/api/commands/<name>` | POST | Execute a command with JSON params |
| `/api/screenshot` | GET | JPEG of the current screen (PNG placeholder while it is off). The capture also feeds the Screenshot entity and Last screenshot over ESPHome |
| `/api/media/artwork` | GET | The shown track's cover art, fetched by the device (which trusts the Sendspin and Music Assistant hosts a browser would not), labelled by its bytes. 404 with no track or no art. `X-Artwork-Url` carries the source URL. |
| `/api/camera/snapshot` | GET | The latest device-camera frame as JPEG (404 until one has been captured). `X-Snapshot-At` carries the capture time as ISO 8601 UTC. Serves the cached frame; it never triggers a capture (use the `takeCameraSnapshot` command for that). |
| `/api/files/download` | GET | Stream a device file. Query params: `root` (`shared` or `app`), `path` (relative to the root) |
| `/api/files/upload` | POST | Write the raw request body to a device file, same `root`/`path` query params. Parent folders are created |
| `/api/update/upload` | POST | Take in a Kiosk Satellite APK as the raw request body, for a kiosk that can reach neither GitHub nor a custom repository. The kiosk reads package, version and build out of it and refuses another package, an older build or a file its cache cannot hold twice. Answers `{version, buildNumber, size, currentVersion, currentBuild}`. Nothing installs until `installUploadedApk` is called; `getUpdateStatus` reports the waiting file under `uploaded` and `installing` while the hand-off runs, then the outcome in `lastOutcome`. See [Updates](updates.md#installing-an-uploaded-apk) |
| `/api/fleet/identity`, `/api/fleet/invite`, `/api/fleet/invite/<nonce>` | GET, POST, GET | Fleet Management's public face, for a kiosk with no token here: who this kiosk is, an invitation to follow (answered on the kiosk screen or with `fleetAccept` and `fleetDecline` in its remote admin) and what became of one. See [Fleet Management](fleet.md) |
| `/api/fleet/status`, `/api/fleet/apply`, `/api/fleet/leave`, `/api/fleet/roster` | GET, POST, POST, POST | The follower's side of the fleet: opened by the fleet token a follower mints on accepting, which is good for these, `getUpdateStatus`, `checkUpdateNow`, `installUpdate`, `/api/update/upload` and `installUploadedApk` and nothing else, only while it names this kiosk's leader |
| `/api/intercom/identity`, `/api/intercom/call`, `/api/intercom/call/<id>`, `/api/intercom/audio/<id>`, `/api/intercom/video/<id>` | GET, POST, POST, WebSocket, WebSocket | The [intercom's](intercom.md#remote-api) wire between kiosks: who this kiosk is (public), a call or broadcast coming in, the answer going back and the voice socket. All but the identity carry a token signed with the shared intercom key, never an admin token |
| `/api/logs` | GET | Recent app log ring buffer |
| `/api/console` | GET | Current WebView JS console buffer |

The File Manager tab drives these plus the `fileRoots`, `fileList` and
`fileDelete` commands. The `shared` root is the device's shared storage and
needs the "All files access" grant (a settings screen on the device, offered
from the tab); the `app` root is the app's own folder and always works. Paths
are canonicalized against their root, so `..` cannot escape it.

The `soundDiagnostics` command captures and replays a TTS response for Android
playback troubleshooting. See [TTS playback diagnostics](tts-diagnostics.md).

Representative commands (`POST /api/commands/<name>`): `loadUrl {url}`,
`loadDashboard {dashboard}`, `loadStartUrl` (back to the configured
Start URL), `reload`, `screenOn` / `screenOff` / `isScreenOn` (`screenOn {path: "activity"}`
skips the wake lock and wakes through the Activity route only, to tell
which of the two works on a panel that stays dark),
`setBrightness {level}` (turns Default brightness, or Maximum brightness
with [adaptive brightness](screen.md#adaptive-brightness) on; `ceiling:
true` sets the bright-room level for the session instead, which is what
the screensaver does; `getBrightness` reads the same level, `{ceiling:
true}` the session's, `{panel: true}` what the panel shows),
`startScreensaver` / `stopScreensaver` /
`isScreensaverActive`,
`postponeScreensaver` (reset the idle timer, dismissing a showing
screensaver first), `nextScreensaverSlide` / `previousScreensaverSlide`
(step a showing photo-mode slideshow; a no-op for other modes, the
result says whether anything stepped),
`setWakeWordActive {active}`, `showCameraView {viewId}`,
`hideCameraView`, `getCameraViewState` (`{active, viewId, viewName,
focusedCameraId}`), `cameraGetConfig`, `restartApp`, `rebootDevice`
(restart the whole device; only as device owner or through a granted
Shizuku connection, which `getDeviceRebootSupport` reports as
`{supported, route, reason}`), `tts {text}`,
`launchApp {package}` (open another Android app over the kiosk),
`showLinkPage {url, hold}` / `hideOverlayPage` (a web page with a close
button over the dashboard, the surface a tapped dashboard link gets;
`hold: true` turns hold mode on with the page and off when it goes; the
`open_url` and `close_url` [ESPHome actions](esphome.md#open-a-web-page)
call the same two),
`bringToFront` (come back in front of it), `installedApps` (every
launchable app as `[{package, label}]`), `immichAlbums`,
`immichPeople` and `immichTags` (the Immich screensaver's albums, named
people and tags as `[{id, name}]`, for its source and filter pickers), `showAppLauncher` /
`hideAppLauncher` (the app launcher overlay;
`showAppLauncher` refuses while the App Launcher is disabled in
settings, and shows only the Allowed Apps while Kiosk Mode is on), `homeLauncherStatus`, `acquireHomeRole` and `releaseHomeRole`
(the [Home Launcher](home-launcher.md) role: its live state, starting the
takeover, and giving the role back; `releaseHomeRole` is the recovery
lever and works with no kiosk screen up, as long as the process runs), `showNotification {message, title, duration, type, chime, scale, icon, chime_file, volume, image}` and
`dismissNotification {id}` (a message over whatever is on screen, the
screensaver included; `message` is read as Markdown and `title` takes
its inline part, see [esphome.md](esphome.md#formatting); `duration` is seconds, `0` stays until dismissed,
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

Connect to `/api/ws?token=<admin-token>`. Messages are JSON objects with a
`type`. Fleet tokens cannot use this endpoint. The server sends a `state`
snapshot on connection with device identity, battery, brightness,
`screenOn`, `screensaverActive`, `cameraView`, `nowPlayingShown`,
`intercomShown` and `currentUrl`. Subscribers to `events` also get
`{"type":"fullscreen-view","view":"nowPlaying","shown":true}` whenever the
Now Playing view (`nowPlaying`) or the intercom's roster or call screen
(`intercom`) comes up or goes.

Subscribe to the data this client needs. Each `subscribe` replaces the
previous topic set. An empty list unsubscribes from all live data. Clients
that never subscribe retain the original event and log feed.

```json
{"type":"subscribe","id":1,"topics":["settings","events","stats"]}
{"type":"command","id":2,"name":"getVolume","params":{}}
{"type":"settings","id":3,"values":{"screensaver.mode":"clock"}}
{"type":"get","id":4,"name":"info"}
```

Commands and settings writes return `{"type":"result","id":...}` with
`ok` and the command's `data` or `error`. Settings writes use the same
validation as `PATCH /api/settings` and return `rejected` and `errors`.
A `get` request answers with the same `data` the matching HTTP read
returns: `info` (`GET /api/info`), `settings` (`GET /api/settings`),
`console` (`GET /api/console`) and `logs` (`GET /api/logs`), so a
connected client needs no HTTP requests beyond the binary endpoints.
Replies may arrive out of order. Match them by `id`. A disconnected request
has an unknown outcome, so clients should read current state after
reconnecting instead of replaying writes.

| Topic | Server message |
| --- | --- |
| `settings` | `settings {snapshot, settings, subpageHints}`. The first subscription sends the current schema and values with `snapshot: true` and the second-level page hints. Later messages contain changed definitions only. Secrets stay masked as `__set__` or an empty string |
| `events` | `event {event, data}` for screen, screensaver, camera view, fleet and other public device events |
| `stats` | `stats {battery, charging, cpu, temp}` while subscribed |
| `logs` | `log {entry}` for app log entries |
| `console` | `console {level, message, time}` for the dashboard's JavaScript console |
| `brightness`, `lightlevel`, `micLevel`, `wakeword-state` | The matching message type. A `micLevel` subscription holds the microphone meter until it is removed or the connection closes |
| `ha`, `voice`, `media`, `media-players`, `sonos`, `plugins`, `plugin-tiles`, `plugin-settings`, `fleet`, `fleetsync`, `intercom`, `location`, `person`, `volume`, `audio`, `update`, `camera-snapshot`, `cameras`, `gestures` | `update {topic}` when the manager behind it reports a change. Refresh the relevant status command |
| `rtsp`, `bluetooth`, `bluetooth-nearby`, `service`, `home-role`, `artwork-cache`, `filter` | `update {topic, results}` when diagnostic values change. `results` contains status command responses keyed by command name |

Settings changes are batched for 100 milliseconds. Events with no
subscribers do no serialization. A settings write is not a status
change: each manager announces its own status when it moves (the
service when its reasons change, Home Assistant when its connection
does, the player when it starts, stops or connects), and the few
settings a status command reads straight from the store (`ha.url`,
`ha.token`, `sendspin.*`) map to that command's topic. Native
diagnostics without change callbacks share one observer across all
viewers and stop when the last viewer unsubscribes. A manager's
announcement re-samples them at once, and unchanged samples are not
transmitted, so a `bluetooth` or `service` update always carries the
results that moved. Binary camera and screenshot data stay on their
existing HTTP endpoints.

The admin opens the socket first and reads everything it needs to build
the page through it. It subscribes to visible panels, releases their
observers when the page is hidden and reads fresh state when the page
returns. Settings updates continue into a bounded queue while hidden and
render on return. A reconnect subscribes again to recover changes missed
during the outage, and a `state` snapshot that reports a different
`appVersion` or `buildNumber` than the page was loaded against (the app
restarted on an update) shows a notice and reloads the page.
While an established connection is away the page is covered by a
"Reconnecting" notice and resumes on its own when the socket returns.
`{"type":"ping"}` receives `{"type":"pong"}` for connection health checks.

## Remote UI

Routes use readable slugs such as `#camera/rtsp-onvif-streaming`. Older
bookmarks containing section titles still open and are replaced with the
canonical route. Plugin routes retain their unique plugin IDs.

The admin UI is a vanilla-JS single-page app: the page
at [app/remote-ui/index.html](../app/remote-ui/index.html)
holds the markup, and the stylesheet plus ES modules live under
[app/remote-ui/static/](../app/remote-ui/static/). Before Flutter
bundles them, `app/tool/build_remote_ui.mjs` minifies each file on its own
into `app/assets/remote-ui/`, which is generated and not tracked. Gradle
runs the script on every APK build and installs its one dependency,
esbuild, on the first run. Run `npm run build` from `app/` by hand before
`flutter test`, since the tests that serve the admin read the bundle. The
server serves the page at `/` and the files at `/static/<name>`, gzipped
for browsers that accept it and discovered from the asset manifest, so
adding a module is just adding the file. Tabs: Overview (a Needs attention card for an update
to install, a plugin update to review, a missing grant a switched-on feature needs, a lost Home
Assistant connection or a stopped wake word engine, hidden while there is
nothing; the screenshot with a badge while the panel is dark, on the
screensaver, showing Now Playing, the intercom or a camera view, taken again
a second after any of those changes, a Still or Live toggle, full size and
download; status tiles for Home Assistant, Voice Satellite, ESPHome, Media
Player, the service and updates, each opening its page, and CPU, memory and
temperature tiles with the last fifteen minutes as a stack of cells per
sample, colored by height band and labelled with the scale's ceiling and
floor (the device samples every fifteen seconds whether or not a page is
open, `getStatsHistory`, and the `stats` push carries `memFree` and
`memTotal` beside the CPU load and temperature); a Now playing card
while the media player has a track; quick controls, brightness and master
volume. The screen, screensaver and camera view controls are one tile each,
relabelled by the device's state, **Screen off** while the panel is lit and
**Screen on** once it is dark, **Start screensaver** or **Dismiss
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
