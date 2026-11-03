import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/analytics/analytics_manager.dart';
import 'package:kiosk_satellite/managers/analytics/usage_counters.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kiosk Satellite Analytics, as docs/analytics.md promises it: a daily
/// snapshot with only the parts whose switches are on, one report per
/// distinct crash while Diagnostics is on, a random install id that goes
/// away with the last switch, and nothing at all otherwise.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const deviceInfo = {
    'manufacturer': 'Amazon',
    'model': 'Amazon KFONWI',
    'device': 'onyx',
    'board': 'mt8168',
    'abis': ['armeabi-v7a'],
    'osVersion': 'Android 11',
    'sdkInt': 30,
    'screenWidth': 1280,
    'ramTotal': 7 * 1024 * 1024 * 1024 + 600 * 1024 * 1024, // 7.6 GiB
    'screenHeight': 800,
    'screenDensity': 1.5,
    'appVersion': '2026.9.43',
    'buildNumber': '250',
    'buildMode': 'release',
    'name': 'KS Echo Show 8 Office',
    'ip': '192.168.1.70',
    'webviewPackage': 'com.google.android.webview',
    'webviewVersion': '140.0.7339.51',
  };

  String crash = '';
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/background'),
          (call) async => call.method == 'getLastCrash' ? crash : null,
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late Logger log;
  late SettingsManager settings;
  late AnalyticsManager analytics;
  late List<http.Request> sent;
  late int status;
  late DateTime now;
  // What the stubbed page and native side answer; a test changes them
  // between snapshots.
  Map<String, Object?>? vsPage;
  late Map<String, Object?> wakeState;
  late Map<String, Object?> installerState;
  late Map<String, Object?> shizukuState;
  late List<String> answers;
  late Map<String, Object?> pluginState;
  // What the echo canceller says it last ran; null fails the call, like a
  // platform without the native side.
  Map<String, Object?>? echoState;
  // Community Plugins as getPluginDirectory answers; null fails the call.
  Map<String, Object?>? pluginDirectory;
  var directoryReads = 0;

  Future<void> build(
    Map<String, Object> initial, {
    Duration firstDelay = Duration.zero,
    Duration tickInterval = const Duration(days: 1),
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    commands.register(
      Command(
        name: 'getDeviceInfo',
        description: 'stub',
        handler: (_) async => const CommandResult.ok(deviceInfo),
      ),
    );
    pluginState = {
      'enabled': true,
      'plugins': [
        {'id': 'a'},
        {'id': 'b'},
      ],
    };
    pluginDirectory = null;
    directoryReads = 0;
    echoState = null;
    commands.register(
      Command(
        name: 'getEchoCancellerState',
        description: 'stub',
        handler: (_) async => echoState == null
            ? const CommandResult.fail('no echo canceller here')
            : CommandResult.ok(echoState),
      ),
    );
    commands.register(
      Command(
        name: 'getPluginState',
        description: 'stub',
        handler: (_) async => CommandResult.ok(pluginState),
      ),
    );
    commands.register(
      Command(
        name: 'getPluginDirectory',
        description: 'stub',
        handler: (_) async {
          directoryReads++;
          final d = pluginDirectory;
          return d == null
              ? const CommandResult.fail('offline')
              : CommandResult.ok(d);
        },
      ),
    );
    wakeState = {
      'engine': 'vsWakeWord',
      'engineLabel': 'vsWakeWord',
      'released': false,
      'models': [
        {'id': 'ok_nova', 'wakeWord': 'Ok Nova'},
      ],
    };
    vsPage = {
      'config': {'skin': 'kiosk-satellite', 'theme_mode': 'auto'},
      'satellite': 'assist_satellite.office',
      'engine': {'running': false},
    };
    installerState = {
      'nativeSilent': false,
      'shizukuReady': false,
      'helper': 'unavailable',
      'shizukuEnabled': false,
    };
    shizukuState = {'status': 'unavailable'};
    commands.register(
      Command(
        name: 'getWakeWordState',
        description: 'stub',
        handler: (_) async => CommandResult.ok(wakeState),
      ),
    );
    answers = ['assist', 'assist'];
    commands.register(
      Command(
        name: 'voiceStatus',
        description: 'stub',
        handler: (_) async => CommandResult.ok({'answers': answers}),
      ),
    );
    commands.register(
      Command(
        name: 'customWakeModels',
        description: 'stub',
        handler: (_) async => const CommandResult.ok({
          'models': [
            {'id': 'custom_1', 'wakeWord': 'Hey Custom'},
          ],
          'engine': 'vswakeword',
          'managed': false,
        }),
      ),
    );
    commands.register(
      Command(
        name: 'vsEngineState',
        description: 'stub',
        handler: (_) async {
          final page = vsPage;
          return page == null
              ? const CommandResult.fail('the page has no hook')
              : CommandResult.ok(page);
        },
      ),
    );
    commands.register(
      Command(
        name: 'getUpdateInstallerStatus',
        description: 'stub',
        handler: (_) async => CommandResult.ok(installerState),
      ),
    );
    commands.register(
      Command(
        name: 'getShizukuState',
        description: 'stub',
        handler: (_) async => CommandResult.ok(shizukuState),
      ),
    );
    sent = [];
    status = 200;
    now = DateTime.utc(2026, 9, 12, 20);
    analytics = AnalyticsManager(
      bus,
      commands,
      log,
      settings,
      endpoint: 'https://analytics.test/v1/report',
      clientFactory: () => MockClient((req) async {
        sent.add(req);
        return http.Response('', status);
      }),
      firstDelay: firstDelay,
      tickInterval: tickInterval,
      now: () => now,
    );
    addTearDown(analytics.dispose);
    await analytics.init();
  }

  Map<String, Object?> bodyOf(http.Request r) =>
      jsonDecode(r.body) as Map<String, Object?>;

  Future<void> pump() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'the defaults send one snapshot with both parts, and then wait',
    () async {
      await build({'ks.voice.runtime': 'dashboard'});
      await pump();
      expect(sent, hasLength(1));
      final body = bodyOf(sent.single);
      expect(sent.single.url.toString(), 'https://analytics.test/v1/report');
      expect(
        sent.single.headers['content-type'],
        startsWith('application/json'),
      );
      expect(body['schema'], AnalyticsManager.schema);
      expect(body['kind'], 'snapshot');
      expect(body['install_id'], matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(body['install_id'], analytics.installId);
      expect((body['app'] as Map)['version'], '2026.9.43');
      final basic = body['basic'] as Map;
      expect(basic['model'], 'Amazon KFONWI');
      expect(basic['android'], 'Android 11');
      expect((basic['screen'] as Map)['width'], 1280);
      expect(basic['ram_gb'], 8.0);
      final usage = body['usage'] as Map;
      expect(usage['plugins'], 2);
      // Installed from ZIP: counted, never named.
      expect(usage['plugin_ids'], isEmpty);
      expect(usage['plugins_from_zip'], 2);
      expect(usage['fleet_role'], 'none');
      expect(usage['wake_word_engine'], 'vsWakeWord');
      expect(usage['wake_word'], 'Ok Nova');
      expect(usage['wake_word_2'], '');
      expect(usage['vs_skin'], 'kiosk-satellite');
      expect(usage['intercom'], false);
      expect(usage['intercom_answer_mode'], 'ring');
      expect(usage['intercom_talk_mode'], 'ptt');
      expect(usage['announcements'], true);
      // The hook answered: the integration runs voice on this kiosk.
      expect(usage['voice_satellite'], 'integration');
      expect(usage['widgets'], isEmpty);
      expect(usage['widget_count'], 0);
      expect(usage['gesture_triggers'], isEmpty);
      expect(usage['camera_streams'], isFalse);
      expect(usage['update_installer'], 'confirm');
      expect(usage['shizuku'], 'unavailable');
      expect(basic['webview'], 'com.google.android.webview');
      expect(basic['webview_version'], '140.0.7339.51');
      expect(analytics.lastSnapshot, now);
      // Not due again until a day has passed.
      expect(await analytics.sendSnapshot(), isFalse);
      now = now.add(const Duration(hours: 25));
      expect(await analytics.sendSnapshot(), isTrue);
      expect(sent, hasLength(2));
    },
  );

  test(
    'a dashboard runtime reads by the page hook, then by memory of it',
    () async {
      await build({
        'ks.voice.runtime': 'dashboard',
      }, firstDelay: const Duration(days: 1));
      Future<Map> usage() async {
        sent.clear();
        expect(await analytics.sendSnapshot(force: true), isTrue);
        return bodyOf(sent.single)['usage'] as Map;
      }

      // The hook answers: the integration is there, whatever its engine
      // is doing right now.
      expect((await usage())['voice_satellite'], 'integration');
      vsPage = {
        'config': {'skin': 'waveform'},
        'engine': {'running': true},
      };
      var u = await usage();
      expect(u['voice_satellite'], 'integration');
      expect(u['vs_skin'], 'waveform');
      // No hook (the page is elsewhere), but Voice Satellite pushed the
      // wake word config this session.
      vsPage = null;
      u = await usage();
      expect(u['voice_satellite'], 'integration');
      expect(u['vs_skin'], '');
      // No hook and no config either: the sighting holds for a week.
      wakeState = {'released': false, 'models': <Object?>[]};
      now = now.add(const Duration(days: 6));
      expect((await usage())['voice_satellite'], 'integration');
      now = now.add(const Duration(days: 2));
      expect((await usage())['voice_satellite'], 'off');
    },
  );

  test(
    'a dashboard runtime that never met Voice Satellite reads off',
    () async {
      await build({
        'ks.voice.runtime': 'dashboard',
      }, firstDelay: const Duration(days: 1));
      vsPage = null;
      wakeState = {'released': false, 'models': <Object?>[]};
      expect(await analytics.sendSnapshot(force: true), isTrue);
      final usage = bodyOf(sent.single)['usage'] as Map;
      expect(usage['voice_satellite'], 'off');
      expect(usage['wake_word_engine'], '');
      expect(usage['wake_word'], '');
    },
  );

  test(
    'a native runtime reads by its own switch and skin, never the page',
    () async {
      await build({
        'ks.voice.runtime': 'native',
        'ks.voice.skin': 'lens-flares',
      }, firstDelay: const Duration(days: 1));
      Future<Map> usage() async {
        sent.clear();
        expect(await analytics.sendSnapshot(force: true), isTrue);
        return bodyOf(sent.single)['usage'] as Map;
      }

      // The page hook still answers (the integration is installed in Home
      // Assistant) but this kiosk does not run voice through it. Off, the
      // engine's last loaded models are not what the kiosk listens for.
      var u = await usage();
      expect(u['voice_satellite'], 'off');
      expect(u['vs_skin'], '');
      expect(u['wake_word_engine'], '');
      expect(u['wake_word'], '');
      expect(u['native_pipeline'], isTrue);
      await settings.set(defs.voiceEnabled, true);
      await settings.set(defs.voiceWakeWordEngine, 'microwakeword');
      u = await usage();
      expect(u['voice_satellite'], 'native');
      expect(u['vs_skin'], 'lens-flares');
      // The engine is the kiosk's own pick, the words what it loaded.
      expect(u['wake_word_engine'], 'microWakeWord');
      expect(u['wake_word'], 'Ok Nova');
      expect(u['wake_word_2'], '');
      // Muted, the engine is released but still the kiosk's engine.
      wakeState = {...wakeState, 'released': true};
      u = await usage();
      expect(u['voice_satellite'], 'native');
      expect(u['wake_word_engine'], 'microWakeWord');
      expect(u['wake_word'], 'Ok Nova');
      // A fresh install never seeds the runtime: it is native by default.
      await build({}, firstDelay: const Duration(days: 1));
      expect((await usage())['voice_satellite'], 'off');
    },
  );

  test('the calendar reports counts and picks, never its calendars', () async {
    await build({
      'ks.voice.runtime': 'dashboard',
      'ks.calendar.calendars':
          '[{"entity":"calendar.sam_work","name":"Sam","color":"192,97,58",'
          '"person":"person.sam"},'
          '{"entity":"calendar.leo","name":"Leo","color":"1,2,3"},'
          '{"entity":"calendar.old","name":"Old","color":"72,130,132",'
          '"on":false}]',
      'ks.calendar.hidden': '["calendar.leo"]',
      'ks.calendar.weather_entity': 'weather.home',
    });
    commands.register(
      Command(
        name: 'calendarStatus',
        description: 'stub',
        handler: (_) async => const CommandResult.ok({'source': 'live'}),
      ),
    );
    await UsageCounters.bump(settings, 'calendar_opens');
    await UsageCounters.bump(settings, 'calendar_opens');
    await pump();
    final usage = bodyOf(sent.single)['usage'] as Map;
    expect(usage['calendars'], 2);
    expect(usage['calendars_off'], 1);
    expect(usage['calendars_hidden'], 1);
    expect(usage['calendar_people'], 1);
    expect(usage['calendar_custom_colors'], 1);
    expect(usage['calendar_weather'], isTrue);
    expect(usage['calendar_default_view'], 'week');
    expect(usage['calendar_source'], 'live');
    expect(usage['calendar_opens'], '1-5');
    final text = jsonEncode(usage);
    for (final secret in ['sam_work', 'Sam', 'person.', 'weather.home']) {
      expect(text, isNot(contains(secret)), reason: secret);
    }
  });

  test('the native satellite reports its settings as picks and counts, only '
      'while it is on', () async {
    await build({
      'ks.voice.runtime': 'native',
      'ks.voice.tts_output': 'media_player.kitchen',
      'ks.voice.tts_output_mode': 'normal_playback',
      'ks.voice.ha_pipeline_2': 'Second brain',
      'ks.voice_chimes.wake': 'ding.mp3',
      'ks.voice.followup_delay_ms': 1500,
    }, firstDelay: const Duration(days: 1));
    Future<Map> usage() async {
      sent.clear();
      expect(await analytics.sendSnapshot(force: true), isTrue);
      return bodyOf(sent.single)['usage'] as Map;
    }

    // Off: none of it is in use, so none of it goes out.
    var u = await usage();
    expect(u.containsKey('vs_theme'), isFalse);
    expect(u.containsKey('wake_word_custom'), isFalse);
    await settings.set(defs.voiceEnabled, true);
    u = await usage();
    expect(u['vs_muted'], isFalse);
    expect(u['vs_theme'], 'auto');
    expect(u['vs_wake_word_sensitivity'], 'moderately');
    expect(u['wake_word_custom'], 1);
    expect(u['vs_stop_word'], isFalse);
    expect(u['vs_followup'], isTrue);
    // The speaker's entity id and the assistant's name never leave.
    expect(u['vs_tts_output'], 'normal_playback');
    expect(u['vs_second_assistant'], isTrue);
    expect(u['vs_custom_chimes'], 1);
    expect(u['vs_reactive_bar'], isTrue);
    expect(u['vs_timer_pills'], isTrue);
    expect(jsonEncode(u), isNot(contains('kitchen')));
    expect(jsonEncode(u), isNot(contains('Second brain')));
    expect(jsonEncode(u), isNot(contains('ding')));
  });

  test(
    'what answers each wake word, the realtime picks and turn counts',
    () async {
      await build({
        'ks.voice.runtime': 'native',
        'ks.voice.enabled': true,
        'ks.voice.realtime_openai_model': 'gpt-realtime-mini',
        'ks.voice.realtime_instructions': 'Talk like a pirate',
        'ks.voice.realtime_mcp_url': 'https://mcp.example/secret',
      }, firstDelay: const Duration(days: 1));
      Future<Map> usage() async {
        sent.clear();
        expect(await analytics.sendSnapshot(force: true), isTrue);
        return bodyOf(sent.single)['usage'] as Map;
      }

      // Assist alone: no realtime picks, and the turns read as ranges.
      var u = await usage();
      expect(u['vs_answers_1'], 'assist');
      expect(u.containsKey('vs_answers_2'), isFalse);
      expect(u.containsKey('vs_realtime_tools'), isFalse);
      expect(u['vs_turns_assist'], '0');
      expect(u['vs_turns_openai'], '0');
      expect(u['vs_wake_arbitration'], isFalse);
      expect(u.containsKey('vs_arbitration_won'), isFalse);

      // OpenAI answers wake word 1, a second wake word goes to Assist.
      answers = ['openai', 'assist'];
      wakeState = {
        ...wakeState,
        'models': [
          {'id': 'ok_nova', 'wakeWord': 'Ok Nova'},
          {'id': 'hey_jarvis', 'wakeWord': 'Hey Jarvis'},
        ],
      };
      for (var i = 0; i < 7; i++) {
        await UsageCounters.bump(settings, 'vs_turns_openai');
      }
      await UsageCounters.bump(settings, 'vs_turns_assist');
      u = await usage();
      expect(u['vs_answers_1'], 'openai');
      expect(u['vs_answers_2'], 'assist');
      expect(u['vs_realtime_tools'], 'home_assistant');
      expect(u['vs_realtime_talk_over'], isTrue);
      expect(u['vs_realtime_instructions'], isTrue);
      expect(u['vs_realtime_openai_model'], 'gpt-realtime-mini');
      expect(u['vs_realtime_openai_voice'], 'default');
      expect(u.containsKey('vs_realtime_xai_model'), isFalse);
      expect(u['vs_turns_openai'], '6-20');
      expect(u['vs_turns_assist'], '1-5');
      final text = jsonEncode(u);
      expect(text, isNot(contains('pirate')));
      expect(text, isNot(contains('mcp.example')));
      // Sent: the counts start over.
      u = await usage();
      expect(u['vs_turns_openai'], '0');
      expect(u['vs_turns_assist'], '0');
    },
  );

  test('a failed snapshot keeps its counts for the next one', () async {
    await build({
      'ks.voice.runtime': 'native',
      'ks.voice.enabled': true,
    }, firstDelay: const Duration(days: 1));
    await UsageCounters.bump(settings, 'vs_turns_assist');
    status = 500;
    expect(await analytics.sendSnapshot(force: true), isFalse);
    status = 200;
    sent.clear();
    expect(await analytics.sendSnapshot(force: true), isTrue);
    expect((bodyOf(sent.single)['usage'] as Map)['vs_turns_assist'], '1-5');
  });

  test('counts nothing while Usage is off', () async {
    await build({
      'ks.analytics.usage': false,
      'ks.voice.runtime': 'native',
      'ks.voice.enabled': true,
    }, firstDelay: const Duration(days: 1));
    await UsageCounters.bump(settings, 'vs_turns_assist');
    expect(UsageCounters.read(settings), isEmpty);
  });

  test(
    'wake word arbitration reports its window and contested wakes',
    () async {
      await build({
        'ks.voice.runtime': 'native',
        'ks.voice.enabled': true,
        'ks.voice.wake_arbitration': true,
      }, firstDelay: const Duration(days: 1));
      await UsageCounters.bump(settings, 'vs_arbitration_won');
      for (var i = 0; i < 25; i++) {
        await UsageCounters.bump(settings, 'vs_arbitration_lost');
      }
      expect(await analytics.sendSnapshot(force: true), isTrue);
      final u = bodyOf(sent.single)['usage'] as Map;
      expect(u['vs_wake_arbitration'], isTrue);
      expect(u['vs_wake_arbitration_window_ms'], 400);
      expect(u['vs_arbitration_won'], '1-5');
      expect(u['vs_arbitration_lost'], '21+');
    },
  );

  test('echo cancellation, the overlay mode, DuraSpeed and the clock '
      'layouts', () async {
    await build({
      'ks.voice.runtime': 'native',
      'ks.voice.enabled': true,
      'ks.voice.overlay_mode': 'docked',
      'ks.voice.dock_position': '0.9,0.1',
      'ks.screensaver.clock_vertical': true,
      'ks.screensaver.clock_style': 'analog',
      'ks.screensaver.weather_clock_vertical': true,
      'ks.screensaver.clock_night': true,
      'ks.screensaver.clock_night_hide_widgets': true,
    }, firstDelay: const Duration(days: 1));
    // Set after start: the update that made it the only canceller turns
    // it back on once.
    await settings.set(defs.micSoftwareEchoCancellation, false);
    await UsageCounters.bump(settings, 'duraspeed_blocked');
    Future<Map> usage() async {
      sent.clear();
      expect(await analytics.sendSnapshot(force: true), isTrue);
      return bodyOf(sent.single)['usage'] as Map;
    }

    var u = await usage();
    expect(u['vs_overlay_mode'], 'docked');
    expect(u['vs_dock_position'], 'top_right');
    expect(u['software_echo_cancellation'], isFalse);
    expect(u['duraspeed_blocked'], isTrue);
    // The analog face has no vertical layout, whatever the switch says.
    expect(u['clock_vertical'], isFalse);
    expect(u['weather_clock_vertical'], isTrue);
    expect(u['clock_night_mode'], isTrue);
    expect(u['clock_night_hide_widgets'], isTrue);
    // A block reads once, then not again until another one.
    u = await usage();
    expect(u['duraspeed_blocked'], isFalse);
    await settings.set(defs.screensaverClockStyle, 'flip');
    await settings.set(defs.voiceOverlayMode, 'full');
    u = await usage();
    expect(u['clock_vertical'], isTrue);
    expect(u.containsKey('vs_dock_position'), isFalse);
  });

  test('the dock position reads as its nearest edge or corner', () {
    expect(dockEdge('0.5,1'), 'bottom');
    expect(dockEdge('0.5,0'), 'top');
    expect(dockEdge('0,0.5'), 'left');
    expect(dockEdge('0.1,0.9'), 'bottom_left');
    expect(dockEdge('0.5,0.5'), 'center');
    expect(dockEdge('nonsense'), 'bottom');
  });

  group('plugins', () {
    Map<String, Object?> plugin(
      String id, {
      String version = '1.0.0',
      String? repository,
      bool enabled = true,
      bool running = true,
      String error = '',
      List<String> capabilities = const [],
      Map<String, Object?> actionOptions = const {},
      bool fleet = false,
    }) => {
      'id': id,
      'version': version,
      'enabled': enabled,
      'running': running,
      'error': error,
      'statusError': false,
      'capabilities': capabilities,
      'actionOptions': actionOptions,
      if (repository != null) 'source': {'repository': repository},
      if (fleet) 'fleetManaged': true,
    };

    Future<Map> usage() async {
      sent.clear();
      expect(await analytics.sendSnapshot(force: true), isTrue);
      return bodyOf(sent.single)['usage'] as Map;
    }

    test(
      'names only Community Plugins and counts the rest by source',
      () async {
        await build({}, firstDelay: const Duration(days: 1));
        pluginState = {
          'enabled': true,
          'plugins': [
            plugin(
              'weather-radar',
              version: '1.2.0',
              repository: 'https://github.com/someone/weather-radar',
              capabilities: ['screensaver', 'ha'],
              actionOptions: {
                'refresh': {'drawer': true, 'homeAssistant': true},
              },
            ),
            plugin(
              'my-secret-tool',
              repository: 'https://github.com/me/my-secret-tool',
              capabilities: ['shizuku'],
              running: false,
            ),
            plugin(
              'garage-hack',
              error: 'Plugin stopped at start',
              running: false,
            ),
            plugin('office-pack', fleet: true, enabled: false, running: false),
          ],
        };
        pluginDirectory = {
          'plugins': [
            {
              'id': 'weather-radar',
              'installed': true,
              'sameSource': true,
              'updateAvailable': true,
            },
            {'id': 'clock-faces', 'installed': false},
          ],
        };
        final u = await usage();
        expect(u['plugins'], 4);
        expect(u['plugin_ids'], ['weather-radar']);
        expect(u['plugin_versions'], ['weather-radar@1.2.0']);
        expect(u['plugins_update_available'], 1);
        expect(u['plugins_from_directory'], 1);
        expect(u['plugins_from_github'], 1);
        expect(u['plugins_from_zip'], 1);
        expect(u['plugins_from_fleet'], 1);
        expect(u['plugins_source_unknown'], 0);
        expect(u['plugins_on'], 3);
        expect(u['plugins_running'], 1);
        expect(u['plugins_errors'], 1);
        // On, no error, not running: the private tool.
        expect(u['plugins_stalled'], 1);
        // Enabled plugins only: the fleet one is off.
        expect(u['plugin_capabilities'], ['ha', 'screensaver', 'shizuku']);
        expect(u['plugin_menu_actions'], 1);
        expect(u['plugin_ha_actions'], 1);
        final text = jsonEncode(u);
        expect(text, isNot(contains('my-secret-tool')));
        expect(text, isNot(contains('garage-hack')));
        expect(text, isNot(contains('office-pack')));
      },
    );

    test('an unreadable directory names nothing and says so', () async {
      await build({}, firstDelay: const Duration(days: 1));
      pluginState = {
        'enabled': true,
        'plugins': [
          plugin('weather-radar', repository: 'https://github.com/x/y'),
        ],
      };
      final u = await usage();
      expect(u['plugin_ids'], isEmpty);
      expect(u['plugins_source_unknown'], 1);
      expect(u['plugins_from_github'], 0);
    });

    test(
      'the directory is only read when a plugin came from a repository',
      () async {
        await build({}, firstDelay: const Duration(days: 1));
        await usage();
        expect(directoryReads, 0);
        pluginState = {'enabled': false, 'plugins': <Object?>[]};
        final u = await usage();
        expect(u['plugins'], 0);
        expect(u.containsKey('plugins_from_zip'), isFalse);
        expect(directoryReads, 0);
      },
    );

    test('a plugin screensaver reads as plugin, without its id', () async {
      await build({
        'ks.screensaver.enabled': true,
        'ks.screensaver.mode': 'plugin:my-secret-tool:aquarium',
      }, firstDelay: const Duration(days: 1));
      final u = await usage();
      expect(u['screensaver'], 'plugin');
      expect(u['plugin_screensaver'], isTrue);
      expect(jsonEncode(u), isNot(contains('aquarium')));
    });

    test(
      'install activity reads as ranges and starts over once sent',
      () async {
        await build({}, firstDelay: const Duration(days: 1));
        await UsageCounters.bump(settings, 'plugin_installs_directory');
        await UsageCounters.bump(settings, 'plugin_install_failures');
        for (var i = 0; i < 7; i++) {
          await UsageCounters.bump(settings, 'plugin_updates');
        }
        var u = await usage();
        expect(u['plugin_installs_directory'], '1-5');
        expect(u['plugin_installs_zip'], '0');
        expect(u['plugin_updates'], '6-20');
        expect(u['plugin_install_failures'], '1-5');
        u = await usage();
        expect(u['plugin_updates'], '0');
      },
    );
  });

  test('the Music Library reads as picks and ranges', () async {
    await build({
      'ks.library.source': 'sonos',
      'ks.library.menu': false,
      'ks.library.grid_density': 'compact',
      'ks.library.source_picker': false,
      'ks.library.speaker_pill': false,
    }, firstDelay: const Duration(days: 1));
    await UsageCounters.bump(settings, 'library_opens');
    for (var i = 0; i < 6; i++) {
      await UsageCounters.bump(settings, 'library_plays_sonos');
    }
    await UsageCounters.bump(settings, 'queue_edits');
    expect(await analytics.sendSnapshot(force: true), isTrue);
    var u = bodyOf(sent.single)['usage'] as Map;
    expect(u['library_source'], 'sonos');
    expect(u['library_menu'], isFalse);
    expect(u['library_now_playing_button'], isTrue);
    expect(u['library_kiosk_allowed'], isTrue);
    expect(u['library_idle_close_minutes'], '2');
    expect(u['library_grid_density'], 'compact');
    expect(u['library_source_picker'], isFalse);
    expect(u['library_speaker_pill'], isFalse);
    expect(u['library_text_scale'], 100);
    expect(u['library_opens'], '1-5');
    expect(u['library_plays_sonos'], '6-20');
    expect(u['library_plays_ma'], '0');
    expect(u['queue_edits'], '1-5');
    expect(u['library_voice_requests'], '0');
    // Sent: the counts start over. No source picked reads as auto.
    await settings.set(defs.librarySource, '');
    sent.clear();
    expect(await analytics.sendSnapshot(force: true), isTrue);
    u = bodyOf(sent.single)['usage'] as Map;
    expect(u['library_plays_sonos'], '0');
    expect(u['library_source'], 'auto');
  });

  test('the echo canceller reads as what it ran, not the setting', () async {
    await build({
      'ks.audio.echo_cancellation_method': 'gtcrn',
    }, firstDelay: const Duration(days: 1));
    Future<Map> usage() async {
      sent.clear();
      expect(await analytics.sendSnapshot(force: true), isTrue);
      return bodyOf(sent.single)['usage'] as Map;
    }

    // No native side: nothing said either way.
    var u = await usage();
    expect(u.containsKey('echo_canceller'), isFalse);
    // GTCRN picked, but this CPU cannot run it: AEC3 is what cancels.
    echoState = {'engine': 'aec3', 'why': 'unavailable', 'running': true};
    u = await usage();
    expect(u['echo_canceller'], 'aec3');
    expect(u['echo_canceller_why'], 'unavailable');
    echoState = {'engine': 'gtcrn', 'why': 'testing', 'running': false};
    u = await usage();
    expect(u['echo_canceller'], 'gtcrn');
    expect(u['echo_canceller_why'], 'testing');
    // No capture has run the canceller since the app started.
    echoState = {'engine': '', 'why': '', 'running': false};
    u = await usage();
    expect(u['echo_canceller'], 'none');
    expect(u.containsKey('echo_canceller_why'), isFalse);
  });

  test('alarms read as counts and picks, never as times or labels', () async {
    await build({
      'ks.alarms.list': jsonEncode([
        {
          'id': 'a',
          'time': '06:30',
          'days': [1, 2, 3, 4, 5],
          'label': 'Work',
          'tone': '',
          'sunrise': true,
          'on': true,
        },
        {
          'id': 'b',
          'time': '09:00',
          'days': <int>[],
          'date': '2026-10-01',
          'label': 'Dentist',
          'tone': 'rooster.mp3',
          'sunrise': false,
          'on': false,
        },
      ]),
      'ks.alarms.tone': 'gentle.mp3',
      'ks.alarms.snooze_minutes': '5',
    }, firstDelay: const Duration(days: 1));
    expect(await analytics.sendSnapshot(force: true), isTrue);
    final u = bodyOf(sent.single)['usage'] as Map;
    expect(u['alarms'], 2);
    expect(u['alarms_on'], 1);
    expect(u['alarms_repeating'], 1);
    expect(u['alarms_sunrise'], 1);
    expect(u['alarms_menu'], isTrue);
    expect(u['alarms_tone'], 'custom');
    expect(u['alarms_snooze_minutes'], '5');
    expect(u['alarms_silence_after_minutes'], '10');
    expect(u['alarms_sunrise_minutes'], '30');
    final text = jsonEncode(u);
    expect(text, isNot(contains('Work')));
    expect(text, isNot(contains('Dentist')));
    expect(text, isNot(contains('06:30')));
    expect(text, isNot(contains('rooster')));
    expect(text, isNot(contains('gentle')));
  });

  test('custom pages read as counts and places, never as names or '
      'addresses', () async {
    await build({
      'ks.ha.custom_pages': jsonEncode([
        {'name': 'Kitchen wall', 'path': '/local/kitchen.html'},
        {'name': 'Den', 'path': '/local/den.html#lights'},
        {'name': 'Garage', 'path': 'https://pages.lan/garage.html'},
      ]),
      'ks.ha.custom_pages_socket': true,
      'ks.browser.start_url': 'http://ha.lan:8123/local/kitchen.html',
      'ks.ha.rotation_enabled': true,
      'ks.ha.rotation_dashboards': jsonEncode([
        'lovelace/home',
        'local/https://pages.lan/garage.html',
      ]),
    }, firstDelay: const Duration(days: 1));
    for (var i = 0; i < 7; i++) {
      await UsageCounters.bump(settings, 'custom_page_loads');
    }
    await UsageCounters.bump(settings, 'custom_page_ha_sockets');
    Future<Map> usage() async {
      sent.clear();
      expect(await analytics.sendSnapshot(force: true), isTrue);
      return bodyOf(sent.single)['usage'] as Map;
    }

    var u = await usage();
    expect(u['custom_pages'], 3);
    expect(u['custom_pages_local'], 2);
    expect(u['custom_pages_external'], 1);
    expect(u['custom_pages_socket'], isTrue);
    expect(u['custom_page_start'], isTrue);
    expect(u['custom_page_rotation'], isTrue);
    expect(u['custom_page_loads'], '6-20');
    expect(u['custom_page_ha_sockets'], '1-5');
    final text = jsonEncode(u);
    for (final secret in ['Kitchen', 'Den', 'Garage', 'pages.lan', '.html']) {
      expect(text, isNot(contains(secret)));
    }
    // The counts went out with the last snapshot.
    u = await usage();
    expect(u['custom_page_loads'], '0');
    expect(u['custom_page_ha_sockets'], '0');

    // Only pages in Home Assistant: the shared connection says nothing.
    await settings.set(
      defs.haCustomPages,
      jsonEncode([
        {'name': 'Kitchen wall', 'path': '/local/kitchen.html'},
      ]),
    );
    await settings.set(defs.startUrl, 'http://ha.lan:8123/lovelace/home');
    await settings.set(defs.haRotationEnabled, false);
    u = await usage();
    expect(u.containsKey('custom_pages_socket'), isFalse);
    expect(u.containsKey('custom_page_rotation'), isFalse);
    expect(u['custom_page_start'], isFalse);

    // No pages, no detail.
    await settings.set(defs.haCustomPages, '[]');
    u = await usage();
    expect(u['custom_pages'], 0);
    expect(u.containsKey('custom_pages_local'), isFalse);
    expect(u.containsKey('custom_page_loads'), isFalse);
  });

  test('URL Filter rules read as counts and kinds, never as names or '
      'patterns', () async {
    await build({
      'ks.browser.url_filter': jsonEncode([
        {
          'name': 'No history',
          'pattern': '/history*',
          'type': 'wildcard',
          'scope': 'dashboard',
          'action': 'block',
        },
        {
          'name': 'Lovelace only',
          'pattern': '/lovelace/*',
          'type': 'wildcard',
          'scope': 'dashboard',
          'action': 'allow',
        },
        {
          'name': 'Tube',
          'pattern': r'youtube\.com',
          'type': 'regex',
          'scope': 'external',
          'action': 'block',
        },
      ]),
      'ks.browser.url_filter_notice': false,
    }, firstDelay: const Duration(days: 1));
    for (var i = 0; i < 3; i++) {
      await UsageCounters.bump(settings, 'url_filter_blocked');
    }
    expect(await analytics.sendSnapshot(force: true), isTrue);
    var u = bodyOf(sent.single)['usage'] as Map;
    expect(u['url_filter_rules'], 3);
    expect(u['url_filter_allow_rules'], 1);
    expect(u['url_filter_regex_rules'], 1);
    expect(u['url_filter_scopes'], ['dashboard', 'external']);
    expect(u['url_filter_notice'], isFalse);
    expect(u['url_filter_blocked'], '1-5');
    final text = jsonEncode(u);
    for (final secret in ['history', 'Lovelace', 'Tube', 'youtube']) {
      expect(text, isNot(contains(secret)));
    }

    await settings.set(defs.browserUrlFilter, '[]');
    sent.clear();
    expect(await analytics.sendSnapshot(force: true), isTrue);
    u = bodyOf(sent.single)['usage'] as Map;
    expect(u['url_filter_rules'], 0);
    expect(u.containsKey('url_filter_scopes'), isFalse);
    expect(u.containsKey('url_filter_blocked'), isFalse);
  });

  test('widgets, gestures, cameras and the installer read as kinds and '
      'counts, never as what they point at', () async {
    await build({
      'ks.screensaver.widgets':
          '[{"position":"top_left","type":"clock","config":{}},'
          '{"position":"top_right","type":"battery","config":{}},'
          '{"position":"bottom_left","type":"clock","config":{}}]',
      'ks.gestures.mappings':
          '[{"id":"g1","trigger":{"type":"claps","claps":3},'
          '"action":{"type":"camera_view","viewId":"front","viewName":"Front door"}},'
          '{"id":"g2","trigger":{"type":"fingers","fingers":5},'
          '"action":{"type":"screensaver"}}]',
      'ks.camera.config':
          '{"version":1,"servers":[{"url":"http://192.168.1.9:1984"}],'
          '"cameras":[{"name":"Front door"},{"name":"Garage"}],'
          '"views":[{"id":"front","name":"Front door"}]}',
      'ks.camera.enabled': true,
      'ks.camera.rtsp.enabled': true,
      'ks.browser.secure_proxy': true,
    }, firstDelay: const Duration(days: 1));
    installerState = {
      'nativeSilent': false,
      'shizukuReady': true,
      'helper': 'ready',
      'shizukuEnabled': true,
    };
    shizukuState = {'status': 'ready'};
    expect(await analytics.sendSnapshot(force: true), isTrue);
    final raw = sent.single.body;
    final usage = bodyOf(sent.single)['usage'] as Map;
    expect(usage['widgets'], ['battery', 'clock']);
    expect(usage['widget_count'], 3);
    expect(usage['gesture_mappings'], 2);
    expect(usage['gesture_triggers'], ['claps', 'fingers']);
    expect(usage['gesture_actions'], ['camera_view', 'screensaver']);
    expect(usage['camera_streams'], isTrue);
    expect(usage['camera_servers'], 1);
    expect(usage['camera_sources'], 2);
    expect(usage['camera_views'], 1);
    expect(usage['rtsp_stream'], isTrue);
    expect(usage['secure_proxy'], isTrue);
    // The helper outranks Shizuku when both could install.
    expect(usage['update_installer'], 'helper');
    expect(usage['update_helper'], isTrue);
    expect(usage['shizuku'], 'ready');
    expect(raw, isNot(contains('Front door')));
    expect(raw, isNot(contains('Garage')));
    expect(raw, isNot(contains('192.168.1.9')));
  });

  test(
    'a device owner installs updates itself; Shizuku only when armed',
    () async {
      await build({}, firstDelay: const Duration(days: 1));
      installerState = {
        'nativeSilent': true,
        'shizukuReady': true,
        'helper': 'unavailable',
        'shizukuEnabled': true,
      };
      expect(await analytics.sendSnapshot(force: true), isTrue);
      var usage = bodyOf(sent.single)['usage'] as Map;
      expect(usage['update_installer'], 'device_owner');
      expect(usage['update_helper'], isFalse);
      sent.clear();
      installerState = {
        'nativeSilent': false,
        'shizukuReady': true,
        'helper': 'unavailable',
        'shizukuEnabled': true,
      };
      expect(await analytics.sendSnapshot(force: true), isTrue);
      usage = bodyOf(sent.single)['usage'] as Map;
      expect(usage['update_installer'], 'shizuku');
    },
  );

  test('memory rounds up to the nominal size in half gigabytes', () {
    const gib = 1024 * 1024 * 1024;
    expect(AnalyticsManager.nominalRamGb((1.4 * gib).round()), 1.5);
    expect(AnalyticsManager.nominalRamGb((1.9 * gib).round()), 2.0);
    expect(AnalyticsManager.nominalRamGb((3.6 * gib).round()), 4.0);
    expect(AnalyticsManager.nominalRamGb((5.6 * gib).round()), 6.0);
    expect(AnalyticsManager.nominalRamGb((11.4 * gib).round()), 12.0);
    expect(AnalyticsManager.nominalRamGb(0), isNull);
    expect(AnalyticsManager.nominalRamGb(null), isNull);
  });

  test('nothing in a report names the device, its network or its HA', () async {
    await build({
      'ks.ha.url': 'https://home.example.com:8123',
      'ks.device.name': 'Kitchen tablet',
    });
    await pump();
    final raw = sent.single.body;
    expect(raw, isNot(contains('example.com')));
    expect(raw, isNot(contains('Kitchen')));
    expect(raw, isNot(contains('192.168')));
    expect(raw, isNot(contains('Echo Show 8 Office')));
    expect(raw, isNot(contains('onyx')));
    // Usage is flags and picks only, plus one list of plugin ids: short
    // plain names, the same rule the receiver enforces.
    final usage = bodyOf(sent.single)['usage'] as Map;
    for (final entry in usage.entries) {
      final v = entry.value;
      if (const {
        'plugin_ids',
        'plugin_versions',
        'plugin_capabilities',
        'url_filter_scopes',
        'widgets',
        'gesture_triggers',
        'gesture_actions',
      }.contains(entry.key)) {
        expect(v, isA<List>());
        for (final id in v as List) {
          expect(id, isA<String>());
          expect((id as String).length, lessThanOrEqualTo(64));
          expect(id, isNot(contains('://')));
        }
        continue;
      }
      expect(v is bool || v is num || v is String, isTrue, reason: '$v');
      if (v is String) expect(v, isNot(contains('://')));
    }
  });

  test('each switch gates its own part', () async {
    await build({'ks.analytics.usage': false});
    await pump();
    final body = bodyOf(sent.single);
    expect(body.containsKey('basic'), isTrue);
    expect(body.containsKey('usage'), isFalse);
  });

  test('with Basic and Usage off no snapshot goes out', () async {
    await build({'ks.analytics.basic': false, 'ks.analytics.usage': false});
    await pump();
    expect(sent, isEmpty);
    expect(await analytics.buildSnapshot(), isNull);
    expect(await analytics.sendSnapshot(force: true), isFalse);
  });

  test(
    'with every switch off there is no install id and nothing is sent',
    () async {
      await build({
        'ks.analytics.basic': false,
        'ks.analytics.usage': false,
        'ks.analytics.diagnostics': false,
        'ks.internal.analytics_install_id': 'deadbeefdeadbeefdeadbeefdeadbeef',
      });
      crash = 'FATAL EXCEPTION: main\njava.lang.RuntimeException: boom';
      await pump();
      expect(sent, isEmpty);
      expect(analytics.installId, isEmpty);
    },
  );

  test(
    'turning the last switch off forgets the id; on again mints a new one',
    () async {
      await build({});
      await pump();
      final first = analytics.installId;
      expect(first, isNotEmpty);
      await settings.set(defs.analyticsBasic, false);
      await settings.set(defs.analyticsUsage, false);
      await settings.set(defs.analyticsDiagnostics, false);
      await pump();
      expect(analytics.installId, isEmpty);
      expect(analytics.lastSnapshot, isNull);
      await settings.set(defs.analyticsUsage, true);
      await pump();
      expect(await analytics.sendSnapshot(), isTrue);
      expect(analytics.installId, isNotEmpty);
      expect(analytics.installId, isNot(first));
    },
  );

  test(
    'a recorded crash is reported once, scrubbed, while Diagnostics is on',
    () async {
      crash =
          'FATAL EXCEPTION: main\n'
          'java.lang.IllegalStateException: https://home.example.com/api down\n'
          '\tat me.jxl.kiosk_satellite.MainActivity.onCreate(MainActivity.kt:42)';
      await build({'ks.analytics.basic': false, 'ks.analytics.usage': false});
      await pump();
      expect(sent, hasLength(1));
      final body = bodyOf(sent.single);
      expect(body['kind'], 'crash');
      expect(body['install_id'], matches(RegExp(r'^[0-9a-f]{32}$')));
      expect((body['android'] as Map)['sdk'], 30);
      expect(body['crash'], contains('MainActivity.onCreate'));
      expect(body['crash'], contains('<url>'));
      expect(body['crash'], isNot(contains('example.com')));
      expect(body.containsKey('basic'), isFalse);
      // The journal still holds the same trace at the next tick: not again.
      expect(await analytics.sendCrashIfAny(), isFalse);
      expect(sent, hasLength(1));
      // A different crash is new.
      crash = 'FATAL EXCEPTION: main\njava.lang.RuntimeException: other';
      expect(await analytics.sendCrashIfAny(), isTrue);
      expect(sent, hasLength(2));
    },
  );

  test('deliberate restarts stay home; each real crash goes once, newest '
      'first, under the version that crashed', () async {
    crash = '''
\tat java.lang.reflect.Method.invoke(Native Method)

=== crash at 2026-09-08 15:32:33 (app 2026.9.30, thread main) ===
java.lang.RuntimeException: process restarted deliberately: restart requested (kiosk menu, remote admin or ESPHome)
\tat a7.jc.a(r8-map-id:23)

=== crash at 2026-09-09 09:00:00 (app 2026.9.35, thread main) ===
java.lang.NullPointerException: older
\tat me.jxl.kiosk_satellite.A.b(A.kt:1)

=== crash at 2026-09-09 10:00:00 (app 2026.9.35, thread main) ===
java.lang.RuntimeException: process restarted deliberately: the frame watchdog found the UI wedged (no frames for 30s)
\tat a7.jc.a(r8-map-id:23)

=== crash at 2026-09-10 08:01:02 (app 2026.9.41, thread main) ===
java.lang.IllegalStateException: WebView gone
\tat me.jxl.kiosk_satellite.MainActivity.onCreate(MainActivity.kt:42)
''';
    await build({'ks.analytics.basic': false, 'ks.analytics.usage': false});
    await pump();
    final kinds = sent.map((r) => bodyOf(r)['kind']).toList();
    expect(kinds, ['crash', 'crash', 'crash']);
    final first = bodyOf(sent[0]);
    final second = bodyOf(sent[1]);
    final third = bodyOf(sent[2]);
    expect(first['crash'], contains('WebView gone'));
    expect(first['cause'], 'exception');
    expect((first['app'] as Map)['version'], '2026.9.41');
    expect(first['recorded_at'], '2026-09-10 08:01:02');
    expect(second['cause'], 'watchdog');
    expect(second['crash'], contains('frame watchdog'));
    expect(third['crash'], contains('older'));
    expect((third['app'] as Map)['version'], '2026.9.35');
    for (final r in sent) {
      expect(r.body, isNot(contains('restart requested')));
      expect(r.body, isNot(contains('Method.invoke')));
    }
    // The same journal at the next tick: nothing new.
    expect(await analytics.sendCrashIfAny(), isFalse);
    expect(sent, hasLength(3));
  });

  test('a journal holding more entries than the memory of sent ones does '
      'not lap: the newest window goes once and nothing repeats', () async {
    // 60 distinct crashes, more than the old fifty-fingerprint memory.
    final buf = StringBuffer();
    for (var i = 0; i < 60; i++) {
      final minute = i.toString().padLeft(2, '0');
      buf.write(
        '=== crash at 2026-09-02 08:$minute:00 (app 2026.9.2, thread main) ===\n'
        'java.lang.RuntimeException: process restarted deliberately: the frame '
        'watchdog found the UI wedged (no frames for 30s) run $i\n'
        '\tat a7.jc.a(r8-map-id:23)\n\n',
      );
    }
    crash = buf.toString();
    await build({'ks.analytics.basic': false, 'ks.analytics.usage': false});
    // Tick until the sender says there is nothing left, well past the
    // point where a lap would have started.
    var ticks = 0;
    while (await analytics.sendCrashIfAny() && ticks < 100) {
      ticks++;
    }
    final crashes = sent.map((r) => bodyOf(r)['crash'] as String).toList();
    expect(crashes, hasLength(AnalyticsManager.crashCandidates));
    expect(crashes.toSet(), hasLength(AnalyticsManager.crashCandidates));
    // The newest entries went, the oldest stayed home.
    expect(crashes.first, contains('run 59'));
    expect(crashes.any((c) => c.contains('run 0\n')), isFalse);
    for (var i = 0; i < 5; i++) {
      expect(await analytics.sendCrashIfAny(), isFalse);
    }
    expect(sent, hasLength(AnalyticsManager.crashCandidates));
  });

  test('Diagnostics off keeps a recorded crash on the device', () async {
    crash = 'FATAL EXCEPTION: main\njava.lang.RuntimeException: boom';
    await build({'ks.analytics.diagnostics': false});
    await pump();
    expect(sent.map((r) => bodyOf(r)['kind']), ['snapshot']);
  });

  test(
    'a refused snapshot is not marked sent, so the next tick retries',
    () async {
      await build({});
      status = 500;
      await pump();
      expect(sent, hasLength(1));
      expect(analytics.lastSnapshot, isNull);
      status = 200;
      expect(await analytics.sendSnapshot(), isTrue);
      expect(analytics.lastSnapshot, now);
    },
  );

  test('the report command shows what would go out', () async {
    await build({}, firstDelay: const Duration(days: 1));
    final r = await commands.execute('getAnalyticsReport', const {});
    final data = r.data as Map;
    expect(data['lastSnapshot'], isNull);
    expect((data['snapshot'] as Map)['kind'], 'snapshot');
    expect(sent, isEmpty);
  });

  tearDown(() => crash = '');
}
