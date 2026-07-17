import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;

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

    // "auto" kiosk mode needs to know up front whether the plugin exists so
    // the initial URL can carry ?kiosk. Detect before the kiosk screen builds.
    if (configured && _settings.get(defs.haKioskMode) == 'auto') {
      await detectKioskModePlugin();
    }
  }

  Timer? _themeTimer;

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
    try {
      final completer = Completer<Object?>();
      late StreamSubscription<dynamic> sub;
      sub = channel.stream.listen((raw) {
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
      }, onError: completer.completeError);

      final result = await completer.future.timeout(
        const Duration(seconds: 10),
      );
      await sub.cancel();
      return result;
    } finally {
      await channel.sink.close();
    }
  }

  @override
  Future<void> dispose() async {
    _themeTimer?.cancel();
  }
}
