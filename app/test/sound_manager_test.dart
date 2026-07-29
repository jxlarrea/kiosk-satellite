import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sound/sound_manager.dart';

/// Volume is a native concern (the mixer model, issues #62/#69/#79): the
/// platform side composes master, media and assistant. This side must pass
/// sound volumes through untouched, or something gets scaled twice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommandRegistry commands;
  final sent = <MethodCall>[];

  Future<void> build() async {
    sent.clear();
    final log = Logger();
    commands = CommandRegistry(log);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kiosk_satellite/sound'),
      (call) async {
        sent.add(call);
        return true;
      },
    );
    final sound = SoundManager(EventBus(), commands, log);
    await sound.init();
  }

  test('sound volumes pass through unscaled - native owns the mixer',
      () async {
    await build();
    final r = await commands
        .execute('setSoundVolume', {'id': 'snd1', 'volume': 0.8});
    expect(r.ok, isTrue);
    final call = sent.singleWhere((c) => c.method == 'setVolume');
    expect(((call.arguments as Map)['volume'] as num).toDouble(),
        closeTo(0.8, 1e-9));
  });
}
