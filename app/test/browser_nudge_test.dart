import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The resume-path HA socket recovery. The old behavior cycled the socket
/// unconditionally on every resume, which made a routine wake (the screen-off
/// feature wakes several times a day) rebuild the whole dashboard: connection
/// flash, every camera card renegotiating. Now only a socket that fails a
/// ping round trip gets cycled; the zombie the recovery exists for reads OPEN
/// but never answers, so it still falls through to the reconnect.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BrowserManager browser;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://192.168.1.10:8123/lovelace/home',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
  }

  tearDown(() async => browser.dispose());

  test('a socket that answers the ping is left alone', () async {
    await build();
    var reconnects = 0;
    var polls = 0;
    browser.evalOverride = (source) async {
      if (source.contains('sendMessagePromise')) return 'pending';
      if (source.contains('__ksPingCheck')) {
        polls++;
        return 'alive';
      }
      if (source.contains('conn.reconnect')) reconnects++;
      return null;
    };

    await browser.nudgeHaSocketIfDead(
      timeout: const Duration(milliseconds: 600),
    );

    expect(polls, greaterThan(0));
    expect(reconnects, 0);
  });

  test('a ping that errors out cycles the socket', () async {
    await build();
    var reconnects = 0;
    browser.evalOverride = (source) async {
      if (source.contains('sendMessagePromise')) return 'pending';
      if (source.contains('__ksPingCheck')) return 'dead';
      if (source.contains('conn.reconnect')) {
        reconnects++;
        return 'reconnect';
      }
      return null;
    };

    await browser.nudgeHaSocketIfDead(
      timeout: const Duration(milliseconds: 600),
    );

    expect(reconnects, 1);
  });

  test('the zombie: a pong that never arrives times out into the cycle',
      () async {
    await build();
    var reconnects = 0;
    browser.evalOverride = (source) async {
      if (source.contains('sendMessagePromise')) return 'pending';
      if (source.contains('__ksPingCheck')) return 'pending';
      if (source.contains('conn.reconnect')) {
        reconnects++;
        return 'reconnect';
      }
      return null;
    };

    await browser.nudgeHaSocketIfDead(
      timeout: const Duration(milliseconds: 600),
    );

    expect(reconnects, 1);
  });

  test('a page with no HA connection skips the probe and still nudges',
      () async {
    await build();
    var reconnects = 0;
    var polls = 0;
    browser.evalOverride = (source) async {
      if (source.contains('sendMessagePromise')) return 'no-connection';
      if (source.contains('__ksPingCheck')) polls++;
      if (source.contains('conn.reconnect')) {
        reconnects++;
        return 'no-connection';
      }
      return null;
    };

    await browser.nudgeHaSocketIfDead(
      timeout: const Duration(milliseconds: 600),
    );

    // No connection to ping: no polling loop, straight to the old nudge
    // (itself a no-op on such a page).
    expect(polls, 0);
    expect(reconnects, 1);
  });
}
