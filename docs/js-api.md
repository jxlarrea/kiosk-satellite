# Kiosk Satellite JavaScript API

Kiosk Satellite seamlessly injects the `window.kioskSatellite` object into every page at document start. This API is entirely **promise based** (meaning all methods return promises, even if they resolve immediately) and relies on **DOM `CustomEvent`s** for signals. This eliminates the need for string evaluation callback registration (like Fully Kiosk's `fully.bind()`).

The primary consumer of this API is Voice Satellite's kiosk abstraction (`src/kiosk/index.js`), which utilizes it as a third platform adapter alongside `'fullykiosk'` and `'kiosker'`.

## Detection

```javascript
if (window.kioskSatellite) { /* running inside Kiosk Satellite */ }
```

Because the object exists synchronously right from document start, a simple synchronous presence check is sufficient. `platform` and `version` are plain properties, meaning you don't need an asynchronous round trip to confirm presence (unlike Kiosker).

## Properties

| Property | Type | Description |
|---|---|---|
| `platform` | `'kiosksatellite'` | A constant discriminator identifying the platform. |
| `version` | `string` | The current app version (e.g., `'1.0.0'`). |
| `os` | `'android' \| 'ios'` | Identifies the host operating system. |

## Methods

Every method returns a `Promise`. To match the defensive coding style of Voice Satellite's wrapper, methods will resolve to `null` (for queries) or `false` (for commands) upon failure. They will never reject due to a platform error.

### Device / Screen

| Method | Returns | Description |
|---|---|---|
| `getDeviceInfo()` | `{uuid, name, model, os, osVersion, appVersion, battery, charging}` | Returns device identity and current status. |
| `getBrightness()` | `number` (0 to 1) | Returns the brightness level controlled by the Screen light entity: the panel itself, or the Maximum brightness setting if [adaptive brightness](screen.md#adaptive-brightness) is enabled. |
| `setBrightness(level)` | `boolean` | Sets the brightness using a `level` from 0 to 1. This adjusts Default brightness, or Maximum brightness if adaptive brightness is enabled. |
| `screenOn()` / `screenOff()` | `boolean` | Controls real display power. Turning the screen on wakes a sleeping panel. Turning it off requires the device admin permission (refer to remote API docs). |
| `isScreenOn()` | `boolean` | Returns the current screen power state. |

### Interactions

| Method | Returns | Description |
|---|---|---|
| `setInteractionActive(active, reason?)` | `boolean` | Brackets a page interaction: pass `true` when starting, and `false` when ending. While an interaction is active, all ambient app features (like the screensaver, dashboard view rotation, and return to home timers) pause. The optional `reason` parameter accepts strings like `voice`, `announcement`, `ask_question`, `start_conversation`, `timer`, or `media`. A `media` interaction specifically holds off only the screensaver, allowing dashboard rotation and the home timer to continue running during playback. Prefer using this over `pauseScreensaver` for interaction bracketing. |

### Screensaver

| Method | Returns | Description |
|---|---|---|
| `stopScreensaver()` | `boolean` | Performs a one shot dismiss of the screensaver (using Fully Kiosk semantics). |
| `pauseScreensaver(paused)` | `boolean` | Suppresses (`true`) or releases (`false`) the screensaver while the page is busy (using Kiosker semantics; the app supports both styles). Legacy note: this also feeds the generic interaction signal (acting exactly like `setInteractionActive` without a specific reason) so older Voice Satellite versions continue to successfully pause rotation. |
| `getScreensaverSuppressed()` | `boolean` | Always returns true. Because the app fully owns the screen, the web page must stand down its own internal screensaver. |

### Motion

| Method | Returns | Description |
|---|---|---|
| `getMotionEnabled()` | `boolean` | Returns whether camera motion detection is currently on. |
| `getFaceEnabled()` | `boolean` | Returns whether camera face detection is on. This reads false if "Dismiss on motion" takes precedence. |
| `getProximityEnabled()` | `boolean` | Returns whether proximity sensor detection is on. This always returns false on devices lacking the physical sensor. |

Motion events report via the `kiosksatellite:motion` event (detailed below). Faces report via `kiosksatellite:face`, and the proximity sensor reports via `kiosksatellite:proximity`. Enabling or configuring these detection methods is handled strictly in the app or remote admin settings, not by the web page.

### Wake Word

Wake word configuration is strictly **inherited from Voice Satellite**. It is never chosen directly in Kiosk Satellite. Voice Satellite supports three engines (microWakeWord, openWakeWord, and vsWakeWord). Each engine uses its own model catalog served by the VS integration as static paths under `<ha>/voice_satellite/models/` (providing a model file and JSON manifest). Voice Satellite pushes the active engine and models to the app, and the app automatically downloads what it needs from those URLs.

| Method | Returns | Description |
|---|---|---|
| `setWakeWordConfig({engine, models, stopModel, energyGate, nativePipeline})` | `{available, stopWordAvailable}` | Pushes the satellite's wake configuration. The `engine` string must be `'microWakeWord'`, `'openWakeWord'`, or `'vsWakeWord'`. `models` is an array mapping `[{id, wakeWord, manifestUrl}]` (handling up to two words, as VS routes them to separate pipeline slots). Setting `nativePipeline: true` tells the app the card understands the delegated pipeline transport, allowing the app's settings to indicate whether voice turns run natively. A card predating this feature sends nothing. The method resolves to `{available: false}` if the app cannot listen for the pushed config (due to lacking a native runner, denied microphone permissions, or failed model downloads). **Voice Satellite must then fall back to using its own browser engine**. Pushing the config again acts as a retry: it clears previous failures and takes the microphone back after a release. |
| `setWakeWordActive(active)` | `boolean` | Resumes (`true`) or suspends (`false`) native listening. The microphone remains open to ensure an instant resume between turns. **The page must call `setWakeWordActive(true)` when its voice session returns to an idle state** (see the handoff protocol). |
| `releaseWakeWord({reason})` | `boolean` | Executes a hard microphone off: it stops detecting **and completely closes the microphone** (unlike `setWakeWordActive(false)`). This is used when a satellite is muted, or when the browser forcibly takes detection back. The `reason` string (`'muted'` or `'browser'`) is shown to the user. Because both situations look identical from the app's side, **only Voice Satellite can specify which occurred**. If no reason is provided, the app simply reports "the microphone was released". Calling `setWakeWordConfig` takes the microphone back. |
| `getWakeWordState()` | Object | Returns the current state of the engine. See the object structure below. |

`getWakeWordState()` resolves the complete state object. This is the exact same shape used by the app's own settings screen and remote admin interface, ensuring they can never disagree about the device's status:

```javascript
{
  available: false,          // Indicates if the app is currently listening for the pushed config
  stopWordAvailable: false,  // Indicates if the stop classifier is running natively
  enabled: true,             // The app's own master switch status
  active: true,              // True if not suspended for a voice turn
  listening: false,
  engine: 'openWakeWord',
  engineLabel: 'openWakeWord',
  status: 'muted',           // Machine-readable status; see details below
  statusLabel: 'Muted in Voice Satellite. The microphone is closed until ...',
  canRetry: false,           // Indicates if retryWakeWord() would be effective
  needsAppSettings: false,   // True if the microphone is blocked and requires OS settings to fix
  released: true,
  releaseReason: 'muted',
  stopWord: 'Stop',
  nativePipeline: false,     // True if voice turns will run their transport natively (the card announced it via `nativePipeline: true` and the app accepted it)
  models: [{ id, wakeWord, manifestUrl, confidenceScale, cutoff }],
}
```

The `status` property will strictly be one of the following distinct states: `disabled`, `waiting`, `muted`, `browser`, `released`, `micBlocked`, `micDeclined`, `micLost`, `modelsUnavailable`, `failed`, `unavailable`, `listening`, or `suspended`. There is deliberately no catch all status. The `statusLabel` provides the human readable sentence to display. Never derive logic from `status` that the label already explicitly states.

### Sound

This handles the output half of the audio handoff. The web page passes a URL over, and the app plays it natively on the user's selected speaker (Settings > Screen & Audio > Speaker). This bypasses the strict WebView autoplay gate. Because the app fetches the URL through its own HTTP stack, a self signed Home Assistant certificate accepted by the user works perfectly here. Voice Satellite utilizes this for chimes when running in Kiosk Satellite; browser audio acts as the automatic fallback.

| Method | Returns | Description |
|---|---|---|
| `playSound(url, {volume, cache, stream})` | `{id}` or `false` | Plays the `url` natively. Sounds handed over by the page always play at the app's Assistant volume setting. The `volume` option is accepted for API compatibility but completely ignored, preventing the page from stacking extra attenuation on top of the app's fader. Setting `cache: true` saves the download so subsequent replays start instantly, which is ideal for fixed assets like chimes. Setting `stream: true` plays the audio through a loopback relay while it is still downloading. This is necessary for server generated sources like TTS; waiting for the whole file to download would artificially delay speech by the synthesis tail duration. Resolving `false` means the app refused the request (fetch failed, playback error, etc.), prompting Voice Satellite to fall back to browser audio. |
| `prefetchSound(url)` | `boolean` | Warms the cache so the very first `playSound` call for that `url` starts with zero fetch delay. |
| `stopSound(id)` | `boolean` | Stops a playing sound early. A `sound-ended` event will still fire. |
| `setSoundVolume(id, volume)` | `boolean` | Accepted for compatibility, but the `volume` value is strictly ignored. The app's Assistant volume fader dictates loudness and applies live to playing sounds automatically. |

### Pipeline Delegation

The app is capable of running the transport for a Voice Satellite assist pipeline turn natively. It subscribes to `voice_satellite/run_pipeline` on its own authenticated Home Assistant websocket and uploads raw microphone PCM as binary frames. This means that during a voice turn, no audio data crosses the JavaScript bridge in either direction. The web page retains control over everything else: the session policy, the visual overlay UI, and every single pipeline event (which the app forwards verbatim). The native audio methods perfectly mirror the page's own send, buffer, and mute choreography, ensuring the chime mute window, cross device deduplication, and seamless one shot buffering operate exactly as they normally would.

This delegation negotiates completely transparently, just like the wake word handoff. A page that knows these methods will use them; an older page will stick to the browser path, requiring zero configuration. If the app cannot take the turn (e.g., it is not configured for Home Assistant, the wake word engine is down, or the remote diagnostic kill switch `vs.native_pipeline` is flipped off), all methods will fail (resolving to `false`). Voice Satellite will then gracefully fall back to running the pipeline over the dashboard's own connection.

| Method | Returns | Description |
|---|---|---|
| `pipelineRun(params)` | `{runId}` or `false` | Subscribes a new run. The `params` object is the standard `voice_satellite/run_pipeline` payload (`entity_id`, `start_stage`, `end_stage`, `sample_rate`, plus optional parameters like `conversation_id`, `extra_system_prompt`, `wake_word_phrase`, `wake_word_slot`, `intent_input`, and `pipeline_id`). Subscription events surface as `kiosksatellite:pipeline` events. The synthetic `init` event's binary handler ID remains strictly in the app, as the app owns the upload transport. Only one run can happen at a time; launching a new run instantly displaces a stale one. |
| `pipelineStop(runId)` | `boolean` | Unsubscribes the run and immediately halts its audio upload. |
| `pipelineOpenMic()` | `{sampleRate}` or `false` | Opens the delegated capture. Microphone chunks flow into the app side buffer (handling pre-roll first, trimmed to the wake word's exact end). The app dispatches per-chunk speech levels back to the page for the reactive visual bar. Fails if the wake word engine is not actively running. |
| `pipelineCloseMic()` | `boolean` | Closes the delegated capture and drops all buffered audio. |
| `pipelineSetMuted(muted)` | `boolean` | While `true`, the app drops all microphone chunks on arrival without ever buffering them. The web page brackets its wake chime with this command so the chime cannot accidentally leak into STT. |
| `pipelineStartBuffering({reset})` | `boolean` | Starts capturing chunks into the buffer before actual sending starts (creating the seamless one shot window). Passing `reset` clears the buffer completely first. |
| `pipelineStopBuffering({clear})` | `boolean` | Stops capturing chunks. Passing `clear` aggressively drops whatever was already buffered. |
| `pipelineClearBuffer()` | `boolean` | Drops buffered audio directly. Useful for clearing out stale chime window audio just before a stream resumes. |
| `pipelineStartSending(runId)` | `boolean` | Begins the upload process, transmitting buffered chunks first, followed by live audio. The app handles waiting out the `init` event internally. |
| `pipelineStopSending()` | `boolean` | Pauses the active upload. The chime window utilizes this function. |

## Events

The API dispatches `CustomEvent`s directly on the `window` object:

| Event | `detail` Payload | When it fires |
|---|---|---|
| `kiosksatellite:wakeword` | `{model, phrase}` | The native engine detected the wake word. Native microphone capture is **already fully stopped** when this fires, meaning the page may open `getUserMedia` immediately if it needs to. |
| `kiosksatellite:motion` | `{}` | Camera motion was detected (rate-limited to 1 per second). |
| `kiosksatellite:face` | `{}` | Someone is looking directly at the kiosk. Triggers when a camera facing face reaches the configured Face sensitivity threshold while Dismiss on face is actively watching (rate-limited to 1 per second). |
| `kiosksatellite:proximity` | `{held}` | An object came close to the proximity sensor while Dismiss on proximity had it watching. Repeats every 5 seconds while the object remains close. `held` is `true` on repeat events and `false` on the initial approach. |
| `kiosksatellite:person` | `{held}` | Someone is visible to the device's own person sensor (currently supported on Meta Portals) while Dismiss on person is active. Repeats every 2 seconds while they remain in view. `held` is `true` on repeat events and `false` upon arrival. |
| `kiosksatellite:screenon` / `:screenoff` | `{}` | The screen power state changed. |
| `kiosksatellite:screensaverstart` / `:screensaverstop` | `{}` | The screensaver state changed. |
| `kiosksatellite:sound-started` | `{id}` | A `playSound` request actually began playing (audio is physically leaving the speaker). You should time stop word arming and UI state changes off this event, not off the `playSound` resolution. |
| `kiosksatellite:sound-level` | `{id, level}` | Provides the playback level of a playing sound (the mean absolute amplitude from 0 to 1, updating at most ~20 times per second, with near duplicate samples skipped). This allows a page visualizer to animate to audio it never actually touches. Note: This is best-effort and will be absent on devices lacking a functional hardware `Visualizer`. |
| `kiosksatellite:sound-ended` | `{id, error?}` | A `playSound` request naturally finished, failed (with the `error` string detailing why), or was manually stopped. This fires exactly once per sound. |
| `kiosksatellite:pipeline` | `{runId, message}` | Delivers one raw event verbatim from a delegated run's subscription. This includes the synthetic `init`, `run-start`, STT partials, `intent-progress` deltas, `tts-end`, and any errors. |
| `kiosksatellite:pipeline-closed` | `{runId, reason}` | The delegated run's transport died mid-run (meaning the app's websocket abruptly closed). Because subscriptions cannot be resumed, the page must restart the turn entirely, just as the page's own reconnect recovery logic would. |
| `kiosksatellite:pipeline-level` | `{level, levels?}` | Provides speech weighted microphone levels during a delegated turn, intended for the reactive visual bar. These are batched (~4 times a second). The `levels` array contains `[{o, v}]` where `o` is the millisecond offset from the batch's first entry. The page replays this locally so the bar animates smoothly at chunk cadence, sitting exactly one batch window behind live audio. A single `{level}` payload is processed immediately (used for the absolute zero a mute forces). The app uses the exact same band-split math the page applies to raw chunks, ensuring the visual bar renders identically. |

Example listener implementation:

```javascript
window.addEventListener('kiosksatellite:wakeword', (e) => {
  console.log('wake word', e.detail.phrase);
});
```

## Wake Word Handoff Protocol (Voice Satellite)

This protocol relies on two strict preconditions: 
1. Voice Satellite has successfully pushed its config via `setWakeWordConfig` and received `{available: true}` in response. 
2. The Voice Satellite `wake_word_detection` selector is set to `Disabled` (or a dedicated "Kiosk App" mode), ensuring Voice Satellite never opens the microphone for passive browser listening.

The handoff flow:
1. Kiosk Satellite natively owns the microphone. Native inference runs exclusively on the models it downloaded from the VS integration's model URLs.
2. Upon detection, the app **stops native capture first**, then dispatches the `kiosksatellite:wakeword` event.
3. The VS adapter catches this and routes it into `triggerWake(session)`. Voice Satellite then opens the browser WebView microphone for STT processing and runs the Assist pipeline starting from `start_stage: 'stt'`.
4. When the VS session finishes and returns to idle, Voice Satellite calls `kioskSatellite.setWakeWordActive(true)`. The app immediately re-opens the native microphone and resumes inference.

Microphone ownership is strictly sequential. The ordering of step 2 (stop before dispatch) and the explicit resume in step 4 form the core contract. If the page fails to resume (due to a crash or navigation event), the app handles self healing: a page unload or a configurable timeout (defaulting to 60 seconds without an active WebView microphone stream) will forcefully re-arm native listening.

## Transport (Internal)

Method calls travel over the `flutter_inappwebview` `callHandler` bridge using the format `window.flutter_inappwebview.callHandler('ksApi', {method, params})`. This native bridge returns promises with precise per-call correlation, eliminating the need for messy FIFO reply matching. The injected user script seamlessly wraps this bridge inside the `window.kioskSatellite` facade, ensuring pages never interact directly with the transport layer. The app dispatches events by evaluating `window.dispatchEvent(new CustomEvent(...))`.

## Voice Satellite Adapter Sketch

Here is a sketch of how the third platform adapter integrates into VS (`src/kiosk/index.js`):

```javascript
function ksPresent() {
  return typeof window !== 'undefined' && !!window.kioskSatellite
    && window.kioskSatellite.platform === 'kiosksatellite';
}

// platform() → 'kiosksatellite', name() → 'Kiosk Satellite'
// supportsMotion() → true (works across both OSes, unlike Kiosker)
// confirmAvailable() → !!(await window.kioskSatellite.getDeviceInfo())
// getBrightness()    → window.kioskSatellite.getBrightness()      // automatically returns 0..1
// setBrightness(n)   → window.kioskSatellite.setBrightness(n)
// stopScreensaver(reason)  → window.kioskSatellite.setInteractionActive(true, reason)
//                            (On older app builds: window.kioskSatellite.pauseScreensaver(true))
// releaseScreensaver(reason) → window.kioskSatellite.setInteractionActive(false, reason)
//                            (On older app builds: window.kioskSatellite.pauseScreensaver(false))
// bindMotion(handlerName) →
//   window.addEventListener('kiosksatellite:motion', () => window[handlerName]())
```

It requires an additional VS-side hook (sitting outside the current surface of the kiosk wrapper): it must listen for `kiosksatellite:wakeword` to trigger `triggerWake(session)`, and it must explicitly call `setWakeWordActive(true)` upon returning to `State.IDLE`.