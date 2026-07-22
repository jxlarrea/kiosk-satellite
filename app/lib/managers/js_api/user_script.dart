/// The `window.kioskSatellite` facade injected into every page at document
/// start. Pages never touch the flutter_inappwebview transport directly.
///
/// Contract: docs/js-api.md. All methods return promises; queries resolve
/// null on failure, commands resolve false — never reject.
String buildKioskSatelliteScript({required String version, required String os}) =>
    '''
(function () {
  if (window.kioskSatellite) return;

  function call(method, params) {
    try {
      return window.flutter_inappwebview
        .callHandler('ksApi', method, params || {})
        .catch(function () { return null; });
    } catch (e) {
      return Promise.resolve(null);
    }
  }

  window.kioskSatellite = {
    platform: 'kiosksatellite',
    version: '$version',
    os: '$os',

    getDeviceInfo: function () { return call('getDeviceInfo'); },
    getBrightness: function () { return call('getBrightness'); },
    setBrightness: function (level) { return call('setBrightness', { level: level }); },
    screenOn: function () { return call('screenOn'); },
    screenOff: function () { return call('screenOff'); },
    isScreenOn: function () { return call('isScreenOn'); },

    stopScreensaver: function () { return call('stopScreensaver'); },
    pauseScreensaver: function (paused) { return call('pauseScreensaver', { paused: !!paused }); },

    // The page is running an interaction (a voice turn, a ringing timer
    // alert, media playback): ambient features (view rotation, the
    // screensaver) stand down until the matching false. This is the honest
    // name for what pauseScreensaver was being used for; prefer it.
    // The optional reason ('voice', 'announcement', 'ask_question',
    // 'start_conversation', 'timer', 'media') lets the app log and, later,
    // specialize per interaction kind.
    setInteractionActive: function (active, reason) {
      return call('setInteractionActive', {
        active: !!active,
        reason: reason == null ? '' : String(reason),
      });
    },

    // True when the page should stand down its own screensaver: the app's
    // screensaver is enabled and set to take precedence. Re-negotiated per
    // page load (the app reloads the page when the answer changes).
    getScreensaverSuppressed: function () { return call('getScreensaverSuppressed'); },

    // Bring the app to the foreground — for a server-initiated interaction that
    // arrives while the app is behind another one. Resolves true if it came (or
    // was already) forward, false if it could not (no overlay grant).
    bringToFront: function () { return call('bringToFront'); },

    getMotionEnabled: function () { return call('getMotionEnabled'); },

    setWakeWordConfig: function (config) { return call('setWakeWordConfig', config); },
    setWakeWordActive: function (active) { return call('setWakeWordActive', { active: !!active }); },

    // Hard mic-off: stops detection and closes the microphone (mute, or the
    // page switching to an engine we do not run natively). setWakeWordConfig
    // takes it back. Pass {reason: 'muted' | 'browser'} — both look identical
    // from here, and the app shows this state to a person.
    releaseWakeWord: function (opts) {
      return call('releaseWakeWord', { reason: (opts && opts.reason) || null });
    },
    getWakeWordState: function () { return call('getWakeWordState'); },

    // Stop word: armed by the page only while something interruptible is
    // playing. Fires as a 'kiosksatellite:stopword' event.
    setStopWordActive: function (active) { return call('setStopWordActive', { active: !!active }); },

    // Audio delegation: the app owns the mic, so a page can stream captured
    // audio from us instead of calling getUserMedia. Chunks arrive as
    // 'kiosksatellite:audio' events ({pcm: base64 PCM16 LE, sampleRate}),
    // beginning with a short pre-roll so speech right after a wake word is
    // not lost.
    startAudioStream: function () { return call('startAudioStream'); },
    stopAudioStream: function () { return call('stopAudioStream'); },

    // Sound delegation, the output half of the audio handoff: the app plays
    // the URL natively, on the user's selected speaker, with no autoplay
    // gate. Resolves {id} (or false); a 'kiosksatellite:sound-ended' event
    // ({id, error?}) follows when it finishes. opts: {volume: 0..1,
    // cache: bool} - cache keeps the download so replays start instantly
    // (chimes yes, one-shot TTS no).
    playSound: function (url, opts) {
      return call('playSound', Object.assign({ url: url }, opts || {}));
    },
    prefetchSound: function (url) { return call('prefetchSound', { url: url }); },
    stopSound: function (id) { return call('stopSound', { id: id }); }
  };
})();
''';
