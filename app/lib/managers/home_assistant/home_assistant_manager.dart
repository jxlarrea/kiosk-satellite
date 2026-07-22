import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding;

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/ha_http_overrides.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Home Assistant connection: long-lived-token auth, connection validation,
/// and the dashboard list used by the dashboard picker.
///
/// Later milestones add MQTT discovery publishing and HA event
/// subscriptions for event-driven navigation.
class HomeAssistantManager extends Manager {
  HomeAssistantManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'home_assistant';

  /// The Home Assistant origin — scheme, host and port, no path.
  ///
  /// Everything here builds on it: `/api/` for the REST checks, `/api/websocket`
  /// for media browsing and the screensaver. Home Assistant serves all of those
  /// from the origin, never under a dashboard path, so a setting of
  /// `https://ha.example/dashboard-x/0` (an easy paste of the address bar) must
  /// still resolve to `https://ha.example`. Falls back to the trimmed string if
  /// it will not parse.
  String get baseUrl {
    final url = _settings.get(defs.haUrl).trim();
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return uri.hasPort
          ? '${uri.scheme}://${uri.host}:${uri.port}'
          : '${uri.scheme}://${uri.host}';
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  bool get configured =>
      baseUrl.isNotEmpty && _settings.get(defs.haToken).isNotEmpty;

  /// Whether the configured connection has been proven this run. Never
  /// persisted — every app start revalidates, and both settings UIs hide
  /// the rest of the Home Assistant configuration until this holds.
  final connectionOk = ValueNotifier<bool>(false);

  /// Validate the connection and remember the verdict for the UIs.
  Future<String?> validateConnection() async {
    final error = await checkConnection();
    connectionOk.value = error == null;
    // The API side tolerates the self-signed certificate by policy (see
    // HaHttpOverrides); the WebView has its own trust stack, so when one
    // was actually seen, switch its setting on too — otherwise the wizard
    // validates but the dashboard page refuses to load.
    if (error == null &&
        HaHttpOverrides.sawSelfSigned &&
        !_settings.get(defs.ignoreSslErrors)) {
      log.info(
        name,
        'self-signed certificate accepted; enabling "Ignore SSL errors" '
        'for the browser',
      );
      await _settings.setFromJson(defs.ignoreSslErrors.key, true);
    }
    return error;
  }

  @override
  Future<void> init() async {
    // Startup validation: the kiosk boots either way (an offline HA must
    // not brick the tablet), but the settings gate stays shut until HA
    // actually answered once this run.
    if (configured) {
      unawaited(validateConnection());
    }
    // And the gate self-heals: when the tablet boots faster than the HA
    // server (a whole-house power cycle), the startup validation fails and
    // would otherwise stay false all run. Retry quietly until HA answers,
    // so the settings pages unlock without anyone tapping Validate. Idle
    // once the connection is good.
    _revalidateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (configured && !connectionOk.value) {
        unawaited(validateConnection());
      }
    });
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.haUrl.key || e.key == defs.haToken.key) {
        connectionOk.value = false;
      }
    });
    commands
      ..register(Command(
        name: 'haCheckConnection',
        description: 'Validate the Home Assistant URL and token',
        handler: (_) async {
          final error = await validateConnection();
          return error == null
              ? const CommandResult.ok()
              : CommandResult.fail(error);
        },
      ))
      ..register(Command(
        name: 'haStatus',
        description:
            'Whether Home Assistant is configured and this run\'s '
            'connection check passed.',
        handler: (_) async => CommandResult.ok({
          'configured': configured,
          'connected': connectionOk.value,
        }),
      ))
      ..register(Command(
        name: 'haDetectVoiceSatellite',
        description:
            'Whether the Voice Satellite integration is installed on the '
            'connected Home Assistant instance.',
        handler: (_) async => CommandResult.ok(await detectVoiceSatellite()),
      ))
      ..register(Command(
        name: 'applyVsRecommended',
        description:
            'Apply the recommended settings for a Voice Satellite kiosk: '
            'resilience, refresh, mixed content, mic, autoplay, boot '
            'start, keep-awake, wake word and remote management.',
        handler: (_) async {
          const recommended = <String, Object>{
            'browser.auto_reload_on_error': true,
            'browser.pull_to_refresh': true,
            'browser.pull_to_refresh_clear_cache': true,
            'browser.allow_mixed_content': true,
            'browser.ignore_ssl_errors': true,
            'web.microphone': true,
            'web.autoplay': true,
            'kiosk.start_on_boot': true,
            'screen.keep_on': true,
            'wake_word.enabled': true,
            'wake_word.background': true,
            'remote.enabled': true,
          };
          var applied = 0;
          for (final entry in recommended.entries) {
            if (await _settings.setFromJson(entry.key, entry.value)) {
              applied++;
            } else {
              log.warn(name, 'recommended setting rejected: ${entry.key}');
            }
          }
          return CommandResult.ok({'applied': applied});
        },
      ))
      ..register(Command(
        name: 'haListVoiceSatellites',
        description:
            'The assist_satellite entities the Voice Satellite '
            'integration provides.',
        handler: (_) async {
          final satellites = await listVoiceSatellites();
          return satellites == null
              ? const CommandResult.fail('could not list satellites')
              : CommandResult.ok(satellites);
        },
      ))
      ..register(Command(
        name: 'haListDashboards',
        description: 'List Home Assistant dashboards',
        handler: (_) async {
          final dashboards = await listDashboards();
          return dashboards == null
              ? const CommandResult.fail('could not list dashboards')
              : CommandResult.ok(dashboards);
        },
      ))
      ..register(Command(
        name: 'haListDashboardViews',
        description: "One dashboard's views, for the rotation picker",
        params: const {'url_path': "the dashboard's url_path"},
        handler: (p) async {
          final views = await listDashboardViews('${p['url_path'] ?? ''}');
          return views == null
              ? const CommandResult.fail('could not read the dashboard')
              : CommandResult.ok(views);
        },
      ))
      ..register(Command(
        name: 'haBrowseMedia',
        description: 'Browse a Home Assistant media node for the screensaver '
            'picker. Omit mediaContentId for the root of every media source.',
        params: const {'mediaContentId': 'media-source id, or omit for root'},
        handler: (p) async {
          final node = await browseMedia(p['mediaContentId'] as String?);
          return node == null
              ? const CommandResult.fail('could not browse media')
              : CommandResult.ok(node);
        },
      ));

    // Day/night theme. Re-assert on every full page load (login, logout,
    // reload all reset the frontend), react to schedule edits at once, and tick
    // once a minute to catch the scheduled switchover with no page load.
    bus.on<PageChanged>().listen((_) => _applyThemeSchedule(force: true));
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.themeAuto.key ||
          e.key == defs.themeAutoApp.key ||
          e.key == defs.themeDarkAt.key ||
          e.key == defs.themeLightAt.key) {
        _applyThemeSchedule(force: true);
      }
    });
    _themeTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _applyThemeSchedule());

    // Dashboard view rotation: an endless loop over the chosen dashboards.
    // Each setting applies as narrowly as possible — tuning from the remote
    // UI saves per change, and a full reconfigure on every keystroke made
    // the ring visibly restart while the user was still editing.
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.haRotationEnabled.key) {
        _configureRotation();
      } else if (e.key == defs.haRotationDashboards.key ||
          e.key == defs.haRotationUrls.key) {
        // Ring contents changed: restart from the top of the new list, but
        // never yank an active hold (touch pause, voice interaction) — the
        // new ring takes over when rotation resumes.
        _rotationIndex = -1;
        if (_rotationTimer != null) _armRotationTimer();
      } else if (e.key == defs.haRotationSeconds.key) {
        // New dwell time, same ring position.
        if (_rotationTimer != null) _armRotationTimer();
      }
      // haRotationPauseSeconds is read at pause time; nothing to rebuild.
    });
    // While the screensaver is up (or the app is not on screen) rotation
    // would navigate views nobody sees — and a strategy view's hard load
    // would churn the Voice Satellite session for nothing. The ring freezes
    // in place and picks up where it left off.
    bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
    });
    // Touch pauses rotation for the configured window so the current view
    // can be used; each touch restarts that window.
    bus.on<ActivityDetected>().listen((e) {
      if (e.source == 'touch') _pauseRotationForTouch();
    });
    // A voice interaction pauses rotation for its whole duration: Voice
    // Satellite drives VoiceInteractionChanged on both edges of the turn.
    bus.on<VoiceInteractionChanged>().listen((e) {
      _voiceInteracting = e.active;
      _voiceSafetyTimer?.cancel();
      if (e.active) {
        if (_rotationTimer != null) {
          log.info(
              name,
              'rotation paused by interaction'
              '${e.reason.isEmpty ? '' : ' (${e.reason})'}');
        }
        _rotationTimer?.cancel();
        _rotationTimer = null;
        // Reveal the dashboard (with the voice UI) if an external page was
        // up; the wake handler in the kiosk screen also does this, but the
        // interaction can begin without a fresh wake (a follow-up turn).
        unawaited(commands.execute('hideOverlayPage', const {}));
        // Never stay held forever if the "ended" signal is lost (a page
        // reload mid-turn, a Voice Satellite crash): release after a
        // generous ceiling.
        _voiceSafetyTimer = Timer(const Duration(minutes: 3), () {
          _voiceInteracting = false;
          _resumeRotationIfIdle();
        });
      } else {
        _resumeRotationIfIdle();
      }
    });
    _configureRotation();

    // "auto" kiosk mode needs to know up front whether the plugin exists so
    // the initial URL can carry ?kiosk. Detect before the kiosk screen builds.
    if (configured && _settings.get(defs.haKioskMode) == 'auto') {
      await detectKioskModePlugin();
    }
  }

  Timer? _rotationTimer;

  /// The slot last shown. -1 = none yet: the tick pre-increments, so the
  /// first navigation lands on the FIRST slot (0 here made it skip to the
  /// second, and the first view only ever appeared when the ring wrapped).
  int _rotationIndex = -1;

  Timer? _touchPauseTimer;
  Timer? _voiceSafetyTimer;
  bool _voiceInteracting = false;
  bool _screensaverActive = false;

  /// Dashboard paths a soft navigation cannot resolve (strategy dashboards,
  /// redirect aliases), learned once and then hard-loaded directly instead of
  /// re-discovering them with a spinner-then-reload every single pass.
  final Set<String> _hardLoadPaths = {};

  /// (Re)arm rotation from scratch: the enable toggle flipped.
  void _configureRotation() {
    _rotationIndex = -1;
    _touchPauseTimer?.cancel();
    _touchPauseTimer = null;
    if (!_settings.get(defs.haRotationEnabled)) {
      _rotationTimer?.cancel();
      _rotationTimer = null;
      // A lingering external page must not outlive the feature that put
      // it up.
      unawaited(commands.execute('hideOverlayPage', const {}));
      return;
    }
    // A voice interaction in progress keeps rotation held until it ends.
    if (_voiceInteracting) {
      log.info(name, 'view rotation enabled (held by voice interaction)');
    } else {
      _armRotationTimer();
      log.info(name, 'view rotation armed');
    }
  }

  /// (Re)start the interval countdown from now, without disturbing the
  /// current slot.
  void _armRotationTimer() {
    _rotationTimer?.cancel();
    final seconds = _settings
        .get(defs.haRotationSeconds)
        .toInt()
        .clamp(5, 86400);
    _rotationTimer = Timer.periodic(
      Duration(seconds: seconds),
      (_) => _rotationTick(),
    );
  }

  /// Touch pauses rotation for the configured window so the current view is
  /// usable; each touch restarts the window. Zero disables the pause (touch
  /// does not interrupt rotation). Never resumes over a live voice
  /// interaction — that pause outranks this one.
  void _pauseRotationForTouch() {
    if (!_settings.get(defs.haRotationEnabled)) return;
    final pause = _settings.get(defs.haRotationPauseSeconds).toInt();
    if (pause <= 0) return;
    _rotationTimer?.cancel();
    _rotationTimer = null;
    _touchPauseTimer?.cancel();
    log.info(name, 'rotation paused by touch (${pause}s)');
    _touchPauseTimer = Timer(Duration(seconds: pause), () {
      _touchPauseTimer = null;
      _resumeRotationIfIdle();
    });
  }

  /// Re-arm rotation only when nothing still wants it held: no live voice
  /// interaction and no pending touch-pause window.
  void _resumeRotationIfIdle() {
    if (!_settings.get(defs.haRotationEnabled)) return;
    if (_voiceInteracting || _touchPauseTimer != null) return;
    log.info(name, 'rotation resumed');
    _armRotationTimer();
  }

  List<String> _rotationPaths() {
    try {
      final list =
          jsonDecode(_settings.get(defs.haRotationDashboards)) as List;
      return [
        for (final p in list)
          if (p is String && p.isNotEmpty) p,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// External pages in the ring, shown in an overlay WebView so the
  /// dashboard (and Voice Satellite) stays loaded underneath.
  List<String> _rotationUrls() {
    try {
      final list = jsonDecode(_settings.get(defs.haRotationUrls)) as List;
      return [
        for (final u in list)
          if (u is String && u.isNotEmpty) u,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// The full ring: dashboard views first, then external pages, in the
  /// order the lists hold them.
  List<String> _rotationSlots() => [
    for (final p in _rotationPaths()) 'view:$p',
    for (final u in _rotationUrls()) 'url:$u',
  ];

  /// Advance to the next slot in the ring. A dashboard view navigates
  /// inside HA's SPA (pushState + location-changed, the same thing a
  /// card's navigate action does) so nothing reloads and the page stays
  /// warm; the script bails when something other than this HA instance is
  /// on screen — another site's history is not ours to rewrite. An
  /// external page shows in the overlay WebView instead, leaving the
  /// dashboard untouched below.
  Future<void> _rotationTick() async {
    // Nobody is looking: the screensaver is up, or the app is not on
    // screen. Skip WITHOUT advancing, so the ring freezes in place (and a
    // strategy view's hard load never churns the page while it is hidden).
    // lifecycleState is NULL until Android delivers the first transition
    // (i.e. for the whole first foreground session) — null means resumed.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (_screensaverActive ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    final slots = _rotationSlots();
    if (slots.isEmpty || baseUrl.isEmpty) return;
    _rotationIndex = (_rotationIndex + 1) % slots.length;
    final slot = slots[_rotationIndex];
    if (slot.startsWith('url:')) {
      await commands.execute('showOverlayPage', {
        'url': slot.substring('url:'.length),
      });
      return;
    }
    final viewPath = slot.substring('view:'.length);
    // A path a soft navigation cannot resolve goes straight to a full load
    // (loadUrl drops the overlay itself). One-time discovery below.
    if (_hardLoadPaths.contains(viewPath)) {
      await commands.execute('loadUrl', {'url': '$baseUrl/$viewPath'});
      return;
    }
    // With the secure context proxy on, the page lives on the loopback
    // origin, not baseUrl — guard against what is actually on screen.
    final mappedBase = await commands.execute('proxyMapUrl', {
      'url': baseUrl,
    });
    final effectiveBase = mappedBase.ok && mappedBase.data is String
        ? mappedBase.data as String
        : baseUrl;
    // Navigate the SPA FIRST — beneath any overlay — and only then reveal
    // the dashboard. Hiding first flashed the previous view for the beat
    // the soft navigation took.
    final js =
        '''
(function () {
  var base = ${jsonEncode(effectiveBase)};
  if (!location.href.startsWith(base)) return 'off-origin';
  var path = '/' + ${jsonEncode(viewPath)};
  if (location.pathname === path || location.pathname.indexOf(path + '/') === 0) return 'already';
  history.pushState(null, '', path);
  window.dispatchEvent(new CustomEvent('location-changed'));
  return 'navigated';
})();
''';
    final nav = await commands.execute('evalJs', {'code': js});
    await commands.execute('hideOverlayPage', const {});
    if (!nav.ok || '${nav.data}' != 'navigated') return;
    // Self-heal, once per path: a soft navigation cannot resolve every
    // dashboard — strategy dashboards (the auto "Overview") and redirect
    // aliases leave the panel spinning forever. If it is still spinning
    // shortly after the soft nav, remember the path as hard-load-only and
    // do the full load now; every later pass goes straight to loadUrl with
    // no spinner-then-reload double hit.
    final tickIndex = _rotationIndex;
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (_rotationTimer == null || _rotationIndex != tickIndex) return;
    final check = await commands.execute('evalJs', {
      'code': '''
(function () {
  try {
    if (location.pathname !== '/' + ${jsonEncode(viewPath)}) return false;
    var ha = document.querySelector('home-assistant');
    var main = ha && ha.shadowRoot && ha.shadowRoot.querySelector('home-assistant-main');
    var panel = main && main.shadowRoot && main.shadowRoot.querySelector('ha-panel-lovelace');
    if (!panel || !panel.shadowRoot) return false;
    // Unresolved = the panel never rendered a view root at all. Do NOT match
    // error cards: a view with one broken card is a rendered view, and
    // treating it as unresolved put a full reload in every rotation pass.
    return !panel.shadowRoot.querySelector('hui-root');
  } catch (e) { return false; }
})();
''',
    });
    if (check.ok && '${check.data}' == 'true') {
      _hardLoadPaths.add(viewPath);
      log.info(
          name,
          'rotation: "$viewPath" needs a full load (strategy dashboard or '
          'alias); remembering for future passes');
      await commands.execute('loadUrl', {'url': '$baseUrl/$viewPath'});
    }
  }

  Timer? _themeTimer;
  Timer? _revalidateTimer;

  /// The dark state last pushed to the page, so the minute tick only fires JS
  /// on an actual light↔dark transition. Cleared when the feature is off so
  /// re-enabling always re-applies.
  bool? _lastDark;

  /// Push the scheduled light/dark theme into the HA frontend when it changes.
  ///
  /// Mirrors what browser_mod's `set_theme` does — dispatch a `settheme` event
  /// on the `<home-assistant>` base element — but keeps the selected theme and
  /// only flips its dark variant. HA persists this per browser (localStorage),
  /// so it survives SPA navigation; we re-assert on full loads that reset it.
  Future<void> _applyThemeSchedule({bool force = false}) async {
    if (!_settings.get(defs.themeAuto)) {
      _lastDark = null;
      return;
    }
    final dark = _desiredDark(DateTime.now());
    if (!force && dark == _lastDark) return;
    _lastDark = dark;
    await commands.execute('evalJs', {'code': _themeJs(dark)});
    // The app's own theme follows the same clock when asked to. Through the
    // settings store, not directly: main.dart already listens for ui.theme
    // and applies it live, remote UI included.
    if (_settings.get(defs.themeAutoApp)) {
      final want = dark ? 'dark' : 'light';
      if (_settings.get(defs.uiTheme) != want) {
        await _settings.setFromJson(defs.uiTheme.key, want);
      }
    }
  }

  /// Whether [now] falls in the dark window between the two configured times.
  /// The usual case (dark 19:00 → light 07:00) wraps midnight.
  bool _desiredDark(DateTime now) {
    final darkAt = _parseMinutes(_settings.get(defs.themeDarkAt), 19 * 60);
    final lightAt = _parseMinutes(_settings.get(defs.themeLightAt), 7 * 60);
    if (darkAt == lightAt) return false;
    final t = now.hour * 60 + now.minute;
    return darkAt < lightAt
        ? (t >= darkAt && t < lightAt)
        : (t >= darkAt || t < lightAt);
  }

  int _parseMinutes(String hhmm, int fallback) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return fallback;
    }
    return h * 60 + m;
  }

  String _themeJs(bool dark) => '''
(function () {
  var base = document.querySelector('home-assistant');
  if (!base || !base.hass) return;
  var t = (base.hass.selectedTheme && base.hass.selectedTheme.theme)
      || (base.hass.themes && base.hass.themes.default_theme)
      || 'default';
  base.dispatchEvent(new CustomEvent('settheme',
      { detail: { theme: t, dark: $dark } }));
})();
''';

  bool? _kioskPlugin;

  /// Whether the kiosk-mode HACS plugin is installed on the connected HA
  /// instance (probes its static resource). Cached per app run. When present
  /// it is the preferred way to hide the header/sidebar — it tracks HA's DOM
  /// across releases, unlike our CSS fallback.
  bool get kioskPluginDetected => _kioskPlugin ?? false;

  Future<bool> detectKioskModePlugin() async {
    if (_kioskPlugin != null) return _kioskPlugin!;
    if (baseUrl.isEmpty) return false;
    try {
      final response = await http
          .head(Uri.parse('$baseUrl/hacsfiles/kiosk-mode/kiosk-mode.js'))
          .timeout(const Duration(seconds: 5));
      _kioskPlugin = response.statusCode == 200;
    } catch (_) {
      _kioskPlugin = false;
    }
    log.info(name, 'kiosk-mode plugin ${_kioskPlugin! ? 'detected' : 'absent'}');
    return _kioskPlugin!;
  }

  bool? _vsDetected;

  /// Whether the Voice Satellite integration is installed on the connected
  /// HA instance (probes its static frontend path). Cached per app run.
  Future<bool> detectVoiceSatellite() async {
    if (_vsDetected != null) return _vsDetected!;
    if (baseUrl.isEmpty) return false;
    try {
      final response = await http
          .head(Uri.parse('$baseUrl/voice_satellite/voice-satellite-card.js'))
          .timeout(const Duration(seconds: 5));
      _vsDetected = response.statusCode == 200;
    } catch (_) {
      _vsDetected = false;
    }
    if (_vsDetected!) log.info(name, 'Voice Satellite detected');
    return _vsDetected!;
  }

  /// Null when reachable and authorized, otherwise an error description.
  Future<String?> checkConnection() async {
    if (!configured) return 'Home Assistant URL and token not configured';
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/'),
        headers: {'Authorization': 'Bearer ${_settings.get(defs.haToken)}'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) return 'invalid token';
      if (response.statusCode != 200) return 'HTTP ${response.statusCode}';
      return null;
    } catch (e) {
      return 'unreachable: $e';
    }
  }

  /// The voice_satellite integration's assist_satellite entities, via the
  /// entity registry (the only place platform ownership is recorded).
  Future<List<Map<String, Object?>>?> listVoiceSatellites() async {
    if (!configured) return null;
    try {
      final result = await _wsCommand({'type': 'config/entity_registry/list'});
      if (result is! List) return null;
      // Registry names are usually null for these; the slug reads fine
      // once title-cased (living_room_tablet → Living Room Tablet).
      String prettify(String entityId) => entityId
          .split('.')
          .last
          .split('_')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
      final satellites = [
        for (final e in result.cast<Map>())
          if (e['platform'] == 'voice_satellite' &&
              (e['entity_id'] as String? ?? '').startsWith(
                'assist_satellite.',
              ))
            {
              'entity_id': e['entity_id'],
              'name':
                  e['name'] ??
                      e['original_name'] ??
                      prettify(e['entity_id'] as String),
            },
      ];
      satellites.sort(
        (a, b) => '${a['name']}'.compareTo('${b['name']}'),
      );
      return satellites;
    } catch (e) {
      log.warn(name, 'listVoiceSatellites failed: $e');
      return null;
    }
  }

  /// Dashboards via the websocket API (`lovelace/dashboards/list`), plus the
  /// default `lovelace` which the API does not include.
  Future<List<Map<String, Object?>>?> listDashboards() async {
    if (!configured) return null;
    // Source the list from the page's `hass.panels` — HA's own registry of
    // what the sidebar can navigate to. It is the only place that knows the
    // real default dashboard: modern Home Assistant ships an auto "Overview"
    // whose panel component is `home` (not `lovelace`) at a url like /home,
    // while /lovelace is a legacy redirect alias that a soft navigation
    // cannot follow. The old WS-only path hardcoded `lovelace` and so
    // offered that broken alias instead of the dashboard that actually
    // renders. Falls back to the WS list when the page has no hass yet.
    final page = await _dashboardsFromPage();
    if (page != null) return page;
    try {
      final result = await _wsCommand({'type': 'lovelace/dashboards/list'});
      if (result is! List) return null;
      return [
        {'url_path': 'lovelace', 'title': 'Default'},
        for (final d in result.cast<Map>())
          if (d['mode'] == 'storage')
            {'url_path': d['url_path'], 'title': d['title']},
      ];
    } catch (e) {
      log.warn(name, 'listDashboards failed: $e');
      return null;
    }
  }

  /// The navigable dashboards from the page's `hass.panels`: every Lovelace
  /// dashboard plus the auto "Overview" default (panel component `home`),
  /// each with the url the sidebar navigates to. Null when hass is not up.
  Future<List<Map<String, Object?>>?> _dashboardsFromPage() async {
    const js = r'''
(function () {
  try {
    var el = document.querySelector('home-assistant');
    var hass = el && el.hass;
    if (!hass || !hass.panels) return 'null';
    var panels = hass.panels;
    // The auto "Overview" default supersedes the empty /lovelace alias.
    var hasHome = Object.keys(panels).some(function (k) {
      return panels[k].component_name === 'home';
    });
    var out = [];
    Object.keys(panels).forEach(function (k) {
      var p = panels[k];
      var isDash = p.component_name === 'lovelace' || p.component_name === 'home';
      if (!isDash) return;
      if (p.url_path === 'lovelace' && p.title == null && hasHome) return;
      var title = p.title
        ? ((hass.localize && hass.localize('panel.' + p.title)) || p.title)
        : (p.component_name === 'home' ? 'Overview' : p.url_path);
      out.push({ url_path: p.url_path, title: title, comp: p.component_name });
    });
    // Default dashboard first, matching the sidebar: hass.defaultPanel when
    // set, otherwise the auto "Overview" (component `home`). The rest keep
    // their registration order.
    out.sort(function (a, b) {
      function rank(d) {
        if (hass.defaultPanel && d.url_path === hass.defaultPanel) return 0;
        if (d.comp === 'home') return 1;
        return 2;
      }
      return rank(a) - rank(b);
    });
    return JSON.stringify(out.map(function (d) {
      return { url_path: d.url_path, title: d.title };
    }));
  } catch (e) {
    return 'null';
  }
})()
''';
    try {
      final res = await commands.execute('evalJs', {'code': js});
      if (!res.ok) return null;
      final decoded = jsonDecode(res.data as String);
      if (decoded is! List || decoded.isEmpty) return null;
      return [
        for (final d in decoded.cast<Map>())
          {'url_path': d['url_path'], 'title': d['title']},
      ];
    } catch (_) {
      return null;
    }
  }

  /// The views of one dashboard (`lovelace/config`). Each entry carries
  /// `title` and `route` — the path segment HA navigates by: the view's
  /// declared path when it has one, its index otherwise. Null when the
  /// config cannot be read (auto-generated strategy dashboards store no
  /// view list).
  Future<List<Map<String, Object?>>?> listDashboardViews(
    String urlPath,
  ) async {
    if (!configured || urlPath.isEmpty) return null;
    try {
      final result = await _wsCommand({
        'type': 'lovelace/config',
        // The default dashboard is addressed by a null url_path.
        'url_path': urlPath == 'lovelace' ? null : urlPath,
      });
      if (result is! Map) return null;
      final views = result['views'];
      if (views is! List) return null;
      return [
        for (final (i, v) in views.cast<Map>().indexed)
          {'title': '${v['title'] ?? 'View ${i + 1}'}', 'route': '${v['path'] ?? i}'},
      ];
    } catch (e) {
      log.warn(name, 'listDashboardViews($urlPath) failed: $e');
      return null;
    }
  }

  /// Single authenticated websocket round-trip.
  /// Browse a Home Assistant media node (`media_source/browse_media`). Null
  /// [mediaContentId] is the root of every media source, including the
  /// synthetic `camera` source that lists camera entities. Returns the raw node
  /// (`title`, `media_content_id`, `can_play`, `can_expand`, `children`), or
  /// null on failure.
  Future<Map<String, Object?>?> browseMedia([String? mediaContentId]) async {
    if (!configured) return null;
    try {
      final result = await _wsCommand({
        'type': 'media_source/browse_media',
        if (mediaContentId != null) 'media_content_id': mediaContentId,
      });
      return result is Map ? result.cast<String, Object?>() : null;
    } catch (e) {
      log.warn(name, 'browseMedia failed: $e');
      return null;
    }
  }

  Future<Object?> _wsCommand(Map<String, Object?> command) async {
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final wsUrl = '$wsBase/api/websocket';
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    StreamSubscription<dynamic>? sub;
    try {
      final completer = Completer<Object?>();
      sub = channel.stream.listen((raw) {
        if (completer.isCompleted) return;
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        switch (msg['type']) {
          case 'auth_required':
            channel.sink.add(jsonEncode({
              'type': 'auth',
              'access_token': _settings.get(defs.haToken),
            }));
          case 'auth_ok':
            channel.sink.add(jsonEncode({'id': 1, ...command}));
          case 'auth_invalid':
            completer.completeError(StateError('auth invalid'));
          case 'result':
            if (msg['success'] == true) {
              completer.complete(msg['result']);
            } else {
              completer.completeError(StateError('${msg['error']}'));
            }
        }
      }, onError: (Object e, StackTrace s) {
        // Guarded: an error after the result (or a second result frame)
        // must not throw "Future already completed" into the stream zone.
        if (!completer.isCompleted) completer.completeError(e, s);
      });

      return await completer.future.timeout(
        const Duration(seconds: 10),
      );
    } finally {
      await sub?.cancel();
      await channel.sink.close();
    }
  }

  @override
  Future<void> dispose() async {
    _themeTimer?.cancel();
    _revalidateTimer?.cancel();
    _rotationTimer?.cancel();
    _touchPauseTimer?.cancel();
    _voiceSafetyTimer?.cancel();
  }
}
