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

    getMotionEnabled: function () { return call('getMotionEnabled'); },

    setWakeWordConfig: function (config) { return call('setWakeWordConfig', config); },
    setWakeWordActive: function (active) { return call('setWakeWordActive', { active: !!active }); },
    getWakeWordState: function () { return call('getWakeWordState'); }
  };
})();
''';
