import 'dart:convert';

/// The page-side half of the secure context proxy.
///
/// Home Assistant generates absolute URLs at its own base URL (TTS audio,
/// announcement media, camera proxies). With the proxy on, the page lives on
/// the loopback origin instead, so those URLs are suddenly CROSS-origin:
/// they still download, but a media element that Voice Satellite taps with
/// Web Audio (its reactive bar uses MediaElementAudioSource) is required by
/// spec to output silence for cross-origin media without CORS approval,
/// which Home Assistant does not send. The audible symptom is announcements
/// and TTS "playing" two seconds of nothing.
///
/// The cure is to keep everything same-origin: any URL on the proxied
/// Home Assistant origin is rewritten onto the loopback origin the moment
/// page code uses it — media element `src` (property and attribute),
/// `<source>` elements, the `Audio()` constructor, and fetch/XHR, whose
/// cross-origin http requests would fail CORS preflight for the same
/// reason. Same bytes either way; the proxy forwards them verbatim.
String proxyMediaRewriteScript({
  required String targetOrigin,
  required String loopbackOrigin,
}) =>
    '''
(function () {
  var FROM = ${jsonEncode(targetOrigin)};
  var TO = ${jsonEncode(loopbackOrigin)};
  function remap(v) {
    return (typeof v === 'string' && v.indexOf(FROM) === 0)
      ? TO + v.slice(FROM.length)
      : v;
  }
  function patchSrc(proto) {
    var desc = Object.getOwnPropertyDescriptor(proto, 'src');
    if (!desc || !desc.set) return;
    Object.defineProperty(proto, 'src', {
      configurable: true,
      get: desc.get,
      set: function (v) { desc.set.call(this, remap(v)); },
    });
  }
  patchSrc(HTMLMediaElement.prototype);
  patchSrc(HTMLSourceElement.prototype);
  var setAttr = Element.prototype.setAttribute;
  Element.prototype.setAttribute = function (name, value) {
    if ((this instanceof HTMLMediaElement || this instanceof HTMLSourceElement)
        && typeof name === 'string' && name.toLowerCase() === 'src') {
      value = remap(value);
    }
    return setAttr.call(this, name, value);
  };
  var NativeAudio = window.Audio;
  var PatchedAudio = function (src) {
    return src === undefined ? new NativeAudio() : new NativeAudio(remap(src));
  };
  PatchedAudio.prototype = NativeAudio.prototype;
  window.Audio = PatchedAudio;
  var nativeFetch = window.fetch;
  window.fetch = function (input, init) {
    if (typeof input === 'string') {
      input = remap(input);
    } else if (input && typeof input.url === 'string'
        && input.url.indexOf(FROM) === 0) {
      input = new Request(remap(input.url), input);
    }
    return nativeFetch.call(this, input, init);
  };
  var nativeOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
    var args = Array.prototype.slice.call(arguments);
    args[1] = remap(url);
    return nativeOpen.apply(this, args);
  };
})();
''';
