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
/// Dashboard reads also add dependencies at runtime. Scanning all states or
/// an unavailable tracking hook makes the view pass through unfiltered.
/// Unknown subscriptions and unresolved views also pass through. Filtering is
/// controlled at runtime by `window.__ksWs.setEnabled(bool)` so it can be
/// A/B'd live, and `window.__ksWs` exposes counters for measurement.
const wsFilterScript = r'''
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
    subs: {},              // command id -> what it subscribed to (census)
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
    // Every subscription the page opened, and how many of them ask for the
    // uncompressed state_changed firehose (see onSend).
    var subs = [], fire = 0;
    for (var sid in S.subs) {
      subs.push(S.subs[sid]);
      if (S.subs[sid].indexOf('subscribe_events:state_changed') === 0) fire++;
    }
    return { enabled: S.enabled, allow: S.allow ? S.allow.size : null,
      runtimeTracking: R.attached && !R.failed, runtimeEntities: R.ids.size,
      runtimeAll: R.all, runtimeFailure: R.failure || null,
      subs: subs, stateChangedSubs: fire,
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
        if (p.a) {
          cur.a = cur.a || {};
          // Retarget: the pointer an allowed entity carries now names a
          // different entity (the TTS output was switched to another
          // speaker). The allowlist was built around the old one, so
          // rebuild rather than leave the new target's updates dropped
          // until the next navigation.
          if ('entity_id' in p.a && S.allow && S.allow.has(e)
            && JSON.stringify(p.a.entity_id) !== JSON.stringify(cur.a.entity_id)) {
            clearTimeout(S.tgtTimer);
            S.tgtTimer = setTimeout(function () { if (S.enabled) recompute(); }, 250);
          }
          for (var k in p.a) cur.a[k] = p.a[k];
        }
      }
      if (d['-'] && d['-'].a && cur.a) {
        var rm = d['-'].a;
        (Array.isArray(rm) ? rm : Object.keys(rm)).forEach(function (k) { delete cur.a[k]; });
      }
    }
  }
  function applyRemove(r) { (r || []).forEach(function (e) { delete S.shadow[e]; }); }

  // An entity whose `entity_id` attribute names OTHER entities (Voice
  // Satellite's TTS output select, group-shaped helpers) drags those onto
  // the allowlist with it: whoever reads the pointer reads the target's
  // state next.
  function addTargets(st, acc) {
    var t = st && st.attributes && st.attributes.entity_id;
    if (!t) return;
    (Array.isArray(t) ? t : [t]).forEach(function (id) {
      if (typeof id === 'string' && id.indexOf('.') > 0) acc.add(id);
    });
  }

  // update.* always passes: the sidebar's update badges live outside every
  // view, and update entities change state rarely enough that forwarding
  // them costs nothing (issue #131).
  function allowed(e) {
    return !S.enabled || !S.allow || S.allow.has(e) ||
      e.lastIndexOf('update.', 0) === 0;
  }

  // ---- deliver a raw frame to the frontend's listeners ----
  function deliver(str) {
    var evt; try { evt = new MessageEvent('message', { data: str }); } catch (e) { evt = { data: str }; }
    S.listeners.slice().forEach(function (l) { try { l(evt); } catch (e) {} });
  }
  function sendAdd(eids) {
    var a = {}, any = false;
    eids.forEach(function (e) { if (S.shadow[e]) { a[e] = S.shadow[e]; any = true; } });
    if (any) deliver(JSON.stringify({ id: S.subId, type: 'event', event: { a: a } }));
  }
  // Replays go out in batches. Lifting the filter on a large instance replays
  // every entity there is, and handing the frontend all of them in one frame
  // is a single long task — it rebuilds `hass.states` and re-renders against
  // it without yielding, and for as long as that runs the page is not reading
  // its socket, which is the backpressure that gets a client dropped for not
  // keeping up. Yielding between batches lets the socket drain in between.
  // A batch mid-flight is abandoned when the socket changes under it: the new
  // one boots the frontend's state from scratch anyway.
  var CHUNK = 250;
  function pushAdd(eids) {
    if (S.subId == null || !eids || !eids.length) return;
    if (eids.length <= CHUNK) { sendAdd(eids); return; }
    var sub = S.subId, socket = S.currentWs, i = 0;
    (function step() {
      if (S.subId !== sub || S.currentWs !== socket) return;
      sendAdd(eids.slice(i, i + CHUNK));
      i += CHUNK;
      if (i < eids.length) setTimeout(step, 0);
    })();
  }

  // Track only the hass object delivered to the active Lovelace view. Instrumenting the
  // global store would count HA's own immutable state copies as dashboard
  // reads and allow every entity on every view.
  var R = { ids: new Set(), all: false, attached: false, failed: false,
    path: null, epoch: 0 };
  var runtimeScopes = new WeakMap();
  var runtimePending = new Set(), runtimeReplayAll = false, runtimeTimer, runtimeBuildTimer;
  var runtimeRegistries = new WeakSet(), runtimePrototypes = new WeakSet();

  function runtimeReplay(all, id) {
    if (all) runtimeReplayAll = true;
    else runtimePending.add(id);
    if (runtimeTimer != null) return;
    var socket = S.currentWs;
    // Do not deliver synthetic updates inside a component's getter/render.
    runtimeTimer = setTimeout(function () {
      runtimeTimer = null;
      var ids = runtimeReplayAll ? Object.keys(S.shadow) : Array.from(runtimePending);
      runtimeReplayAll = false;
      runtimePending.clear();
      if (S.enabled && S.currentWs === socket) pushAdd(ids);
    }, 0);
  }

  function runtimeLift() {
    var had = !!S.allow;
    S.allow = null;
    if (had) runtimeReplay(true);
  }

  function runtimeFailure(reason) {
    R.failed = true;
    R.failure = reason;
    runtimeLift();
  }

  function runtimeView() {
    var l = loc(), path = l.dash + '/' + l.view;
    if (R.path === path) return;
    R.path = path;
    R.epoch++;
    R.ids = new Set();
    R.all = false;
    R.attached = false;
    runtimeScopes = new WeakMap();
    // A pending refresh might contain states withheld on the previous view.
    // Keep it queued while the new view learns its dependencies.
    runtimeLift();
  }

  function runtimeRead(id, scope) {
    if (!runtimeCurrent(scope) || R.all || R.failed || typeof id !== 'string' ||
        !/^[a-z_0-9]+\.[a-z0-9_]+$/.test(id) || R.ids.has(id)) return;
    R.ids.add(id);
    if (S.allow && !S.allow.has(id)) {
      S.allow.add(id);
      runtimeReplay(false, id);
    } else if (!S.allow) {
      // A view with only calculated ids initially has no config allowlist.
      // Its first reads give us enough information to start filtering.
      runtimeRebuild();
    }
  }

  function runtimeRebuild() {
    if (runtimeBuildTimer != null) return;
    runtimeBuildTimer = setTimeout(function () {
      runtimeBuildTimer = null;
      if (S.enabled) recompute();
    }, 0);
  }

  function runtimeScan(scope) {
    if (!runtimeCurrent(scope) || R.all) return;
    // Object.values/entries, spreads and other enumeration can select by
    // changing state. Do not guess which candidates the component needs.
    R.all = true;
    runtimeLift();
  }

  function runtimeCurrent(scope) {
    return scope.epoch === R.epoch && scope.view.isConnected &&
      scope.view.index === scope.index;
  }

  function runtimeActive(view) {
    if (!view.isConnected) return false;
    var l = loc(), lv = view.lovelace, index = view.index;
    var cfg = lv && lv.config, v = cfg && cfg.views && cfg.views[index];
    if (!v || (lv.urlPath || 'lovelace') !== l.dash) return false;
    var path = v.path == null ? String(index) : String(v.path);
    return path === l.view || String(index) === l.view;
  }

  function trackHass(hass, view) {
    runtimeView();
    if (!hass || !hass.states || R.failed || R.all || !runtimeActive(view)) return hass;
    var scope = runtimeScopes.get(view);
    if (!scope || scope.index !== view.index) {
      scope = { view: view, index: view.index, epoch: R.epoch,
        hass: new WeakMap(), states: new WeakMap() };
      runtimeScopes.set(view, scope);
    }
    var runtimeHass = scope.hass, runtimeStates = scope.states;
    if (runtimeHass.has(hass)) return runtimeHass.get(hass);
    var states = hass.states;
    var descriptor = Object.getOwnPropertyDescriptor(hass, 'states');
    // Respect Proxy invariants if a future frontend freezes this property.
    if (descriptor && !descriptor.configurable && descriptor.writable === false) {
      runtimeFailure('hass.states is frozen');
      return hass;
    }
    var tracked = runtimeStates.get(states);
    if (!tracked) {
      tracked = new Proxy(states, {
        get: function (target, key, receiver) {
          runtimeRead(key, scope);
          return Reflect.get(target, key, receiver);
        },
        has: function (target, key) {
          runtimeRead(key, scope);
          return Reflect.has(target, key);
        },
        getOwnPropertyDescriptor: function (target, key) {
          runtimeRead(key, scope);
          return Reflect.getOwnPropertyDescriptor(target, key);
        },
        ownKeys: function (target) {
          runtimeScan(scope);
          return Reflect.ownKeys(target);
        }
      });
      runtimeStates.set(states, tracked);
    }
    var wrapped = new Proxy(hass, {
      get: function (target, key, receiver) {
        return key === 'states' ? tracked : Reflect.get(target, key, receiver);
      }
    });
    runtimeHass.set(hass, wrapped);
    runtimeHass.set(wrapped, wrapped);
    if (!R.attached) {
      R.attached = true;
      runtimeRebuild();
    }
    return wrapped;
  }

  function installRuntime(ctor) {
    var proto = ctor && ctor.prototype;
    if (!proto || runtimePrototypes.has(proto)) return;
    var owner = proto, descriptor;
    while (owner && !descriptor) {
      descriptor = Object.getOwnPropertyDescriptor(owner, 'hass');
      owner = Object.getPrototypeOf(owner);
    }
    if (!descriptor || !descriptor.get || !descriptor.set || !descriptor.configurable) {
      runtimeFailure('hass accessor unavailable');
      return;
    }
    Object.defineProperty(proto, 'hass', {
      configurable: descriptor.configurable, enumerable: descriptor.enumerable,
      get: descriptor.get,
      set: function (hass) {
        var value = hass;
        try { value = trackHass(hass, this); }
        catch (e) { runtimeFailure(String(e)); }
        return descriptor.set.call(this, value);
      }
    });
    runtimePrototypes.add(proto);
    // A scoped registry can expose a placeholder before the real class is
    // ready. A later successful installation recovers that startup failure.
    if (R.failure === 'hass accessor unavailable') {
      R.failed = false;
      R.failure = null;
    }
    // Definition can finish after the first hass assignment. Reassign once
    // so existing views and their descendants also receive the tracked copy.
    function attach(root) {
      root.querySelectorAll('*').forEach(function (el) {
        if (el.localName === 'hui-view' && el.hass) el.hass = el.hass;
        if (el.shadowRoot) attach(el.shadowRoot);
      });
    }
    attach(document);
  }

  function watchRuntime() {
    var registry = window.customElements;
    if (!registry || typeof Proxy === 'undefined') return;
    try { installRuntime(registry.get('hui-view')); }
    catch (e) { runtimeFailure(String(e)); }
    if (runtimeRegistries.has(registry)) return;
    runtimeRegistries.add(registry);
    registry.whenDefined('hui-view').then(function (ctor) {
      // The old native registry can resolve with the polyfill's stand-in
      // after the real class has already been installed in the new registry.
      if (registry !== window.customElements) { watchRuntime(); return; }
      try {
        installRuntime(ctor || registry.get('hui-view'));
        if (R.failure === 'hass accessor unavailable') setTimeout(watchRuntime, 0);
      } catch (e) { runtimeFailure(String(e)); }
    });
  }

  // ---- per-view allowlist from lovelace config ----
  function hassEl() {
    try { var el = document.querySelector('home-assistant'); return (el && el.hass && el.hass.connection) ? el.hass : null; } catch (e) { return null; }
  }
  function loc() {
    var p = location.pathname.replace(/^\/+/, '').split('/');
    return { dash: p[0] || 'lovelace', view: p[1] != null ? p[1] : '0' };
  }
  function collect(node, acc) {
    if (node == null) return;
    if (typeof node === 'string') {
      if (/^[a-z_0-9]+\.[a-z0-9_]+$/.test(node)) { acc.add(node); return; }
      // Longer strings are templates and markdown (button-card JS,
      // card-mod styles, jinja), which name their entities verbatim —
      // states['sensor.x'] — so scan them for id-shaped substrings
      // (issue #139). Only ids built dynamically in the template escape
      // this. Junk that happens to be id-shaped ("0.5em", "e.g") is
      // dropped against hass.states by the caller, and over-collection
      // only passes a few extra updates.
      if (node.indexOf('.') >= 0) {
        var m = node.match(/[a-z_0-9]+\.[a-z0-9_]+/g);
        if (m) for (var mi = 0; mi < m.length; mi++) acc.add(m[mi]);
      }
      return;
    }
    if (Array.isArray(node)) { for (var i = 0; i < node.length; i++) collect(node[i], acc); return; }
    if (typeof node === 'object') { for (var k in node) collect(node[k], acc); }
  }
  S.collect = collect; // diagnostics: inspect what a config subtree yields

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
    // Escape each character. * is the only supported glob wildcard.
    var s = String(g), esc = '';
    for (var gi = 0; gi < s.length; gi++) {
      var ch = s.charAt(gi);
      if (ch === '*') esc += '.*';
      else if (/[a-zA-Z0-9_]/.test(ch)) esc += ch;
      else esc += '\\' + ch;
    }
    return new RegExp('^' + esc + '$');
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
    if (!R.attached || R.failed || R.all) { lift(); return; }
    var views = (cfg && cfg.views) || [], v = null;
    for (var i = 0; i < views.length; i++) {
      var vp = views[i].path != null ? String(views[i].path) : String(i);
      if (vp === view) { v = views[i]; break; }
    }
    if (!v) v = views[Number(view)] || null;
    if (!v) { lift(); return; } // unknown view -> do not filter
    var acc = new Set();
    collect(v.cards, acc); collect(v.badges, acc); collect(v.sections, acc);
    var autos = []; findAuto(v, autos);
    var hass = hassEl();
    for (var a = 0; a < autos.length; a++) {
      if (!hass || !expandAuto(autos[a], acc, hass)) { lift(); return; }
    }
    // The literal scan can match entity-id-shaped strings that are not
    // entities ("0.5em" from a card-mod style, "e.g" in prose). Keep only ids
    // the instance actually has; a to-be-created entity still gets through
    // later because its first appearance is an `a` add, which always passes.
    if (hass && hass.states) {
      var known = hass.states;
      acc.forEach(function (id) { if (!known[id]) acc.delete(id); });
    }
    // Runtime reads include calculated ids and missing entities that may
    // appear later. Rebuilding the config must retain these dependencies.
    R.ids.forEach(function (id) { acc.add(id); });
    // An empty allowlist would go stale EVERYWHERE on the view — a view whose
    // entities cannot be determined must pass through, not filter to nothing.
    if (!acc.size) { lift(); return; }
    // Voice Satellite's own device must never go stale, whatever view is on
    // screen: the card gates its whole wake pipeline on the satellite's
    // sibling select/switch entities (wake_word_detection, mute, wake_sound,
    // stop_word), and a page always boots while they read 'unavailable' (the
    // browser is disconnected until the card registers). Their real states
    // arrive as `c` updates moments later; dropping those leaves the card
    // reading wake detection as disabled and voice dead until a full refresh.
    try {
      var satId = localStorage.getItem('vs-satellite-entity');
      if (satId && hass && hass.entities) {
        acc.add(satId);
        var se = hass.entities[satId];
        var dev = se && se.device_id;
        if (dev) {
          for (var eid in hass.entities) {
            if (hass.entities[eid].device_id === dev) {
              acc.add(eid);
              // Some of the satellite's own entities POINT AT one somewhere
              // else — the TTS output select names the media_player the card
              // speaks through, and the card watches that player's state to
              // know when speech ended. It belongs to the Cast (or Sonos, or
              // DLNA) integration, so nothing above ever put it on the list,
              // and its updates were dropped: every remote-TTS turn hung
              // until the card's 30-second safety timeout gave up, firing
              // the done chime half a minute after the speaker went quiet.
              addTargets(hass.states[eid], acc);
            }
          }
        }
      }
    } catch (e) {}
    S.allow = acc;
    pushAdd(Array.from(acc)); // refresh this view's entities to current state
  }
  // Stop filtering for the current location. If an allowlist was active,
  // replay every entity from the shadow so the page catches up on all the
  // changes dropped while it was filtering (the same move setEnabled(false)
  // makes). Without the replay a Settings page arrives reading whatever
  // states it had when filtering started, and only a full app restart used
  // to fix that (issue #131).
  function lift() {
    var had = !!S.allow;
    S.built = true;
    S.allow = null;
    if (had) pushAdd(Object.keys(S.shadow));
  }
  function recompute() {
    runtimeView();
    watchRuntime();
    var hass = hassEl();
    if (!hass) { setTimeout(recompute, 500); return; }
    var l = loc();
    var epoch = R.epoch;
    // Non-dashboard panels (Settings, Developer tools, History, custom
    // panels like Voice Satellite's) carry no lovelace config, so filtering
    // there leaves the page stale (issue #131). The frontend already knows
    // what every path is: hass.panels maps the first segment to its panel,
    // and only lovelace panels are dashboards. Deciding here also spares the
    // server a doomed lovelace/config call on every Settings visit. When the
    // panel is unknown (or panels are not loaded yet), fall through to the
    // config request below, whose rejection lifts the filter anyway.
    var panel = (hass.panels || {})[l.dash];
    if (panel && panel.component_name !== 'lovelace') { lift(); return; }
    if (S.configCache[l.dash]) { build(S.configCache[l.dash], l.view); return; }
    try {
      hass.connection.sendMessagePromise({ type: 'lovelace/config', url_path: l.dash === 'lovelace' ? null : l.dash })
        .then(function (cfg) {
          S.configCache[l.dash] = cfg;
          if (S.enabled && epoch === R.epoch) build(cfg, l.view);
        })
        // Strategy dashboard etc. -> do not filter.
        .catch(function () { if (epoch === R.epoch) lift(); });
    } catch (e) { lift(); }
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
    if (!m) return;
    // Census of what this page subscribed to, for `__ksWs.stats().subs`.
    // Home Assistant drops a client that cannot keep up with its outgoing
    // queue, and by far the most expensive thing a page can ask for is the
    // raw `state_changed` firehose: every change with its complete old and
    // new state, uncompressed, for every entity in the instance — a stream
    // this filter cannot touch, since it only speaks the compressed
    // subscribe_entities format. Which subscription is doing that is
    // otherwise invisible from the device, so it is recorded here.
    if (typeof m.type === 'string' && m.type.lastIndexOf('subscribe_', 0) === 0 &&
        m.id != null) {
      S.subs[m.id] = m.type +
        (m.event_type ? ':' + m.event_type : '') +
        (m.entity_ids && m.entity_ids.length ? '(' + m.entity_ids.length + ')' : '');
    }
    if (m.type === 'unsubscribe_events' && m.subscription != null) {
      delete S.subs[m.subscription];
    }
    if (m.type === 'subscribe_entities' && m.id != null && S.subId == null &&
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
    if (!/\/api\/websocket\/?($|\?)/.test('' + url)) return ws;

    // New HA socket (fresh connect / reconnect): drop stale listeners and
    // re-learn the subscription id (haws re-subscribes with a new id). Keep
    // the shadow so a view switch right after a reconnect still refreshes.
    S.listeners = [];
    S.subId = null;
    // The census is per socket: a reconnect re-subscribes everything under
    // fresh command ids, and keeping the old ones would count every
    // subscription once more for every reconnect the page has lived through.
    S.subs = {};
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
  // HA may replace customElements with its scoped registry after injection.
  watchRuntime();
  document.addEventListener('DOMContentLoaded', watchRuntime, { once: true });
  window.addEventListener('load', watchRuntime, { once: true });
})();
''';
