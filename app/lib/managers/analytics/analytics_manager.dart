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
import '../alarms/alarm_model.dart';
import '../browser/url_filter.dart';
import '../calendar/calendar_model.dart';
import '../home_assistant/custom_pages.dart';
import '../kiosk/drawer_items.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../update/update_http_client.dart';
import '../voice/wake_catalog.dart';
import '../wake_word/engine.dart';
import 'analytics_scrub.dart';
import 'crash_journal.dart';
import 'usage_counters.dart';

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

  /// The counts the snapshot being built reports, taken off once it is
  /// sent. Empty when Usage is off or nothing counted applies.
  Map<String, int> _reportedCounts = const {};

  /// How long a Voice Satellite sighting keeps a dashboard runtime reading
  /// 'integration' while the page hook is not answering.
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
        await UsageCounters.consume(_settings, _reportedCounts);
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
    _reportedCounts = const {};
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
    final drawer = DrawerItems.decode(s.get(defs.uiDrawerItems));
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

    final plugins = await _plugins();
    final echo = await _echoCanceller();

    // What Voice Satellite is listening for and with: the wake word
    // manager's state. Names only; a model name is a catalog label, not
    // the user's audio. A native runtime picks the engine itself, so its
    // setting names it whether the engine is muted or not, and a released
    // engine means nothing more than that. On the dashboard runtime a
    // released engine means the page took detection to Home Assistant.
    // Native voice that is off reports nothing: whatever the engine last
    // loaded is not what the kiosk listens for.
    final native = s.get(defs.voiceRuntime) == 'native';
    final nativeOn = native && s.get(defs.voiceEnabled);
    var wakeEngine = '';
    var wakeWord = '';
    var wakeWord2 = '';
    if (nativeOn) {
      wakeEngine =
          (voiceEngines[s.get(defs.voiceWakeWordEngine)] ??
                  WakeWordEngineType.vsWakeWord)
              .label;
    }
    if (!native || nativeOn) {
      try {
        final r = await commands.execute('getWakeWordState', const {});
        final data = r.data;
        if (data is Map) {
          if (!native) {
            wakeEngine = data['released'] == true
                ? 'home_assistant'
                : '${data['engineLabel'] ?? data['engine'] ?? ''}';
          }
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
    }
    final vs = await _voiceSatellite(configPushed: wakeEngine.isNotEmpty);

    // The native satellite's own settings: switches and picks, and how
    // many custom wake word models the kiosk holds. The speaker the
    // answers play on and Home Assistant's Assistant picks are names, so
    // they read as kinds and a yes or no.
    var customWakeWords = 0;
    var answers = const ['assist', 'assist'];
    if (nativeOn) {
      try {
        final r = await commands.execute('customWakeModels', const {});
        final data = r.data;
        if (data is Map && data['models'] is List) {
          customWakeWords = (data['models'] as List).length;
        }
      } catch (_) {}
      try {
        final r = await commands.execute('voiceStatus', const {});
        final data = r.data;
        if (data is Map && data['answers'] is List) {
          final list = data['answers'] as List;
          if (list.length == 2) answers = [for (final a in list) '$a'];
        }
      } catch (_) {}
    }
    // What answers each wake word: Home Assistant's Assist pipeline or a
    // realtime provider. The second one only counts with a second wake
    // word to answer.
    final answering = [answers[0], if (wakeWord2.isNotEmpty) answers[1]];
    final realtime = {
      for (final a in answering)
        if (a != 'assist') a,
    };
    // How often each one answered since the last snapshot, and how often
    // arbitration settled a wake other kiosks heard too.
    final arbitration = nativeOn && s.get(defs.voiceWakeArbitration);
    final calendars = decodeCalendars(s.get(defs.calendarCalendars));
    final calendarHidden = decodeHidden(s.get(defs.calendarHidden));
    final calendarStatus = calendars.isEmpty
        ? null
        : await commands.execute('calendarStatus', const {});
    final calendarSource =
        calendarStatus != null &&
            calendarStatus.ok &&
            calendarStatus.data is Map
        ? (calendarStatus.data as Map)['source']
        : null;
    final counts = UsageCounters.read(s);
    final pages = parseCustomPages(s.get(defs.haCustomPages));
    final rules = parseUrlFilter(s.get(defs.browserUrlFilter));
    _reportedCounts = {
      'duraspeed_blocked': counts['duraspeed_blocked'] ?? 0,
      for (final k in pluginActivity) k: counts[k] ?? 0,
      if (pages.isNotEmpty)
        for (final k in ['custom_page_loads', 'custom_page_ha_sockets'])
          k: counts[k] ?? 0,
      if (rules.isNotEmpty)
        'url_filter_blocked': counts['url_filter_blocked'] ?? 0,
      if (calendars.isNotEmpty) 'calendar_opens': counts['calendar_opens'] ?? 0,
      for (final k in libraryActivity) k: counts[k] ?? 0,
      if (nativeOn)
        for (final k in [
          'vs_turns_assist',
          'vs_turns_openai',
          'vs_turns_xai',
          'vs_turns_gemini',
        ])
          k: counts[k] ?? 0,
      if (arbitration)
        for (final k in ['vs_arbitration_won', 'vs_arbitration_lost'])
          k: counts[k] ?? 0,
    };
    String pick(String v) => v.trim().isEmpty ? 'default' : v;
    final nativeVoice = <String, Object?>{
      if (nativeOn) ...{
        'vs_muted': s.get(defs.voiceMute),
        'vs_theme': s.get(defs.voiceTheme),
        'vs_wake_word_sensitivity': s.get(defs.voiceWakeWordSensitivity),
        'wake_word_custom': customWakeWords,
        'vs_noise_gate': s.get(defs.voiceNoiseGate),
        'vs_stop_word': s.get(defs.voiceStopWord),
        'vs_seamless_wake': s.get(defs.voiceSeamlessWake),
        'vs_followup': s.get(defs.voiceFollowupDelayMs) > 0,
        'vs_finished_speaking': s.get(defs.voiceHaVadSensitivity),
        'vs_second_assistant': s.get(defs.voiceHaPipeline2).trim().isNotEmpty,
        'vs_tts_output': s.get(defs.voiceTtsOutput).trim().isEmpty
            ? 'device'
            : s.get(defs.voiceTtsOutputMode),
        'vs_wake_sound': s.get(defs.voiceWakeSound),
        'vs_custom_chimes': [
          s.get(defs.voiceChimeWake),
          s.get(defs.voiceChimeDone),
          s.get(defs.voiceChimeError),
          s.get(defs.voiceChimeTimer),
          s.get(defs.voiceChimeAnnounce),
        ].where((c) => c.trim().isNotEmpty).length,
        'vs_reactive_bar': s.get(defs.voiceReactiveBar),
        'vs_show_command': s.get(defs.voiceShowCommand),
        'vs_show_answer': s.get(defs.voiceShowAnswer),
        'vs_show_tools': s.get(defs.voiceShowTools),
        'vs_timer_pills': s.get(defs.voiceTimerPills),
        'vs_timer_speak': s.get(defs.voiceTimerSpeak),
        'vs_overlay_mode': s.get(defs.voiceOverlayMode),
        // Which edge the docked overlay sits on, never its exact place.
        if (s.get(defs.voiceOverlayMode) == 'docked')
          'vs_dock_position': dockEdge(s.get(defs.voiceDockPosition)),
        'vs_answers_1': answers[0],
        if (wakeWord2.isNotEmpty) 'vs_answers_2': answers[1],
        if (realtime.isNotEmpty) ...{
          'vs_realtime_tools': s.get(defs.voiceRealtimeTools),
          'vs_realtime_talk_over': s.get(defs.voiceRealtimeTalkOver),
          'vs_realtime_instructions': s
              .get(defs.voiceRealtimeInstructions)
              .trim()
              .isNotEmpty,
        },
        if (realtime.contains('openai')) ...{
          'vs_realtime_openai_model': pick(
            s.get(defs.voiceRealtimeOpenAiModel),
          ),
          'vs_realtime_openai_voice': pick(
            s.get(defs.voiceRealtimeOpenAiVoice),
          ),
        },
        if (realtime.contains('xai')) ...{
          'vs_realtime_xai_model': pick(s.get(defs.voiceRealtimeXaiModel)),
          'vs_realtime_xai_voice': pick(s.get(defs.voiceRealtimeXaiVoice)),
        },
        if (realtime.contains('gemini')) ...{
          'vs_realtime_gemini_model': pick(
            s.get(defs.voiceRealtimeGeminiModel),
          ),
          'vs_realtime_gemini_voice': pick(
            s.get(defs.voiceRealtimeGeminiVoice),
          ),
        },
        'vs_wake_arbitration': arbitration,
        if (arbitration)
          'vs_wake_arbitration_window_ms': s
              .get(defs.voiceWakeArbitrationWindowMs)
              .toInt(),
        for (final e in _reportedCounts.entries)
          if (e.key.startsWith('vs_')) e.key: UsageCounters.bucket(e.value),
      },
    };

    // Alarms: how many the kiosk holds and of what kind, as counts. The
    // times, labels and tone files stay on the kiosk.
    final alarms = decodeAlarms(s.get(defs.alarmsList));

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
      // A plugin's screensaver counts as 'plugin', without its id.
      'screensaver': !s.get(defs.screensaverEnabled)
          ? 'off'
          : defs.isPluginScreensaver(s.get(defs.screensaverMode))
          ? 'plugin'
          : s.get(defs.screensaverMode),
      'screensaver_schedule': s.get(defs.screensaverScheduleEnabled),
      'glance': s.get(defs.screensaverGlanceEnabled),
      'widgets': widgets.toList()..sort(),
      'widget_count': widgetCount,
      'wake_on_motion': s.get(defs.screensaverDismissOnMotion),
      'wake_on_face': s.get(defs.screensaverDismissOnFace),
      'wake_on_person': s.get(defs.screensaverDismissOnPerson),
      'wake_on_proximity': s.get(defs.screensaverDismissOnProximity),
      'voice_satellite': vs.state,
      // The native satellite runs every turn itself; the switch is the
      // dashboard runtime's.
      'native_pipeline': native || s.get(defs.vsNativePipeline),
      'wake_word_engine': wakeEngine,
      'wake_word': wakeWord,
      'wake_word_2': wakeWord2,
      'vs_skin': vs.skin,
      ...nativeVoice,
      // The kiosk's own echo canceller, for everything that listens: the
      // switch, and the engine it actually ran with and why, which can
      // differ from the method picked (Automatic's verdict, or GTCRN
      // unavailable on this CPU).
      'software_echo_cancellation': s.get(defs.micSoftwareEchoCancellation),
      ...echo,
      // MediaTek's DuraSpeed refused the dashboard's renderer since the
      // last report.
      'duraspeed_blocked': (_reportedCounts['duraspeed_blocked'] ?? 0) > 0,
      'clock_vertical':
          s.get(defs.screensaverClockVertical) &&
          ['digital', 'flip'].contains(s.get(defs.screensaverClockStyle)),
      'weather_clock_vertical':
          s.get(defs.screensaverWeatherClock) &&
          s.get(defs.screensaverWeatherClockVertical),
      'clock_night_mode': s.get(defs.screensaverClockNight),
      if (s.get(defs.screensaverClockNight))
        'clock_night_hide_widgets': s.get(
          defs.screensaverClockNightHideWidgets,
        ),
      'alarms': alarms.length,
      'alarms_on': alarms.where((a) => a.on).length,
      'alarms_repeating': alarms.where((a) => a.repeats).length,
      'alarms_sunrise': alarms.where((a) => a.sunrise).length,
      'alarms_menu': drawer.shows('alarms'),
      'alarms_tone': s.get(defs.alarmsTone).trim().isEmpty
          ? 'built_in'
          : 'custom',
      'alarms_snooze_minutes': s.get(defs.alarmsSnoozeMinutes),
      'alarms_silence_after_minutes': s.get(defs.alarmsSilenceAfterMinutes),
      'alarms_sunrise_minutes': s.get(defs.alarmsSunriseMinutes),
      // Calendar: counts and picks only, never the calendars, their names
      // or the people.
      'calendars': calendars.where((c) => c.on).length,
      if (calendars.isNotEmpty) ...{
        'calendars_off': calendars.where((c) => !c.on).length,
        'calendars_hidden': calendars
            .where((c) => c.on && calendarHidden.contains(c.entity))
            .length,
        'calendar_people': calendars.where((c) => c.person.isNotEmpty).length,
        'calendar_custom_colors': calendars
            .where((c) => !calendarPalette.any((p) => p.rgb == c.color))
            .length,
        'calendar_weather': s.get(defs.calendarWeatherEntity).trim().isNotEmpty,
        'calendar_default_view': s.get(defs.calendarDefaultView),
        'calendar_week_start': s.get(defs.calendarWeekStart),
        'calendar_menu': drawer.shows('calendar'),
        'calendar_idle_close_minutes': s.get(defs.calendarIdleCloseMinutes),
        'calendar_source': calendarSource is String
            ? calendarSource
            : 'unknown',
        'calendar_opens': UsageCounters.bucket(
          _reportedCounts['calendar_opens'] ?? 0,
        ),
      },
      // Music Library: switches and picks, and how often it was opened,
      // played from, searched and steered since the last report. Never
      // what was searched for or played.
      'library_menu': drawer.shows('music_library'),
      'library_source': s.get(defs.librarySource).isEmpty
          ? 'auto'
          : s.get(defs.librarySource),
      'library_now_playing_button': s.get(defs.libraryNowPlayingButton),
      'library_kiosk_allowed': s.get(defs.kioskAllowMusicLibrary),
      'library_idle_close_minutes': s.get(defs.libraryIdleCloseMinutes),
      'library_grid_density': s.get(defs.libraryGridDensity),
      'library_text_scale': s.get(defs.libraryTextScale).round(),
      'library_square_artwork': s.get(defs.librarySquareArtwork),
      'library_source_picker': s.get(defs.librarySourcePicker),
      'library_speaker_pill': s.get(defs.librarySpeakerPill),
      'library_album_artists': s.get(defs.libraryAlbumArtists),
      for (final k in libraryActivity)
        k: UsageCounters.bucket(_reportedCounts[k] ?? 0),
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
      'sendspin_master_volume': s.get(defs.sendspinMasterVolume),
      'dlna': s.get(defs.dlnaEnabled),
      // The receiver serves only while it is the Media Player pick.
      'airplay':
          s.get(defs.airplayEnabled) &&
          s.get(defs.sendspinPlayerSource).isEmpty &&
          s.get(defs.sendspinPlayer) == 'airplay',
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
      // Custom pages: how many, where they live and where the kiosk shows
      // them. Their names and addresses stay on the kiosk.
      'custom_pages': pages.length,
      if (pages.isNotEmpty) ...{
        'custom_pages_local': pages.where((p) => !p.external).length,
        'custom_pages_external': pages.where((p) => p.external).length,
        if (pages.any((p) => p.external))
          'custom_pages_socket': s.get(defs.haCustomPagesSocket),
        'custom_page_start': _customPageStart(pages),
        if (s.get(defs.haRotationEnabled))
          'custom_page_rotation': _rotationPaths().any(isCustomPagePath),
        for (final k in ['custom_page_loads', 'custom_page_ha_sockets'])
          k: UsageCounters.bucket(_reportedCounts[k] ?? 0),
      },
      // URL Filter: how many rules of which kind. The patterns and names
      // stay on the kiosk.
      'url_filter_rules': rules.length,
      if (rules.isNotEmpty) ...{
        'url_filter_allow_rules': rules.where((r) => r.isAllow).length,
        'url_filter_regex_rules': rules.where((r) => r.isRegex).length,
        'url_filter_scopes': {for (final r in rules) r.scope}.toList()..sort(),
        'url_filter_notice': s.get(defs.browserUrlFilterNotice),
        'url_filter_blocked': UsageCounters.bucket(
          _reportedCounts['url_filter_blocked'] ?? 0,
        ),
      },
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
      ...plugins,
      for (final k in pluginActivity)
        k: UsageCounters.bucket(_reportedCounts[k] ?? 0),
      'plugin_screensaver':
          s.get(defs.screensaverEnabled) &&
          defs.isPluginScreensaver(s.get(defs.screensaverMode)),
      'theme': s.get(defs.uiTheme),
    };
  }

  /// Whether the start URL opens one of the custom [pages]: a file under
  /// Home Assistant's /local/ or a page on another server.
  bool _customPageStart(List<CustomPage> pages) {
    final start = _settings.get(defs.startUrl).trim();
    if (Uri.tryParse(start)?.path.startsWith('/local/') ?? false) return true;
    return externalPageNavPath(start, pages) != null;
  }

  /// The navigation paths the dashboard rotation cycles through.
  List<String> _rotationPaths() {
    try {
      final raw = jsonDecode(_settings.get(defs.haRotationDashboards));
      if (raw is List) return [for (final p in raw) '$p'];
    } catch (_) {}
    return const [];
  }

  /// How this kiosk does voice: 'native' (the app's own satellite, turned
  /// on), 'integration' (the Voice Satellite integration in the dashboard)
  /// or 'off'. A native runtime answers from its own switch and skin. A
  /// dashboard runtime asks the hook the integration puts on every Home
  /// Assistant page, which answers only where it is installed. No answer,
  /// while the page is mid-load or showing something else, says nothing on
  /// its own, so an install that received a wake word config this session
  /// or heard the hook within the last week still reads 'integration'.
  Future<({String state, String skin})> _voiceSatellite({
    required bool configPushed,
  }) async {
    final s = _settings;
    if (s.get(defs.voiceRuntime) == 'native') {
      return s.get(defs.voiceEnabled)
          // A plugin's skin counts as 'plugin', without its id.
          ? (
              state: 'native',
              skin: defs.isPluginVoiceSkin(s.get(defs.voiceSkin))
                  ? 'plugin'
                  : s.get(defs.voiceSkin),
            )
          : (state: 'off', skin: '');
    }
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
      await s.setInternal(_vsSeenKey, stamp);
      return (state: 'integration', skin: skin);
    }
    if (configPushed) {
      await s.setInternal(_vsSeenKey, stamp);
      return (state: 'integration', skin: skin);
    }
    final seen = int.tryParse(s.internal(_vsSeenKey));
    if (seen != null) {
      final at = DateTime.fromMillisecondsSinceEpoch(seen, isUtc: true);
      if (_now().toUtc().difference(at) <= vsMemory) {
        return (state: 'integration', skin: skin);
      }
    }
    return (state: 'off', skin: skin);
  }

  /// Music Library use counted since the last snapshot: opens, plays by
  /// source and Play next or Add to queue, tapped or asked for by voice,
  /// typed searches, queue edits from any player and requests through the
  /// music voice blueprint.
  static const libraryActivity = [
    'library_opens',
    'library_plays_ma',
    'library_plays_ha',
    'library_plays_sonos',
    'library_queue_adds',
    'library_searches',
    'queue_edits',
    'library_voice_requests',
  ];

  /// The echo canceller the capture last ran ('gtcrn' or 'aec3', 'none'
  /// before any capture ran it since the app started) and why, read from
  /// the canceller itself rather than the setting.
  Future<Map<String, Object?>> _echoCanceller() async {
    try {
      final r = await commands.execute('getEchoCancellerState', const {});
      final data = r.data;
      if (r.ok && data is Map) {
        final engine = '${data['engine'] ?? ''}';
        return {
          'echo_canceller': engine.isEmpty ? 'none' : engine,
          if (engine.isNotEmpty) 'echo_canceller_why': '${data['why'] ?? ''}',
        };
      }
    } catch (_) {}
    return const {};
  }

  /// The plugin installs, updates, removals and failed installs people
  /// asked for, counted since the last snapshot (PluginManager.onActivity).
  static const pluginActivity = [
    'plugin_installs_directory',
    'plugin_installs_github',
    'plugin_installs_zip',
    'plugin_updates',
    'plugin_removals',
    'plugin_install_failures',
  ];

  /// What is installed, where it came from and how it is doing. A plugin
  /// is named, by id and version, only when it comes from Community
  /// Plugins: those names are public. Every other plugin, a ZIP or a
  /// private repository, only adds to the counts.
  Future<Map<String, Object?>> _plugins() async {
    var enabled = false;
    var list = <Map>[];
    try {
      final r = await commands.execute('getPluginState', const {});
      final data = r.data;
      if (data is Map) {
        enabled = data['enabled'] == true;
        if (data['plugins'] is List) {
          list = (data['plugins'] as List).whereType<Map>().toList();
        }
      }
    } catch (_) {}
    bool fromRepository(Map p) {
      final source = p['source'];
      return source is Map && source['repository'] is String;
    }

    // Community Plugins' own view of what is installed: listed, from the
    // same repository and whether a newer release waits. Only read when a
    // plugin came from a repository, and null when the list cannot be read.
    Map<String, Map>? listed;
    if (list.any((p) => p['fleetManaged'] != true && fromRepository(p))) {
      try {
        final r = await commands.execute('getPluginDirectory', const {});
        final data = r.data;
        if (r.ok && data is Map && data['plugins'] is List) {
          listed = {
            for (final e in (data['plugins'] as List).whereType<Map>())
              if (e['installed'] == true && e['sameSource'] == true)
                '${e['id']}': e,
          };
        }
      } catch (_) {}
    }
    final sources = {
      'directory': 0,
      'github': 0,
      'zip': 0,
      'fleet': 0,
      'unknown': 0,
    };
    final ids = <String>[];
    final versions = <String>[];
    var updates = 0;
    for (final p in list) {
      final id = '${p['id']}';
      final String kind;
      if (p['fleetManaged'] == true) {
        kind = 'fleet';
      } else if (!fromRepository(p)) {
        kind = 'zip';
      } else if (listed == null) {
        kind = 'unknown';
      } else if (listed.containsKey(id)) {
        kind = 'directory';
      } else {
        kind = 'github';
      }
      sources[kind] = sources[kind]! + 1;
      if (kind != 'directory') continue;
      ids.add(id);
      final pair = '$id@${p['version'] ?? ''}';
      if (pair.length <= 64) versions.add(pair);
      if (listed![id]!['updateAvailable'] == true) updates++;
    }
    bool hasError(Map p) =>
        '${p['error'] ?? ''}'.isNotEmpty || p['statusError'] == true;
    final on = list.where((p) => p['enabled'] == true).toList();
    var menuActions = 0;
    var haActions = 0;
    for (final p in list) {
      final options = p['actionOptions'];
      if (options is! Map) continue;
      for (final o in options.values.whereType<Map>()) {
        if (o['drawer'] == true) menuActions++;
        if (o['homeAssistant'] == true) haActions++;
      }
    }
    return {
      'plugins_enabled': enabled,
      'plugins': list.length,
      'plugin_ids': ids..sort(),
      if (list.isNotEmpty) ...{
        'plugin_versions': versions..sort(),
        'plugins_update_available': updates,
        for (final e in sources.entries)
          e.key == 'unknown'
                  ? 'plugins_source_unknown'
                  : 'plugins_from_${e.key}':
              e.value,
        'plugins_on': on.length,
        'plugins_running': list.where((p) => p['running'] == true).length,
        'plugins_errors': list.where(hasError).length,
        // Switched on with plugins running, yet not running, and no error
        // to say why.
        'plugins_stalled': enabled
            ? on.where((p) => p['running'] != true && !hasError(p)).length
            : 0,
        'plugin_capabilities': {
          for (final p in on)
            for (final c in (p['capabilities'] as List? ?? const []))
              if (c is String && c.isNotEmpty && c.length <= 64) c,
        }.toList()..sort(),
        'plugin_menu_actions': menuActions,
        'plugin_ha_actions': haActions,
      },
    };
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

/// The docked overlay's place, an 'x,y' fraction of the screen, as the
/// edge or corner it is nearest to.
@visibleForTesting
String dockEdge(String position) {
  final parts = position.split(',');
  final x = parts.isNotEmpty ? double.tryParse(parts[0].trim()) : null;
  final y = parts.length > 1 ? double.tryParse(parts[1].trim()) : null;
  if (x == null || y == null) return 'bottom';
  String axis(double v, String low, String high) =>
      v <= 1 / 3 ? low : (v >= 2 / 3 ? high : '');
  final v = axis(y, 'top', 'bottom');
  final h = axis(x, 'left', 'right');
  if (v.isEmpty && h.isEmpty) return 'center';
  return [v, h].where((e) => e.isNotEmpty).join('_');
}
