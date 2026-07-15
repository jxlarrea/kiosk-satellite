import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';

void main() {
  group('EventBus', () {
    test('delivers typed events to typed subscribers only', () async {
      final bus = EventBus();
      final motions = <MotionDetected>[];
      final wakes = <WakeWordDetected>[];
      bus.on<MotionDetected>().listen(motions.add);
      bus.on<WakeWordDetected>().listen(wakes.add);

      bus.publish(const MotionDetected());
      bus.publish(const WakeWordDetected(model: 'm', phrase: 'p'));
      await Future<void>.delayed(Duration.zero);

      expect(motions, hasLength(1));
      expect(wakes, hasLength(1));
      expect(wakes.single.phrase, 'p');
      await bus.dispose();
    });
  });

  group('CommandRegistry', () {
    test('executes registered commands and fails unknown ones', () async {
      final registry = CommandRegistry(Logger());
      registry.register(Command(
        name: 'echo',
        description: 'returns its input',
        handler: (p) async => CommandResult.ok(p['value']),
      ));

      final ok = await registry.execute('echo', {'value': 42});
      expect(ok.ok, isTrue);
      expect(ok.data, 42);

      final unknown = await registry.execute('nope', const {});
      expect(unknown.ok, isFalse);
      expect(unknown.error, contains('unknown command'));
    });

    test('converts thrown errors into failed results', () async {
      final registry = CommandRegistry(Logger());
      registry.register(Command(
        name: 'boom',
        description: 'always throws',
        handler: (_) async => throw StateError('bang'),
      ));
      final result = await registry.execute('boom', const {});
      expect(result.ok, isFalse);
      expect(result.error, contains('bang'));
    });
  });

  group('Logger', () {
    test('keeps a bounded ring buffer', () {
      final logger = Logger();
      for (var i = 0; i < 600; i++) {
        logger.info('test', 'entry $i');
      }
      expect(logger.recent, hasLength(500));
      expect(logger.recent.first.message, 'entry 100');
      expect(logger.recent.last.message, 'entry 599');
    });
  });
}
