import 'dart:convert';

/// Makes a page's `prefers-color-scheme` answer with the dashboard's light
/// or dark state instead of Android's (issue #907).
///
/// Music Assistant's Auto theme (its default) resolves light or dark through
/// `window.matchMedia('(prefers-color-scheme: dark)')`, for both its Vuetify
/// theme and its Tailwind `dark` class, and listens on that query for
/// changes. The WebView answers from the app's own night mode, which knows
/// nothing about a theme scheduled or pinned for the dashboard. So at
/// document start, color-scheme queries get a stand-in list that matches
/// [dark], and every other query goes to the real `matchMedia`.
///
/// [colorSchemeSetJs] flips the state live: each stand-in list whose answer
/// changed fires `change`, which is how the page's own listeners pick up an
/// OS switch at sunset.
///
/// CSS `@media (prefers-color-scheme)` rules are out of reach, which only
/// touches Music Assistant's login page. A theme set to Light or Dark inside
/// Music Assistant never asks, so it keeps its own choice.
String colorSchemeJs({required bool dark}) {
  return '''
    (function () {
      if (window.__ksSetDark || typeof window.matchMedia !== 'function') {
        return;
      }
      var dark = $dark;
      var native = window.matchMedia.bind(window);
      var lists = [];
      var scheme = /prefers-color-scheme\\s*:\\s*(dark|light)/i;
      window.matchMedia = function (query) {
        var m = scheme.exec(String(query));
        if (!m) return native(query);
        var want = m[1].toLowerCase() === 'dark';
        var list = new EventTarget();
        Object.defineProperty(list, 'media', { value: String(query) });
        Object.defineProperty(list, 'matches', {
          get: function () { return dark === want; },
        });
        list.onchange = null;
        list.addListener = function (fn) {
          list.addEventListener('change', fn);
        };
        list.removeListener = function (fn) {
          list.removeEventListener('change', fn);
        };
        lists.push(list);
        return list;
      };
      window.__ksSetDark = function (next) {
        if (next === dark) return;
        dark = next;
        lists.forEach(function (list) {
          var ev = new Event('change');
          ev.matches = list.matches;
          ev.media = list.media;
          list.dispatchEvent(ev);
          if (typeof list.onchange === 'function') list.onchange(ev);
        });
      };
    })();
  ''';
}

/// Flips the state [colorSchemeJs] installed. A no-op on a page without it.
String colorSchemeSetJs({required bool dark}) =>
    'window.__ksSetDark && window.__ksSetDark($dark);';

/// Sets light or dark for the Home Assistant frontend on this device only
/// (issue #1101). [dark] null leaves the choice to Home Assistant.
///
/// Home Assistant keeps the theme in the user's profile, shared live by
/// every browser that user is signed into, so a `settheme` event from one
/// kiosk switched them all. Instead, the page's `prefers-color-scheme`
/// answers with [dark], which is what Home Assistant follows when the
/// profile's dark mode is Auto. A profile set to Light or Dark ignores that
/// answer, so while [dark] is set this page also renders as if the profile
/// said Auto: `_applyTheme` sees the selected theme without its `dark` key
/// for the length of the call. The profile itself is never written, the
/// theme name is kept and other browsers are left alone.
///
/// Acts only on pages with a `<home-assistant>` element, which sits in the
/// markup ahead of the scripts that ask, so it can ride the dashboard
/// WebView's document-start scripts. Custom pages have their own override
/// in [customPageColorSchemeJs]. [haColorSchemeSetJs] switches it live.
String haColorSchemeJs({required bool? dark}) =>
    '''
    (function () {
      if (window.__ksHaScheme || typeof window.matchMedia !== 'function') {
        return;
      }
      var mode = ${dark ?? 'null'};
      var native = window.matchMedia.bind(window);
      var scheme = /prefers-color-scheme\\s*:\\s*(dark|light)/i;
      var lists = [];
      function fire(list) {
        var ev = new Event('change');
        ev.matches = list.matches;
        ev.media = list.media;
        list.dispatchEvent(ev);
        if (typeof list.onchange === 'function') list.onchange(ev);
      }
      window.matchMedia = function (query) {
        var m = scheme.exec(String(query));
        if (!m || !document.querySelector('home-assistant')) {
          return native(query);
        }
        var real = native(query);
        var want = m[1].toLowerCase() === 'dark';
        var list = new EventTarget();
        Object.defineProperty(list, 'media', { value: String(query) });
        Object.defineProperty(list, 'matches', {
          get: function () { return mode === null ? real.matches : mode === want; },
        });
        list.onchange = null;
        list.addListener = function (fn) {
          list.addEventListener('change', fn);
        };
        list.removeListener = function (fn) {
          list.removeEventListener('change', fn);
        };
        real.addEventListener('change', function () {
          if (mode === null) fire(list);
        });
        lists.push(list);
        return list;
      };
      function darkNow() {
        return mode === null
          ? native('(prefers-color-scheme: dark)').matches : mode;
      }
      if (window.customElements) {
        customElements.whenDefined('home-assistant').then(function () {
          var proto = customElements.get('home-assistant').prototype;
          var apply = proto._applyTheme;
          if (typeof apply !== 'function' || apply.__ks) return;
          var wrapped = function () {
            if (mode === null) return apply.apply(this, arguments);
            var hass = this.hass;
            var theme = hass && hass.selectedTheme;
            if (!theme || theme.dark === undefined) {
              return apply.call(this, mode);
            }
            var shadow = {};
            for (var k in theme) if (k !== 'dark') shadow[k] = theme[k];
            hass.selectedTheme = shadow;
            try {
              return apply.call(this, mode);
            } finally {
              hass.selectedTheme = theme;
              if (this.hass && this.hass.selectedTheme === shadow) {
                this.hass.selectedTheme = theme;
              }
            }
          };
          wrapped.__ks = true;
          proto._applyTheme = wrapped;
        });
      }
      window.__ksHaScheme = function (next) {
        if (next === mode) return;
        var before = lists.map(function (list) { return list.matches; });
        mode = next;
        lists.forEach(function (list, i) {
          if (list.matches !== before[i]) fire(list);
        });
        var el = document.querySelector('home-assistant');
        if (el && el.hass && typeof el._applyTheme === 'function') {
          try { el._applyTheme(darkNow()); } catch (e) {}
        }
      };
    })();
  ''';

