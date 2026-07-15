# Kiosk Satellite — JavaScript API

Kiosk Satellite injects `window.kioskSatellite` into every page at document
start. It is a **promise-based** API (all methods return promises, even ones
that resolve immediately) with **DOM `CustomEvent`s** for signals — no
string-eval callback registration like Fully Kiosk's `fully.bind()`.

Primary consumer: the Voice Satellite card's kiosk abstraction
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
`false` (commands) — they never reject for platform errors, matching the
defensive style of Voice Satellite's kiosk wrapper.

### Device / screen

| Method | Returns | Description |
|---|---|---|
| `getDeviceInfo()` | `{uuid, name, model, os, osVersion, appVersion, battery, charging}` | Device identity + status |
| `getBrightness()` | `number` 0..1 | Current hardware backlight, normalized |
| `setBrightness(level)` | `boolean` | Set backlight, `level` 0..1 |
| `screenOn()` / `screenOff()` | `boolean` | Force screen power state |
| `isScreenOn()` | `boolean` | Current screen power state |

### Screensaver

| Method | Returns | Description |
|---|---|---|
| `stopScreensaver()` | `boolean` | One-shot dismiss (Fully Kiosk semantics) |
| `pauseScreensaver(paused)` | `boolean` | Suppress (`true`) / release (`false`) the screensaver while the page is busy (Kiosker semantics — both styles supported) |

### Motion

| Method | Returns | Description |
|---|---|---|
| `getMotionEnabled()` | `boolean` | Whether camera motion detection is on |

Motion is reported via the `kiosksatellite:motion` event (below). Enabling or
configuring detection is an app/remote-admin setting, not a page decision.

### Wake word

| Method | Returns | Description |
|---|---|---|
| `setWakeWordActive(active)` | `boolean` | Resume (`true`) or suspend (`false`) native wake-word listening. **The page must call `setWakeWordActive(true)` when its voice session returns to idle** — see handoff protocol. |
| `getWakeWordState()` | `{available, active, listening, model}` | Current engine state |
| `getWakeWordModels()` | `[{id, wakeWord, engine}]` | Installed models |

## Events

Dispatched on `window` as `CustomEvent`s:

| Event | `detail` | When |
|---|---|---|
| `kiosksatellite:wakeword` | `{model, phrase}` | Native engine detected the wake word. Native mic capture is **already stopped** when this fires — the page may open `getUserMedia` immediately. |
| `kiosksatellite:motion` | `{}` | Camera motion detected (rate-limited to 1/s) |
| `kiosksatellite:screenon` / `:screenoff` | `{}` | Screen power changed |
| `kiosksatellite:screensaverstart` / `:screensaverstop` | `{}` | Screensaver state changed |

```js
window.addEventListener('kiosksatellite:wakeword', (e) => {
  console.log('wake word', e.detail.phrase);
});
```

## Wake-word handoff protocol (Voice Satellite)

Precondition: the Voice Satellite `wake_word_detection` select is `Disabled`,
so the card never opens the mic for passive listening.

1. Kiosk Satellite owns the mic; TFLite microWakeWord inference runs natively.
2. On detection the app **stops native capture first**, then dispatches
   `kiosksatellite:wakeword`.
3. The VS adapter routes this into `triggerWake(session)` — the card opens the
   WebView mic for STT and runs the Assist pipeline from `start_stage: 'stt'`.
4. When the VS session returns to idle, the card calls
   `kioskSatellite.setWakeWordActive(true)`; the app re-opens the mic and
   resumes inference.

Mic ownership is strictly sequential; step 2's stop-before-dispatch ordering
and step 4's explicit resume are the contract. If the page never resumes
(crash/navigation), the app self-heals: a page unload or a configurable
timeout (default 60 s without an active WebView mic stream) re-arms listening.

## Transport (internal)

Method calls go over `flutter_inappwebview`'s `callHandler` bridge
(`window.flutter_inappwebview.callHandler('ksApi', {method, params})`), which
natively returns promises with per-call correlation — no FIFO reply matching.
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
// stopScreensaver()  → window.kioskSatellite.stopScreensaver()
// releaseScreensaver() → window.kioskSatellite.pauseScreensaver(false)
// bindMotion(handlerName) →
//   window.addEventListener('kiosksatellite:motion', () => window[handlerName]())
```

Plus a new VS-side hook (outside the kiosk wrapper's current surface):
listen for `kiosksatellite:wakeword` → `triggerWake(session)`, and call
`setWakeWordActive(true)` on return to `State.IDLE`.
