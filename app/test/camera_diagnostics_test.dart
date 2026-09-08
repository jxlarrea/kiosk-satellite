import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/motion/camera_diagnostics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Logger log;
  late CameraDiagnostics diagnostics;
  final calls = <String>[];

  Future<void> emit(Map<String, Object> record) async {
    await messenger.handlePlatformMessage(
      CameraDiagnostics.channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('record', record),
      ),
      (_) {},
    );
  }

  setUp(() {
    log = Logger();
    diagnostics = CameraDiagnostics(log);
    calls.clear();
    messenger.setMockMethodCallHandler(CameraDiagnostics.channel, (call) async {
      calls.add(call.method);
      return call.method == 'start'
          ? [
              {
                'id': 'previous',
                'level': 'warn',
                'message': 'Previous camera failure: Broken pipe',
              },
            ]
          : null;
    });
  });

  tearDown(() async {
    await diagnostics.dispose();
    messenger.setMockMethodCallHandler(CameraDiagnostics.channel, null);
    await log.dispose();
  });

  test(
    'historical failure and live configuration reach regular App Logs',
    () async {
      await diagnostics.start();
      await emit({
        'id': 'session-1',
        'level': 'info',
        'message': 'camera-1 bound: actual=640x480',
      });
      expect(log.recent.map((e) => e.level), [LogLevel.warn, LogLevel.info]);
      expect(log.recent.every((e) => e.tag == 'camera'), isTrue);
      expect(log.recent.last.toJson()['message'], contains('actual=640x480'));
    },
  );

  test('startup replay does not duplicate live records', () async {
    await diagnostics.start();
    await emit({
      'id': 'previous',
      'level': 'warn',
      'message': 'Previous camera failure: Broken pipe',
    });
    expect(log.recent, hasLength(1));
    await diagnostics.dispose();
    expect(calls, contains('stop'));
  });

  test('missing bridge leaves camera initialization available', () async {
    messenger.setMockMethodCallHandler(CameraDiagnostics.channel, null);
    await diagnostics.start();
    expect(log.recent, isEmpty);
  });
}
