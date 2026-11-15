import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/managers/browser/dashboard_page.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:shared_preferences/shared_preferences.dart';

// A Compass layout without a dashboard view has no use for the dashboard
// page, so the kiosk never loads it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('page storage', storageTests);

  late AppContainer c;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = AppContainer();
    await c.settings.init();
    followDashboardPage(c.settings, c.bus, c.browser.pageNeeded);
  });
  tearDown(() async {
    await c.settings.dispose();
    await c.bus.dispose();
    await c.log.dispose();
  });

  Future<void> set(String key, String value) async {
    await c.settings.setFromJson(key, value);
    await Future<void>.delayed(Duration.zero);
  }

  final noDashboard = jsonEncode({
    'center': {'kind': 'alarms'},
    'up': [
      {'kind': 'calendar'},
    ],
    'left': [
      {'kind': 'menu'},
    ],
  });

  test('only Compass without a dashboard view drops the page', () async {
    // Classic shows the page, whatever the layout says.
    await set(defs.navCompassLayout.key, noDashboard);
    expect(dashboardPageNeeded(c.settings), isTrue);
    expect(c.browser.pageNeeded.value, isTrue);

    await set(defs.navStyle.key, 'compass');
    expect(dashboardPageNeeded(c.settings), isFalse);
    expect(c.browser.pageNeeded.value, isFalse);

    // A dashboard view anywhere in the layout brings it back.
    await set(
      defs.navCompassLayout.key,
      jsonEncode({
        'center': {'kind': 'alarms'},
        'down': [
          {'kind': 'dashboard', 'path': 'lovelace/0'},
        ],
      }),
    );
    expect(c.browser.pageNeeded.value, isTrue);

    await set(defs.navCompassLayout.key, noDashboard);
    expect(c.browser.pageNeeded.value, isFalse);
    await set(defs.navStyle.key, 'classic');
    expect(c.browser.pageNeeded.value, isTrue);
  });

  test('what shows or runs in the page keeps it', () async {
    await set(defs.navCompassLayout.key, noDashboard);
    await set(defs.navStyle.key, 'compass');
    expect(c.browser.pageNeeded.value, isFalse);

    // The Home Assistant Dashboard screensaver shows the page itself.
    await set(defs.screensaverMode.key, 'dashboard');
    expect(c.browser.pageNeeded.value, isTrue);
    await set(defs.screensaverMode.key, 'clock');
    expect(c.browser.pageNeeded.value, isFalse);

    // So does a schedule entry, while the schedule is on.
    await set(
      defs.screensaverSchedule.key,
      jsonEncode([
        {'at': '22:00', 'mode': 'dashboard'},
      ]),
    );
    expect(c.browser.pageNeeded.value, isFalse);
    await c.settings.set(defs.screensaverScheduleEnabled, true);
    await Future<void>.delayed(Duration.zero);
    expect(c.browser.pageNeeded.value, isTrue);
    await c.settings.set(defs.screensaverScheduleEnabled, false);
    await Future<void>.delayed(Duration.zero);
    expect(c.browser.pageNeeded.value, isFalse);

    // Voice Satellite running in the dashboard needs the page to run.
    await set(defs.voiceRuntime.key, 'dashboard');
    expect(c.browser.pageNeeded.value, isTrue);
  });

  test('no page loads nothing', () async {
    await set(defs.navCompassLayout.key, noDashboard);
    await set(defs.navStyle.key, 'compass');
    await c.browser.loadUrl('https://example.com/lovelace/0');
    expect(
      c.log.recent.map((e) => e.message),
      contains(
        'not loading https://example.com/lovelace/0: no dashboard view in use',
      ),
    );
  });

  test('no page, no navigation into it', () async {
    await set(defs.haUrl.key, 'https://ha.local');
    final ran = <String>[];
    for (final name in ['evalJs', 'proxyMapUrl', 'hideOverlayPage']) {
      c.commands.register(
        Command(
          name: name,
          description: name,
          handler: (_) async {
            ran.add(name);
            return const CommandResult.ok();
          },
        ),
      );
    }
    c.homeAssistant.pageInUse = () => c.browser.pageNeeded.value;
    await set(defs.navCompassLayout.key, noDashboard);
    await set(defs.navStyle.key, 'compass');
    expect(await c.homeAssistant.navigateToViewPath('lovelace/0'), 'failed');
    expect(ran, isEmpty);
  });

  test('late news from a closed page is turned away', () async {
    // Classic built the page; Compass dropped it before it reported in.
    c.browser.onPageLoaded('https://ha.local/lovelace/0');
    expect(c.browser.currentUrl, 'https://ha.local/lovelace/0');
    await set(defs.navCompassLayout.key, noDashboard);
    await set(defs.navStyle.key, 'compass');
    c.browser.detach();
    expect(c.browser.currentUrl, isEmpty);
    c.browser.onPageLoaded('https://ha.local/lovelace/0');
    c.browser.onUrlChanged('https://ha.local/lovelace/1');
    expect(c.browser.currentUrl, isEmpty);

    // Back to Classic: the page reports in again.
    await set(defs.navStyle.key, 'classic');
    c.browser.onPageLoaded('https://ha.local/lovelace/0');
    expect(c.browser.currentUrl, 'https://ha.local/lovelace/0');
  });
}