/// Switches what [haColorSchemeJs] installed. A no-op on a page without it.
String haColorSchemeSetJs({required bool? dark}) =>
    'window.__ksHaScheme && window.__ksHaScheme(${dark ?? 'null'});';

/// [colorSchemeJs] for a custom page (a person's own HTML under `/local/`),
/// which also covers the page's CSS: a custom page asks
/// `@media (prefers-color-scheme)` as often as it asks `matchMedia`.
///
/// Chromium offers no way to answer the CSS media feature for a page, so
/// the page's own rules are rewritten instead. Every media condition naming
/// `prefers-color-scheme` in a same-origin stylesheet, a `<link media>`, a
/// `<style media>` or a `<source media>` gets that feature swapped for a
/// query that always or never matches, kept with the original so a flip
/// rewrites it again. Stylesheets from another host cannot be read and keep
/// answering from Android. Installed on every document and acting only on
/// custom pages (under /local/, or on one of the [origins] of the pages on
/// other servers), so it can ride the dashboard WebView's document-start
/// scripts. It also marks such a page with `window.__ksCustomPage`, which
/// the update filter reads.
String customPageColorSchemeJs({
  required bool dark,
  Iterable<String> origins = const [],
}) =>
    '''
    (function () {
      if (location.pathname.indexOf('/local/') !== 0 &&
          ${jsonEncode(origins.toList())}.indexOf(location.origin) < 0) return;
      window.__ksCustomPage = true;
      ${colorSchemeJs(dark: dark)}
      if (!window.__ksSetDark || window.__ksCssScheme) return;
      window.__ksCssScheme = true;
      var dark = $dark;
      var feature = /\\(\\s*prefers-color-scheme\\s*:\\s*(dark|light)\\s*\\)/i;
      var features = /\\(\\s*prefers-color-scheme\\s*:\\s*(dark|light)\\s*\\)/gi;
      function rewrite(text) {
        return text.replace(features, function (_, scheme) {
          return (scheme.toLowerCase() === 'dark') === dark
            ? '(min-width: 0px)' : '(max-width: -1px)';
        });
      }
      function fixList(list, owner) {
        if (!list) return;
        if (owner.__ksMedia === undefined) {
          if (!feature.test(list.mediaText)) return;
          owner.__ksMedia = list.mediaText;
        }
        var next = rewrite(owner.__ksMedia);
        if (list.mediaText !== next) list.mediaText = next;
      }
      function walk(rules) {
        for (var i = 0; i < rules.length; i++) {
          var rule = rules[i];
          if (rule.media) fixList(rule.media, rule);
          if (rule.styleSheet) sheet(rule.styleSheet);
          if (rule.cssRules) walk(rule.cssRules);
        }
      }
      function sheet(s) {
        try {
          fixList(s.media, s);
          walk(s.cssRules);
        } catch (e) {}
      }
      function sources() {
        var els = document.querySelectorAll('source[media]');
        for (var i = 0; i < els.length; i++) {
          var el = els[i];
          if (el.__ksMedia === undefined) {
            if (!feature.test(el.media)) continue;
            el.__ksMedia = el.media;
          }
          var next = rewrite(el.__ksMedia);
          if (el.media !== next) el.media = next;
        }
      }
      function all() {
        for (var i = 0; i < document.styleSheets.length; i++) {
          sheet(document.styleSheets[i]);
        }
        sources();
      }
      var queued = false;
      function soon() {
        if (queued) return;
        queued = true;
        setTimeout(function () { queued = false; all(); }, 0);
      }
      new MutationObserver(soon).observe(document, { childList: true, subtree: true });
      document.addEventListener('load', soon, true);
      document.addEventListener('DOMContentLoaded', all);
      var setDark = window.__ksSetDark;
      window.__ksSetDark = function (next) {
        setDark(next);
        if (next === dark) return;
        dark = next;
        all();
      };
    })();
  ''';
