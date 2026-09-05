/// Releases supported Home Assistant dashboard camera players while covered.
/// Rendering an empty Lit template disconnects the players through their own
/// lifecycle, closing WebRTC and HLS connections. Restoring the template creates
/// fresh players. The page's visibility, microphone and other media stay live.
const dashboardCameraScript = r'''
(function () {
  if (window.__ksDashboardCameras || !window.customElements) return;
  var paused = false;
  var ready = false;
  var watched = new WeakSet();
  var patched = new WeakSet();

  function refresh(root) {
    root.querySelectorAll('*').forEach(function (el) {
      if (el.localName === 'ha-camera-stream' &&
          typeof el.requestUpdate === 'function') el.requestUpdate();
      if (el.shadowRoot) refresh(el.shadowRoot);
    });
  }

  window.__ksDashboardCameras = {
    setPaused: function (value) {
      watchRegistry();
      value = !!value;
      if (paused === value) return;
      paused = value;
      if (ready) refresh(document);
    },
    get paused() { return paused; },
    get supported() { return ready; }
  };

  function install(ctor) {
    var proto = ctor && ctor.prototype;
    if (!proto || patched.has(proto)) return;
    var render = proto.render;
    if (typeof render !== 'function') return;
    patched.add(proto);
    proto.render = function () {
      // Keep intentional camera audio playing. Only HA's camera component
      // in this dashboard document is affected, including newly added streams.
      if (paused && this.muted === true && this.isConnected &&
          document.querySelector('home-assistant')) {
        // Removing an MJPEG image alone can leave its HTTP request running.
        if (this.shadowRoot) {
          this.shadowRoot.querySelectorAll('img').forEach(function (img) {
            img.removeAttribute('src');
          });
        }
        return null;
      }
      return render.apply(this, arguments);
    };
    ready = true;
    if (paused) refresh(document);
  }

  function watchRegistry() {
    var registry = window.customElements;
    if (!registry || watched.has(registry)) return;
    watched.add(registry);
    registry.whenDefined('ha-camera-stream').then(function (ctor) {
      install(ctor || registry.get('ha-camera-stream'));
    });
  }

  // HA can replace the native registry with its scoped registry polyfill
  // after document-start injection. Its definitions never resolve promises
  // on the old registry, so subscribe again once the frontend has loaded.
  watchRegistry();
  document.addEventListener('DOMContentLoaded', watchRegistry, { once: true });
  window.addEventListener('load', watchRegistry, { once: true });
})();
''';

String pauseDashboardCamerasJs(bool paused) =>
    'window.__ksDashboardCameras && '
    'window.__ksDashboardCameras.setPaused($paused);';