// The page's localStorage outlives the page: with none loaded it is read
// and written in a page of its own on the same origin, so a backup keeps
// it and a restore lands in it.
void storageTests() {
  late EventBus bus;
  late SettingsManager settings;
  late BrowserManager browser;
  late CommandRegistry commands;
  late Map<String, String> storage;
  late List<String> origins;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
    await settings.setFromJson(
      defs.startUrl.key,
      'https://ha.local/lovelace/0',
    );
    storage = {'hassTokens': '{"access_token":"a"}'};
    origins = [];
    // The page of its own: runs the write the script carries, answers
    // with all of the storage.
    browser.pageOriginOverride = (origin, js) async {
      origins.add(origin);
      final write = RegExp(r'JSON\.parse\((".*")\)').firstMatch(js);
      if (write != null) {
        final entries = jsonDecode(jsonDecode(write.group(1)!) as String);
        (entries as Map).forEach((k, v) => storage['$k'] = '$v');
      }
      return jsonEncode(storage);
    };
    browser.pageNeeded.value = false;
  });

  test('read with no page loaded', () async {
    final r = await commands.execute('getLocalStorage', const {});
    expect(r.ok, isTrue);
    expect(jsonDecode(r.data! as String), {
      'hassTokens': '{"access_token":"a"}',
    });
    expect(origins, ['https://ha.local']);
  });

  test('a backup carries it with no page loaded', () async {
    final r = await commands.execute('exportConfig', const {});
    final config = r.data! as Map;
    expect(jsonDecode(config['localStorage'] as String), {
      'hassTokens': '{"access_token":"a"}',
    });
  });

  test('a restore with no page loaded goes straight into it', () async {
    final r = await commands.execute('setLocalStorage', {
      'data': jsonEncode({'vs-satellite-entity': 'assist_satellite.x'}),
    });
    expect(r.ok, isTrue);
    expect(storage['vs-satellite-entity'], 'assist_satellite.x');
    expect(settings.internal('pending_local_storage'), isEmpty);
  });

  test('a restore left waiting for a page is written before a read', () async {
    await settings.setInternal(
      'pending_local_storage',
      jsonEncode({'selectedTheme': 'dark'}),
    );
    final r = await commands.execute('getLocalStorage', const {});
    expect(jsonDecode(r.data! as String)['selectedTheme'], 'dark');
    expect(settings.internal('pending_local_storage'), isEmpty);
  });

  test('with a page coming, a restore waits for it', () async {
    browser.pageNeeded.value = true;
    await commands.execute('setLocalStorage', {
      'data': jsonEncode({'k': 'v'}),
    });
    expect(origins, isEmpty);
    expect(settings.internal('pending_local_storage'), isNotEmpty);
  });
}
