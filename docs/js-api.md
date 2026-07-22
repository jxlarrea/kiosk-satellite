# Kiosk Satellite JavaScript API

Kiosk Satellite injects `window.kioskSatellite` into every page at document
start. It is a **promise-based** API (all methods return promises, even ones
that resolve immediately) with **DOM `CustomEvent`s** for signals, with no
string-eval callback registration like Fully Kiosk's `fully.bind()`.

Primary consumer: Voice Satellite's kiosk abstraction
(`src/kiosk/index.js`), which gains a third platform adapter alongside
`'fullykiosk'` and `'kiosker'`.

## Detection

```js
if (window.kioskSatellite) { /* running inside Kiosk Satellite */ }
```

The object exists synchronously from document start. `platform` and `version`
are plain properties so a synchronous presence check is enough (unlike
Kiosker, which needs an async round-trip to confirm).

## Properties

| Property | Type | Description |
|---|---|---|
| `platform` | `'kiosksatellite'` | Constant discriminator |
| `version` | `string` | App version, e.g. `'1.0.0'` |
| `os` | `'android' \| 'ios'` | Host OS |

## Methods

All methods return a `Promise`. On failure they resolve `null` (queries) or
`false` (commands); they never reject for platform errors, matching the
defensive style of Voice Satellite's kiosk wrapper.

### Device / screen

| Method | Returns | Description |
|---|---|---|
| `getDeviceInfo()` | `{uuid, name, model, os, osVersion, appVersion, battery, charging}` | Device identity + status |
| `getBrightness()` | `number` 0..1 | Current hardware backlight, normalized |
| `setBrightness(level)` | `boolean` | Set backlight, `level` 0..1 |
| `screenOn()` / `screenOff()` | `boolean` | Real display power: on wakes a sleeping panel; off needs the device admin permission (see remote API docs) |
| `isScreenOn()` | `boolean` | Current screen power state |

### Interactions

| Method | Returns | Description |
|---|---|---|
| `setInteractionActive(active, reason?)` | `boolean` | Bracket a page interaction: `true` on the way in, `false` on the way out. While one is active, every ambient app feature stands down (the screensaver, dashboard view rotation, and anything added later). `reason` is an optional string describing the kind: `voice`, `announcement`, `ask_question`, `start_conversation`, `timer`, `media` — used for logging today, per-kind behavior later. Prefer this over `pauseScreensaver` for interaction bracketing |

### Screensaver

| Method | Returns | Description |
|---|---|---|
| `stopScreensaver()` | `boolean` | One-shot dismiss (Fully Kiosk semantics) |
| `pauseScreensaver(paused)` | `boolean` | Suppress (`true`) / release (`false`) the screensaver while the page is busy (Kiosker semantics, both styles supported). Legacy note: this also feeds the interaction signal (like `setInteractionActive` without a reason) so older Voice Satellite versions keep pausing rotation |
| `getScreensaverSuppressed()` | `boolean` | True when the page should stand down its own screensaver: the app's screensaver is enabled and set to take precedence. Re-negotiated per page load (the app reloads the page when the answer changes) |

### Motion

| Method | Returns | Description |
|---|---|---|
| `getMotionEnabled()` | `boolean` | Whether camera motion detection is on |

Motion is reported via the `kiosksatellite:motion` event (below). Enabling or
configuring detection is an app/remote-admin setting, not a page decision.

### Wake word

Wake-word configuration is **inherited from Voice Satellite**, never chosen
in Kiosk Satellite. VS supports three engines (microWakeWord, openWakeWord,
and vsWakeWord), each with its own model catalog served by the VS
integration as static paths under `<ha>/voice_satellite/models/` (model file
+ JSON manifest). Voice Satellite pushes the active engine + models to the
app; the app downloads what it needs from those URLs.

| Method | Returns | Description |
|---|---|---|
| `setWakeWordConfig({engine, models, stopModel, energyGate})` | `{available, stopWordAvailable}` | Push the satellite's wake config: `engine` is `'microWakeWord' \| 'openWakeWord' \| 'vsWakeWord'`, `models` is `[{id, wakeWord, manifestUrl}]` (up to two; VS routes two wake words to separate pipeline slots). Resolves `{available: false}` when the app is not listening for that config (no native runner, but also a refused microphone or models it could not download), and **Voice Satellite must then keep using its browser engine**. Pushing again is also the retry: it clears any previous failure and takes the mic back after a release. |
| `setWakeWordActive(active)` | `boolean` | Resume (`true`) or suspend (`false`) native listening. The mic stays open, for an instant resume between turns. **The page must call `setWakeWordActive(true)` when its voice session returns to idle**; see handoff protocol. |
| `releaseWakeWord({reason})` | `boolean` | Hard mic-off: stop detecting **and close the microphone**, unlike `setWakeWordActive(false)`. For a muted satellite, or the browser taking detection back. `reason` is `'muted' \| 'browser'` and is shown to the user; both look identical from the app's side, so **only Voice Satellite can say which**, and an unexplained release can only be reported as "the microphone was released". `setWakeWordConfig` takes it back. |
| `getWakeWordState()` | see below | Current engine state |

`getWakeWordState()` resolves the whole state, which is also what the app's own
settings screen and its remote admin render: one shape, so the two cannot
disagree about the same device:

```js
{
  available: false,          // are we listening for the pushed config, right now
  stopWordAvailable: false,  // is the stop classifier running natively
  enabled: true,             // the app's own master switch
  active: true,              // not suspended for a turn
  listening: false,
  engine: 'openWakeWord',
  engineLabel: 'openWakeWord',
  status: 'muted',           // machine-readable; see below
  statusLabel: 'Muted in Voice Satellite. The microphone is closed until …',
  canRetry: false,           // would retryWakeWord() mean anything
  needsAppSettings: false,   // mic blocked: only the OS settings can undo it
  released: true,
  releaseReason: 'muted',
  stopWord: 'Stop',
  models: [{ id, wakeWord, manifestUrl, confidenceScale, cutoff }],
}
```

