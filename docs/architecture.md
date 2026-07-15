# Kiosk Satellite — Architecture

Kiosk Satellite is a cross-platform (Android/iOS) kiosk browser built as a modern
alternative to Fully Kiosk and a companion app for
[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration).

Three pillars:

1. **Kiosk browser** — a locked-down WebView with the classic Fully Kiosk feature
   set (start URL, keep awake, screensaver, brightness control, motion detection,
   crash recovery, boot start) behind a modern UI. Fully standalone: pillars 2
   and 3 are optional layers, and every generic kiosk feature works without them.
2. **Home Assistant native integration (optional)** — long-lived-token connection,
   dashboard picker, HA kiosk mode (hide header/sidebar), MQTT discovery entities,
   event-driven navigation.
3. **Voice Satellite companion** — native wake-word detection (microWakeWord via
   TFLite) handed off to the Voice Satellite card through a JavaScript API, plus
   screen dimming and motion signals. See [js-api.md](js-api.md).

## Repository layout

```
kiosk-satellite/
├── app/                 # Flutter application
│   └── lib/
│       ├── core/        # DI container, event bus, logging, lifecycle
│       ├── managers/    # one folder per manager (see below)
│       └── ui/          # theme, setup wizard, settings, overlays
├── remote-ui/           # remote-admin SPA, built and bundled into app assets
└── docs/                # this file, js-api.md, remote-api.md
```

## Design rules

- **One manager per folder.** A manager owns exactly one domain and exposes a
  narrow public class. No manager imports another manager directly.
- **Communication via the event bus and the command registry** (both in
  `core/`). Managers publish typed events (`ScreenDimmed`, `MotionDetected`,
  `WakeWordDetected`, …) and subscribe to what they need.
- **Single command surface.** Every user-facing capability is registered as a
  `Command` in the `CommandRegistry` with a name, parameter schema, and handler.
  The JS API bridge, the remote-management REST/WS API, MQTT command topics, and
  the local settings UI are all thin protocol adapters over this registry. A
  feature is never implemented twice for two surfaces; if it exists, it is
  remotely administrable by construction.
- **Settings are declarative.** Every setting is declared once (key, type,
  default, description) in the settings manager; the settings UI and the remote
  admin UI render from the same declarations.

## Managers

| Manager | Folder | Owns |
|---|---|---|
| Browser | `managers/browser/` | WebView lifecycle, navigation, start URL, error/crash recovery, auto-reload, page-load state |
| JS API | `managers/js_api/` | `window.kioskSatellite` bridge: handler registration, event dispatch into the page, user-script injection |
| Kiosk | `managers/kiosk/` | Lockdown: Android lock task / screen pinning, iOS Guided Access guidance, boot start, single-app enforcement, exit PIN |
| Screen | `managers/screen/` | Brightness get/set, keep-awake, screen on/off, dim schedules |
| Screensaver | `managers/screensaver/` | Idle tracking, screensaver modes (black / dim / photo slideshow / alternate dashboard), dismiss policy |
| Motion | `managers/motion/` | Camera frame-diff motion detection, sensitivity, `MotionDetected` events |
| Wake word | `managers/wake_word/` | Mic capture, microWakeWord TFLite inference, model download/management, mic-ownership handoff with the WebView |
| Home Assistant | `managers/home_assistant/` | Token storage, WS/REST client, dashboard list, kiosk-mode injection strategy, MQTT discovery publishing, HA event subscriptions |
| Remote | `managers/remote/` | Embedded HTTP server: REST + WebSocket, auth (PIN/password, rate-limited), serves the remote-ui SPA, mDNS advertisement |
| Settings | `managers/settings/` | Declarative setting definitions, persistence, import/export, change notifications |
| Device | `managers/device/` | Battery, network info, device identity/UUID, platform info |

## Core

- `core/event_bus.dart` — typed publish/subscribe. Events are plain immutable
  classes in `core/events.dart`.
- `core/command_registry.dart` — named commands with JSON-serializable params
  and results; the single administration surface.
- `core/manager.dart` — `Manager` base class: `init()` / `dispose()`, access to
  bus, registry, and settings.
- `core/logging.dart` — ring-buffer logger; the remote UI tails it over WS.

## Startup sequence

1. `main()` builds the DI container, constructs managers (order-independent —
   construction does no work).
2. `init()` runs in dependency-safe order: settings → device → screen → browser
   → js_api → kiosk → screensaver → motion → home_assistant → wake_word → remote.
3. First-run (no start URL configured) shows the setup wizard instead of the
   WebView.

## Wake-word handoff (Voice Satellite)

The mic is a single exclusive resource shared between native wake-word capture
and the WebView's `getUserMedia` STT capture. Ownership is strictly sequential
and driven by an explicit handshake — never inferred:

```
[idle]   wake_word manager owns mic, runs TFLite inference
   │ detection
   ▼
app stops native capture ──► JS event 'kiosksatellite:wakeword' ──► VS card
                                                                    (mode: Disabled)
                                                                    triggerWake()
                                                                    WebView mic → STT
   ▲                                                                     │ session idle
   └── setWakeWordActive(true) ◄─────────────────────────────────────────┘
```

Voice Satellite's `wake_word_detection` select must be set to `Disabled` so the
card never opens the mic for passive listening. The card resumes native
listening by calling `kioskSatellite.setWakeWordActive(true)` when its session
returns to idle.

Because wake listening is native, it keeps working with the screen off or while
the screensaver/another dashboard is displayed — which the browser-based
engines cannot do.

## Platform caveats (accepted, documented)

- **iOS lockdown** requires Guided Access or supervised Single App Mode; the
  kiosk manager detects and walks the user through enabling it.
- **iOS remote server** runs only while the app is foreground — always true in
  kiosk use.
- **HA kiosk mode** (`ha.kiosk_mode`, default **off** — the normal HA UI shows
  until you opt in): `auto` probes for the `kiosk-mode` HACS plugin and, when
  present, appends `?kiosk` and defers to it entirely (it tracks HA's shadow-DOM
  changes across releases); otherwise it falls back to our own CSS injection
  (`plugin` and `css` force either path). The CSS fallback is version-fragile
  and isolated in `managers/home_assistant/kiosk_mode.dart`. Kiosk mode is
  applied live — injected per navigation and re-applied on setting change — so
  toggling it never needs an app restart.
- **WebView media permissions** follow Fully Kiosk's model: the "Web Content"
  settings (microphone, camera, geolocation, pop-ups, autoplay) gate what
  `onPermissionRequest` grants. When a toggle is enabled or a page first asks,
  the standard OS runtime permission dialog appears and the user taps Allow
  once — the normal App Store flow, no developer tooling required. We never
  request permissions the user hasn't enabled.
  - **iOS**: usage-description strings are set in `ios/Runner/Info.plist`
    (mic/camera/location) — mandatory or the app crashes on request and Apple
    rejects it. `ios/Podfile` compiles in only those three permission handlers.
  - **Android**: `RECORD_AUDIO`, `CAMERA`, and location are declared in the
    manifest; the runtime grant is requested on demand.
  - *Optional, enterprise only*: fleets can pre-grant via MDM or
    `adb shell pm grant … RECORD_AUDIO` for zero-prompt provisioning. This is
    never part of the consumer flow.
- **Remote-admin auth** uses stateless HMAC-signed tokens (7-day expiry) keyed
  by a secret persisted in settings, so sessions survive app restarts. An
  earlier in-memory token store signed the remote UI out on every relaunch.
