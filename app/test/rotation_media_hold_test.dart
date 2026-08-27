import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dashboard view rotation and media playback (issue #332): music from the
/// Sendspin player (or the page) raises VoiceInteractionChanged with the
/// 'media' reason, and the rotation ring must keep turning through it. A
/// spoken turn still holds rotation until it ends.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> evalCalls;
  late EventBus bus;
  late Logger log;
  late HomeAssistantManager ha;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({
      'ks.ha.url': 'http://ha.test:8123',
      'ks.ha.token': 'token',
      'ks.browser.start_url': 'http://ha.test:8123/lovelace/home',
      'ks.ha.rotation_enabled': true,
      'ks.ha.rotation_dashboards': '["lovelace/kitchen","lovelace/bath"]',
      'ks.ha.rotation_seconds': 5,
    });
    bus = EventBus();
    log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    evalCalls = [];
    commands.register(
      Command(
        name: 'evalJs',
        description: 'stub',
        handler: (p) async {
          evalCalls.add('${p['code']}');
          return const CommandResult.ok('navigated');
        },
      ),
    );
    ha = HomeAssistantManager(bus, commands, log, settings);
    await ha.init();
  }

  Iterable<String> rotationLog() =>
      log.recent.where((e) => e.tag == 'home_assistant').map((e) => e.message);

  test('media playback does not pause rotation', () {
    fakeAsync((async) {
      unawaited(build());
      async.flushMicrotasks();
      bus.publish(const VoiceInteractionChanged(active: true, reason: 'media'));
      async.flushMicrotasks();
      expect(rotationLog(), isNot(contains(startsWith('rotation paused'))));
      async.elapse(const Duration(seconds: 6));
      expect(evalCalls, hasLength(1));
      expect(evalCalls.single, contains('lovelace/kitchen'));
      // The 3 minute voice safety ceiling has nothing to release either.
      async.elapse(const Duration(minutes: 3));
      expect(rotationLog(), isNot(contains('rotation resumed')));
      // The play/pause edges of a song never disturb the ring.
      bus.publish(
        const VoiceInteractionChanged(active: false, reason: 'media'),
      );
      async.flushMicrotasks();
      expect(rotationLog(), isNot(contains('rotation resumed')));
    });
  });

  test('a voice turn still holds rotation until it ends', () {
    fakeAsync((async) {
      unawaited(build());
      async.flushMicrotasks();
      bus.publish(const VoiceInteractionChanged(active: true, reason: 'voice'));
      async.flushMicrotasks();
      expect(rotationLog(), contains('rotation paused by interaction (voice)'));
      async.elapse(const Duration(seconds: 12));
      expect(evalCalls, isEmpty);
      bus.publish(
        const VoiceInteractionChanged(active: false, reason: 'voice'),
      );
      async.flushMicrotasks();
      expect(rotationLog(), contains('rotation resumed'));
      async.elapse(const Duration(seconds: 6));
      expect(evalCalls, hasLength(1));
    });
  });
}