`status` is one of `disabled`, `waiting`, `muted`, `browser`, `released`,
`micBlocked`, `micDeclined`, `micLost`, `modelsUnavailable`, `failed`,
`unavailable`, `listening`, `suspended`, one per distinct way of being in that
state, deliberately with no catch-all. `statusLabel` is the sentence to show;
derive nothing from `status` that the label already says.

### Sound

The output half of the audio handoff: the page hands a URL over and the app
plays it natively — on the user's selected speaker (Settings → Voice
Satellite → Speaker), with no WebView autoplay gate. The app fetches the URL
itself through its own HTTP stack, so a self-signed HA certificate the user
accepted works here too. Voice Satellite uses this for its chimes when
running in Kiosk Satellite; browser audio remains the fallback.

| Method | Returns | Description |
|---|---|---|
| `playSound(url, {volume, cache, stream})` | `{id}` or `false` | Play `url` natively. `volume` is 0..1 relative to media volume (default 1). `cache: true` keeps the download so replays start instantly — right for fixed assets (chimes). `stream: true` plays while downloading, through a loopback relay, for sources still being generated server-side (TTS) — waiting for the whole file would delay speech by the synthesis tail. `false` means the app refused (fetch failed, playback error): fall back to browser audio. |
| `prefetchSound(url)` | `boolean` | Warm the cache so the first `playSound` of `url` starts with zero fetch delay. |
| `stopSound(id)` | `boolean` | Stop a playing sound early. A `sound-ended` event still fires. |

## Events

Dispatched on `window` as `CustomEvent`s:

| Event | `detail` | When |
|---|---|---|
| `kiosksatellite:wakeword` | `{model, phrase}` | Native engine detected the wake word. Native mic capture is **already stopped** when this fires, so the page may open `getUserMedia` immediately. |
| `kiosksatellite:motion` | `{}` | Camera motion detected (rate-limited to 1/s) |
| `kiosksatellite:screenon` / `:screenoff` | `{}` | Screen power changed |
| `kiosksatellite:screensaverstart` / `:screensaverstop` | `{}` | Screensaver state changed |
| `kiosksatellite:sound-started` | `{id}` | A `playSound` sound actually began playing (audio is leaving the speaker). Time stop-word arming and speaking UI off this, not off the `playSound` resolve. |
| `kiosksatellite:sound-ended` | `{id, error?}` | A `playSound` sound finished, failed (`error` says how), or was stopped. Exactly one per sound. |

```js
window.addEventListener('kiosksatellite:wakeword', (e) => {
  console.log('wake word', e.detail.phrase);
});
```

## Wake-word handoff protocol (Voice Satellite)

Preconditions: Voice Satellite has pushed its config via `setWakeWordConfig`
and received `{available: true}`, and the Voice Satellite
`wake_word_detection` select is `Disabled` (or a dedicated "Kiosk App" mode),
so Voice Satellite never opens the mic for passive listening.

1. Kiosk Satellite owns the mic; native inference runs on the models it
   downloaded from the VS integration's model URLs.
2. On detection the app **stops native capture first**, then dispatches
   `kiosksatellite:wakeword`.
3. The VS adapter routes this into `triggerWake(session)` and Voice Satellite
   opens the WebView mic for STT and runs the Assist pipeline from
   `start_stage: 'stt'`.
4. When the VS session returns to idle, Voice Satellite calls
   `kioskSatellite.setWakeWordActive(true)`; the app re-opens the mic and
   resumes inference.

Mic ownership is strictly sequential; step 2's stop-before-dispatch ordering
and step 4's explicit resume are the contract. If the page never resumes
(crash/navigation), the app self-heals: a page unload or a configurable
timeout (default 60 s without an active WebView mic stream) re-arms listening.

## Transport (internal)

Method calls go over `flutter_inappwebview`'s `callHandler` bridge
(`window.flutter_inappwebview.callHandler('ksApi', {method, params})`), which
natively returns promises with per-call correlation, with no FIFO reply matching.
The injected user script wraps this in the `window.kioskSatellite` facade so
pages never touch the transport. Events are dispatched by the app evaluating
`window.dispatchEvent(new CustomEvent(...))`.

## Voice Satellite adapter sketch

Third platform in VS `src/kiosk/index.js`:

```js
function ksPresent() {
  return typeof window !== 'undefined' && !!window.kioskSatellite
    && window.kioskSatellite.platform === 'kiosksatellite';
}

// platform() → 'kiosksatellite', name() → 'Kiosk Satellite'
// supportsMotion() → true (both OSes, unlike Kiosker)
// confirmAvailable() → !!(await window.kioskSatellite.getDeviceInfo())
// getBrightness()    → window.kioskSatellite.getBrightness()      // already 0..1
// setBrightness(n)   → window.kioskSatellite.setBrightness(n)
// stopScreensaver(reason)  → window.kioskSatellite.setInteractionActive(true, reason)
//                            (older app: window.kioskSatellite.pauseScreensaver(true))
// releaseScreensaver(reason) → window.kioskSatellite.setInteractionActive(false, reason)
//                            (older app: window.kioskSatellite.pauseScreensaver(false))
// bindMotion(handlerName) →
//   window.addEventListener('kiosksatellite:motion', () => window[handlerName]())
```

Plus a new VS-side hook (outside the kiosk wrapper's current surface):
listen for `kiosksatellite:wakeword` → `triggerWake(session)`, and call
`setWakeWordActive(true)` on return to `State.IDLE`.
