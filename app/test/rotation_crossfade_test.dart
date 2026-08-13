import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/browser/rotation_fade_script.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rotation crossfade (issue #189): the in-page dissolve is tried first
/// and owns the navigation when it answers 'fade'; anything else falls
/// through to the instant pushState path. A stub evalJs stands in for the
/// browser and scripts are told apart by their markers - the fade script
/// carries its busy stamp, the instant path a bare pushState.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> evalCalls;
  late HomeAssistantManager ha;

  Future<void> build({String fadeAnswer = 'fade'}) async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.test:8123',
      'ks.ha.token': 'token',
      'ks.browser.start_url': 'http://ha.test:8123/lovelace/home',
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    evalCalls = [];
    commands.register(Command(
      name: 'evalJs',
      description: 'stub',
      handler: (p) async {
        final code = '${p['code']}';
        evalCalls.add(code);
        return CommandResult.ok(
          code.contains('__ksRotFadeBusy') ? fadeAnswer : 'navigated',
        );
      },
    ));
    ha = HomeAssistantManager(bus, commands, log, settings);
    await ha.init();
  }

  test('the toggle exists, off by default, gated on rotation', () {
    expect(defs.haRotationCrossfade.defaultValue, isFalse);
    expect(defs.haRotationCrossfade.dependsOn, defs.haRotationEnabled.key);
    expect(defs.allSettings, contains(defs.haRotationCrossfade));
  });

  test('a started fade owns the navigation - no instant path after it',
      () async {
    await build();
    unawaited(ha.navigateToViewPath('lovelace/kitchen', crossfade: true));
    await pumpEventQueue();
    expect(evalCalls, hasLength(1));
    expect(evalCalls.single, contains('__ksRotFadeBusy'));
  });

  test("'plain' from the fade falls through to the instant path", () async {
    await build(fadeAnswer: 'plain');
    unawaited(ha.navigateToViewPath('lovelace/kitchen', crossfade: true));
    await pumpEventQueue();
    expect(evalCalls, hasLength(2));
    expect(evalCalls.first, contains('__ksRotFadeBusy'));
    expect(evalCalls.last, contains('pushState'));
    expect(evalCalls.last, isNot(contains('__ksRotFadeBusy')));
  });

  test('without crossfade the fade script is never sent', () async {
    await build();
    unawaited(ha.navigateToViewPath('lovelace/kitchen'));
    await pumpEventQueue();
    expect(evalCalls, hasLength(1));
    expect(evalCalls.single, contains('pushState'));
    expect(evalCalls.single, isNot(contains('__ksRotFadeBusy')));
  });

  test('the script bakes its arguments in as JSON', () {
    final js = rotationCrossfadeJs(
      base: 'http://ha.test:8123',
      viewPath: 'lovelace/kit"chen',
    );
    expect(js, contains('"http://ha.test:8123"'));
    // Encoded, not spliced: a quote in a view path must not break out.
    expect(js, contains(r'"lovelace/kit\"chen"'));
    // The switch happens behind a full-viewport cover in the theme's
    // background color, and the cover must always come back down: the
    // poll is bounded and the reveal runs regardless of the swap.
    expect(js, contains('__ksRotFadeCover'));
    expect(js, contains('--primary-background-color'));
    expect(js, contains('waited >= POLL_MAX'));
  });
}
