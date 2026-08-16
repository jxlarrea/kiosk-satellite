import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:shared_preferences/shared_preferences.dart';

/// The dashboard connection watchdog (issue #228).
///
/// A wall panel that is never backgrounded, on a network that never drops,
/// fires none of the edges the other recoveries hang off — so a dashboard
/// whose connection died had nothing coming for it and sat on "Connection
/// lost. Reconnecting…" behind the screensaver for hours. The watchdog polls
/// for that state, nudges it, and reloads only when the nudge fails.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BrowserManager browser;
  late SettingsManager settings;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://192.168.1.10:8123/lovelace/home',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
    browser.healthRepairTimeout = const Duration(milliseconds: 400);
  }

  tearDown(() async => browser.dispose());

  /// A page probe answering [state], with the nudge and liveness evals
  /// counted. [recovers] makes the connection come back after the nudge.
  void page(String state, {bool recovers = false, List<String>? nudges}) {
    var nudged = false;
    browser.evalOverride = (source) async {
      if (source.contains('ha-init-page')) return state;
      if (source.contains('conn.socket') || source.contains('dispatchEvent')) {
        nudged = true;
        nudges?.add(source);
        return 'reconnect';
      }
      if (source.contains('readyState === 1')) {
        return recovers && nudged;
      }
      return null;
    };
  }

  test('a healthy dashboard is left alone', () async {
    await build();
    page('connected');
    for (var i = 0; i < 5; i++) {
      await browser.checkDashboardHealth();
    }
    expect(browser.renavigations, 0);
  });

  test('a page that is not the dashboard is left alone', () async {
    await build();
    page('other');
    for (var i = 0; i < 5; i++) {
      await browser.checkDashboardHealth();
    }
    expect(browser.renavigations, 0);
  });

  test('one dead check is not enough to act on', () async {
    await build();
    final nudges = <String>[];
    page('stale', nudges: nudges);
    await browser.checkDashboardHealth();
    expect(nudges, isEmpty);
    expect(browser.renavigations, 0);
  });

  test('a connection down for three checks is nudged, not reloaded when it '
      'comes back', () async {
    await build();
    final nudges = <String>[];
    page('stale', recovers: true, nudges: nudges);
    for (var i = 0; i < 3; i++) {
      await browser.checkDashboardHealth();
    }
    expect(nudges, isNotEmpty);
    expect(browser.renavigations, 0);
  });

  test('a connection the nudge cannot revive is reloaded', () async {
    await build();
    page('stale');
    for (var i = 0; i < 3; i++) {
      await browser.checkDashboardHealth();
    }
    expect(browser.renavigations, 1);
  });

  test('the launch screen counts as dead too', () async {
    await build();
    page('shell');
    for (var i = 0; i < 3; i++) {
      await browser.checkDashboardHealth();
    }
    expect(browser.renavigations, 1);
  });

  test('a dashboard that cannot connect at all is not reloaded in a loop',
      () async {
    await build();
    page('stale');
    for (var i = 0; i < 12; i++) {
      await browser.checkDashboardHealth();
    }
    expect(browser.renavigations, 1);
  });

  test('auto-reload off keeps the nudge and withholds the reload', () async {
    await build();
    await settings.set(defs.autoReloadOnError, false);
    final nudges = <String>[];
    page('stale', nudges: nudges);
    for (var i = 0; i < 6; i++) {
      await browser.checkDashboardHealth();
    }
    expect(nudges, isNotEmpty);
    expect(browser.renavigations, 0);
  });

  test('a failed load is left to its own retry ladder', () async {
    await build();
    browser.loadFailed.value = true;
    page('stale');
    for (var i = 0; i < 5; i++) {
      await browser.checkDashboardHealth();
    }
    expect(browser.renavigations, 0);
  });

  test('a socket that closes and comes back on its own is left alone',
      () async {
    await build();
    browser.socketCloseGrace = const Duration(milliseconds: 200);
    final sources = <String>[];
    browser.evalOverride = (source) async {
      sources.add(source);
      return source.contains('readyState === 1') ? true : null;
    };
    browser.onHaSocketClosed();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(sources.where((s) => s.contains('dispatchEvent')), isEmpty);
  });

  test('a socket still down after the grace period is unblocked', () async {
    await build();
    browser.socketCloseGrace = const Duration(milliseconds: 200);
    final sources = <String>[];
    browser.evalOverride = (source) async {
      sources.add(source);
      return source.contains('readyState === 1') ? false : null;
    };
    browser.onHaSocketClosed();
    browser.onHaSocketClosed(); // a reconnect storm must not stack repairs
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(sources.where((s) => s.contains('dispatchEvent')), hasLength(1));
    // The close hook never reloads: that stays the watchdog's call.
    expect(browser.renavigations, 0);
  });

  test('a socket-less connection is unblocked rather than cycled', () async {
    await build();
    final sources = <String>[];
    browser.evalOverride = (source) async {
      sources.add(source);
      return null;
    };
    await browser.reconnectHaSocket();
    expect(
      sources.single,
      allOf(contains("new Event('focus')"), contains('conn.reconnect(true)')),
    );
  });
}
