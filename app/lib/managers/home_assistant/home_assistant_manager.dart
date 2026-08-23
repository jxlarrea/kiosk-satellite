import 'dart:async';
import 'dart:convert';

import 'dart:ui' show Brightness;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/ha_http_overrides.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../browser/rotation_fade_script.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'dashboard_list.dart';

/// Home Assistant connection: long-lived-token auth, connection validation,
/// and the dashboard list used by the dashboard picker.
///
/// Later milestones add MQTT discovery publishing and HA event
/// subscriptions for event-driven navigation.
class HomeAssistantManager extends Manager {
  HomeAssistantManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this._holdReleaseUnit = const Duration(minutes: 1),
  });

  final SettingsManager _settings;

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
        // Another server may speak another language.
        _language = null;
        _stateTranslations.clear();
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
          name: 'haSearchEntities',
          description:
              'Search entities by id or friendly name, for the At a Glance '
              'picker. Returns at most 50, closest matches first.',
          params: const {'query': 'text to match against id and name'},
          handler: (p) async {
            final matches = await searchEntities('${p['query'] ?? ''}');
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
          handler: (_) async {
            final dashboards = await listDashboards();
            return dashboards == null
                ? const CommandResult.fail('could not list dashboards')
                : CommandResult.ok(dashboards);
          },
        ),
      )
      ..register(
        Command(
          name: 'haListDashboardViews',
          description: "One dashboard's views, for the rotation picker",
          params: const {'url_path': "the dashboard's url_path"},
          handler: (p) async {
            final views = await listDashboardViews('${p['url_path'] ?? ''}');
            return views == null
                ? const CommandResult.fail('could not read the dashboard')
                : CommandResult.ok(views);
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
            final path = '${p['path'] ?? ''}'.trim().replaceAll(
              RegExp(r'^/+|/+$'),
              '',
            );
            if (path.isEmpty) return const CommandResult.fail('no path');
            if (!configured) {
              return const CommandResult.fail('Home Assistant not configured');
            }
            await commands.execute('stopScreensaver', const {});
            await commands.execute('hideCameraView', const {});
            // A commanded view should not instantly rotate away: give it the
            // same grace window a touch gets.
            if (_rotationTimer != null) _pauseRotationForTouch();
            // The outcome travels in the result so the MQTT select knows
            // whether the page actually moved before echoing state.
            return CommandResult.ok(await navigateToViewPath(path));
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
              'start, debug logging, skin, theme mode, reactive bar, text '
              'scale) through '
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
      if (e.key == defs.themeAuto.key ||
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
      // haRotationPauseSeconds is read at pause time and
      // haRotationCrossfade at tick time; nothing to rebuild for either.
    });
    // While the screensaver is up (or the app is not on screen) rotation
    // would navigate views nobody sees — and a strategy view's hard load
    // would churn the Voice Satellite session for nothing. The ring freezes
    // in place and picks up where it left off.
    bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      if (e.active) {
        // The screensaver reached idle first: do the return now, quietly
        // behind the cover, so the wake reveals the home dashboard with no
        // visible navigation. Only rendering is frozen under the pause
        // optimization — JS pushed from Dart still executes — so this
        // works with the dashboard WebView hidden.
        _returnHomeTimer?.cancel();
        _returnHomeTimer = null;
        if (_returnHomeConfigured && !_holdActive) unawaited(_returnHome());
      } else {
        _configureReturnHome();
      }
    });
    // Touch pauses rotation for the configured window so the current view
    // can be used; each touch restarts that window.
    bus.on<ActivityDetected>().listen((e) {
      if (e.source == 'touch') _pauseRotationForTouch();
      _configureReturnHome();
    });
    // Any navigation counts as activity for the return-home clock: the
    // user moving through views is exactly the "in use" it must not
    // interrupt (our own return resets it too, harmlessly).
    bus.on<UrlChanged>().listen((_) => _configureReturnHome());
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
    // lifecycleState is NULL until Android delivers the first transition
    // (i.e. for the whole first foreground session) — null means resumed.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (_screensaverActive ||
        _holdActive ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
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
    final uri = Uri.tryParse(_settings.get(defs.startUrl));
    if (uri == null) return null;
    final path = uri.path.replaceAll(RegExp(r'^/+|/+$'), '');
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
  Future<void> _returnHome() async {
    final path = homeViewPath();
    if (path == null) return;
    await navigateToViewPath(path);
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
  /// moved) or 'failed' — so callers reporting state elsewhere (the MQTT
  /// select) do not have to guess.
  Future<String> navigateToViewPath(
    String viewPath, {
    bool crossfade = false,
  }) async {
    if (baseUrl.isEmpty || viewPath.isEmpty) return 'failed';
    final seq = ++_navSeq;
    // A path a soft navigation cannot resolve goes straight to a full load
    // (loadUrl drops the overlay itself). One-time discovery below.
    if (_hardLoadPaths.contains(viewPath)) {
      await commands.execute('loadUrl', {'url': '$baseUrl/$viewPath'});
      return 'navigated';
    }
    // With the secure context proxy on, the page lives on the loopback
    // origin, not baseUrl — guard against what is actually on screen.
    final mappedBase = await commands.execute('proxyMapUrl', {'url': baseUrl});
    final effectiveBase = mappedBase.ok && mappedBase.data is String
        ? mappedBase.data as String
        : baseUrl;
    if (crossfade) {
      final fade = await commands.execute('evalJs', {
        'code': rotationCrossfadeJs(base: effectiveBase, viewPath: viewPath),
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
    final outcome = nav.ok ? '${nav.data}' : 'failed';
    if (outcome != 'navigated') {
      return outcome == 'already' || outcome == 'off-origin'
          ? outcome
          : 'failed';
    }
    // Self-heal, once per path: a soft navigation cannot resolve every
    // dashboard — strategy dashboards (the auto "Overview") and redirect
    // aliases leave the panel spinning forever. If it is still spinning
    // shortly after the soft nav, remember the path as hard-load-only and
    // do the full load now; every later pass goes straight to loadUrl with
    // no spinner-then-reload double hit.
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (_navSeq != seq) return 'navigated';
    final check = await commands.execute('evalJs', {
      'code':
          '''
(function () {
  try {
    if (location.pathname !== '/' + ${jsonEncode(viewPath)}) return false;
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
      await commands.execute('loadUrl', {'url': '$baseUrl/$viewPath'});
    }
    return 'navigated';
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
    final matchApp = _settings.get(defs.themeMatchApp);
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
        if (!force && dark == _lastDark) return;
        _lastDark = dark;
        await commands.execute('evalJs', {'code': _themeJs(dark)});
        return;
      }
    }
    // The mirror (issue #92): the dashboard follows the app's EFFECTIVE
    // theme — the App theme setting, or the device's own dark mode when it
    // is System, which Android flips at its own sunset/sunrise.
    if (matchApp) {
      final dark = _effectiveAppDark();
      if (!force && dark == _lastDark) return;
      _lastDark = dark;
      await commands.execute('evalJs', {'code': _themeJs(dark)});
      return;
    }
    _lastDark = null;
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
  Future<GlanceSubscription?> subscribeEntities(
    List<String> entityIds,
    void Function(String entityId, Map<String, Object?> state) onState, {
    void Function(Map<String, int> precisions)? onPrecision,
  }) async {
    if (!configured || entityIds.isEmpty) return null;
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse('$wsBase/api/websocket'),
      );
      final subscription = GlanceSubscription._(channel);
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
                if (onPrecision != null) {
                  channel.sink.add(
                    jsonEncode({
                      'id': 2,
                      'type': 'config/entity_registry/get_entries',
                      'entity_ids': entityIds,
                    }),
                  );
                }
              case 'auth_invalid':
                log.warn(name, 'glance subscription rejected: bad token');
                subscription.close();
              case 'result':
                // The subscribe command confirms itself here too; only the
                // registry lookup's reply carries anything to read. A failure
                // (an old Home Assistant without get_entries) just leaves
                // states unrounded, which is what the row always did.
                if (msg['id'] == 2 && msg['success'] == true) {
                  onPrecision?.call(_displayPrecisions(msg['result']));
                }
              case 'event':
                _handleEntityEvent(msg['event'], onState);
            }
          } catch (e) {
            log.warn(name, 'glance frame ignored: $e');
          }
        },
        onError: (Object e) => log.warn(name, 'glance socket error: $e'),
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

  /// Entities matching [query], for the At a Glance picker.
  ///
  /// `/api/states` is the whole instance in one response, which is why the
  /// result is capped and why this is called per search rather than kept:
  /// a big instance is a few hundred kilobytes and there is no reason to
  /// hold it on a device this feature exists to keep light.
  ///
  /// An exact id or a name that starts with the query sorts first, so
  /// typing "gara" puts Garage Door above Front Garage Light Sensor.
  Future<List<Map<String, Object?>>?> searchEntities(String query) async {
    final states = await fetchStates();
    if (states == null) return null;
    final needle = query.trim().toLowerCase();
    final matches = <(int, String, Map<String, Object?>)>[];
    for (final state in states) {
      final id = '${state['entity_id'] ?? ''}';
      if (id.isEmpty) continue;
      final attributes = (state['attributes'] as Map?) ?? const {};
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
      // YAML-mode dashboards included: they read over `lovelace/config`
      // the same as storage ones. Keeping only storage dashboards here
      // dropped every YAML dashboard from the view selects (issue #244).
      return dashboardsFromWsList(result);
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
  Future<List<Map<String, Object?>>?> listDashboardViews(String urlPath) async {
    if (!configured || urlPath.isEmpty) return null;
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

  /// The language Home Assistant itself is configured in ("it", "en-GB"),
  /// from its core config. Cached for the run — it changes about as often
  /// as the server moves house, and a failed read is not cached so the next
  /// caller retries.
  String? _language;

  /// Per-domain state translations, keyed by domain. An empty map is a
  /// cached "nothing to translate" (an English server, or a domain Home
  /// Assistant has no translations for), not a miss.
  final _stateTranslations = <String, Map<String, String>>{};

  Future<String> serverLanguage() async {
    final cached = _language;
    if (cached != null) return cached;
    if (!configured) return 'en';
    try {
      final config = await _wsCommand({'type': 'get_config'});
      final language = config is Map
          ? '${config['language'] ?? ''}'.trim()
          : '';
      if (language.isEmpty) return 'en';
      return _language = language;
    } catch (e) {
      log.debug(name, 'language lookup failed: $e');
      return 'en';
    }
  }

  /// Home Assistant's own translations for a domain's entity states, keyed
  /// by state ("fog" -> "Nebbia"), in the server's language (issue #268).
  /// This is exactly what the frontend renders states with, so a kiosk in a
  /// Dutch or Italian house reads like the rest of the house.
  ///
  /// Empty when the server speaks English (the app's own wording already
  /// is, and it is often the better wording), when the domain carries no
  /// state translations, or when the lookup fails: every caller falls back
  /// to its built-in labels.
  Future<Map<String, String>> stateTranslations(String domain) async {
    final cached = _stateTranslations[domain];
    if (cached != null) return cached;
    if (!configured) return const {};
    final language = await serverLanguage();
    if (language.toLowerCase().startsWith('en')) {
      return _stateTranslations[domain] = const {};
    }
    try {
      final result = await _wsCommand({
        'type': 'frontend/get_translations',
        'language': language,
        'category': 'entity_component',
        'integration': [domain],
      });
      return _stateTranslations[domain] = parseStateTranslations(
        result,
        domain,
      );
    } catch (e) {
      log.debug(name, 'state translations for $domain failed: $e');
      return const {};
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

  @override
  Future<void> dispose() async {
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

  final WebSocketChannel _channel;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Fired when the socket dies underneath us (server gone, network drop) —
  /// NOT on a deliberate [close]. The owner uses it to reopen; without it a
  /// subscription that died after establishing stayed dead until the
  /// screensaver cycled.
  void Function()? onClosed;

  void _markClosed() {
    if (_closed) return;
    _closed = true;
    onClosed?.call();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
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
