import 'dart:async';
import 'dart:convert';

import 'dart:ui' show Brightness;

import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/ha_http_overrides.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../browser/rotation_fade_script.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'custom_pages.dart';
import 'dashboard_list.dart';
import 'entity_list.dart';
import 'plugin_entities.dart';
import 'package:kiosk_satellite/core/lifecycle.dart';

/// Home Assistant connection: long-lived-token auth, connection validation,
/// and the dashboard list used by the dashboard picker.
class HomeAssistantManager extends Manager {
  HomeAssistantManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this._holdReleaseUnit = const Duration(minutes: 1),
  });

  final SettingsManager _settings;
  late final _pluginEntities = HaPluginEntities(
    baseUrl: () => baseUrl,
    token: () => _settings.get(defs.haToken),
    emit: (owner, id, state) => bus.publish(
      owner == '__remote_voice'
          ? const RemoteStatusChanged('voice')
          : PluginHaStateChanged(owner, id, state),
    ),
  );

  /// One "minute" of the hold auto-release clock; injectable so tests can
  /// shrink it (the screensaver's screenOffUnit pattern).
  final Duration _holdReleaseUnit;

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
    // Only this check's own handshake counts. The flag is process-wide, so
    // a certificate refused earlier in the run (an older HA URL behind a
    // private CA) would otherwise flip the setting back on with every
    // validation of a host that verifies fine (issue #776).
    HaHttpOverrides.sawSelfSigned = false;
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

  bool _remoteVoiceObserved = false;
  Set<String> _remoteVoiceIds = {};
  StreamSubscription<RemoteObserversChanged>? _remoteObservers;

  @override
  Future<void> init() async {
    _remoteObservers = bus.on<RemoteObserversChanged>().listen((event) {
      _remoteVoiceObserved = event.topics.contains('voice');
      if (!_remoteVoiceObserved) {
        _pluginEntities.unwatch('__remote_voice', null);
        _remoteVoiceIds.clear();
      } else {
        _watchRemoteVoice();
      }
    });
    connectionOk.addListener(() {
      bus.publish(const RemoteStatusChanged('ha'));
      if (connectionOk.value) unawaited(_leaveDashboardRuntime());
    });
    commands.register(
      Command(
        name: 'haPluginReadEntity',
        description: 'Read a selected HA entity for the plugin SDK.',
        quiet: true,
        handler: (p) async {
          if (!HaPluginEntities.validId(p['entityId'])) {
            return const CommandResult.fail('Invalid entity ID');
          }
          return CommandResult.ok(
            await _pluginEntities.read(p['entityId'] as String),
          );
        },
      ),
    );
    commands.register(
      Command(
        name: 'haPluginWatchEntity',
        description: 'Observe a selected HA entity for a plugin session.',
        quiet: true,
        handler: (p) async {
          if (p['owner'] is! String ||
              !HaPluginEntities.validId(p['entityId'])) {
            return const CommandResult.fail('Invalid entity subscription');
          }
          _pluginEntities.watch(p['owner'] as String, p['entityId'] as String);
          return const CommandResult.ok();
        },
      ),
    );
    commands.register(
      Command(
        name: 'haPluginUnwatchEntity',
        description: 'Release HA entity subscriptions for a plugin session.',
        quiet: true,
        handler: (p) async {
          if (p['owner'] is! String) {
            return const CommandResult.fail('Invalid entity subscription');
          }
          _pluginEntities.unwatch(
            p['owner'] as String,
            p['entityId'] as String?,
          );
          return const CommandResult.ok();
        },
      ),
    );
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
        _pluginEntities.restart();
        connectionOk.value = false;
        // Another server may speak another language.
        _language = null;
        _stateTranslations.clear();
        _stateLabels.clear();
      }
    });
    commands
      ..register(
        Command(
          name: 'haCheckConnection',
          description: 'Validate the Home Assistant URL and token',
          handler: (_) async {
            final error = await validateConnection();
            return error == null
                ? const CommandResult.ok()
                : CommandResult.fail(error);
          },
        ),
      )
      ..register(
        Command(
          name: 'haStatus',
          description:
              'Whether Home Assistant is configured and this run\'s '
              'connection check passed.',
          handler: (_) async => CommandResult.ok({
            'configured': configured,
            'connected': connectionOk.value,
          }),
        ),
      )
      ..register(
        Command(
          name: 'haDetectVoiceSatellite',
          description:
              'Whether the Voice Satellite integration is installed on the '
              'connected Home Assistant instance.',
          handler: (_) async => CommandResult.ok(await detectVoiceSatellite()),
        ),
      )
      ..register(
        Command(
          name: 'applyVsRecommended',
          description:
              'Apply the recommended settings for a Voice Satellite kiosk: '
              'resilience, refresh, mixed content, mic, autoplay, boot '
              'start, keep-awake, wake word, remote management and the '
              'dashboard optimizations.',
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
              'browser.disable_suspend': true,
              'browser.freeze_on_screensaver': true,
              'browser.ws_filter': true,
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
        ),
      )
      ..register(
        Command(
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
        ),
      )
      ..register(
        Command(
          name: 'haListServices',
          description:
              'Every service once, for the service picker: name, domain '
              'and its title, icon and the entity domains it acts on.',
          params: const {
            'icons':
                'true to add icon_path, the SVG path of each icon, for '
                "the remote admin's service picker",
          },
          handler: (p) async {
            final services = await listServices();
            if (services == null) {
              return const CommandResult.fail('could not list services');
            }
            return CommandResult.ok(
              p['icons'] == true ? await withIconPaths(services) : services,
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'haListEntities',
          description:
              'Every entity once, for the entity picker: name, formatted '
              'state, icon, domain and its title, area.',
          params: const {
            'domains': 'optional list of domains to keep',
            'device_class':
                'optional device class to keep (illuminance also takes '
                'readings in lux, occupancy also takes motion and presence '
                'binary sensors)',
            'icons':
                'true to add icon_path, the SVG path of each icon, for '
                "the remote admin's entity picker",
          },
          handler: (p) async {
            final entities = await listEntities(
              domains: [
                if (p['domains'] is List)
                  for (final d in p['domains'] as List) '$d',
              ],
              deviceClass: p['device_class'] as String?,
            );
            if (entities == null) {
              return const CommandResult.fail('could not list entities');
            }
            return CommandResult.ok(
              p['icons'] == true ? await withIconPaths(entities) : entities,
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'haSearchEntities',
          description:
              'Search entities by id or friendly name, for the At a Glance '
              'picker. Returns at most 50, closest matches first.',
          params: const {
            'query': 'text to match against id and name',
            'filter':
                'optional: illuminance keeps only light level sensors (an '
                'empty query then lists them all)',
          },
          handler: (p) async {
            final matches = await searchEntities(
              '${p['query'] ?? ''}',
              filter: p['filter'] as String?,
            );
            return matches == null
                ? const CommandResult.fail('could not list entities')
                : CommandResult.ok(matches);
          },
        ),
      )
      ..register(
        Command(
          name: 'haEntityAttributes',
          description:
              "One entity's current attributes, for the At a Glance "
              'attribute picker.',
          params: const {'entity_id': 'the entity to read'},
          handler: (p) async {
            final attributes = await fetchEntityAttributes(
              '${p['entity_id'] ?? ''}',
            );
            return attributes == null
                ? const CommandResult.fail('could not read the entity')
                : CommandResult.ok(attributes);
          },
        ),
      )
      ..register(
        Command(
          name: 'haListDashboards',
          description: 'List Home Assistant dashboards',
          params: const {
            'source':
                "'page' to read only the page's own registry, failing "
                'rather than falling back to the websocket list',
            'icons':
                'true to add icon_path, the SVG path of each icon, for '
                "the remote admin's dashboard picker",
          },
          handler: (p) async {
            final dashboards = await listDashboards(
              pageOnly: p['source'] == 'page',
            );
            if (dashboards == null) {
              return const CommandResult.fail('could not list dashboards');
            }
            return CommandResult.ok(
              p['icons'] == true ? await withIconPaths(dashboards) : dashboards,
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'haListDashboardViews',
          description: "One dashboard's views, for the dashboard picker",
          params: const {
            'url_path': "the dashboard's url_path",
            'icons': 'true to add icon_path, as haListDashboards does',
          },
          handler: (p) async {
            final views = await listDashboardViews('${p['url_path'] ?? ''}');
            if (views == null) {
              return const CommandResult.fail('could not read the dashboard');
            }
            return CommandResult.ok(
              p['icons'] == true ? await withIconPaths(views) : views,
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'haSaveCustomPage',
          description:
              'Add or change a custom page after checking that Home '
              'Assistant or its own server serves it. Backs Save & Validate '
              'in the Custom Pages editors on both settings surfaces.',
          params: const {
            'name': 'the name the pickers show',
            'path':
                'the path under /local/, such as /local/kitchen.html, or '
                'the http or https URL of a page on another server',
            'original':
                'optional: the path of the page being changed, absent '
                'for a new one',
          },
          handler: (p) async {
            final error = await saveCustomPage(
              name: '${p['name'] ?? ''}',
              path: '${p['path'] ?? ''}',
              original: p['original'] is String
                  ? p['original'] as String
                  : null,
            );
            return error == null
                ? const CommandResult.ok()
                : CommandResult.fail(error);
          },
        ),
      )
      ..register(
        Command(
          name: 'haRemoveCustomPage',
          description: 'Remove a custom page from the list.',
          params: const {'path': 'the stored path of the page'},
          handler: (p) async {
            final path = '${p['path'] ?? ''}';
            final pages = customPages;
            if (!pages.any((e) => e.path == path)) {
              return const CommandResult.fail('no such page');
            }
            await _settings.setFromJson(
              defs.haCustomPages.key,
              encodeCustomPages([
                for (final e in pages)
                  if (e.path != path) e,
              ]),
            );
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'haNavigate',
          description:
              'Navigate the kiosk to a dashboard view path, dismissing the '
              'screensaver and any overlays so the view is actually seen.',
          params: const {'path': 'the navigation path ("url_path/view-route")'},
          handler: (p) async {
            final path = normalizeViewPath('${p['path'] ?? ''}');
            if (path.isEmpty) return const CommandResult.fail('no path');
            if (!configured) {
              return const CommandResult.fail('Home Assistant not configured');
            }
            await commands.execute('stopScreensaver', const {});
            await commands.execute('hideCameraView', const {});
            // A commanded view should not instantly rotate away: give it the
            // same grace window a touch gets.
            if (_rotationTimer != null) _pauseRotationForTouch();
            // The outcome travels in the result so the ESPHome select knows
            // whether the page actually moved before echoing state.
            return CommandResult.ok(await navigateToViewPath(path));
          },
        ),
      )
      ..register(
        Command(
          name: 'showScreensaverDashboard',
          description:
              'Move the dashboard to the Home Assistant Dashboard '
              "screensaver's view, remembering where it was. Called by the "
              'screensaver as the mode comes up.',
          params: const {'path': 'the navigation path ("url_path/view-route")'},
          handler: (p) async {
            await showScreensaverDashboard(
              '${p['path'] ?? ''}'.trim().replaceAll(RegExp(r'^/+|/+$'), ''),
            );
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'leaveScreensaver',
          description:
              'Move the dashboard to where the screensaver dismissal lands: '
              'the Now Playing target, back from the Home Assistant '
              'Dashboard screensaver, or home. Called by the screensaver as '
              'it ends.',
          params: const {
            'nowPlaying': 'true when the session showed Now Playing',
          },
          handler: (p) async {
            await leaveScreensaver(nowPlaying: p['nowPlaying'] == true);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'haPauseRotation',
          description:
              'Hold dashboard view rotation on the current page for the '
              'touch pause window, as a touch would.',
          handler: (_) async {
            _pauseRotationForTouch();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'haCallService',
          description:
              'Call a Home Assistant service (covers scripts, scenes and '
              'automation triggers). data is the service data object.',
          params: const {
            'domain': 'service domain, e.g. light',
            'service': 'service name, e.g. turn_on',
            'entity_id': 'optional target entity',
            'data': 'optional service data (JSON object)',
          },
          handler: (p) async {
            final domain = '${p['domain'] ?? ''}'.trim();
            final service = '${p['service'] ?? ''}'.trim();
            if (domain.isEmpty || service.isEmpty) {
              return const CommandResult.fail('domain and service required');
            }
            if (!configured) {
              return const CommandResult.fail('Home Assistant not configured');
            }
            final entity = '${p['entity_id'] ?? ''}'.trim();
            final data = p['data'];
            try {
              await _wsCommand({
                'type': 'call_service',
                'domain': domain,
                'service': service,
                if (data is Map) 'service_data': data,
                if (entity.isNotEmpty) 'target': {'entity_id': entity},
              });
              log.info(name, 'called $domain.$service');
              return const CommandResult.ok();
            } catch (e) {
              return CommandResult.fail('$domain.$service failed: $e');
            }
          },
        ),
      )
      ..register(
        Command(
          name: 'haValidateAction',
          description:
              'Check that a service (and an optional entity) exists in Home '
              'Assistant. Backs the Validate button in the gesture editors.',
          params: const {
            'domain': 'service domain to check, e.g. light',
            'service': 'service name to check, e.g. turn_on',
            'entity_id': 'optional entity to check',
          },
          handler: (p) async {
            final domain = '${p['domain'] ?? ''}'.trim();
            final service = '${p['service'] ?? ''}'.trim();
            final entity = '${p['entity_id'] ?? ''}'.trim();
            if (!configured) {
              return const CommandResult.fail('Home Assistant not configured');
            }
            try {
              final results = <String, Object?>{};
              if (domain.isNotEmpty) {
                final services = await _wsCommand({'type': 'get_services'});
                final domainMap = services is Map ? services[domain] : null;
                results['domain'] = domainMap != null;
                results['service'] =
                    domainMap is Map && domainMap.containsKey(service);
              }
              if (entity.isNotEmpty) {
                final response = await http
                    .get(
                      Uri.parse('$baseUrl/api/states/$entity'),
                      headers: {
                        'Authorization':
                            'Bearer ${_settings.get(defs.haToken)}',
                      },
                    )
                    .timeout(const Duration(seconds: 10));
                results['entity'] = response.statusCode == 200;
              }
              return CommandResult.ok(results);
            } catch (e) {
              return CommandResult.fail('validation failed: $e');
            }
          },
        ),
      )
      ..register(
        Command(
          name: 'haFireEvent',
          description:
              'Fire an event on the Home Assistant event bus, for automations '
              'to listen to.',
          params: const {
            'event': 'event type, e.g. kiosk_satellite_gesture',
            'data': 'optional event data (JSON object)',
          },
          handler: (p) async {
            final event = '${p['event'] ?? ''}'.trim();
            if (event.isEmpty) {
              return const CommandResult.fail('event required');
            }
            if (!configured) {
              return const CommandResult.fail('Home Assistant not configured');
            }
            final data = p['data'];
            try {
              await _wsCommand({
                'type': 'fire_event',
                'event_type': event,
                if (data is Map) 'event_data': data,
              });
              log.info(name, 'fired event $event');
              return const CommandResult.ok();
            } catch (e) {
              return CommandResult.fail('firing $event failed: $e');
            }
          },
        ),
      )
      ..register(
        Command(
          name: 'haBrowseMedia',
          description:
              'Browse a Home Assistant media node for the screensaver '
              'picker. Omit mediaContentId for the root of every media source.',
          params: const {'mediaContentId': 'media-source id, or omit for root'},
          handler: (p) async {
            final node = await browseMedia(p['mediaContentId'] as String?);
            return node == null
                ? const CommandResult.fail('could not browse media')
                : CommandResult.ok(node);
          },
        ),
      )
      ..register(
        Command(
          name: 'vsControls',
          description:
              'Everything the Voice Satellite settings page controls: the '
              'satellite binding, its sibling select entities (pipelines, '
              'wake word engine and models) with current values and '
              'options, and the browser-local appearance settings from the '
              'page.',
          handler: (_) async {
            if (!configured) {
              return const CommandResult.fail('Home Assistant not configured');
            }
            return CommandResult.ok(await vsControlsSnapshot());
          },
        ),
      )
      ..register(
        Command(
          name: 'vsSetBrowserSettings',
          description:
              'Change the browser-local Voice Satellite settings (auto '
              'start, muted microphone warning, debug logging, skin, theme '
              'mode, reactive bar, text scale) through '
              'the page hook, which persists them to the Home Assistant '
              'panel profile and applies them live.',
          params: const {'settings': 'partial config object'},
          handler: (p) async {
            final settings = p['settings'];
            if (settings is! Map || settings.isEmpty) {
              return const CommandResult.fail('settings object required');
            }
            final code =
                'JSON.stringify(window.__vsExternalSettings '
                '? window.__vsExternalSettings.apply(${jsonEncode(settings)}) '
                ': null)';
            final result = await commands.execute('evalJs', {'code': code});
            final data = result.ok ? result.data : null;
            if (data is String && data.isNotEmpty && data != 'null') {
              return CommandResult.ok(jsonDecode(data));
            }
            return const CommandResult.fail(
              'the page has no Voice Satellite settings hook — the kiosk '
              'must be showing Home Assistant with a current Voice '
              'Satellite version',
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'vsEngineState',
          description:
              'What the page reports about Voice Satellite right now: '
              'whether the engine is running, whether it could start, the '
              'satellite it is bound to and the browser-local settings. '
              'One evaluation in the page, where vsControls also walks the '
              'Home Assistant registry.',
          handler: (_) async {
            final result = await commands.execute('evalJs', {
              'code':
                  'JSON.stringify(window.__vsExternalSettings '
                  '? window.__vsExternalSettings.get() : null)',
            });
            final data = result.ok ? result.data : null;
            if (data is String && data.isNotEmpty && data != 'null') {
              final decoded = jsonDecode(data);
              if (decoded is Map) {
                // The skin catalog is for pickers; callers of this command
                // want the state, and it is the bulky half of the answer.
                decoded.remove('skins');
                return CommandResult.ok(decoded);
              }
            }
            return const CommandResult.fail(
              'the page has no Voice Satellite settings hook — the kiosk '
              'must be showing Home Assistant with a current Voice '
              'Satellite version',
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'vsEngine',
          description:
              'Start or stop the Voice Satellite engine in the page, '
              "through the same path as the panel's own Start and Stop "
              'buttons.',
          params: const {'action': "'start' or 'stop'"},
          handler: (p) async {
            final action = '${p['action'] ?? ''}'.trim();
            if (action != 'start' && action != 'stop') {
              return const CommandResult.fail('action must be start or stop');
            }
            final fn = action == 'start' ? 'startEngine' : 'stopEngine';
            final code =
                'JSON.stringify(window.__vsExternalSettings '
                '? window.__vsExternalSettings.$fn() : null)';
            final result = await commands.execute('evalJs', {'code': code});
            final data = result.ok ? result.data : null;
            if (data is String && data.isNotEmpty && data != 'null') {
              return CommandResult.ok(jsonDecode(data));
            }
            return const CommandResult.fail(
              'the page has no Voice Satellite settings hook — the kiosk '
              'must be showing Home Assistant with a current Voice '
              'Satellite version',
            );
          },
        ),
      )
      ..register(
        Command(
          name: 'vsSetSatellite',
          description:
              'Rebind this kiosk to another assist_satellite entity, or '
              'clear the binding with an empty entity_id: rewrites the '
              'page binding, keeps the app fallback in step, and reloads '
              'the page so Voice Satellite renegotiates.',
          params: const {'entity_id': 'the assist_satellite entity, or empty'},
          handler: (p) async {
            final entity = '${p['entity_id'] ?? ''}'.trim();
            if (entity.isNotEmpty && !entity.startsWith('assist_satellite.')) {
              return const CommandResult.fail(
                'an assist_satellite entity is required',
              );
            }
            if (entity.isEmpty) {
              // Clearing must hit both halves of the page binding: the
              // dedicated key and the panel-config copy resolveEntity
              // falls back to, which would otherwise revive it.
              await commands.execute('evalJs', {
                'code': '''
(function () {
  localStorage.removeItem('vs-satellite-entity');
  try {
    var raw = localStorage.getItem('vs-panel-config');
    if (raw) {
      var cfg = JSON.parse(raw);
      delete cfg.satellite_entity;
      localStorage.setItem('vs-panel-config', JSON.stringify(cfg));
    }
  } catch (e) {}
})()''',
              });
            } else {
              await commands.execute('evalJs', {
                'code':
                    "localStorage.setItem('vs-satellite-entity', "
                    '${jsonEncode(entity)})',
              });
            }
            // The engine binds the satellite at start, so the page must
            // come back up for the renegotiation (profile hydration
            // included; a cleared binding leaves the engine dormant).
            // When the fallback setting changes, the kiosk screen
            // rebuilds the WebView so the seed user script is fresh — a
            // plain reload would re-run the stale one and undo a clear.
            final previous = _settings.get(defs.haSatelliteEntity).trim();
            await _settings.setFromJson(defs.haSatelliteEntity.key, entity);
            if (previous == entity) {
              await commands.execute('reload', const {});
            }
            return const CommandResult.ok();
          },
        ),
      );

    // Day/night theme. Re-assert on every full page load (login, logout,
    // reload all reset the frontend), react to schedule edits at once, and tick
    // once a minute to catch the scheduled switchover with no page load.
    bus.on<PageChanged>().listen((_) => _applyThemeSchedule(force: true));
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.haTheme.key ||
          e.key == defs.themeAuto.key ||
          e.key == defs.themeAutoApp.key ||
          e.key == defs.themeMatchApp.key ||
          e.key == defs.uiTheme.key ||
          e.key == defs.themeDarkAt.key ||
          e.key == defs.themeLightAt.key) {
        _applyThemeSchedule(force: true);
      }
    });
    _themeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _applyThemeSchedule(),
    );
    // Android flips its own dark mode on its schedule (typically sunset and
    // sunrise); with the theme mirror on and the App theme on System, that
    // flip is the theme source (issue #92) and must reach the dashboard the
    // moment it lands, not on the next minute tick.
    WidgetsBinding.instance.addObserver(_brightnessWatch);

    // Dashboard view rotation: an endless loop over the chosen dashboards.
    // Each setting applies as narrowly as possible — tuning from the remote
    // UI saves per change, and a full reconfigure on every keystroke made
    // the ring visibly restart while the user was still editing.
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.haRotationEnabled.key) {
        // Rotation and the return-home timer both want to own navigation
        // on an idle kiosk: turning rotation on forces the return off
        // (issue #83), and both UIs render its switch disabled meanwhile.
        if (e.value == true && _settings.get(defs.haReturnHomeEnabled)) {
          log.info(name, 'rotation on: return to the dashboard turned off');
          unawaited(_settings.set(defs.haReturnHomeEnabled, false));
        }
        _configureRotation();
        _configureReturnHome();
      } else if (e.key == defs.haReturnHomeEnabled.key ||
          e.key == defs.haReturnHomeSeconds.key) {
        _configureReturnHome();
      } else if (e.key == defs.haHoldMode.key ||
          e.key == defs.haHoldReleaseMinutes.key) {
        // Hold mode (issue #266): the return-home clock stands down while
        // it is on, and the optional auto-release clock follows the toggle
        // (moving the slider mid-hold restarts the countdown at the new
        // value). Rotation needs no rebuild: its tick checks hold live and
        // freezes in place, resuming on the next tick after release.
        _configureHoldRelease();
        _configureReturnHome();
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
      // Pause duration is read at pause time. Fade settings are read on
      // each navigation, so changes need no timer rebuild.
    });
    // While the screensaver is up (or the app is not on screen) rotation
    // would navigate views nobody sees — and a strategy view's hard load
    // would churn the Voice Satellite session for nothing. The ring freezes
    // in place and picks up where it left off.
    bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      if (e.active) {
        _returnHomeTimer?.cancel();
        _returnHomeTimer = null;
        unawaited(_onScreensaverStart(nowPlaying: e.nowPlaying));
      } else {
        // The touch that dismissed the screensaver gets its grace window
        // now, once the dashboard is back in view. The stop lands a few
        // awaits after the touch, so anything older than that was a
        // control press that left the screensaver up.
        final touched = _touchUnderScreensaverAt;
        _touchUnderScreensaverAt = null;
        if (touched != null &&
            DateTime.now().difference(touched) < _dismissTouchWindow) {
          _pauseRotationForTouch();
        }
        _configureReturnHome();
      }
    });
    // Touch pauses rotation for the configured window so the current view
    // can be used; each touch restarts that window. Under the screensaver
    // there is no view to keep usable (the ring is already frozen in
    // place, see _rotationTick), so a touch there, a Now Playing control
    // press, only leaves a timestamp for the dismissal above.
    bus.on<ActivityDetected>().listen((e) {
      if (e.source == 'touch') {
        if (_screensaverActive) {
          _touchUnderScreensaverAt = DateTime.now();
        } else {
          _pauseRotationForTouch();
        }
      }
      _configureReturnHome();
    });
    // Any navigation counts as activity for the return-home clock: the
    // user moving through views is exactly the "in use" it must not
    // interrupt (our own return resets it too, harmlessly).
    bus.on<UrlChanged>().listen((_) => _configureReturnHome());
    // A voice interaction pauses rotation for its whole duration: Voice
    // Satellite drives VoiceInteractionChanged on both edges of the turn.
    // Media playback is not one: music from Sendspin or the page plays
    // behind whatever is on screen, so rotation and the return to home
    // clock run on through it. (Holding them here never worked past the
    // safety ceiling below anyway: a song outlives 3 minutes, a turn does
    // not.) The screensaver keeps its own hold for audible media.
    bus.on<VoiceInteractionChanged>().listen((e) {
      if (e.reason == 'media') return;
      _voiceInteracting = e.active;
      _voiceSafetyTimer?.cancel();
      if (e.active) {
        if (_rotationTimer != null) {
          log.info(
            name,
            'rotation paused by interaction'
            '${e.reason.isEmpty ? '' : ' (${e.reason})'}',
          );
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
          _configureReturnHome();
        });
      } else {
        _resumeRotationIfIdle();
      }
      _configureReturnHome();
    });
    bus.on<CameraViewStateChanged>().listen((event) {
      _cameraViewActive = event.active;
      if (event.active) {
        _rotationTimer?.cancel();
        _rotationTimer = null;
        unawaited(commands.execute('hideOverlayPage', const {}));
      } else {
        _resumeRotationIfIdle();
      }
      _configureReturnHome();
    });
    _configureRotation();
    _configureReturnHome();
    // A hold that survived a restart (the setting persists on purpose)
    // gets its auto-release clock back too.
    _configureHoldRelease();
  }

  Timer? _rotationTimer;

  /// The slot last shown. -1 = none yet: the tick pre-increments, so the
  /// first navigation lands on the FIRST slot (0 here made it skip to the
  /// second, and the first view only ever appeared when the ring wrapped).
  int _rotationIndex = -1;

  Timer? _touchPauseTimer;
  Timer? _voiceSafetyTimer;
  bool _voiceInteracting = false;
  bool _cameraViewActive = false;
  bool _screensaverActive = false;

  /// When the last touch under the screensaver arrived, so the one that
  /// dismisses it can still earn the touch pause once the dashboard shows.
  DateTime? _touchUnderScreensaverAt;

  /// How long after a touch a screensaver stop still counts as dismissed
  /// by it. The stop runs a handful of awaited commands first, well under
  /// a second on a healthy device.
  static const _dismissTouchWindow = Duration(seconds: 5);

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
    if (_voiceInteracting || _cameraViewActive || _touchPauseTimer != null) {
      return;
    }
    log.info(name, 'rotation resumed');
    _armRotationTimer();
  }

  List<String> _rotationPaths() {
    try {
      final list = jsonDecode(_settings.get(defs.haRotationDashboards)) as List;
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
    // Off screen by the lifecycle, which is null for the whole first
    // foreground session and inactive on a return without the input
    // focus: both count as on screen (see Lifecycle).
    if (_screensaverActive || _holdActive || !Lifecycle.onScreen) return;
    final slots = _rotationSlots();
    if (slots.isEmpty || baseUrl.isEmpty) return;
    // The crossfade needs the outgoing view visible: after an external
    // page's slot the dashboard sits covered (and frozen) under the
    // overlay, so that step cuts - the overlay teardown is a cut anyway.
    final prevWasUrl =
        _rotationIndex >= 0 &&
        _rotationIndex < slots.length &&
        slots[_rotationIndex].startsWith('url:');
    _rotationIndex = (_rotationIndex + 1) % slots.length;
    final slot = slots[_rotationIndex];
    if (slot.startsWith('url:')) {
      await commands.execute('showOverlayPage', {
        'url': slot.substring('url:'.length),
      });
      return;
    }
    await navigateToViewPath(
      slot.substring('view:'.length),
      crossfade: _settings.get(defs.haRotationCrossfade) && !prevWasUrl,
    );
  }

  // ── Return to the dashboard (issue #83) ─────────────────────────────
  // An independent idle clock, deliberately not the screensaver's: it must
  // work with the screensaver off or set long. Reset by touch, navigation
  // and voice; held while a voice turn or camera view runs; and handed to
  // the screensaver when that fires first (the return then happens behind
  // the cover at start). Stands down while view rotation is on — rotation
  // owns navigation on an idle kiosk.

  Timer? _returnHomeTimer;

  /// Whether the feature applies at all right now (regardless of holds).
  bool get _returnHomeConfigured =>
      configured &&
      _settings.get(defs.haReturnHomeEnabled) &&
      !_settings.get(defs.haRotationEnabled);

  /// The start URL's navigation path ("url_path/view-route"), or null when
  /// it carries none (a bare origin has no view to soft-navigate to).
  /// Public: the settings UIs show it as the return target.
  String? homeViewPath() {
    final start = _settings.get(defs.startUrl);
    final uri = Uri.tryParse(start);
    if (uri == null) return null;
    // A start page on another server is one of the custom pages, or no
    // view at all.
    if (baseUrl.isNotEmpty && !start.startsWith('$baseUrl/')) {
      final external = externalPageNavPath(start, customPages);
      if (external != null) return external;
    }
    final path = landingPathOfUri(uri);
    return path.isEmpty ? null : path;
  }

  /// (Re)start the idle countdown, or stop it while it cannot apply: every
  /// activity edge and every gate change lands here.
  void _configureReturnHome() {
    _returnHomeTimer?.cancel();
    _returnHomeTimer = null;
    if (!_returnHomeConfigured) return;
    if (_screensaverActive ||
        _voiceInteracting ||
        _cameraViewActive ||
        _holdActive) {
      return;
    }
    final seconds = _settings
        .get(defs.haReturnHomeSeconds)
        .toInt()
        .clamp(10, 86400);
    _returnHomeTimer = Timer(Duration(seconds: seconds), () {
      _returnHomeTimer = null;
      log.info(name, 'idle: returning to the dashboard');
      unawaited(_returnHome());
    });
  }

  // ── Hold mode (issue #266) ──────────────────────────────────────────
  // Pin the current view: while ha.hold_mode is on, the screensaver will
  // not start (gated in its manager), rotation's tick freezes in place,
  // the return-home clock above stands down and the display stays awake
  // (ScreenManager). The toggle is the live state; this manager only owns
  // the optional auto-release clock.

  Timer? _holdReleaseTimer;

  bool get _holdActive => _settings.get(defs.haHoldMode);

  /// (Re)arm the auto-release countdown, or stop it: runs on every flip of
  /// the toggle or the duration slider, and once at startup for a hold
  /// that persisted across a restart.
  void _configureHoldRelease() {
    _holdReleaseTimer?.cancel();
    _holdReleaseTimer = null;
    if (!_holdActive) return;
    final minutes = _settings
        .get(defs.haHoldReleaseMinutes)
        .toInt()
        .clamp(0, 1440);
    if (minutes <= 0) return;
    _holdReleaseTimer = Timer(_holdReleaseUnit * minutes, () {
      _holdReleaseTimer = null;
      log.info(name, 'hold mode released after ${minutes}m');
      unawaited(_settings.set(defs.haHoldMode, false));
    });
  }

  /// Navigate home: the same soft SPA path rotation uses, which never
  /// touches the screensaver (unlike haNavigate, which dismisses it — the
  /// behind-the-cover return must not wake the kiosk) and drops a
  /// forgotten link overlay on the way.
  Future<void> _returnHome({bool awaitSelfHeal = true}) async {
    final path = homeViewPath();
    if (path == null) return;
    await navigateToViewPath(path, awaitSelfHeal: awaitSelfHeal);
  }

  // ── Where a screensaver dismissal lands ─────────────────────────────
  // The screensaver reaching idle first does the return to the dashboard
  // at its start, quietly behind the cover, so the wake reveals the home
  // view with no visible navigation. Only rendering is frozen under the
  // pause optimization (JS pushed from Dart still executes), so this works
  // with the dashboard WebView hidden. Now Playing can ask for another
  // landing (issue #899): the view the kiosk showed as the screensaver
  // started, or a chosen one. A session that starts on Now Playing holds
  // the return home back, and the dismissal settles the page while the
  // overlay still covers it: the Now Playing target when the session ends
  // on it, home otherwise.

  /// Counts screensaver starts and dismissals, so a start still reading the
  /// page when its dismissal lands stands down.
  int _saverSeq = 0;

  /// The view the page showed as the session started. Read for Last view
  /// only.
  String? _saverStartPath;

  /// The session's start moved the page home.
  bool _saverWentHome = false;

  /// The session's start held the return home back for Now Playing.
  bool _saverHomeHeld = false;

  Future<void> _onScreensaverStart({required bool nowPlaying}) async {
    final seq = ++_saverSeq;
    _saverStartPath = null;
    _saverWentHome = false;
    _saverHomeHeld = false;
    if (_settings.get(defs.sendspinFullscreenReturn) == 'last') {
      // The Home Assistant Dashboard screensaver has already moved the
      // page, and kept where it was.
      _saverStartPath = _saverDashboardReturn ?? await _currentViewPath();
      if (seq != _saverSeq) return;
    }
    // The Home Assistant Dashboard screensaver has just moved the page to
    // its own view, which is what must show now. The return lands on its
    // way out instead (leaveScreensaver).
    if (!_returnHomeConfigured || _holdActive || _saverDashboardPath != null) {
      return;
    }
    if (nowPlaying && _nowPlayingTarget() != null) {
      _saverHomeHeld = true;
      return;
    }
    _saverWentHome = true;
    await _returnHome();
  }

  /// Where a dismissal that ends on Now Playing takes the page, or null to
  /// leave it to Return to the dashboard.
  String? _nowPlayingTarget() {
    switch (_settings.get(defs.sendspinFullscreenReturn)) {
      case 'last':
        return _saverStartPath;
      case 'custom':
        final view = _settings
            .get(defs.sendspinFullscreenReturnView)
            .trim()
            .replaceAll(RegExp(r'^/+|/+$'), '');
        return view.isEmpty ? null : view;
      default:
        return null;
    }
  }

  /// Settle the page as the screensaver ends, awaited by its dismissal
  /// while the overlay still covers the dashboard.
  Future<void> leaveScreensaver({required bool nowPlaying}) async {
    _saverSeq++;
    final target = nowPlaying ? _nowPlayingTarget() : null;
    final wentHome = _saverWentHome;
    final homeHeld = _saverHomeHeld;
    _saverStartPath = null;
    _saverWentHome = false;
    _saverHomeHeld = false;
    if (_saverDashboardPath != null) {
      await leaveScreensaverDashboard(to: target);
      return;
    }
    _saverDashboardUp = false;
    _saverDashboardReturn = null;
    if (!configured) return;
    if (target != null) {
      // Last view moves only a page the start moved: otherwise it is
      // still where it was, and a link overlay up there stays.
      if (_settings.get(defs.sendspinFullscreenReturn) == 'last' && !wentHome) {
        return;
      }
      log.info(name, 'Now Playing dismissed; to "$target"');
      await navigateToViewPath(target, awaitSelfHeal: false);
      return;
    }
    if (homeHeld && _returnHomeConfigured && !_holdActive) {
      log.info(name, 'screensaver ended; returning to the dashboard');
      await _returnHome(awaitSelfHeal: false);
    }
  }

  // ── The Home Assistant Dashboard screensaver ──────────────────────
  // The mode shows a chosen view in the dashboard's own WebView, so the
  // page never reloads: a soft navigation there as it starts and back as
  // it ends. The screensaver drives both edges over commands, awaiting
  // each, so a dismissal and a navigation commanded right after it land
  // in that order.

  /// Whether the mode is up, from its start to its dismissal. A start
  /// still reading the page when the dismissal lands stands down.
  bool _saverDashboardUp = false;

  /// The view the mode moved the page to, null while it moved nothing.
  String? _saverDashboardPath;

  /// Where the page was before the mode moved it.
  String? _saverDashboardReturn;

  /// The origin the page actually lives on: the loopback one when the
  /// secure context proxy is on, [baseUrl] otherwise.
  Future<String> _pageBase() async {
    final mapped = await commands.execute('proxyMapUrl', {'url': baseUrl});
    return mapped.ok && mapped.data is String ? mapped.data as String : baseUrl;
  }

  /// Page script: whether the page on screen is a custom page on another
  /// server, by its origin. Such a page is the kiosk's own to leave, like
  /// Home Assistant's, where any other site is not.
  String _onExternalPageJs() =>
      '${jsonEncode(externalPageOrigins(customPages).toList())}'
      '.indexOf(location.origin) >= 0';

  /// The view the page shows ("url_path/view-route"), or null when it is
  /// not this Home Assistant.
  Future<String?> _currentViewPath() async {
    if (!configured || baseUrl.isEmpty) return null;
    final base = await _pageBase();
    final where = await commands.execute('evalJs', {
      'code':
          '''
(function () {
  if (!location.href.startsWith(${jsonEncode(base)})) {
    return ${_onExternalPageJs()} ? location.href : 'off-origin';
  }
  return location.pathname + location.search + location.hash;
})();
''',
    });
    final page = '${where.data}';
    if (!where.ok) return null;
    if (page.contains('://')) return externalPageNavPath(page, customPages);
    if (!page.startsWith('/')) return null;
    final uri = Uri.tryParse(page);
    final path = uri == null ? '' : landingPathOfUri(uri);
    return path.isEmpty ? null : path;
  }

  /// Move the page to [viewPath] for the screensaver. An empty path, or a
  /// page that is not this Home Assistant, leaves the screen as it is.
  /// A mode that comes back within one session (a schedule swapping it
  /// out and in again) keeps the first return point.
  Future<void> showScreensaverDashboard(String viewPath) async {
    _saverDashboardUp = true;
    if (!configured || baseUrl.isEmpty || viewPath.isEmpty) return;
    final current = await _currentViewPath();
    if (!_saverDashboardUp) return;
    if (_saverDashboardReturn == null) {
      if (current == null) return;
      _saverDashboardReturn = current;
    }
    _saverDashboardPath = viewPath;
    log.info(name, 'screensaver shows "$viewPath"');
    // Awaited up to the navigation itself, not the seconds-long self-heal
    // after it, which the screensaver's start must not wait out.
    await navigateToViewPath(viewPath, awaitSelfHeal: false);
  }

  /// Take the page back as the screensaver ends: to [to] when Now Playing
  /// asks for a landing, else to the dashboard's home view when Return to
  /// the dashboard is on (its return was handed to this moment), otherwise
  /// to where it was. Only while the page still shows the screensaver's
  /// view: a navigation from Home Assistant in the meantime (browser_mod,
  /// a card) is where the person should land.
  Future<void> leaveScreensaverDashboard({String? to}) async {
    _saverDashboardUp = false;
    final shown = _saverDashboardPath;
    final previous = _saverDashboardReturn;
    _saverDashboardPath = null;
    _saverDashboardReturn = null;
    if (shown == null || previous == null) return;
    final back =
        to ??
        (_returnHomeConfigured && !_holdActive ? homeViewPath() : null) ??
        previous;
    final base = await _pageBase();
    final still = await commands.execute('evalJs', {
      'code':
          '''
(function () {
  // A page on another server is still up while its own URL is.
  if (${jsonEncode(isExternalCustomPagePath(shown))}) {
    return location.href === ${jsonEncode(viewPathUrl(base, shown))};
  }
  if (!location.href.startsWith(${jsonEncode(base)})) return false;
  var shown = '/' + ${jsonEncode(shown)};
  var path = location.pathname;
  // A custom page is told apart by its query and fragment too.
  if (path.indexOf('/local/') === 0) {
    return path + location.search + location.hash === shown;
  }
  return path === shown || path.indexOf(shown + '/') === 0;
})();
''',
    });
    if (!still.ok || '${still.data}' != 'true') return;
    log.info(name, 'screensaver ended; back to "$back"');
    await navigateToViewPath(back, awaitSelfHeal: false);
  }

  /// Monotonic navigation stamp: the delayed self-heal check in
  /// [navigateToViewPath] only acts while no newer navigation has started.
  int _navSeq = 0;

  /// Navigate the on-screen HA frontend to [viewPath] ("url_path" or
  /// "url_path/view-route"): a soft SPA navigation so nothing reloads,
  /// with a learned hard-load fallback for paths the SPA cannot resolve.
  /// Drops any external overlay page so the dashboard is actually seen.
  /// With [crossfade] the rotation's in-page dissolve is tried first (see
  /// rotation_fade_script.dart); whatever it cannot handle falls through
  /// to the instant path below.
  ///
  /// Returns what actually happened — 'navigated', 'already' (the page is
  /// on that view), 'off-origin' (a non-HA page is on screen, nothing
  /// moved) or 'failed' — so callers reporting state elsewhere (the ESPHome
  /// select) do not have to guess. With [awaitSelfHeal] off the call
  /// returns once the page has moved and the self-heal runs on its own.
  Future<String> navigateToViewPath(
    String viewPath, {
    bool crossfade = false,
    bool awaitSelfHeal = true,
  }) async {
    if (baseUrl.isEmpty || viewPath.isEmpty) return 'failed';
    final seq = ++_navSeq;
    // A path a soft navigation cannot resolve goes straight to a full load
    // (loadUrl drops the overlay itself). One-time discovery below.
    if (_hardLoadPaths.contains(viewPath)) {
      await commands.execute('loadUrl', {
        'url': viewPathUrl(baseUrl, viewPath),
      });
      return 'navigated';
    }
    // A custom page is a document of its own, not a route in Home
    // Assistant's app, so it never takes a soft navigation or the fade.
    if (isCustomPagePath(viewPath)) return _navigateToCustomPage(viewPath);
    // With the secure context proxy on, the page lives on the loopback
    // origin, not baseUrl — guard against what is actually on screen.
    final effectiveBase = await _pageBase();
    if (crossfade) {
      final fade = await commands.execute('evalJs', {
        'code': rotationCrossfadeJs(
          base: effectiveBase,
          viewPath: viewPath,
          durationSeconds: _settings.get(defs.haRotationFadeSeconds),
        ),
      });
      if (fade.ok && '${fade.data}' == 'fade') {
        // The dissolve navigates on its own, always within a working
        // same-dashboard hui-root — the strategy-spinner self-heal below
        // cannot apply to such a target.
        await commands.execute('hideOverlayPage', const {});
        return 'navigated';
      }
      // 'plain': a dashboard hop, an off-origin page, an unknown route or
      // a transition already in flight — the instant path handles it.
    }
    // Navigate the SPA FIRST — beneath any overlay — and only then reveal
    // the dashboard. Hiding first flashed the previous view for the beat
    // the soft navigation took.
    final js =
        '''
(function () {
  var base = ${jsonEncode(effectiveBase)};
  // A custom page holds no Home Assistant app to route the path.
  if (!location.href.startsWith(base)) {
    return ${_onExternalPageJs()} ? 'load' : 'off-origin';
  }
  if (location.pathname.indexOf('/local/') === 0) return 'load';
  var path = '/' + ${jsonEncode(viewPath)};
  var route = '/' + ${jsonEncode(viewRoute(viewPath))};
  var rest = path.substring(route.length);
  // A child view is not the dashboard root requested by Go to home (#496).
  // A path with a query or fragment is there only when they match too, and
  // one without a fragment is not there while the page has one: that is an
  // open popup, which going home closes (#1311).
  if (location.pathname === route &&
      (rest ? location.search + location.hash === rest : !location.hash)) {
    return 'already';
  }
  // Around the URL Filter's check (urlFilterJs).
  (history.__ksPushState || history.pushState).call(history, null, '', path);
  window.dispatchEvent(new CustomEvent('location-changed'));
  return 'navigated';
})();
''';
    final nav = await commands.execute('evalJs', {'code': js});
    await commands.execute('hideOverlayPage', const {});
    final outcome = nav.ok ? '${nav.data}' : 'failed';
    if (outcome == 'load') {
      await commands.execute('loadUrl', {
        'url': viewPathUrl(baseUrl, viewPath),
      });
      return 'navigated';
    }
    if (outcome != 'navigated') {
      return outcome == 'already' || outcome == 'off-origin'
          ? outcome
          : 'failed';
    }
    if (awaitSelfHeal) {
      await _selfHeal(viewPath, seq);
    } else {
      unawaited(_selfHeal(viewPath, seq));
    }
    return 'navigated';
  }

  /// Move to a custom page. The same file under another fragment only
  /// changes `location.hash`, which reloads nothing: one page with several
  /// layouts switches between them in place and hears it as `hashchange`.
  /// Anything else is a full load of the page.
  Future<String> _navigateToCustomPage(String viewPath) async {
    final base = await _pageBase();
    final hop = await commands.execute('evalJs', {
      'code':
          '''
(function () {
  if (!location.href.startsWith(${jsonEncode(base)}) &&
      !(${_onExternalPageJs()})) return 'off-origin';
  var target = ${jsonEncode(viewPathUrl(base, viewPath))};
  var cut = target.indexOf('#');
  var file = cut < 0 ? target : target.slice(0, cut);
  var hash = cut < 0 ? '' : target.slice(cut);
  var here = location.href;
  var at = here.indexOf('#');
  if ((at < 0 ? here : here.slice(0, at)) !== file) return 'load';
  if (location.hash === hash) return 'already';
  location.hash = hash;
  return 'navigated';
})();
''',
    });
    final outcome = hop.ok ? '${hop.data}' : 'load';
    if (outcome == 'off-origin') return outcome;
    await commands.execute('hideOverlayPage', const {});
    if (outcome == 'already' || outcome == 'navigated') return outcome;
    await commands.execute('loadUrl', {'url': viewPathUrl(baseUrl, viewPath)});
    return 'navigated';
  }

  /// Self-heal, once per path: a soft navigation cannot resolve every
  /// dashboard — strategy dashboards (the auto "Overview") and redirect
  /// aliases leave the panel spinning forever. If it is still spinning
  /// shortly after the soft nav, remember the path as hard-load-only and
  /// do the full load now; every later pass goes straight to loadUrl with
  /// no spinner-then-reload double hit.
  Future<void> _selfHeal(String viewPath, int seq) async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (_navSeq != seq) return;
    final check = await commands.execute('evalJs', {
      'code':
          '''
(function () {
  try {
    if (location.pathname !== '/' + ${jsonEncode(viewRoute(viewPath))}) return false;
    // A page loaded moments ago has no hui-root YET for a perfectly
    // resolvable path (the frontend is still booting), and a verdict
    // taken then mislearned ordinary views as hard loads for the rest of
    // the session -- observed live when an app start's first rotation
    // ticks landed inside the frontend boot. performance.now() is
    // per-page-load time, so this skips exactly that window.
    if (performance.now() < 15000) return false;
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
        '"$viewPath" needs a full load (strategy dashboard or '
        'alias); remembering for future passes',
      );
      await commands.execute('loadUrl', {
        'url': viewPathUrl(baseUrl, viewPath),
      });
    }
  }

  Timer? _themeTimer;
  Timer? _revalidateTimer;

  /// The dark state last pushed to the page, so the minute tick only fires JS
  /// on an actual light↔dark transition. Cleared when the feature is off so
  /// re-enabling always re-applies. Null means the dashboard picks its own
  /// theme. The Music Assistant page follows it too (issue #907).
  final dashboardDark = ValueNotifier<bool?>(null);

  /// Push the scheduled light/dark theme into the HA frontend when it changes.
  ///
  /// Mirrors what browser_mod's `set_theme` does — dispatch a `settheme` event
  /// on the `<home-assistant>` base element — but keeps the selected theme and
  /// only flips its dark variant. HA persists this per browser (localStorage),
  /// so it survives SPA navigation; we re-assert on full loads that reset it.
  Future<void> _applyThemeSchedule({bool force = false}) async {
    final matchApp = _settings.get(defs.themeMatchApp);
    // A theme pinned from Home Assistant (the Theme select, discussion
    // #351) outranks the schedule and the mirror: Light or Dark holds
    // until the select goes back to Auto. It travels the same path the
    // schedule does, so with the mirror on the app's own screens follow.
    final pinned = switch (_settings.get(defs.haTheme)) {
      'dark' => true,
      'light' => false,
      _ => null,
    };
    if (pinned != null) {
      if (matchApp) {
        final want = pinned ? 'dark' : 'light';
        if (_settings.get(defs.uiTheme) != want) {
          await _settings.setFromJson(defs.uiTheme.key, want);
        }
      }
      if (!force && pinned == dashboardDark.value) return;
      dashboardDark.value = pinned;
      await commands.execute('evalJs', {'code': _themeJs(pinned)});
      return;
    }
    if (_settings.get(defs.themeAuto)) {
      final dark = _desiredDark(DateTime.now());
      // The app's own theme follows the schedule when asked to — via the
      // legacy toggle, or via the mirror, under which the schedule targets
      // the app and the mirror below carries it on to the dashboard.
      // Through the settings store, not directly: main.dart already
      // listens for ui.theme and applies it live, remote UI included.
      if (matchApp || _settings.get(defs.themeAutoApp)) {
        final want = dark ? 'dark' : 'light';
        if (_settings.get(defs.uiTheme) != want) {
          await _settings.setFromJson(defs.uiTheme.key, want);
        }
      }
      if (!matchApp) {
        if (!force && dark == dashboardDark.value) return;
        dashboardDark.value = dark;
        await commands.execute('evalJs', {'code': _themeJs(dark)});
        return;
      }
    }
    // The mirror (issue #92): the dashboard follows the app's EFFECTIVE
    // theme — the App theme setting, or the device's own dark mode when it
    // is System, which Android flips at its own sunset/sunrise.
    if (matchApp) {
      final dark = _effectiveAppDark();
      if (!force && dark == dashboardDark.value) return;
      dashboardDark.value = dark;
      await commands.execute('evalJs', {'code': _themeJs(dark)});
      return;
    }
    dashboardDark.value = null;
  }

  /// Whether the app is effectively dark right now: the App theme setting,
  /// deferring to the platform for System.
  bool _effectiveAppDark() => switch (_settings.get(defs.uiTheme)) {
    'dark' => true,
    'light' => false,
    _ =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  /// Relays the platform's dark-mode flips into the theme logic; see the
  /// observer registration in [init].
  late final _brightnessWatch = _PlatformBrightnessWatch(
    () => _applyThemeSchedule(force: true),
  );

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

  String _themeJs(bool dark) =>
      '''
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

  bool? _vsDetected;

  /// Whether the Voice Satellite integration is installed on the connected
  /// HA instance (probes its static frontend path). Cached per app run.
  /// A kiosk that had a satellite assigned when native Voice Satellite
  /// arrived stayed on the dashboard runtime, and only the integration's
  /// migration moves it on. Once the integration is uninstalled that way is
  /// gone and the page only offers to install it again, so switch the kiosk
  /// to native here. Only on Home Assistant's own 404 for the integration's
  /// script: a network error says nothing. Voice stays off until its owner
  /// turns it on.
  Future<void> _leaveDashboardRuntime() async {
    if (_settings.get(defs.voiceRuntime) != 'dashboard' || baseUrl.isEmpty) {
      return;
    }
    try {
      final response = await http
          .head(Uri.parse('$baseUrl/voice_satellite/voice-satellite-card.js'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 404) return;
    } catch (_) {
      return;
    }
    if (_settings.get(defs.voiceRuntime) != 'dashboard') return;
    _vsDetected = false;
    await _settings.set(defs.voiceRuntime, 'native');
    log.info(
      name,
      'the Voice Satellite integration is not installed; Voice Satellite '
      'now runs natively',
    );
  }

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
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/'),
            headers: {'Authorization': 'Bearer ${_settings.get(defs.haToken)}'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) return 'invalid token';
      if (response.statusCode != 200) return 'HTTP ${response.statusCode}';
      return null;
    } catch (e) {
      return 'unreachable: $e';
    }
  }

  /// A live subscription to a handful of entities, for the At a Glance row.
  ///
  /// `subscribe_entities` takes an entity list, so Home Assistant sends only
  /// these — the filtering is server-side and the socket carries nothing
  /// else. That is the whole reason this exists rather than reading the
  /// dashboard's own stream: the page's update filter (issue #8) is there to
  /// stop a weak tablet processing entities it does not show, and feeding
  /// these back into it would undo exactly that.
  ///
  /// Returns null when Home Assistant is not configured or the socket cannot
  /// be opened. The caller owns the returned subscription and must close it.
  ///
  /// [onPrecision] receives each entity's display precision from the entity
  /// registry, looked up over the subscription's own socket so it costs one
  /// extra frame rather than a second connection (issue #74). States arrive
  /// raw; without this the row shows 69.44 where the entity's own card,
  /// honoring the Display precision setting, shows 69.
  ///
  /// [onTranslations] receives Home Assistant's own wording for the states
  /// of [translationDomain], in the user's language, fetched over the same
  /// socket (issue #268). A lookup on a separate socket could fail while the
  /// states still arrived, and the widget then spoke English for the rest of
  /// the run (issue #900). Riding the subscription means every reconnect
  /// retries until it lands. Empty means an English server: the built-in
  /// labels already speak it.
  ///
  /// [onStateLabels] receives Home Assistant's wording for the entities'
  /// states, in the user's language, so a window sensor reads "Closed"
  /// rather than "Off" (issue #919). English is fetched too: device class
  /// wording is a translation even there.
  ///
  /// [onForecast] receives [forecastEntity]'s daily forecast, as the raw
  /// list `weather/subscribe_forecast` sends, each time it changes. An
  /// integration without a daily forecast never calls it.
  Future<GlanceSubscription?> subscribeEntities(
    List<String> entityIds,
    void Function(String entityId, Map<String, Object?> state) onState, {
    void Function(Map<String, int> precisions)? onPrecision,
    String? translationDomain,
    void Function(Map<String, String> translations)? onTranslations,
    void Function(EntityStateLabels labels)? onStateLabels,
    String? forecastEntity,
    void Function(Object? forecast)? onForecast,
  }) async {
    if (!configured || entityIds.isEmpty) return null;
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse('$wsBase/api/websocket'),
      );
      // A failed connect also fails `ready`. The stream below reports it,
      // so the future must not surface it again as an uncaught error.
      unawaited(channel.ready.catchError((_) {}));
      final subscription = GlanceSubscription._(channel).._expectSubscribed();
      final domain = onTranslations != null ? translationDomain : null;
      void askTranslations(String language) {
        if (domain == null) return;
        if (language.toLowerCase().startsWith('en')) {
          onTranslations!(_stateTranslations[domain] = const {});
          return;
        }
        channel.sink.add(
          jsonEncode({
            'id': 6,
            'type': 'frontend/get_translations',
            'language': language,
            'category': 'entity_component',
            'integration': [domain],
          }),
        );
      }

      // State labels need the registry (which integration and translation
      // key each entity has) and the language before they can be asked
      // for. Whatever is already cached is not asked again.
      Map<String, (String, String)>? labelEntries;
      String? labelLanguage;
      // What each lookup asked for, so an integration with no wording at
      // all still caches as empty instead of being asked every time.
      final labelsAsked = <int, List<String>>{};
      void deliverLabels() {
        if (labelsAsked.isNotEmpty) return;
        final resources = <String, String>{};
        for (final id in entityIds) {
          final cached =
              _stateLabels['$labelLanguage/entity_component/${id.split('.').first}'];
          if (cached != null) resources.addAll(cached);
        }
        for (final (platform, _) in labelEntries!.values) {
          final cached = _stateLabels['$labelLanguage/entity/$platform'];
          if (cached != null) resources.addAll(cached);
        }
        onStateLabels!(EntityStateLabels(resources, labelEntries!));
      }

      void askLabels() {
        if (onStateLabels == null) return;
        final language = labelLanguage;
        if (language == null || labelEntries == null) return;
        final domains = {for (final id in entityIds) id.split('.').first}
            .where(
              (d) => !_stateLabels.containsKey('$language/entity_component/$d'),
            )
            .toList();
        final platforms = {for (final (p, _) in labelEntries!.values) p}
            .where((p) => !_stateLabels.containsKey('$language/entity/$p'))
            .toList();
        for (final (id, category, integrations) in [
          (7, 'entity_component', domains),
          (8, 'entity', platforms),
        ]) {
          if (integrations.isEmpty) continue;
          labelsAsked[id] = integrations;
          channel.sink.add(
            jsonEncode({
              'id': id,
              'type': 'frontend/get_translations',
              'language': language,
              'category': category,
              'integration': integrations,
            }),
          );
        }
        deliverLabels();
      }

      void labelsArrived(int id, Object? result) {
        final category = id == 7 ? 'entity_component' : 'entity';
        final language = labelLanguage;
        final integrations = labelsAsked.remove(id) ?? const [];
        if (result != null && language != null) {
          final parsed = parseStateLabels(result);
          for (final integration in integrations) {
            _stateLabels['$language/$category/$integration'] =
                parsed[integration] ?? const {};
          }
        }
        deliverLabels();
      }

      void languageKnown(String language) {
        if (domain != null && !_stateTranslations.containsKey(domain)) {
          askTranslations(language);
        }
        labelLanguage = language;
        askLabels();
      }

      channel.stream.listen(
        (raw) {
          try {
            final msg = jsonDecode(raw as String) as Map<String, dynamic>;
            switch (msg['type']) {
              case 'auth_required':
                channel.sink.add(
                  jsonEncode({
                    'type': 'auth',
                    'access_token': _settings.get(defs.haToken),
                  }),
                );
              case 'auth_ok':
                channel.sink.add(
                  jsonEncode({
                    'id': 1,
                    'type': 'subscribe_entities',
                    'entity_ids': entityIds,
                  }),
                );
                if (forecastEntity != null && onForecast != null) {
                  channel.sink.add(
                    jsonEncode({
                      'id': 2,
                      'type': 'weather/subscribe_forecast',
                      'entity_id': forecastEntity,
                      'forecast_type': 'daily',
                    }),
                  );
                }
                if (onPrecision != null || onStateLabels != null) {
                  channel.sink.add(
                    jsonEncode({
                      'id': 3,
                      'type': 'config/entity_registry/get_entries',
                      'entity_ids': entityIds,
                    }),
                  );
                }
                final cached = domain != null
                    ? _stateTranslations[domain]
                    : null;
                if (cached != null) onTranslations!(cached);
                if ((domain != null && cached == null) ||
                    onStateLabels != null) {
                  final language = _language;
                  if (language != null) {
                    languageKnown(language);
                  } else {
                    // The user's profile language comes first, as on the
                    // dashboard. The server's own language only applies
                    // when the user never picked one.
                    channel.sink.add(
                      jsonEncode({
                        'id': 4,
                        'type': 'frontend/get_user_data',
                        'key': 'language',
                      }),
                    );
                  }
                }
              case 'auth_invalid':
                log.warn(name, 'glance subscription rejected: bad token');
                subscription.close();
              case 'result':
                // The subscribe command confirms itself here too; only the
                // registry lookup's reply carries anything to read. A failure
                // (an old Home Assistant without get_entries) just leaves
                // states unrounded, which is what the row always did. A
                // failed translation lookup caches nothing, so the next
                // connection asks again.
                if (msg['success'] != true) {
                  // Without the registry the labels still come, by device
                  // class and domain. A failed label lookup delivers what
                  // the other one brought.
                  if (msg['id'] == 3 && onStateLabels != null) {
                    labelEntries = const {};
                    askLabels();
                  } else if (msg['id'] == 7 || msg['id'] == 8) {
                    labelsArrived(msg['id'] as int, null);
                  } else if (msg['id'] == 4) {
                    channel.sink.add(
                      jsonEncode({'id': 5, 'type': 'get_config'}),
                    );
                  }
                  break;
                }
                switch (msg['id']) {
                  case 1:
                    subscription._startHeartbeat();
                  case 3:
                    onPrecision?.call(_displayPrecisions(msg['result']));
                    if (onStateLabels != null) {
                      labelEntries = _translationKeys(msg['result']);
                      askLabels();
                    }
                  case 5:
                    final config = msg['result'];
                    final language = config is Map
                        ? '${config['language'] ?? ''}'.trim()
                        : '';
                    languageKnown(
                      _language = language.isEmpty ? 'en' : language,
                    );
                  case 6:
                    onTranslations!(
                      _stateTranslations[domain!] = parseStateTranslations(
                        msg['result'],
                        domain,
                      ),
                    );
                  case 4:
                    final language = userLanguage(msg['result']);
                    if (language != null) {
                      languageKnown(_language = language);
                    } else {
                      channel.sink.add(
                        jsonEncode({'id': 5, 'type': 'get_config'}),
                      );
                    }
                  case 7 || 8:
                    labelsArrived(msg['id'] as int, msg['result']);
                }
              case 'pong':
                subscription._pong();
              case 'event' when msg['id'] == 2:
                final event = msg['event'];
                onForecast!(event is Map ? event['forecast'] : null);
              case 'event':
                _handleEntityEvent(msg['event'], onState);
            }
          } catch (e) {
            log.warn(name, 'glance frame ignored: $e');
          }
        },
        // cancelOnError skips onDone after an error, so the error itself
        // has to count as the close, or the owner never reopens.
        onError: (Object e) {
          log.warn(name, 'glance socket error: $e');
          subscription._lost();
        },
        onDone: subscription._markClosed,
        cancelOnError: true,
      );
      return subscription;
    } catch (e) {
      log.warn(name, 'glance subscription failed: $e');
      return null;
    }
  }

  /// The compressed `subscribe_entities` payload: `a` is the full state of
  /// everything subscribed (sent once, on subscribe), `c` is a per-entity
  /// diff with `+` for what changed. Attributes only arrive when they change,
  /// so the caller merges rather than replaces.
  void _handleEntityEvent(
    Object? event,
    void Function(String entityId, Map<String, Object?> state) onState,
  ) {
    if (event is! Map) return;
    final added = event['a'];
    if (added is Map) {
      for (final entry in added.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        onState('${entry.key}', {
          'state': value['s'],
          'attributes': value['a'] ?? const {},
        });
      }
    }
    final changed = event['c'];
    if (changed is Map) {
      for (final entry in changed.entries) {
        final diff = entry.value;
        if (diff is! Map) continue;
        final plus = diff['+'];
        if (plus is! Map) continue;
        onState('${entry.key}', {
          if (plus.containsKey('s')) 'state': plus['s'],
          if (plus['a'] is Map) 'attributes': plus['a'],
        });
      }
    }
  }

  /// Each entity's display precision out of a `get_entries` reply: the
  /// Display precision a person set on the entity when there is one, else
  /// the integration's suggestion, which is the same order Home Assistant's
  /// own frontend resolves before rounding a sensor. Entities with neither
  /// (or no registry entry at all) are simply absent.
  static Map<String, int> _displayPrecisions(Object? result) {
    final precisions = <String, int>{};
    if (result is! Map) return precisions;
    for (final entry in result.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final sensor = (value['options'] as Map?)?['sensor'];
      if (sensor is! Map) continue;
      final precision =
          sensor['display_precision'] ?? sensor['suggested_display_precision'];
      if (precision is int) precisions['${entry.key}'] = precision;
    }
    return precisions;
  }

  /// Each entity's integration and translation key out of a `get_entries`
  /// reply, for the entities that have a translation key. Those are the
  /// ones whose states the integration words itself ("idle" on a backup
  /// sensor reads "Leerlauf").
  static Map<String, (String, String)> _translationKeys(Object? result) {
    final keys = <String, (String, String)>{};
    if (result is! Map) return keys;
    for (final entry in result.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final platform = value['platform'];
      final key = value['translation_key'];
      if (platform is String && key is String && key.isNotEmpty) {
        keys['${entry.key}'] = (platform, key);
      }
    }
    return keys;
  }

  /// Entities matching [query], for the At a Glance picker.
  ///
  /// `/api/states` is the whole instance in one response, which is why the
  /// result is capped and why this is called per search rather than kept:
  /// a big instance is a few hundred kilobytes and there is no reason to
  /// hold it on a device this feature exists to keep light.
  ///
  /// An exact id or a name that starts with the query sorts first, so
  /// typing "gara" puts Garage Door above Front Garage Light Sensor.
  ///
  /// [filter] `illuminance` keeps only light level sensors, for adaptive
  /// brightness's entity (issue #911).
  Future<List<Map<String, Object?>>?> searchEntities(
    String query, {
    String? filter,
  }) async {
    final states = await fetchStates();
    if (states == null) return null;
    final needle = query.trim().toLowerCase();
    final matches = <(int, String, Map<String, Object?>)>[];
    for (final state in states) {
      final id = '${state['entity_id'] ?? ''}';
      if (id.isEmpty) continue;
      final attributes = (state['attributes'] as Map?) ?? const {};
      if (filter == 'illuminance' && !_isIlluminance(attributes)) continue;
      final name = '${attributes['friendly_name'] ?? _prettifyEntityId(id)}';
      if (needle.isNotEmpty &&
          !id.toLowerCase().contains(needle) &&
          !name.toLowerCase().contains(needle)) {
        continue;
      }
      final rank = needle.isEmpty
          ? 2
          : name.toLowerCase().startsWith(needle) ||
                id.split('.').last.toLowerCase().startsWith(needle)
          ? 0
          : 1;
      matches.add((
        rank,
        name.toLowerCase(),
        {'entity_id': id, 'name': name, 'state': state['state']},
      ));
    }
    matches.sort((a, b) {
      final byRank = a.$1.compareTo(b.$1);
      return byRank != 0 ? byRank : a.$2.compareTo(b.$2);
    });
    return [for (final match in matches.take(50)) match.$3];
  }

  /// Every entity, once, for the entity picker: id, name, the state as
  /// Home Assistant formats it, icon (the entity's own, else the one Home
  /// Assistant would draw), device class, unit, domain with its title in
  /// Home Assistant's language, area, and whether Home Assistant hides it.
  /// The pickers leave hidden entities out unless they ask for them. Null
  /// when Home Assistant cannot be reached.
  ///
  /// The page's own `hass` comes first: it already holds every state, the
  /// registries the areas come from and Home Assistant's formatting. The
  /// REST states and the websocket registries stand in when the page has
  /// no hass yet.
  Future<List<Map<String, Object?>>?> listEntities({
    List<String> domains = const [],
    String? deviceClass,
  }) async {
    final page = await _entitiesFromPage();
    final entities = page?.$1 ?? await _entitiesFromRest();
    if (entities == null) return null;
    final titles = await _domainTitles(page?.$2 ?? 'en');
    final filtered = filterEntities(
      entities,
      domains: domains,
      deviceClass: deviceClass,
    );
    return [
      for (final e in filtered)
        {
          ...withPickerState(e),
          'domain_title':
              titles['${e['domain']}'] ?? domainTitleFallback('${e['domain']}'),
        },
    ];
  }

  /// Every service Home Assistant offers, named in its language, for the
  /// service picker. Null when Home Assistant cannot be reached.
  Future<List<Map<String, Object?>>?> listServices() async {
    final Object? services;
    try {
      services = await _wsCommand({'type': 'get_services'});
    } catch (e) {
      log.warn(name, 'services unavailable: $e');
      return null;
    }
    if (services is! Map) return null;
    final language = await _pageLanguage();
    return serviceRows(
      services,
      names: await _serviceNames(language),
      titles: await _domainTitles(language),
    );
  }

  /// Home Assistant's language, from the page; English when it has none.
  Future<String> _pageLanguage() async {
    try {
      final res = await commands.execute('evalJs', {
        'code':
            "(function () { var el = document.querySelector('home-assistant');"
            " return (el && el.hass && el.hass.language) || 'en'; })()",
      });
      return res.ok && res.data is String && '${res.data}'.isNotEmpty
          ? '${res.data}'
          : 'en';
    } catch (_) {
      return 'en';
    }
  }

  final Map<String, Map<String, String>> _serviceNamesByLanguage = {};

  /// The services' names in [language], keyed `domain.service`, kept for
  /// the session. Empty when they cannot be read.
  Future<Map<String, String>> _serviceNames(String language) async {
    final cached = _serviceNamesByLanguage[language];
    if (cached != null) return cached;
    try {
      final result = await _wsCommand({
        'type': 'frontend/get_translations',
        'language': language,
        'category': 'services',
      });
      final resources = result is Map ? result['resources'] : null;
      final names = <String, String>{};
      if (resources is Map) {
        for (final entry in resources.entries) {
          final match = RegExp(
            r'^component\.([a-z0-9_]+)\.services\.([a-z0-9_]+)\.name$',
          ).firstMatch('${entry.key}');
          if (match != null) {
            names['${match.group(1)}.${match.group(2)}'] = '${entry.value}';
          }
        }
      }
      return _serviceNamesByLanguage[language] = names;
    } catch (e) {
      log.warn(name, 'service names unavailable: $e');
      return const {};
    }
  }

  /// The entities from the page's hass, with Home Assistant's language.
  Future<(List<Map<String, Object?>>, String)?> _entitiesFromPage() async {
    const js = r'''
(function () {
  try {
    var el = document.querySelector('home-assistant');
    var hass = el && el.hass;
    if (!hass || !hass.states) return 'null';
    var ents = hass.entities || {}, devs = hass.devices || {}, areas = hass.areas || {};
    var out = [];
    Object.keys(hass.states).forEach(function (id) {
      var s = hass.states[id], e = ents[id] || {};
      var a = s.attributes || {};
      var areaId = e.area_id || (e.device_id && devs[e.device_id] && devs[e.device_id].area_id);
      var state = s.state;
      try { if (hass.formatEntityState) state = hass.formatEntityState(s); } catch (_) {}
      out.push({
        entity_id: id,
        name: a.friendly_name || id,
        state: String(state),
        icon: a.icon || e.icon || null,
        device_class: a.device_class || null,
        unit: a.unit_of_measurement || null,
        area: areaId && areas[areaId] ? areas[areaId].name : null,
        hidden: !!e.hidden
      });
    });
    return JSON.stringify({ language: hass.language || 'en', entities: out });
  } catch (e) {
    return 'null';
  }
})()
''';
    try {
      final res = await commands.execute('evalJs', {'code': js});
      if (!res.ok) return null;
      final decoded = jsonDecode(res.data as String);
      if (decoded is! Map || decoded['entities'] is! List) return null;
      return (
        [
          for (final e in (decoded['entities'] as List).cast<Map>())
            _entityRow(e.cast<String, Object?>()),
        ],
        '${decoded['language'] ?? 'en'}',
      );
    } catch (_) {
      return null;
    }
  }

  /// The entities from the REST states, areas from the registries when
  /// the websocket answers.
  Future<List<Map<String, Object?>>?> _entitiesFromRest() async {
    final states = await fetchStates();
    if (states == null) return null;
    final areas = <String, String>{};
    final deviceAreas = <String, String>{};
    final registry = <String, Map>{};
    try {
      final list = await _wsCommand({'type': 'config/area_registry/list'});
      if (list is List) {
        for (final a in list.whereType<Map>()) {
          areas['${a['area_id']}'] = '${a['name']}';
        }
      }
      final devices = await _wsCommand({'type': 'config/device_registry/list'});
      if (devices is List) {
        for (final d in devices.whereType<Map>()) {
          if (d['area_id'] != null) {
            deviceAreas['${d['id']}'] = '${d['area_id']}';
          }
        }
      }
      final entities = await _wsCommand({
        'type': 'config/entity_registry/list',
      });
      if (entities is List) {
        for (final e in entities.whereType<Map>()) {
          registry['${e['entity_id']}'] = e;
        }
      }
    } catch (e) {
      log.warn(name, 'entity registries unavailable: $e');
    }
    return [
      for (final state in states)
        if ('${state['entity_id'] ?? ''}'.isNotEmpty)
          (() {
            final id = '${state['entity_id']}';
            final a = (state['attributes'] as Map?) ?? const {};
            final reg = registry[id];
            final areaId =
                reg?['area_id'] ?? deviceAreas['${reg?['device_id']}'];
            final unit = a['unit_of_measurement'] as String?;
            return _entityRow({
              'entity_id': id,
              'name': '${a['friendly_name'] ?? _prettifyEntityId(id)}',
              'state': formatStateFallback('${state['state'] ?? ''}', unit),
              'icon': a['icon'] ?? reg?['icon'],
              'device_class': a['device_class'],
              'unit': unit,
              'area': areaId == null ? null : areas['$areaId'],
              'hidden': reg?['hidden_by'] != null,
            });
          })(),
    ];
  }

  /// One list row: the fields as read, the domain, and an icon even when
  /// the entity sets none.
  static Map<String, Object?> _entityRow(Map<String, Object?> e) {
    final id = '${e['entity_id']}';
    final domain = id.split('.').first;
    final deviceClass = e['device_class'] as String?;
    final icon = e['icon'];
    return {
      ...e,
      'domain': domain,
      'icon': icon is String && icon.isNotEmpty
          ? icon
          : defaultEntityIcon(domain, deviceClass),
    };
  }

  final Map<String, Map<String, String>> _titlesByLanguage = {};

  /// Home Assistant's own names for the domains, in [language], kept for
  /// the session. Empty when they cannot be read: the picker falls back
  /// to the prettified domain.
  Future<Map<String, String>> _domainTitles(String language) async {
    final cached = _titlesByLanguage[language];
    if (cached != null) return cached;
    try {
      final result = await _wsCommand({
        'type': 'frontend/get_translations',
        'language': language,
        'category': 'title',
      });
      final resources = result is Map ? result['resources'] : null;
      final titles = <String, String>{};
      if (resources is Map) {
        for (final entry in resources.entries) {
          final key = '${entry.key}';
          final match = RegExp(
            r'^component\.([a-z0-9_]+)\.title$',
          ).firstMatch(key);
          if (match != null) titles[match.group(1)!] = '${entry.value}';
        }
      }
      return _titlesByLanguage[language] = titles;
    } catch (e) {
      log.warn(name, 'domain titles unavailable: $e');
      return const {};
    }
  }

  /// A light level sensor (issue #911): the illuminance device class, or
  /// a reading in lux from a template or custom sensor that sets the unit
  /// and no class.
  static bool _isIlluminance(Map attributes) =>
      attributes['device_class'] == 'illuminance' ||
      attributes['unit_of_measurement'] == 'lx';

  /// One entity's current attributes, or null when it (or Home Assistant)
  /// cannot be reached. For the At a Glance attribute picker: values ride
  /// along so the picker can show what each attribute currently reads.
  Future<Map<String, Object?>?> fetchEntityAttributes(String entityId) async {
    if (!configured || entityId.isEmpty) return null;
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/states/$entityId'),
            headers: {'Authorization': 'Bearer ${_settings.get(defs.haToken)}'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        log.warn(name, 'entity fetch failed: HTTP ${response.statusCode}');
        return null;
      }
      final decoded = jsonDecode(response.body);
      final attributes = decoded is Map ? decoded['attributes'] : null;
      return attributes is Map ? attributes.cast<String, Object?>() : const {};
    } catch (e) {
      log.warn(name, 'entity fetch failed: $e');
      return null;
    }
  }

  /// Every entity's current state, or null when Home Assistant cannot be
  /// reached. Also the At a Glance fallback for kiosks whose page is not a
  /// Home Assistant dashboard and so cannot report states itself.
  Future<List<Map<String, Object?>>?> fetchStates() async {
    if (!configured) return null;
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/states'),
            headers: {'Authorization': 'Bearer ${_settings.get(defs.haToken)}'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        log.warn(name, 'states fetch failed: HTTP ${response.statusCode}');
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;
      return [
        for (final item in decoded)
          if (item is Map) item.cast<String, Object?>(),
      ];
    } catch (e) {
      log.warn(name, 'states fetch failed: $e');
      return null;
    }
  }

  static String _prettifyEntityId(String entityId) => entityId
      .split('.')
      .last
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

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
              (e['entity_id'] as String? ?? '').startsWith('assist_satellite.'))
            {
              'entity_id': e['entity_id'],
              'name':
                  e['name'] ??
                  e['original_name'] ??
                  prettify(e['entity_id'] as String),
            },
      ];
      satellites.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
      return satellites;
    } catch (e) {
      log.warn(name, 'listVoiceSatellites failed: $e');
      return null;
    }
  }

  /// The Voice Satellite control surface in one read: the satellite this
  /// kiosk identifies as, the satellites to choose from, the satellite's
  /// sibling select entities keyed by their stable translation_key
  /// (pipeline, pipeline_2, wake_word_detection, wake_word_model,
  /// wake_word_model_2) with current value and options, and the
  /// browser-local settings from the page hook. Every part degrades to
  /// null/empty on its own so the settings page can say precisely what is
  /// missing (no satellite, no page hook) instead of failing whole.
  /// Registry-derived half of [vsControlsSnapshot], cached: the satellites
  /// to choose from and the chosen satellite's sibling entity map. The
  /// registry list is the whole instance (a megabyte-plus of JSON on a big
  /// install) over a fresh TLS websocket, and the snapshot used to fetch
  /// it twice and then /api/states (everything again, bigger) on every
  /// call. The remote admin page refreshes this snapshot on each wake-word
  /// state push - which fires at TTS start AND end of every voice turn -
  /// so each turn parsed megabytes of JSON on the UI thread of the very
  /// tablet that was trying to animate its reactive bar and play its done
  /// chime. Registries change when integrations are added, not per turn;
  /// five minutes of staleness here is invisible, the per-turn freeze
  /// was not.
  ({
    String satellite,
    List<Map<String, Object?>>? satellites,
    Map<String, String> wanted,
    DateTime at,
  })?
  _vsControlsCache;

  void _watchRemoteVoice() {
    if (!_remoteVoiceObserved) return;
    final cache = _vsControlsCache;
    if (cache == null) return;
    final ids = {...cache.wanted.values};
    for (final id in _remoteVoiceIds.difference(ids)) {
      _pluginEntities.unwatch('__remote_voice', id);
    }
    for (final id in ids.difference(_remoteVoiceIds)) {
      _pluginEntities.watch('__remote_voice', id);
    }
    _remoteVoiceIds = ids;
  }

  Future<Map<String, Object?>> vsControlsSnapshot() async {
    // The page's own binding wins (localStorage, changeable in the Voice
    // Satellite panel); the wizard's stored pick is the fallback.
    var satellite = '';
    final stored = await commands.execute('evalJs', {
      'code': "localStorage.getItem('vs-satellite-entity')",
    });
    final storedData = stored.ok ? stored.data : null;
    if (storedData is String && storedData.isNotEmpty && storedData != 'null') {
      satellite = storedData;
    }
    if (satellite.isEmpty) {
      satellite = _settings.get(defs.haSatelliteEntity).trim();
    }

    final cached = _vsControlsCache;
    final cacheHit =
        cached != null &&
        cached.satellite == satellite &&
        DateTime.now().difference(cached.at) < const Duration(minutes: 5);
    final satellites = cacheHit
        ? cached.satellites
        : await listVoiceSatellites();

    // The satellite's sibling selects, located by device rather than by
    // entity_id (ids are user-renamable; the device and translation_key
    // are stable). Same resolution the card's own settings gate uses.
    var wanted = const <String, String>{};
    if (cacheHit) {
      wanted = cached.wanted;
    } else if (satellite.isNotEmpty) {
      try {
        final registry = await _wsCommand({
          'type': 'config/entity_registry/list',
        });
        if (registry is List) {
          final entries = registry.cast<Map>();
          final own = entries.firstWhere(
            (e) => e['entity_id'] == satellite,
            orElse: () => const {},
          );
          final deviceId = own['device_id'];
          if (deviceId != null) {
            // Only the entities the settings page controls; the device
            // carries many more. Older HA lists omit translation_key;
            // the original name is the fallback identity then.
            const controlledSelects = {
              'pipeline',
              'pipeline_2',
              'vad_sensitivity',
              'wake_word_detection',
              'wake_word_model',
              'wake_word_model_2',
              'wake_word_sensitivity',
            };
            const controlledSwitches = {'mute', 'stop_word', 'noise_gate'};
            const byName = {
              'pipeline 1': 'pipeline',
              'pipeline 2': 'pipeline_2',
              'finished speaking detection': 'vad_sensitivity',
              'wake word detection': 'wake_word_detection',
              'wake word 1': 'wake_word_model',
              'wake word 2': 'wake_word_model_2',
              'wake word sensitivity': 'wake_word_sensitivity',
              'mute': 'mute',
              'stop word interruption': 'stop_word',
              'wake word noise gate': 'noise_gate',
            };
            final resolved = <String, String>{}; // key -> entity_id
            for (final e in entries) {
              if (e['device_id'] != deviceId ||
                  e['platform'] != 'voice_satellite') {
                continue;
              }
              final id = '${e['entity_id']}';
              final key =
                  e['translation_key'] as String? ??
                  byName['${e['original_name'] ?? ''}'.toLowerCase()];
              if (key == null) continue;
              final ok = id.startsWith('select.')
                  ? controlledSelects.contains(key)
                  : id.startsWith('switch.') &&
                        controlledSwitches.contains(key);
              if (ok) resolved[key] = id;
            }
            wanted = resolved;
          }
        }
        _vsControlsCache = (
          satellite: satellite,
          satellites: satellites,
          wanted: wanted,
          at: DateTime.now(),
        );
      } catch (e) {
        log.warn(name, 'vsControls sibling lookup failed: $e');
      }
    }

    _watchRemoteVoice();

    // Fresh states for just the sibling entities plus the satellite itself
    // (its attributes carry the integration version): a dozen one-kilobyte
    // reads on one keep-alive connection, never the whole state table.
    final entities = <String, Object?>{};
    String? version;
    if (wanted.isNotEmpty) {
      final client = http.Client();
      try {
        Future<Map<String, Object?>?> read(String id) async {
          try {
            final response = await client
                .get(
                  Uri.parse('$baseUrl/api/states/$id'),
                  headers: {
                    'Authorization': 'Bearer ${_settings.get(defs.haToken)}',
                  },
                )
                .timeout(const Duration(seconds: 10));
            if (response.statusCode != 200) return null;
            final decoded = jsonDecode(response.body);
            return decoded is Map ? decoded.cast<String, Object?>() : null;
          } catch (_) {
            return null;
          }
        }

        final ownState = await read(satellite);
        final attrs = ownState?['attributes'];
        if (attrs is Map && attrs['integration_version'] != null) {
          version = '${attrs['integration_version']}';
        }
        for (final entry in wanted.entries) {
          final state = await read(entry.value);
          final attributes = state?['attributes'];
          entities[entry.key] = {
            'entity_id': entry.value,
            'state': state?['state'],
            'available':
                state?['state'] != null && state?['state'] != 'unavailable',
            'options': attributes is Map
                ? attributes['options'] ?? const []
                : const [],
          };
        }
      } finally {
        client.close();
      }
    }

    // The browser-local half, via the hook the Voice Satellite bundle
    // installs. Absent, the reason matters to the UIs: a running Voice
    // Satellite without the hook is an outdated bundle (say "update"),
    // no engine at all is a page that is not the dashboard.
    Object? browser;
    var browserState = 'unavailable';
    final hook = await commands.execute('evalJs', {
      'code':
          'JSON.stringify(window.__vsExternalSettings '
          '? {state: "ok", data: window.__vsExternalSettings.get()} '
          ': {state: window.__vsEngine ? "outdated" : "unavailable"})',
    });
    final hookData = hook.ok ? hook.data : null;
    if (hookData is String && hookData.isNotEmpty && hookData != 'null') {
      try {
        final decoded = jsonDecode(hookData);
        if (decoded is Map) {
          browserState = '${decoded['state'] ?? 'unavailable'}';
          browser = decoded['data'];
        }
      } catch (_) {}
    }

    return {
      'satellite': satellite,
      'satellites': satellites ?? const [],
      'entities': entities,
      'version': version,
      'browser': browser,
      'browserState': browserState,
    };
  }

  /// Dashboards via the websocket API (`lovelace/dashboards/list`), plus
  /// the default `lovelace` when the API does not include it.
  ///
  /// [pageOnly] skips the websocket fallback: the two sources order and
  /// name the default differently (the page knows the real one), so a
  /// reader that must not see the list flip between them asks for the
  /// page's answer or none (issue #362).
  Future<List<Map<String, Object?>>?> listDashboards({
    bool pageOnly = false,
  }) async {
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
    if (page != null || pageOnly) return _withCustomPagesEntry(page);
    try {
      final result = await _wsCommand({'type': 'lovelace/dashboards/list'});
      if (result is! List) return null;
      // YAML-mode dashboards included: they read over `lovelace/config`
      // the same as storage ones. Keeping only storage dashboards here
      // dropped every YAML dashboard from the view selects (issue #244).
      return _withCustomPagesEntry(dashboardsFromWsList(result));
    } catch (e) {
      log.warn(name, 'listDashboards failed: $e');
      return null;
    }
  }

  /// The person's custom pages, in their order.
  List<CustomPage> get customPages =>
      parseCustomPages(_settings.get(defs.haCustomPages));

  /// [dashboards] with the Custom Pages entry last, while there are pages
  /// to list. Its views are the pages (see [listDashboardViews]), so every
  /// reader of the list offers them without knowing they are not views.
  List<Map<String, Object?>>? _withCustomPagesEntry(
    List<Map<String, Object?>>? dashboards,
  ) {
    if (dashboards == null || customPages.isEmpty) return dashboards;
    return [
      ...dashboards,
      {
        'url_path': customPagesDashboardPath,
        'title': 'Custom Pages',
        'icon': customPagesIcon,
        'custom': true,
      },
    ];
  }

  /// Add or change a custom page, once its server answers for it with a
  /// 200. Null when it saved, otherwise why not: `name` (no name), `path`
  /// (neither a file under /local/ nor an http or https URL), `duplicate`
  /// (another page has the path), `not_found` (Home Assistant has no such
  /// file), `status:<code>` (any other answer) or `unreachable`. A page on
  /// another server answers with `url_not_found`, `url_status:<code>` and
  /// `url_unreachable` instead, since Home Assistant is not the one asked.
  /// [original] names the page being changed, which keeps its place in the
  /// list.
  Future<String?> saveCustomPage({
    required String name,
    required String path,
    String? original,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'name';
    final normalized = normalizeCustomPagePath(path, haBase: baseUrl);
    if (normalized == null) return 'path';
    final pages = customPages;
    if (pages.any((p) => p.path == normalized && p.path != original)) {
      return 'duplicate';
    }
    final page = CustomPage(name: trimmed, path: normalized);
    final prefix = page.external ? 'url_' : '';
    if (!page.external && baseUrl.isEmpty) return 'unreachable';
    try {
      // /local/ needs no authorization, so no token goes with the check,
      // and a page elsewhere never gets one.
      final response = await http
          .get(
            Uri.parse(
              page.external
                  ? customPageFile(normalized)
                  : '$baseUrl${customPageFile(normalized)}',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 404) return '${prefix}not_found';
      if (response.statusCode != 200) {
        return '${prefix}status:${response.statusCode}';
      }
    } catch (e) {
      log.warn(this.name, 'custom page check failed for $normalized: $e');
      return '${prefix}unreachable';
    }
    final at = original == null
        ? -1
        : pages.indexWhere((p) => p.path == original);
    final next = [...pages];
    if (at < 0) {
      next.add(page);
    } else {
      next[at] = page;
    }
    await _settings.setFromJson(
      defs.haCustomPages.key,
      encodeCustomPages(next),
    );
    return null;
  }

  /// The navigable dashboards from the page's `hass.panels`: every Lovelace
  /// dashboard plus the auto "Overview" default (panel component `home`),
  /// then the sidebar panels of apps and Home Assistant's own pages such as
  /// Energy, each with the url the sidebar navigates to. Neither has views
  /// (their `lovelace/config` read answers config_not_found), so the
  /// pickers offer them whole. Null when hass is not up.
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
    var NOT_PAGES = ['config', 'developer-tools', 'profile', 'my', 'notfound'];
    var out = [];
    Object.keys(panels).forEach(function (k) {
      var p = panels[k];
      // An app's sidebar panel (Music Assistant, Panalume, Node-RED) is
      // listed too: Home Assistant renders its web UI on that path. The
      // bare "app" panel without an add-on is the app store.
      if (p.component_name === 'app') {
        if (p.config && p.config.addon) {
          out.push({
            url_path: p.url_path,
            title: p.title || p.url_path,
            comp: 'app',
            icon: p.icon || 'mdi:puzzle',
          });
        }
        return;
      }
      var isDash = p.component_name === 'lovelace' || p.component_name === 'home';
      if (!isDash) {
        // Home Assistant's own pages (Energy, Activity, History, Media,
        // To-do lists) and the pages integrations add are listed after the
        // apps. Settings, Developer tools and other admin panels are not
        // pages to show on a kiosk, and neither are the profile, the My
        // link redirect or the not-found page.
        if (p.require_admin || !p.title || NOT_PAGES.indexOf(p.component_name) >= 0) return;
        out.push({
          url_path: p.url_path,
          title: (hass.localize && hass.localize('panel.' + p.title)) || p.title,
          comp: 'builtin',
          icon: p.icon || null,
        });
        return;
      }
      if (p.url_path === 'lovelace' && p.title == null && hasHome) return;
      var title = p.title
        ? ((hass.localize && hass.localize('panel.' + p.title)) || p.title)
        : (p.component_name === 'home' ? 'Overview' : p.url_path);
      out.push({
        url_path: p.url_path,
        title: title,
        comp: p.component_name,
        icon: p.icon || (p.component_name === 'home' ? 'mdi:home' : null),
      });
    });
    // Default dashboard first, matching the sidebar: hass.defaultPanel when
    // set, otherwise the auto "Overview" (component `home`). Apps come
    // after the dashboards and Home Assistant's own pages after the apps.
    // The rest keep their registration order.
    out.sort(function (a, b) {
      function rank(d) {
        if (hass.defaultPanel && d.url_path === hass.defaultPanel) return 0;
        if (d.comp === 'home') return 1;
        if (d.comp === 'app') return 3;
        if (d.comp === 'builtin') return 4;
        return 2;
      }
      return rank(a) - rank(b);
    });
    return JSON.stringify(out.map(function (d) {
      var e = { url_path: d.url_path, title: d.title, icon: d.icon };
      if (d.comp === 'app') e.app = true;
      if (d.comp === 'builtin') e.builtIn = true;
      return e;
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
          {
            'url_path': d['url_path'],
            'title': d['title'],
            if (d['icon'] is String) 'icon': d['icon'],
            if (d['app'] == true) 'app': true,
            if (d['builtIn'] == true) 'builtIn': true,
          },
      ];
    } catch (_) {
      return null;
    }
  }

  /// The views of one dashboard (`lovelace/config`). Each entry carries
  /// `title` and `route` — the path segment HA navigates by: the view's
  /// declared path when it has one, its index otherwise — plus the view's
  /// `icon` when it has one and `subview` when it is one. Null when the
  /// config cannot be read (auto-generated strategy dashboards store no
  /// view list).
  Future<List<Map<String, Object?>>?> listDashboardViews(String urlPath) async {
    if (!configured || urlPath.isEmpty) return null;
    // The Custom Pages entry: its views are the pages, read from the
    // settings rather than Home Assistant.
    if (urlPath == customPagesDashboardPath) {
      return [
        for (final p in customPages)
          {'title': p.name, 'route': p.route, 'icon': customPageIcon},
      ];
    }
    try {
      final result = await _wsCommand({
        'type': 'lovelace/config',
        // The default dashboard is addressed by a null url_path.
        'url_path': urlPath == 'lovelace' ? null : urlPath,
      });
      if (result is! Map) return null;
      final views = result['views'];
      // A stored config without a views list (a strategy config) has no
      // listable views — a normal answer, same as config_not_found below.
      if (views is! List) return const [];
      return [
        for (final (i, v) in views.cast<Map>().indexed)
          {
            'title': '${v['title'] ?? 'View ${i + 1}'}',
            'route': '${v['path'] ?? i}',
            if (v['icon'] is String) 'icon': v['icon'],
            if (v['subview'] == true) 'subview': true,
          },
      ];
    } catch (e) {
      // A dashboard with no stored config (the auto-generated Overview and
      // other strategy dashboards) is a normal answer, not a failure: it
      // simply has no listable views. Callers fall back to the bare path.
      // Reporting it as an error made every remote UI load log 400s.
      if ('$e'.contains('config_not_found')) return const [];
      log.warn(name, 'listDashboardViews($urlPath) failed: $e');
      // Any other error HA itself answered with (a YAML dashboard whose
      // file will not parse, an admin-gated dashboard this token cannot
      // read) condemns only this dashboard, not the connection: report
      // it as view-less so the crawl moves on, offering the dashboard by
      // its bare path like a strategy one (the kiosk's logged-in page
      // user may well render what this token cannot read). The null
      // failure, which aborts a whole crawl to protect the last known
      // list (issue #214), is reserved for transport-level trouble.
      if (e is HaWsError) return const [];
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
      final command = <String, Object?>{'type': 'media_source/browse_media'};
      if (mediaContentId != null) {
        command['media_content_id'] = mediaContentId;
      }
      final result = await _wsCommand(command);
      return result is Map ? result.cast<String, Object?>() : null;
    } catch (e) {
      log.warn(name, 'browseMedia failed: $e');
      return null;
    }
  }

  /// The `camera.*` entities for the camera import, each with the stream
  /// types its frontend offers — WebRTC (issue #124), HLS, or none at
  /// all, in which case MJPEG over the camera proxy is its only path.
  /// Reads all states for names, then asks `camera/capabilities`
  /// (HA 2024.11+) per entity; entities the command fails for (removed
  /// mid-listing, odd integrations) are simply not offered. Null when
  /// Home Assistant is not configured or unreachable.
  Future<List<({String entityId, String name, List<String> streamTypes})>?>
  listStreamableCameras() async {
    final states = await fetchStates();
    if (states == null) return null;
    final result =
        <({String entityId, String name, List<String> streamTypes})>[];
    for (final state in states) {
      final entityId = '${state['entity_id'] ?? ''}';
      if (!entityId.startsWith('camera.')) continue;
      final streamTypes = await cameraCapabilities(entityId);
      if (streamTypes == null) continue;
      final attributes = (state['attributes'] as Map?) ?? const {};
      final friendly = '${attributes['friendly_name'] ?? ''}'.trim();
      result.add((
        entityId: entityId,
        name: friendly.isEmpty
            ? entityId.substring('camera.'.length)
            : friendly,
        streamTypes: streamTypes,
      ));
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  /// The frontend stream types (`web_rtc`, `hls`) Home Assistant reports
  /// for one camera entity, empty when the entity cannot stream at all (a
  /// stills-only camera such as UniFi's package camera: MJPEG is its only
  /// path). Null when Home Assistant is not configured or the query
  /// failed, which callers treat as unknown rather than incapable.
  Future<List<String>?> cameraCapabilities(String entityId) async {
    if (!configured) return null;
    try {
      final capabilities = await _wsCommand({
        'type': 'camera/capabilities',
        'entity_id': entityId,
      });
      final types = capabilities is Map
          ? capabilities['frontend_stream_types']
          : null;
      if (types is! List) return null;
      return [
        for (final type in types)
          if (type == 'web_rtc' || type == 'hls') '$type',
      ];
    } catch (e) {
      log.debug(name, 'camera/capabilities($entityId) failed: $e');
      return null;
    }
  }

  /// The authenticated MJPEG target for [entityId]: Home Assistant's
  /// camera proxy stream, which every camera entity serves regardless of
  /// stream support, plus the bearer token the request must carry (an
  /// `<img>` cannot send headers, so the camera relay fetches it). Null
  /// when Home Assistant is not configured.
  ({Uri uri, String token})? cameraMjpegTarget(String entityId) {
    if (!configured) return null;
    final uri = Uri.tryParse('$baseUrl/api/camera_proxy_stream/$entityId');
    if (uri == null) return null;
    return (uri: uri, token: _settings.get(defs.haToken));
  }

  /// The absolute URL of a fresh HLS playlist for [entityId]
  /// (`camera/stream`): how cameras with no WebRTC path stream at all.
  /// The URL is token-signed by HA, so fetching it (and the segments it
  /// references) needs no Authorization header. Null when Home Assistant
  /// is not configured or could not start the stream.
  Future<String?> cameraStreamUrl(String entityId) async {
    if (!configured) return null;
    try {
      final result = await _wsCommand({
        'type': 'camera/stream',
        'entity_id': entityId,
      });
      final url = result is Map ? '${result['url'] ?? ''}' : '';
      if (url.isEmpty) return null;
      return url.startsWith('http') ? url : '$baseUrl$url';
    } catch (e) {
      log.warn(name, 'camera/stream($entityId) failed: $e');
      return null;
    }
  }

  /// The RTCConfiguration Home Assistant asks WebRTC clients to use for
  /// [entityId] (`camera/webrtc/get_client_config`): ICE servers, which
  /// matter beyond the LAN (cloud TURN). Null when unavailable — the
  /// caller streams with browser defaults, which is what LAN needs.
  Future<Map<String, Object?>?> webRtcClientConfig(String entityId) async {
    if (!configured) return null;
    try {
      final result = await _wsCommand({
        'type': 'camera/webrtc/get_client_config',
        'entity_id': entityId,
      });
      final configuration = result is Map ? result['configuration'] : null;
      return configuration is Map
          ? configuration.cast<String, Object?>()
          : null;
    } catch (e) {
      log.debug(name, 'webrtc client config($entityId) failed: $e');
      return null;
    }
  }

  /// Negotiate a WebRTC stream for a camera entity over Home Assistant's
  /// own signaling (`camera/webrtc/offer`, HA 2024.11+, issue #124).
  ///
  /// The offer should carry its ICE candidates (the camera page waits for
  /// gathering before sending), so no client-side trickle is needed. HA's
  /// side IS trickled: the answer arrives as an event and the backend's
  /// candidates keep arriving after it, so the returned session stays open
  /// for the stream's lifetime relaying them through [onCandidate], and
  /// the caller MUST [HaWebRtcSession.close] it when the stream ends.
  Future<({HaWebRtcSession session, String answer})> cameraWebRtcOffer({
    required String entityId,
    required String offer,
    required void Function(Map<String, Object?> candidate) onCandidate,
  }) async {
    if (!configured) throw StateError('Home Assistant not configured');
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final channel = WebSocketChannel.connect(
      Uri.parse('$wsBase/api/websocket'),
    );
    final session = HaWebRtcSession._(channel);
    final answer = Completer<String>();
    channel.stream.listen(
      (raw) {
        try {
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          switch (msg['type']) {
            case 'auth_required':
              channel.sink.add(
                jsonEncode({
                  'type': 'auth',
                  'access_token': _settings.get(defs.haToken),
                }),
              );
            case 'auth_ok':
              channel.sink.add(
                jsonEncode({
                  'id': 1,
                  'type': 'camera/webrtc/offer',
                  'entity_id': entityId,
                  'offer': offer,
                }),
              );
            case 'auth_invalid':
              if (!answer.isCompleted) {
                answer.completeError(StateError('auth invalid'));
              }
            case 'result':
              if (msg['success'] != true && !answer.isCompleted) {
                answer.completeError(StateError('${msg['error']}'));
              }
            case 'event':
              final event = msg['event'];
              if (event is! Map) return;
              switch ('${event['type']}') {
                case 'answer':
                  if (!answer.isCompleted) {
                    answer.complete('${event['answer']}');
                  }
                case 'candidate':
                  final candidate = event['candidate'];
                  if (candidate is Map && !session.isClosed) {
                    onCandidate(candidate.cast<String, Object?>());
                  }
                case 'error':
                  if (!answer.isCompleted) {
                    answer.completeError(
                      StateError('${event['code']}: ${event['message']}'),
                    );
                  } else {
                    log.warn(
                      name,
                      'webrtc $entityId: ${event['code']} ${event['message']}',
                    );
                  }
              }
          }
        } catch (e) {
          log.warn(name, 'webrtc frame ignored: $e');
        }
      },
      onError: (Object e) {
        if (!answer.isCompleted) answer.completeError(e);
      },
      onDone: () {
        if (!answer.isCompleted) {
          answer.completeError(StateError('signaling socket closed'));
        }
        session._markClosed();
      },
      cancelOnError: true,
    );
    try {
      final sdp = await answer.future.timeout(const Duration(seconds: 15));
      return (session: session, answer: sdp);
    } catch (_) {
      await session.close();
      rethrow;
    }
  }

  /// The language Home Assistant speaks to this token's user ("it",
  /// "en-GB"): the profile language, or the server's own when the user
  /// never picked one. Cached for the run once the server answers.
  String? _language;

  /// Per-domain state translations, keyed by domain. An empty map is a
  /// cached "nothing to translate" (an English server, or a domain Home
  /// Assistant has no translations for), not a miss. Only an answer from
  /// the server lands here, never a failed lookup.
  final _stateTranslations = <String, Map<String, String>>{};

  /// State wording for the At a Glance entities (issue #919), keyed
  /// `language/category/integration`. An empty map is a cached "nothing to
  /// translate", the same as above.
  final _stateLabels = <String, Map<String, String>>{};

  Future<Object?> _wsCommand(Map<String, Object?> command) async {
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final wsUrl = '$wsBase/api/websocket';
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    StreamSubscription<dynamic>? sub;
    try {
      final completer = Completer<Object?>();
      sub = channel.stream.listen(
        (raw) {
          if (completer.isCompleted) return;
          final msg = jsonDecode(raw as String) as Map<String, dynamic>;
          switch (msg['type']) {
            case 'auth_required':
              channel.sink.add(
                jsonEncode({
                  'type': 'auth',
                  'access_token': _settings.get(defs.haToken),
                }),
              );
            case 'auth_ok':
              channel.sink.add(jsonEncode({'id': 1, ...command}));
            case 'auth_invalid':
              completer.completeError(StateError('auth invalid'));
            case 'result':
              if (msg['success'] == true) {
                completer.complete(msg['result']);
              } else {
                completer.completeError(HaWsError('${msg['error']}'));
              }
          }
        },
        onError: (Object e, StackTrace s) {
          // Guarded: an error after the result (or a second result frame)
          // must not throw "Future already completed" into the stream zone.
          if (!completer.isCompleted) completer.completeError(e, s);
        },
      );

      return await completer.future.timeout(const Duration(seconds: 10));
    } finally {
      await sub?.cancel();
      await channel.sink.close();
    }
  }

  final _esphomeDevices = <String, String>{};
  final _esphomeMisses = <String, DateTime>{};

  /// Home Assistant's device for the ESPHome server reporting [mac], the
  /// kiosk's own device, found by its entities' unique IDs. Null while
  /// Home Assistant has not adopted it. A miss is not asked again for a
  /// minute, so actions on a kiosk without one do not fetch the registry
  /// every time.
  Future<String?> esphomeDeviceId(String mac) async {
    final lower = mac.toLowerCase();
    if (lower.isEmpty || !configured) return null;
    final key = '$baseUrl $lower';
    if (_esphomeDevices[key] case final cached?) return cached;
    final missed = _esphomeMisses[key];
    if (missed != null &&
        DateTime.now().difference(missed) < const Duration(minutes: 1)) {
      return null;
    }
    try {
      final list = await _wsCommand({'type': 'config/entity_registry/list'});
      if (list is List) {
        for (final raw in list) {
          if (raw is! Map || raw['platform'] != 'esphome') continue;
          final unique = '${raw['unique_id'] ?? ''}'.toLowerCase();
          final device = raw['device_id'];
          if (unique.startsWith('$lower-') && device is String) {
            _esphomeMisses.remove(key);
            return _esphomeDevices[key] = device;
          }
        }
      }
    } catch (e) {
      log.debug(name, 'kiosk device lookup failed: $e');
    }
    _esphomeMisses[key] = DateTime.now();
    return null;
  }

  @override
  Future<void> dispose() async {
    await _remoteObservers?.cancel();
    _pluginEntities.dispose();
    _themeTimer?.cancel();
    _revalidateTimer?.cancel();
    _rotationTimer?.cancel();
    _touchPauseTimer?.cancel();
    _voiceSafetyTimer?.cancel();
    _returnHomeTimer?.cancel();
    _holdReleaseTimer?.cancel();
    WidgetsBinding.instance.removeObserver(_brightnessWatch);
  }
}

/// The profile language out of a `frontend/get_user_data` reply for the
/// `language` key, as the frontend saves it: `{value: {language: "nl"}}`.
/// Null when the user never picked one and follows the server.
String? userLanguage(Object? result) {
  final value = result is Map ? result['value'] : null;
  final language = value is Map ? '${value['language'] ?? ''}'.trim() : '';
  return language.isEmpty ? null : language;
}

/// The state translations out of a `frontend/get_translations` result, keyed
/// by bare state. Home Assistant answers with one flat map of dotted keys —
/// `component.weather.entity_component._.state.fog` — where the segment
/// before `.state.` names a device class and `_` is the domain's own,
/// class-less states. Only those are wanted here: a device class ("humidity"
/// sensors and such) translates the same states differently, and picking one
/// at random would be worse than the built-in wording.
Map<String, String> parseStateTranslations(Object? result, String domain) {
  final resources = result is Map ? result['resources'] : null;
  if (resources is! Map) return const {};
  final prefix = 'component.$domain.entity_component._.state.';
  final out = <String, String>{};
  for (final entry in resources.entries) {
    final key = '${entry.key}';
    final value = entry.value;
    if (key.startsWith(prefix) && value is String && value.isNotEmpty) {
      out[key.substring(prefix.length)] = value;
    }
  }
  return out;
}

/// The state wording out of a `frontend/get_translations` reply, split by
/// the integration each key belongs to so each one caches on its own.
/// Attribute states (`state_attributes`) are left out: the row shows the
/// state.
Map<String, Map<String, String>> parseStateLabels(Object? result) {
  final resources = result is Map ? result['resources'] : null;
  final out = <String, Map<String, String>>{};
  if (resources is! Map) return out;
  for (final entry in resources.entries) {
    final key = '${entry.key}';
    final value = entry.value;
    if (value is! String || value.isEmpty) continue;
    if (!key.contains('.state.') || key.contains('.state_attributes.')) {
      continue;
    }
    final parts = key.split('.');
    if (parts.length < 2 || parts[0] != 'component') continue;
    (out[parts[1]] ??= {})[key] = value;
  }
  return out;
}

/// Home Assistant's own wording for entity states (issue #919), picked the
/// way its frontend picks it: the integration's wording for the entity's
/// translation key first, then the domain's for its device class, then the
/// domain's own. "off" on a window sensor reads "Closed".
class EntityStateLabels {
  const EntityStateLabels(this._resources, this._keys);

  /// The translations, dotted the way Home Assistant sends them.
  final Map<String, String> _resources;

  /// Each entity's integration and translation key, for the entities that
  /// have one.
  final Map<String, (String, String)> _keys;

  /// The wording for [state], or null when Home Assistant has none, which
  /// is the case for every number.
  String? label(String entityId, String? deviceClass, String state) {
    final domain = entityId.split('.').first;
    final key = _keys[entityId];
    if (key != null) {
      final text =
          _resources['component.${key.$1}.entity.$domain.${key.$2}.state.$state'];
      if (text != null) return text;
    }
    if (deviceClass != null && deviceClass.isNotEmpty) {
      final text =
          _resources['component.$domain.entity_component.$deviceClass.state.$state'];
      if (text != null) return text;
    }
    return _resources['component.$domain.entity_component._.state.$state'];
  }
}

/// An error Home Assistant itself answered with (a `result` frame carrying
/// `success: false`), as opposed to transport failures (socket down,
/// timeout), which keep their own exception types. The distinction lets
/// callers tell "HA said no to this request" from "HA is unreachable".
/// Extends StateError so the message keeps its historical "Bad state:"
/// rendering for logs and substring checks.
class HaWsError extends StateError {
  HaWsError(super.message);
}

/// A live Home Assistant WebRTC signaling session (issue #124): the socket
/// stays open for the stream's lifetime so the backend's trickled ICE
/// candidates keep arriving. Closed by whoever opened it when the stream
/// ends; closing tells HA to tear the backend session down.
class HaWebRtcSession {
  HaWebRtcSession._(this._channel);

  final WebSocketChannel _channel;
  bool _closed = false;

  bool get isClosed => _closed;

  void _markClosed() => _closed = true;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _channel.sink.close();
    } catch (_) {}
  }
}

/// A live entity subscription, closed by whoever opened it.
class GlanceSubscription {
  GlanceSubscription._(this._channel);

  /// How often a live subscription pings Home Assistant, and how long it
  /// waits for the pong.
  @visibleForTesting
  static Duration heartbeat = const Duration(seconds: 30);
  @visibleForTesting
  static Duration pongTimeout = const Duration(seconds: 10);

  /// How long a new subscription may take to connect, sign in and
  /// subscribe before it counts as lost.
  @visibleForTesting
  static Duration subscribeTimeout = const Duration(seconds: 20);

  final WebSocketChannel _channel;
  bool _closed = false;
  Timer? _heartbeat, _deadline, _connecting;
  // Ids 1 to 8 are the subscribe, forecast, registry, language and
  // translation commands, numbered in the order they go out. Home Assistant
  // rejects an id lower than one it already saw, so a ping that reused 7
  // got no pong and the row reconnected every 40 seconds (issue #1131).
  int _pingId = 9;

  bool get isClosed => _closed;

  /// Fired when the socket dies underneath us (server gone, network drop) —
  /// NOT on a deliberate [close]. The owner uses it to reopen; without it a
  /// subscription that died after establishing stayed dead until the
  /// screensaver cycled.
  void Function()? onClosed;

  /// A connection that dies without closing, such as one a router drops
  /// while the device sleeps, delivers nothing and never reports it. Home
  /// Assistant answers every ping, so a missed pong counts as a close and
  /// the owner reopens. Without it Weather Mood kept last night's sun and
  /// weather at noon.
  /// A connection attempt that neither fails nor finishes, or fails before
  /// the heartbeat starts, would otherwise leave the owner waiting on a
  /// subscription that never delivers. Weather Mood kept 02:20's weather
  /// all morning after a reconnect ran into a Wi-Fi drop.
  void _expectSubscribed() {
    _connecting = Timer(subscribeTimeout, _lost);
  }

  void _startHeartbeat() {
    _connecting?.cancel();
    _connecting = null;
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(heartbeat, (_) {
      if (_closed) return;
      try {
        _channel.sink.add(jsonEncode({'id': _pingId++, 'type': 'ping'}));
      } catch (_) {}
      _deadline ??= Timer(pongTimeout, _lost);
    });
  }

  void _pong() {
    _deadline?.cancel();
    _deadline = null;
  }

  void _lost() {
    if (_closed) return;
    _markClosed();
    unawaited(_channel.sink.close().catchError((_) {}));
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _deadline?.cancel();
    _connecting?.cancel();
    _heartbeat = _deadline = _connecting = null;
  }

  void _markClosed() {
    if (_closed) return;
    _closed = true;
    _stopHeartbeat();
    onClosed?.call();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _stopHeartbeat();
    try {
      await _channel.sink.close();
    } catch (_) {}
  }
}

/// A minimal binding observer that forwards platform dark-mode flips.
/// Its own object rather than a mixin on the manager: the manager needs
/// exactly one callback from the widgets binding, not the whole observer
/// surface.
class _PlatformBrightnessWatch with WidgetsBindingObserver {
  _PlatformBrightnessWatch(this.onChanged);

  final void Function() onChanged;

  @override
  void didChangePlatformBrightness() => onChanged();
}

/// A navigation path without its outer slashes, "url_path/view-route",
/// keeping a query or fragment after it ("cameras/0?camera=garage").
String normalizeViewPath(String raw) {
  final value = raw.trim();
  final cut = value.indexOf(RegExp(r'[?#]'));
  final route = (cut < 0 ? value : value.substring(0, cut)).replaceAll(
    RegExp(r'^/+|/+$'),
    '',
  );
  return cut < 0 || route.isEmpty ? route : route + value.substring(cut);
}

/// The route part of a navigation path, the part location.pathname shows.
String viewRoute(String viewPath) => viewPath.split(RegExp(r'[?#]')).first;
