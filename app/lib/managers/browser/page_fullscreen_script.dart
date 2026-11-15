/// Document-start script that skips the dashboard's requests to put the whole
/// page in fullscreen (issue #1461).
///
/// Android WebView shows an element in fullscreen by moving it into a view of
/// its own on the Activity's content view, above the FlutterView. Everything
/// Kiosk Satellite draws is under it from then on: the screensaver, the
/// drawer, the voice overlay. Wallpanel calls
/// `document.documentElement.requestFullscreen()` on a tap, so after the
/// first touch on such a dashboard the screensaver started under the page and
/// stayed hidden until the app restarted.
///
/// The kiosk already fills the screen, so a request for the root element,
/// the body or Home Assistant's own `home-assistant` element does nothing and
/// reports success. A video, a camera or any other element can still go
/// fullscreen. BrowserManager leaves that fullscreen when the kiosk needs the
/// screen (exitPageFullscreen).
///
/// Runs in every frame: an iframe's own root asking for fullscreen puts the
/// whole iframe there.
const pageFullscreenScript = '''
(function () {
  if (window.__ksPageFullscreenSkipped) return;
  window.__ksPageFullscreenSkipped = true;
  var proto = window.Element && Element.prototype;
  if (!proto) return;
  function wholePage(el) {
    return el === document.documentElement ||
      el === document.body ||
      (el && el.localName === 'home-assistant');
  }
  function wrap(name, promised) {
    var original = proto[name];
    if (typeof original !== 'function') return;
    proto[name] = function () {
      if (wholePage(this)) return promised ? Promise.resolve() : undefined;
      return original.apply(this, arguments);
    };
  }
  wrap('requestFullscreen', true);
  wrap('webkitRequestFullscreen', false);
  wrap('webkitRequestFullScreen', false);
})();
''';

/// Leaves the page's fullscreen, whichever element holds it.
const exitPageFullscreenJs = '''
(function () {
  if (document.fullscreenElement && document.exitFullscreen) {
    document.exitFullscreen().catch(function () {});
  } else if (document.webkitFullscreenElement && document.webkitExitFullscreen) {
    document.webkitExitFullscreen();
  }
})();
''';
