import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/dlna/dlna_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #1236: on a Galaxy Tab A8 another app holds UDP 1900 for a while
/// after boot, without sharing it. The renderer used to stop altogether
/// and stayed down until it was toggled. No test binding here: it would
/// mock out real sockets.
void main() {
  test('a held SSDP port keeps the server up and retries discovery', () async {
    // Taken first and not shared, like the app on the tablet. Dart shares
    // the address unless told not to.
    final holder = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      1900,
      reuseAddress: false,
    );
    final probe = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final port = probe.port;
    await probe.close();

    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log)
      ..register(
        Command(
          name: 'getDeviceInfo',
          description: 'test',
          handler: (_) async => CommandResult.ok({'appVersion': '0.0.0'}),
        ),
      );
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    await settings.set(defs.dlnaPort, '$port');
    await settings.set(defs.dlnaEnabled, true);
    final dlna = DlnaManager(bus, commands, log, settings);
    addTearDown(() async {
      holder.close();
      await dlna.dispose();
    });
    await dlna.init();

    Future<Map> status() async =>
        (await commands.execute('dlnaStatus', const {})).data as Map;
    Future<Map> waitFor(bool Function(Map) done) async {
      for (var i = 0; i < 100; i++) {
        final s = await status();
        if (done(s)) return s;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return status();
    }

    final held = await waitFor((s) => s['running'] == true);
    expect(held['running'], isTrue);
    expect(held['discoverable'], isFalse);

    holder.close();
    final freed = await waitFor((s) => s['discoverable'] == true);
    expect(freed['running'], isTrue);
    expect(freed['discoverable'], isTrue);
  });
}
