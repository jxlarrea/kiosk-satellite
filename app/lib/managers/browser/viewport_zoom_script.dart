/// A zoom level as a viewport-meta scale — what desktop browser zoom
/// actually is — NOT CSS zoom on the document root. CSS zoom breaks
/// imperatively positioned overlays (issue #259): Home Assistant's menus
/// and dialogs measure their anchor with getBoundingClientRect(), which
/// under standardized CSS zoom returns visually scaled coordinates, then
/// write them back as px that the zoomed root scales AGAIN — landing every
/// dropdown at anchor-times-zoom, off screen at 1.35x on a small tablet.
///
/// A viewport scale has no such mismatch: with `initial-scale=z` and no
/// `width`, the layout viewport becomes visible-width/z (the spec's
/// extend-to-zoom width), rendered scaled to fill the screen — one
/// consistent CSS px space, recomputed by Chromium on rotation. Chromium
/// only honors initial-scale at navigation though; a live change applies
/// through the min/max clamp, so both are pinned to z. With pinch to zoom
/// enabled the clamp is relaxed a frame later — the forced scale sticks,
/// pinching stays free.
///
/// The page's own meta (HA declares one) is saved in data-ks-orig and its
/// non-scale keys — viewport-fit=cover above all, edge-to-edge depends on
/// it — are carried into the rewritten content. Idempotent and reversible:
/// 1x restores the original meta, or removes one this script created.
///
/// Shared by the dashboard WebView (the Browser zoom level) and the website
/// screensaver (its own zoom level): the rewritten meta dies with each
/// document, so both run it after every navigation and again on a live
/// change of the setting.
String viewportZoomJs({required num zoom, required bool pinch}) {
  return '''
    (function () {
      var z = $zoom;
      var ms = document.querySelectorAll('meta[name=viewport]');
      var m = ms.length ? ms[ms.length - 1] : null;
      if (z === 1) {
        if (m && m.hasAttribute('data-ks-zoom')) {
          var orig = m.getAttribute('data-ks-orig');
          if (orig === null) { m.remove(); return; }
          m.setAttribute('content', orig);
          m.removeAttribute('data-ks-orig');
          m.removeAttribute('data-ks-zoom');
        }
        return;
      }
      if (!m) {
        m = document.createElement('meta');
        m.name = 'viewport';
        (document.head || document.documentElement).appendChild(m);
        m.setAttribute('data-ks-zoom', '1');
      } else if (!m.hasAttribute('data-ks-zoom')) {
        var c0 = m.getAttribute('content');
        if (c0 !== null) m.setAttribute('data-ks-orig', c0);
        m.setAttribute('data-ks-zoom', '1');
      }
      var scaleKeys =
          ['width', 'height', 'initial-scale', 'minimum-scale',
           'maximum-scale', 'user-scalable'];
      var keep = [];
      (m.getAttribute('data-ks-orig') || '').split(',').forEach(
        function (part) {
          var k = part.split('=')[0].trim().toLowerCase();
          if (k && scaleKeys.indexOf(k) < 0) keep.push(part.trim());
        },
      );
      var base = keep.concat(['initial-scale=' + z]);
      m.setAttribute('content', base.concat(
        ['minimum-scale=' + z, 'maximum-scale=' + z, 'user-scalable=no'],
      ).join(', '));
      if ($pinch) {
        requestAnimationFrame(function () {
          m.setAttribute('content', base.concat(
            ['minimum-scale=0.25', 'maximum-scale=5', 'user-scalable=yes'],
          ).join(', '));
        });
      }
    })();
  ''';
}
