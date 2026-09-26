import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../update/update_http_client.dart';
import 'analytics_scrub.dart';
import 'crash_journal.dart';

/// Kiosk Satellite Analytics: what the three switches under Settings >
/// Device > Kiosk Satellite Analytics let leave the device, and when.
///
/// One snapshot a day carries the Basic analytics (the device) and Usage
/// (which features are on) parts, each only while its switch is on; a crash
/// the native CrashJournal recorded goes out once, on the next start, while
/// Diagnostics is on. Everything goes to one endpoint over HTTPS with
/// certificates always verified, under a random install id that exists only
/// while at least one switch is on. docs/analytics.md is the contract this
/// class implements; change one and change the other.
class AnalyticsManager extends Manager {
  AnalyticsManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this.endpoint = defaultEndpoint,
    this.clientFactory = createStrictHttpClient,
    this.firstDelay = const Duration(minutes: 3),
    this.snapshotInterval = const Duration(hours: 24),
    this.tickInterval = const Duration(hours: 1),
    DateTime Function()? now,
    Random? random,
  }) : _now = now ?? DateTime.now,
       _random = random ?? Random.secure();

  static const defaultEndpoint =
      'https://analytics.kiosksatellite.com/v1/report';

  /// The wire format's version, bumped when a field changes meaning.
  static const schema = 1;

  static const _installIdKey = 'analytics_install_id';
  static const _lastSnapshotKey = 'analytics_last_snapshot';
  static const _sentCrashesKey = 'analytics_sent_crashes';
  static const _vsSeenKey = 'analytics_vs_seen';

  /// How long a Voice Satellite sighting keeps an install reading
  /// 'installed' while the page hook is not answering.
  static const vsMemory = Duration(days: 7);

  /// How many crashes one tick reports at most: a journal that holds a
  /// history of them trickles out rather than bursting.
  static const crashesPerTick = 3;

  /// How many of the journal's newest reportable entries are ever
  /// candidates. The journal is capped in bytes and can hold more short
  /// entries than the fingerprints remembered below: a kiosk whose journal
  /// held 53 watchdog notes from one bad morning sent them, forgot the
  /// oldest fingerprints as the list rolled, and sent them all again the
  /// next day, seventy reports a day for a week. Anything older than the
  /// newest [crashCandidates] entries is history the journal keeps for the
  /// Logs screen, not a report.
  static const crashCandidates = 40;

  /// How many fingerprints to remember: comfortably more than the
  /// candidates, so a remembered entry stays remembered until it has left
  /// the candidate window.
  static const _rememberedCrashes = 200;
  static const _background = MethodChannel('kiosk_satellite/background');

  final SettingsManager _settings;
  final String endpoint;
  final http.Client Function() clientFactory;

  /// How long after start the first snapshot may go: the app has settled,
  /// the network is up, and a device that reboots in a loop never reports.
  final Duration firstDelay;
  final Duration snapshotInterval;
  final Duration tickInterval;
  final DateTime Function() _now;
  final Random _random;

  Timer? _first;
  Timer? _ticker;
  bool _sending = false;

  @override
  String get name => 'analytics';

  bool get basicOn => _settings.get(defs.analyticsBasic);
  bool get usageOn => _settings.get(defs.analyticsUsage);
  bool get diagnosticsOn => _settings.get(defs.analyticsDiagnostics);
  bool get anyOn => basicOn || usageOn || diagnosticsOn;

  /// The random id this install reports under; empty while every switch
  /// is off, since nothing is reported then and nothing should link a
  /// later opt-in to an earlier one.
  String get installId => _settings.internal(_installIdKey);

  /// When the last snapshot went out, null before the first.
  DateTime? get lastSnapshot {
    final raw = int.tryParse(_settings.internal(_lastSnapshotKey));
    return raw == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }

  @override
  Future<void> init() async {
    bus.on<SettingChanged>().listen((e) {
      if (e.key != defs.analyticsBasic.key &&
          e.key != defs.analyticsUsage.key &&
          e.key != defs.analyticsDiagnostics.key) {
        return;
      }
      if (!anyOn) unawaited(_forget());
    });
    if (!anyOn) await _forget();

    commands.register(
      Command(
        name: 'getAnalyticsReport',
        description:
            'The snapshot Kiosk Satellite Analytics would send right now, '
            'and when the last one went out',
        handler: (_) async {
          // The snapshot first: building it mints the id it reports under.
          final snapshot = await buildSnapshot();
          return CommandResult.ok({
            'installId': installId,
            'lastSnapshot': lastSnapshot?.toIso8601String(),
            'snapshot': snapshot,
          });
        },
      ),
    );
    commands.register(
      Command(
        name: 'sendAnalyticsNow',
        description:
            'Send the analytics snapshot without waiting for the '
            'daily schedule',
        handler: (_) async {
          final sent = await sendSnapshot(force: true);
          return sent
              ? const CommandResult.ok()
              : const CommandResult.fail('not sent');
        },
      ),
    );

    _first = Timer(firstDelay, () {
      unawaited(_tick());
      _ticker = Timer.periodic(tickInterval, (_) => unawaited(_tick()));
    });
  }

  @override
  Future<void> dispose() async {
    _first?.cancel();
    _ticker?.cancel();
  }

  Future<void> _tick() async {
    await sendCrashIfAny();
    await sendSnapshot();
  }

  /// Drop everything that identifies this install. Called when the last
  /// switch goes off, so turning one back on starts a new, unlinked id.
  Future<void> _forget() async {
    await _settings.setInternal(_installIdKey, '');
    await _settings.setInternal(_lastSnapshotKey, '');
    await _settings.setInternal(_sentCrashesKey, '');
    await _settings.setInternal(_vsSeenKey, '');
  }

  Future<String> _ensureInstallId() async {
    final current = installId;
    if (current.isNotEmpty) return current;
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _settings.setInternal(_installIdKey, id);
    return id;
  }

  /// Whether a snapshot is due: never sent, or [snapshotInterval] ago.
  bool get snapshotDue {
    final last = lastSnapshot;
    return last == null || _now().toUtc().difference(last) >= snapshotInterval;
  }

  /// Send the daily snapshot if one is due (or [force]), while Basic
  /// analytics or Usage is on. True when the server accepted it.
  Future<bool> sendSnapshot({bool force = false}) async {
    if (!basicOn && !usageOn) return false;
    if (!force && !snapshotDue) return false;
    if (_sending) return false;
    _sending = true;
    try {
      final body = await buildSnapshot();
      if (body == null) return false;
      final ok = await _post(body);
      if (ok) {
        await _settings.setInternal(
          _lastSnapshotKey,
          '${_now().toUtc().millisecondsSinceEpoch}',
        );
      }
      return ok;
    } finally {
      _sending = false;
    }
  }

  /// Report the crashes the native journal holds that have not been
  /// reported yet, while Diagnostics is on: each entry once, by
  /// fingerprint. Frame watchdog restarts count (a wedged UI is a failure
  /// nobody asked for); restarts a person or an automation requested do
  /// not. The
  /// journal is left alone: the device manager keeps it for the Logs
  /// screen until the journal trims it, so the remembered fingerprints
  /// are what stop a repeat. True when at least one report went out.
  Future<bool> sendCrashIfAny() async {
    if (!diagnosticsOn) return false;
    final entries = parseCrashJournal(await _readCrashJournal());
    if (entries.isEmpty) return false;
    final sent = _sentCrashes();
    final pending = <(String, CrashEntry)>[];
    var considered = 0;
    for (final e in entries.reversed) {
      if (!e.reportable) continue;
      if (++considered > crashCandidates) break;
      final fp = sha256.convert(utf8.encode(e.text)).toString();
      if (sent.contains(fp)) continue;
      pending.add((fp, e));
      if (pending.length >= crashesPerTick) break;
    }
    if (pending.isEmpty) return false;
    final app = await _appInfo();
    final android = await _androidInfo();
    var any = false;
    for (final (fp, e) in pending) {
      final body = {
        'schema': schema,
        'kind': 'crash',
        'install_id': await _ensureInstallId(),
        'sent_at': _now().toUtc().toIso8601String(),
        // The version that crashed, when the journal says; the running
        // one is only a fallback for a headerless entry.
        'app': {...app, if (e.appVersion != null) 'version': e.appVersion},
        'android': android,
        if (e.recordedAt != null) 'recorded_at': e.recordedAt,
        'cause': e.watchdog ? 'watchdog' : 'exception',
        'crash': clipDiagnostics(scrubDiagnostics(e.text)),
      };
      if (!await _post(body)) {
        break;
      }
      any = true;
      sent.add(fp);
      await _settings.setInternal(
        _sentCrashesKey,
        sent
            .skip(
              sent.length > _rememberedCrashes
                  ? sent.length - _rememberedCrashes
                  : 0,
            )
            .join(','),
      );
    }
    return any;
  }

  List<String> _sentCrashes() => [
    for (final fp in _settings.internal(_sentCrashesKey).split(','))
      if (fp.isNotEmpty) fp,
  ];

  /// The snapshot as it would go out now: the parts whose switches are on,
  /// or null when neither is.
  Future<Map<String, Object?>?> buildSnapshot() async {
    if (!basicOn && !usageOn) return null;
    return {
      'schema': schema,
      'kind': 'snapshot',
      'install_id': await _ensureInstallId(),
      'sent_at': _now().toUtc().toIso8601String(),
      'app': await _appInfo(),
      if (basicOn) 'basic': await _basic(),
      if (usageOn) 'usage': await _usage(),
    };
  }

  /// The device's memory as the box would print it: Android reports what
  /// is left after the kernel and reserved regions take their share, so an
  /// 8 GB tablet says 7.6 GiB and a 12 GB one 11.4. Rounding up to the
  /// next size devices are sold with gives the nominal figure back
  /// without inventing one; past the ladder, the next whole gigabyte.
  /// Null when unknown.
  static double? nominalRamGb(Object? totalBytes) {
    if (totalBytes is! num || totalBytes <= 0) return null;
    final gib = totalBytes / (1024 * 1024 * 1024);
    const ladder = [0.5, 1, 1.5, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64];
    for (final size in ladder) {
      if (gib <= size) return size.toDouble();
    }
    return gib.ceilToDouble();
  }

  Future<Map<String, Object?>> _deviceInfo() async {
    try {
      final r = await commands.execute('getDeviceInfo', const {});
      final data = r.data;
      if (data is Map) return Map<String, Object?>.from(data);
    } catch (_) {}
    return const {};
  }

  Future<Map<String, Object?>> _appInfo() async {
    final d = await _deviceInfo();
    return {
      'version': d['appVersion'] ?? '',
      'build': d['buildNumber'] ?? '',
      'mode': d['buildMode'] ?? (kDebugMode ? 'debug' : 'release'),
    };
  }

  Future<Map<String, Object?>> _androidInfo() async {
    final d = await _deviceInfo();
    return {'version': d['osVersion'] ?? '', 'sdk': d['sdkInt']};
  }

  /// Basic analytics: the device, as docs/analytics.md lists it. No name,
  /// no address, no id of the hardware's own.
  Future<Map<String, Object?>> _basic() async {
    final d = await _deviceInfo();
    final now = _now();
    return {
      'manufacturer': d['manufacturer'] ?? '',
      'model': d['model'] ?? '',
      'android': d['osVersion'] ?? '',
      'sdk': d['sdkInt'],
      'abis': d['abis'] ?? const [],
      'screen': {
        'width': d['screenWidth'],
        'height': d['screenHeight'],
        'density': d['screenDensity'],
      },
      'locale': Platform.localeName,
      'timezone': now.timeZoneName,
      'utc_offset_minutes': now.timeZoneOffset.inMinutes,
      'ram_gb': nominalRamGb(d['ramTotal']),
      // The system WebView the dashboard runs in: a component that
      // updates on its own, so the version says which Chromium the
      // Home Assistant frontend meets on this device.
      'webview': d['webviewPackage'] ?? '',
      'webview_version': d['webviewVersion'] ?? '',
    };
  }

  /// Usage: which features are on. Booleans, picks, counts and short
  /// catalog names only, never the values behind them (no URLs, names,
  /// entities or credentials).
  Future<Map<String, Object?>> _usage() async {
    final s = _settings;
    String fleetRole() {
      if (s.get(defs.fleetLeader)) return 'leader';
      if (s.get(defs.fleetLeaderInfo).trim().isNotEmpty) return 'follower';
      return 'none';
    }

    // Gestures: how many mappings, and which trigger and action kinds
    // they use. The kinds are the editor's own vocabulary ('claps',
    // 'screensaver'), never what a mapping points at.
    var mappings = 0;
    final triggers = <String>{};
    final actions = <String>{};
    try {
      final raw = jsonDecode(s.get(defs.gestureMappings));
      if (raw is List) {
        mappings = raw.length;
        for (final m in raw) {
          if (m is! Map) continue;
          final t = m['trigger'];
          final a = m['action'];
          if (t is Map && t['type'] is String) {
            triggers.add(t['type'] as String);
          }
          if (a is Map && a['type'] is String) actions.add(a['type'] as String);
        }
      }
    } catch (_) {}

    // Screensaver widgets: which kinds sit in the corners.
    var widgetCount = 0;
    final widgets = <String>{};
    try {
      final raw = jsonDecode(s.get(defs.screensaverWidgets));
      if (raw is List) {
        widgetCount = raw.length;
        for (final w in raw) {
          if (w is Map && w['type'] is String) widgets.add(w['type'] as String);
        }
      }
    } catch (_) {}

    // Camera Streams: how much is configured, as counts. The servers,
    // sources and views themselves carry addresses and names.
    var cameraServers = 0;
    var cameraSources = 0;
    var cameraViews = 0;
    try {
      final raw = jsonDecode(s.get(defs.cameraConfig));
      if (raw is Map) {
        int count(String k) => raw[k] is List ? (raw[k] as List).length : 0;
        cameraServers = count('servers');
        cameraSources = count('cameras');
        cameraViews = count('views');
      }
    } catch (_) {}

    // Which plugins are installed, by the id their manifest declares: a
    // public name from the repository the plugin came from, never a
    // setting or a value the plugin holds. Sorted, so two installs with
    // the same plugins read the same.
    var pluginIds = <String>[];
    var pluginsEnabled = false;
    try {
      final r = await commands.execute('getPluginState', const {});
      final data = r.data;
      if (data is Map) {
        pluginsEnabled = data['enabled'] == true;
        final list = data['plugins'];
        if (list is List) {
          pluginIds = [
            for (final item in list)
              if (item is Map && item['id'] is String) item['id'] as String,
          ]..sort();
        }
      }
    } catch (_) {}

    // What Voice Satellite is listening for and with: the wake word
    // manager's state. Names only; a model name is a catalog label, not
    // the user's audio.
    var wakeEngine = '';
    var wakeWord = '';
    var wakeWord2 = '';
    try {
      final r = await commands.execute('getWakeWordState', const {});
      final data = r.data;
      if (data is Map) {
        wakeEngine = data['released'] == true
            ? 'home_assistant'
            : '${data['engineLabel'] ?? data['engine'] ?? ''}';
        final models = data['models'];
        if (models is List) {
          String word(int i) => models.length > i && models[i] is Map
              ? '${(models[i] as Map)['wakeWord'] ?? ''}'
              : '';
          wakeWord = word(0);
          wakeWord2 = word(1);
        }
      }
    } catch (_) {}
    final vs = await _voiceSatellite(configPushed: wakeEngine.isNotEmpty);

    // Who installs updates: Android itself for a device owner, the ADB
    // update helper, Shizuku, or the on-screen confirmation. Shizuku's own
    // state comes along: installed and authorized, installed and waiting,
    // or absent.
    var shizuku = '';
    try {
      final r = await commands.execute('getShizukuState', const {});
      final data = r.data;
      if (data is Map) shizuku = '${data['status'] ?? ''}';
    } catch (_) {}
    var installer = 'confirm';
    var helper = false;
    try {
      final r = await commands.execute('getUpdateInstallerStatus', const {});
      final data = r.data;
      if (data is Map) {
        helper = data['helper'] == 'ready' || data['helper'] == 'busy';
        if (data['nativeSilent'] == true) {
          installer = 'device_owner';
        } else if (helper) {
          installer = 'helper';
        } else if (data['shizukuEnabled'] == true &&
            data['shizukuReady'] == true) {
          installer = 'shizuku';
        }
      }
    } catch (_) {}

    return {
      'screensaver': s.get(defs.screensaverEnabled)
          ? s.get(defs.screensaverMode)
          : 'off',
      'screensaver_schedule': s.get(defs.screensaverScheduleEnabled),
      'glance': s.get(defs.screensaverGlanceEnabled),
      'widgets': widgets.toList()..sort(),
      'widget_count': widgetCount,
      'wake_on_motion': s.get(defs.screensaverDismissOnMotion),
      'wake_on_face': s.get(defs.screensaverDismissOnFace),
      'wake_on_person': s.get(defs.screensaverDismissOnPerson),
      'wake_on_proximity': s.get(defs.screensaverDismissOnProximity),
      'voice_satellite': vs.state,
      'native_pipeline': s.get(defs.vsNativePipeline),
      'wake_word_engine': wakeEngine,
      'wake_word': wakeWord,
      'wake_word_2': wakeWord2,
      'vs_skin': vs.skin,
      'esphome': s.get(defs.esphomeEnabled),
      'bluetooth_proxy': s.get(defs.btproxyEnabled),
      'gps_sensor': s.get(defs.locationEnabled),
      // The empty pick is the device's own Sendspin player.
      'media_player': !s.get(defs.sendspinEnabled)
          ? 'off'
          : s.get(defs.sendspinPlayerSource).isEmpty
          ? 'device'
          : s.get(defs.sendspinPlayerSource),
      'lyrics': s.get(defs.sendspinLyricsEnabled),
      'dlna': s.get(defs.dlnaEnabled),
      'device_camera': s.get(defs.cameraEnabled),
      'rtsp_stream': s.get(defs.cameraEnabled) && s.get(defs.cameraRtspEnabled),
      'camera_streams': cameraViews > 0,
      'camera_servers': cameraServers,
      'camera_sources': cameraSources,
      'camera_views': cameraViews,
      'gesture_mappings': mappings,
      'gesture_triggers': triggers.toList()..sort(),
      'gesture_actions': actions.toList()..sort(),
      'kiosk_mode': s.get(defs.kioskEnabled),
      'lockdown': s.get(defs.lockdownEnabled),
      'app_launcher': s.get(defs.launcherEnabled),
      'home_launcher': s.get(defs.homeLauncherEnabled),
      'ha_kiosk_mode': s.get(defs.haKioskMode),
      'dashboard_carousel': s.get(defs.haDashboardCarousel),
      'dashboard_rotation': s.get(defs.haRotationEnabled),
      'secure_proxy': s.get(defs.secureProxy),
      'opt_disable_suspend': s.get(defs.disableSuspend),
      'opt_freeze_on_screensaver': s.get(defs.freezeOnScreensaver),
      'opt_ws_filter': s.get(defs.wsFilter),
      'opt_pause_dashboard_cameras': s.get(defs.pauseDashboardCameras),
      'opt_auto_reload': s.get(defs.autoReloadOnError),
      'adaptive_brightness': s.get(defs.adaptiveBrightness),
      'intercom': s.get(defs.intercomEnabled),
      'intercom_answer_mode': s.get(defs.intercomAnswerMode),
      'intercom_talk_mode': s.get(defs.intercomTalkMode),
      'intercom_announcements': s.get(defs.intercomAcceptAnnouncements),
      'announcements': s.get(defs.announcementsEnabled),
      'announcements_chime': s.get(defs.announcementsChime),
      'remote_admin': s.get(defs.remoteEnabled),
      'fleet_role': fleetRole(),
      'shizuku': shizuku,
      'shizuku_updates': s.get(defs.shizukuInstallUpdates),
      'update_installer': installer,
      'update_helper': helper,
      'plugins_enabled': pluginsEnabled,
      'plugins': pluginIds.length,
      'plugin_ids': pluginIds,
      'theme': s.get(defs.uiTheme),
    };
  }

  /// Voice Satellite as the page reports it. The hook the integration
  /// puts on every Home Assistant page answers only where it is
  /// installed, so an answer settles both questions: 'running' or
  /// 'stopped', by the engine. No answer, while the page is mid-load or
  /// showing something else, says nothing on its own, so an install that
  /// received a wake word config this session or heard the hook within
  /// the last week reads 'installed', and anything else 'not_installed'.
  /// The skin rides along from the same answer.
  Future<({String state, String skin})> _voiceSatellite({
    required bool configPushed,
  }) async {
    Map? page;
    try {
      final r = await commands.execute('vsEngineState', const {});
      if (r.ok && r.data is Map) page = r.data as Map;
    } catch (_) {}
    var skin = '';
    final stamp = '${_now().toUtc().millisecondsSinceEpoch}';
    if (page != null) {
      final config = page['config'];
      if (config is Map) skin = '${config['skin'] ?? ''}';
      await _settings.setInternal(_vsSeenKey, stamp);
      final engine = page['engine'];
      final running = engine is Map && engine['running'] == true;
      return (state: running ? 'running' : 'stopped', skin: skin);
    }
    if (configPushed) {
      await _settings.setInternal(_vsSeenKey, stamp);
      return (state: 'installed', skin: skin);
    }
    final seen = int.tryParse(_settings.internal(_vsSeenKey));
    if (seen != null) {
      final at = DateTime.fromMillisecondsSinceEpoch(seen, isUtc: true);
      if (_now().toUtc().difference(at) <= vsMemory) {
        return (state: 'installed', skin: skin);
      }
    }
    return (state: 'not_installed', skin: skin);
  }

  /// The native journal's text, or nothing where there is no journal (a
  /// platform without the bridge answers with an exception).
  Future<String> _readCrashJournal() async {
    try {
      return await _background.invokeMethod<String>('getLastCrash') ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<bool> _post(Map<String, Object?> body) async {
    final client = clientFactory();
    try {
      final res = await client
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        log.debug(name, 'sent ${body['kind']} (${res.statusCode})');
        return true;
      }
      log.debug(name, '${body['kind']} refused: HTTP ${res.statusCode}');
      return false;
    } catch (e) {
      // Offline, DNS-blocked, or the server is down: all fine, and none of
      // them worth more than a debug line. The next tick tries again.
      log.debug(name, '${body['kind']} not sent: $e');
      return false;
    } finally {
      client.close();
    }
  }
}
