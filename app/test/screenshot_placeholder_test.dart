import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/browser_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A screenshot asked for while the panel is truly off: nothing composites
/// frames, so instead of a failed or half-drawn capture the command answers
/// with the generated "Screen off" placeholder (a PNG, where real captures
/// are JPEG). One gate covers every consumer: the remote admin's overview,
/// the MQTT Screenshot camera and the Last screenshot sensor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommandRegistry commands;
  late BrowserManager browser;

  Future<void> build({required bool screenOn}) async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    commands.register(Command(
      name: 'isScreenOn',
      description: 'stub',
      handler: (_) async => CommandResult.ok(screenOn),
    ));
    browser = BrowserManager(bus, commands, log, settings);
    await browser.init();
  }

  tearDown(() async => browser.dispose());

  test('with the panel off the screenshot is the Screen off placeholder',
      () async {
    await build(screenOn: false);
    final result = await commands.execute('screenshot', const {});
    expect(result.ok, isTrue);
    final bytes = base64Decode(result.data as String);
    expect(bytes.take(4).toList(), [0x89, 0x50, 0x4E, 0x47],
        reason: 'the placeholder is a PNG (real captures are JPEG)');
  });

  test('with the panel on the capture path runs (and fails here: no '
      'webview in a test)', () async {
    await build(screenOn: true);
    final result = await commands.execute('screenshot', const {});
    expect(result.ok, isFalse,
        reason: 'a lit panel must never get the placeholder; this harness '
            'has no window or webview, so the real path fails instead');
  });
}
