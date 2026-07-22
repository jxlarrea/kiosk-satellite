/// Document-start script that filters the Home Assistant entity-update stream
/// down to the entities the current dashboard view actually shows.
///
/// The problem (issue #8): HA pushes `subscribe_entities` updates for EVERY
/// entity to every client, and the frontend does real work per update
/// (rebuilds the immutable `hass.states`, fans out to every subscribed card,
/// re-renders). On weak tablets (Echo Show, old Fire tablets) that constant
/// firehose stutters a dashboard that only shows a handful of entities.
///
/// Approach: wrap the page's WebSocket before the frontend creates it. Learn
/// the frontend's `subscribe_entities` subscription id, then for that
/// subscription drop the `c` (change) diffs for entities not on the current
/// view before the frontend's handler ever sees them. The one-time `a` (full
/// boot state) and `r` (removals) pass through untouched, so the frontend
/// still boots with complete state and nothing breaks.
///
/// Staleness is handled without a server round-trip: the wrapper keeps a
/// shadow of every entity's current state (it sees the full stream), and on
/// navigation it recomputes the view's allowlist and replays a synthetic `a`
/// for that view's entities from the shadow, so cards render fresh instantly.
///
/// Safety: anything unexpected (parse error, unknown subscription, a view
/// whose entities cannot be enumerated — e.g. a strategy dashboard) falls back
/// to pass-through, so the page is never left showing wrong data. Filtering is
/// controlled at runtime by `window.__ksWs.setEnabled(bool)` so it can be
/// A/B'd live, and `window.__ksWs` exposes counters for measurement.
const wsFilterScript = '''
(function () {
  if (window.__ksWs) return;
  var Native = window.WebSocket;
  if (!Native) return;

  var S = {
    enabled: true,
    subId: null,
    allow: null,          // Set of allowed entity_ids, or null = do not filter
    built: false,         // an allowlist build has run for the current view
    shadow: {},           // entity_id -> compressed state
    listeners: [],        // frontend 'message' listeners on the current HA socket
    configCache: {},
    // counters. cTotal counts every entity change seen (both A/B phases, so
    // the load can be shown comparable); cFwd counts those forwarded.
    cTotal: 0, cFwd: 0, evSeen: 0, evDropped: 0, longMs: 0, startTs: 0,
  };
  window.__ksWs = S;

  function now() { try { return performance.now(); } catch (e) { return 0; } }
  S.startTs = now();
  S.reset = function () {
    S.cTotal = 0; S.cFwd = 0; S.evSeen = 0; S.evDropped = 0; S.longMs = 0; S.startTs = now();
  };
  S.stats = function () {
    // mode: 'filtering' (allowlist active), 'passthrough' (this view's
    // entities cannot be determined, updates flow unfiltered), 'boot'
    // (allowlist not built yet). The UIs word their telemetry from this.
    var mode = S.allow ? 'filtering' : (S.built ? 'passthrough' : 'boot');
    return { enabled: S.enabled, allow: S.allow ? S.allow.size : null,
      mode: mode, subId: S.subId, shadow: Object.keys(S.shadow).length,
      cTotal: S.cTotal, cFwd: S.cFwd, evSeen: S.evSeen, evDropped: S.evDropped,
      longMs: Math.round(S.longMs), dt: Math.round(now() - S.startTs) };
  };
  S.setEnabled = function (on) {
    on = !!on;
    if (on === S.enabled) return;
    S.enabled = on;
    if (!on) pushAdd(Object.keys(S.shadow)); // disabling: refresh everything so nothing stays stale
    else recompute();
  };

  try {
    new PerformanceObserver(function (l) {
      l.getEntries().forEach(function (e) { S.longMs += e.duration; });
    }).observe({ entryTypes: ['longtask'] });
  } catch (e) {}

  // ---- shadow (compressed subscribe_entities diff format) ----
  function applyAdd(a) { for (var e in a) S.shadow[e] = a[e]; }
  function applyChange(c) {
    for (var e in c) {
      var cur = S.shadow[e] || (S.shadow[e] = {});
      var d = c[e];
      if (d['+']) {
        var p = d['+'];
        if ('s' in p) cur.s = p.s;
        if ('lc' in p) cur.lc = p.lc;
        if ('lu' in p) cur.lu = p.lu;
        if ('c' in p) cur.c = p.c;
        if (p.a) { cur.a = cur.a || {}; for (var k in p.a) cur.a[k] = p.a[k]; }
      }
      if (d['-'] && d['-'].a && cur.a) {
        var rm = d['-'].a;
        (Array.isArray(rm) ? rm : Object.keys(rm)).forEach(function (k) { delete cur.a[k]; });
      }
    }
  }
  function applyRemove(r) { (r || []).forEach(function (e) { delete S.shadow[e]; }); }

  function allowed(e) { return !S.enabled || !S.allow || S.allow.has(e); }

  // ---- deliver a raw frame to the frontend's listeners ----
  function deliver(str) {
    var evt; try { evt = new MessageEvent('message', { data: str }); } catch (e) { evt = { data: str }; }
    S.listeners.slice().forEach(function (l) { try { l(evt); } catch (e) {} });
  }
  function pushAdd(eids) {
    if (S.subId == null || !eids || !eids.length) return;
    var a = {}, any = false;
    eids.forEach(function (e) { if (S.shadow[e]) { a[e] = S.shadow[e]; any = true; } });
    if (any) deliver(JSON.stringify({ id: S.subId, type: 'event', event: { a: a } }));
  }

  // ---- per-view allowlist from lovelace config ----
  function hassEl() {
    try { var el = document.querySelector('home-assistant'); return (el && el.hass && el.hass.connection) ? el.hass : null; } catch (e) { return null; }
  }
  function loc() {
    var p = location.pathname.replace(/^\\/+/, '').split('/');
    return { dash: p[0] || 'lovelace', view: p[1] != null ? p[1] : '0' };
  }
  function collect(node, acc) {
    if (node == null) return;
    if (typeof node === 'string') { if (/^[a-z_0-9]+\\.[a-z0-9_]+\$/.test(node)) acc.add(node); return; }
    if (Array.isArray(node)) { for (var i = 0; i < node.length; i++) collect(node[i], acc); return; }
    if (typeof node === 'object') { for (var k in node) collect(node[k], acc); }
  }

  // auto-entities cards hold FILTERS, not entity ids, so the literal scan above
  // finds nothing in them. Expand the filters against the registries the
  // frontend already carries (hass.entities / hass.devices / hass.areas), the
  // same identities HA itself resolves them with. Over-include on purpose:
  // volatile tests (state/attributes) never shrink the set and excludes are
  // ignored — an extra allowed entity costs a few updates, a missing one means
  // a stale card. Filters we cannot resolve structurally (templates, name or
  // group matches, boolean combinators) make the whole view unfilterable: the
  // caller passes it through, which is always correct, just not faster.
  var AUTO_STRUCT = ['domain', 'entity_id', 'area', 'label', 'device', 'integration'];
  var AUTO_VOLATILE = ['state', 'attributes', 'last_changed', 'last_updated',
    'last_triggered', 'sort', 'options', 'type', 'active_choice'];
  function globRe(g) {
    // Escape char-by-char (no regex-literal char class: its "\\]" escape does
    // not survive this file being a Dart string). * is the only glob wildcard.
    var s = String(g), esc = '';
    for (var gi = 0; gi < s.length; gi++) {
      var ch = s.charAt(gi);
      if (ch === '*') esc += '.*';
      else if (/[a-zA-Z0-9_]/.test(ch)) esc += ch;
      else esc += '\\\\' + ch;
    }
    return new RegExp('^' + esc + '\$');
  }
  // A filter value may be a string, an array, or (from the visual editor) an
  // object like {label: "x", active_choice: "label"}; flatten to strings.
  function vals(v, key) {
    if (v == null) return [];
    if (Array.isArray(v)) { var o = []; v.forEach(function (x) { o = o.concat(vals(x, key)); }); return o; }
    if (typeof v === 'object') return key in v ? vals(v[key], key) : [];
    return [String(v)];
  }
  function expandAuto(card, acc, hass) {
    var f = card.filter || {};
    if (f.template != null) return false;
    var inc = Array.isArray(f.include) ? f.include : [];
    var ents = hass.entities || {}, devs = hass.devices || {}, areas = hass.areas || {};
    var ids = Object.keys(hass.states || {});
    for (var i = 0; i < inc.length; i++) {
      var c = inc[i];
      if (!c || typeof c !== 'object') return false;
      var bad = false;
      Object.keys(c).forEach(function (k) {
        if (AUTO_VOLATILE.indexOf(k) >= 0) return;
        if (AUTO_STRUCT.indexOf(k) < 0) bad = true;
      });
      if (bad) return false;
      var preds = [];
      if (c.domain != null) {
        var doms = vals(c.domain, 'domain');
        preds.push(function (id) { return doms.indexOf(id.split('.')[0]) >= 0; });
      }
      if (c.entity_id != null) {
        var res = vals(c.entity_id, 'entity_id').map(globRe);
        preds.push(function (id) { return res.some(function (re) { return re.test(id); }); });
      }
      if (c.area != null) {
        var wa = vals(c.area, 'area');
        preds.push(function (id) {
          var e = ents[id]; if (!e) return false;
          var aid = e.area_id || (e.device_id && devs[e.device_id] && devs[e.device_id].area_id) || null;
          if (!aid) return false;
          var an = areas[aid] && areas[aid].name;
          return wa.indexOf(aid) >= 0 || (an != null && wa.indexOf(an) >= 0);
        });
      }
      if (c.device != null) {
        var wd = vals(c.device, 'device');
        preds.push(function (id) {
          var e = ents[id]; if (!e || !e.device_id) return false;
          var d = devs[e.device_id];
          return wd.indexOf(e.device_id) >= 0 || (d != null &&
            ((d.name_by_user != null && wd.indexOf(d.name_by_user) >= 0) ||
             (d.name != null && wd.indexOf(d.name) >= 0)));
        });
      }
      if (c.integration != null) {
        var wi = vals(c.integration, 'integration');
        preds.push(function (id) { var e = ents[id]; return !!e && wi.indexOf(e.platform) >= 0; });
      }
      if (c.label != null) {
        var wl = vals(c.label, 'label');
        preds.push(function (id) {
          var e = ents[id];
          return !!e && (e.labels || []).some(function (l) { return wl.indexOf(l) >= 0; });
        });
      }
      // Volatile-only include (a bare `state:` filter) legitimately spans the
      // whole instance; a per-view allowlist cannot bound it.
      if (!preds.length) return false;
      ids.forEach(function (id) {
        if (preds.every(function (p) { return p(id); })) acc.add(id);
      });
    }
    return true;
  }
  S.expandAuto = expandAuto; // diagnostics: test a filter against live registries

  function findAuto(node, out) {
    if (Array.isArray(node)) { node.forEach(function (n) { findAuto(n, out); }); return; }
    if (!node || typeof node !== 'object') return;
    if (typeof node.type === 'string' && node.type.indexOf('auto-entities') >= 0 && node.filter) out.push(node);
    for (var k in node) { var v = node[k]; if (v && typeof v === 'object') findAuto(v, out); }
  }

  function build(cfg, view) {
    S.built = true;
    var views = (cfg && cfg.views) || [], v = null;
    for (var i = 0; i < views.length; i++) {
      var vp = views[i].path != null ? String(views[i].path) : String(i);
      if (vp === view) { v = views[i]; break; }
    }
    if (!v) v = views[Number(view)] || null;
    if (!v) { S.allow = null; return; } // unknown view -> do not filter
    var acc = new Set();
    collect(v.cards, acc); collect(v.badges, acc); collect(v.sections, acc);
    var autos = []; findAuto(v, autos);
    var hass = hassEl();
    for (var a = 0; a < autos.length; a++) {
      if (!hass || !expandAuto(autos[a], acc, hass)) { S.allow = null; return; }
    }
    // The literal scan can match entity-id-shaped strings that are not
    // entities ("0.5em" from a card-mod style, "e.g" in prose). Keep only ids
    // the instance actually has; a to-be-created entity still gets through
    // later because its first appearance is an `a` add, which always passes.
    if (hass && hass.states) {
      var known = hass.states;
      acc.forEach(function (id) { if (!known[id]) acc.delete(id); });
    }
    // An empty allowlist would go stale EVERYWHERE on the view — a view whose
    // entities cannot be determined must pass through, not filter to nothing.
    if (!acc.size) { S.allow = null; return; }
    S.allow = acc;
    pushAdd(Array.from(acc)); // refresh this view's entities to current state
  }
  function recompute() {
    var hass = hassEl();
    if (!hass) { setTimeout(recompute, 500); return; }
    var l = loc();
    if (S.configCache[l.dash]) { build(S.configCache[l.dash], l.view); return; }
    try {
      hass.connection.sendMessagePromise({ type: 'lovelace/config', url_path: l.dash === 'lovelace' ? null : l.dash })
        .then(function (cfg) { S.configCache[l.dash] = cfg; build(cfg, l.view); })
        // Strategy dashboard etc. -> do not filter.
        .catch(function () { S.allow = null; S.built = true; });
    } catch (e) { S.allow = null; S.built = true; }
  }
  window.addEventListener('location-changed', function () { if (S.enabled) recompute(); });
  window.addEventListener('popstate', function () { if (S.enabled) recompute(); });

  // ---- outgoing: learn the GLOBAL subscribe_entities id ----
  // The frontend's firehose is `subscribe_entities` with NO entity_ids (all
  // entities). Specific subscriptions (with entity_ids) are already scoped by
  // the frontend, so leave them alone. Capture the first global one per socket
  // (reset on reconnect); an id captured from a scoped sub would filter the
  // wrong stream and pass the firehose through untouched.
  function onSend(data) {
    if (typeof data !== 'string') return;
    var m; try { m = JSON.parse(data); } catch (e) { return; }
    if (m && m.type === 'subscribe_entities' && m.id != null && S.subId == null &&
        !(m.entity_ids && m.entity_ids.length)) {
      S.subId = m.id; recompute();
    }
  }

  // ---- process one message object; returns it unchanged, a filtered copy, or
  // null to drop it. Only touches our global subscribe_entities subscription;
  // everything else (other subscriptions, results, pongs) passes untouched.
  function processElem(o) {
    if (!o || o.type !== 'event' || o.id !== S.subId) return o;
    var ev = o.event || {};
    if (ev.a) applyAdd(ev.a);
    if (ev.c) applyChange(ev.c);
    if (ev.r) applyRemove(ev.r);
    S.evSeen++;
    if (ev.c) S.cTotal += Object.keys(ev.c).length; // counted in BOTH phases (load)
    if (!S.enabled || !S.allow) return o;           // pass through until ready / when off
    var out = {}, has = false;
    if (ev.a) { out.a = ev.a; has = true; }         // adds pass whole (rare, and safe)
    if (ev.r) { out.r = ev.r; has = true; }
    if (ev.c) {
      var fc = {}, any = false;
      for (var e in ev.c) { if (allowed(e)) { fc[e] = ev.c[e]; S.cFwd++; any = true; } }
      if (any) { out.c = fc; has = true; }
    }
    if (!has) { S.evDropped++; return null; }        // nothing to forward -> drop element
    return { id: o.id, type: 'event', event: out };
  }

  // ---- incoming: HA batches messages, so a frame can be a JSON ARRAY of
  // objects, or a single object. Filter our subscription's elements, keep the
  // rest, and only re-serialize when something actually changed (else pass the
  // original string through untouched). null = passthrough, [] = drop frame.
  function onMessage(str) {
    if (typeof str !== 'string' || S.subId == null) return null;
    var m; try { m = JSON.parse(str); } catch (e) { return null; }
    var arr = Array.isArray(m);
    var list = arr ? m : [m];
    var out = [], ours = false, modified = false;
    for (var i = 0; i < list.length; i++) {
      var o = list[i];
      if (o && o.type === 'event' && o.id === S.subId) {
        ours = true;
        var r = processElem(o);   // maintains the shadow; may filter/drop
        if (r !== o) modified = true;
        if (r !== null) out.push(r);
      } else {
        // A dashboard was edited while on screen: the cached config (and the
        // allowlist built from it) is stale. Rebuild, debounced — the editor
        // can fire several saves in a burst.
        if (o && o.type === 'event' && o.event &&
            o.event.event_type === 'lovelace_updated') {
          S.configCache = {};
          clearTimeout(S.lvTimer);
          S.lvTimer = setTimeout(function () { if (S.enabled) recompute(); }, 1500);
        }
        out.push(o);
      }
    }
    if (!ours || !modified) return null;             // nothing of ours changed
    if (out.length === 0) return [];                 // whole frame dropped
    return [JSON.stringify(arr ? out : out[0])];
  }

  // ---- wrap WebSocket ----
  window.WebSocket = function (url, protocols) {
    var ws = protocols === undefined ? new Native(url) : new Native(url, protocols);
    if (!/\\/api\\/websocket\\/?(\$|\\?)/.test('' + url)) return ws;

    // New HA socket (fresh connect / reconnect): drop stale listeners and
    // re-learn the subscription id (haws re-subscribes with a new id). Keep
    // the shadow so a view switch right after a reconnect still refreshes.
    S.listeners = [];
    S.subId = null;
    S.currentWs = ws;

    var send = ws.send.bind(ws);
    ws.send = function (d) { try { onSend(d); } catch (e) {} return send(d); };

    function wrap(fn) {
      return function (ev) {
        // A superseded socket can still flush buffered frames after the
        // frontend has moved to a new one — and by then haws has reset its
        // command-id space, so those frames look like "unknown subscription
        // N", which haws answers by UNSUBSCRIBING id N on the NEW socket,
        // killing whatever live subscription now owns that id (observed
        // during Home Assistant reboot reconnect storms). Frames from a
        // socket that is no longer the newest must never reach the page.
        if (S.currentWs !== ws) return;
        var res;
        try { res = onMessage(ev && ev.data); } catch (e) { res = null; }
        if (res == null) return fn.call(ws, ev);
        res.forEach(function (d) {
          var e2; try { e2 = new MessageEvent('message', { data: d }); } catch (x) { e2 = { data: d }; }
          fn.call(ws, e2);
        });
      };
    }

    var add = ws.addEventListener.bind(ws), rm = ws.removeEventListener.bind(ws), map = new Map();
    ws.addEventListener = function (type, fn, opts) {
      if (type === 'message' && typeof fn === 'function') {
        var w = wrap(fn); map.set(fn, w); S.listeners.push(fn); return add(type, w, opts);
      }
      return add(type, fn, opts);
    };
    ws.removeEventListener = function (type, fn, opts) {
      if (type === 'message' && map.has(fn)) {
        var w = map.get(fn); map.delete(fn);
        var i = S.listeners.indexOf(fn); if (i >= 0) S.listeners.splice(i, 1);
        return rm(type, w, opts);
      }
      return rm(type, fn, opts);
    };
    var _om = null, _omWrapped = null;
    Object.defineProperty(ws, 'onmessage', {
      configurable: true,
      get: function () { return _om; },
      set: function (fn) {
        // Real onmessage semantics are replace, not append: without
        // removing the previous wrapper every reassignment adds one more
        // native listener that still calls its captured old handler, so
        // each frame is processed once per historical handler.
        if (_omWrapped) {
          rm('message', _omWrapped); _omWrapped = null;
          var i = S.listeners.indexOf(_om); if (i >= 0) S.listeners.splice(i, 1);
        }
        _om = fn;
        if (typeof fn === 'function') {
          _omWrapped = wrap(fn); S.listeners.push(fn); add('message', _omWrapped);
        }
      },
    });

    return ws;
  };
  window.WebSocket.prototype = Native.prototype;
  window.WebSocket.CONNECTING = Native.CONNECTING;
  window.WebSocket.OPEN = Native.OPEN;
  window.WebSocket.CLOSING = Native.CLOSING;
  window.WebSocket.CLOSED = Native.CLOSED;
})();
''';
