import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/analytics/crash_journal.dart';

/// The native journal appends entries under a header and trims its head;
/// the parser hands back one entry per crash and tells the app's own
/// restarts apart from the crashes Diagnostics may report.
void main() {
  const journal = '''
	at android.app.ActivityThread.main(ActivityThread.java:7842)
	at java.lang.reflect.Method.invoke(Native Method)

=== crash at 2026-09-08 15:32:33 (app 2026.9.30, thread main) ===
java.lang.RuntimeException: process restarted deliberately: restart requested (kiosk menu, remote admin or ESPHome)
	at a7.jc.a(r8-map-id:23)

=== crash at 2026-09-10 08:01:02 (app 2026.9.41, thread main) ===
java.lang.IllegalStateException: WebView gone
	at me.jxl.kiosk_satellite.MainActivity.onCreate(MainActivity.kt:42)
	at android.app.Activity.performCreate(Activity.java:8000)
Resource snapshot (best effort):
java_heap_bytes: used=123 committed=456 max=789
Threads: 120
native_thread_sample: read=120 listed=120 limit=256
  fleet-mdns: 2
''';

  test('entries come out in order, with the truncated head dropped', () {
    final entries = parseCrashJournal(journal);
    expect(entries, hasLength(2));
    expect(entries.first.text, startsWith('=== crash at 2026-09-08'));
    expect(entries.first.appVersion, '2026.9.30');
    expect(entries.first.recordedAt, '2026-09-08 15:32:33');
    expect(entries.first.thread, 'main');
    expect(entries.last.appVersion, '2026.9.41');
    expect(entries.last.text, contains('MainActivity.onCreate'));
    expect(entries.last.text, contains('Threads: 120'));
    expect(entries.last.text, isNot(contains('restarted deliberately')));
    expect(
      entries.last.headline,
      'java.lang.IllegalStateException: WebView gone',
    );
  });

  test('a requested restart is not reported; a watchdog restart is', () {
    final entries = parseCrashJournal(journal);
    expect(entries.first.deliberate, isTrue);
    expect(entries.first.watchdog, isFalse);
    expect(entries.first.reportable, isFalse);
    expect(entries.last.deliberate, isFalse);
    expect(entries.last.reportable, isTrue);
    final wd = parseCrashJournal(
      '=== crash at 2026-09-11 01:02:03 (app 2026.9.42, thread main) ===\n'
      'java.lang.RuntimeException: process restarted deliberately: the '
      'frame watchdog found the UI wedged (no frames for 30s)\n'
      '\tat a7.jc.a(r8-map-id:23)\n',
    ).single;
    expect(wd.deliberate, isTrue);
    expect(wd.watchdog, isTrue);
    expect(wd.reportable, isTrue);
    expect(
      wd.reason,
      'the frame watchdog found the UI wedged (no frames for 30s)',
    );
  });

  test('a main thread watchdog restart is reported', () {
    final wd = parseCrashJournal(
      '=== crash at 2026-10-26 01:02:03 (app 2026.10.42, thread main) ===\n'
      'java.lang.RuntimeException: process restarted deliberately: the '
      'main thread watchdog found the main thread stuck in one task for 60s\n'
      '\tat J.N.VJJJO(Native Method)\n'
      '\tat org.chromium.components.viz.service.frame_sinks.'
      'ExternalBeginFrameSourceAndroid.doFrame(r8-map-id:64)\n',
    ).single;
    expect(wd.deliberate, isTrue);
    expect(wd.watchdog, isTrue);
    expect(wd.reportable, isTrue);
  });

  test('a camera watchdog restart is reported', () {
    final wd = parseCrashJournal(
      '=== crash at 2026-11-07 16:51:58 (app 2026.11.12, thread main) ===\n'
      'java.lang.RuntimeException: process restarted deliberately: the '
      'camera watchdog found 400 leaked camera threads; each failed open of '
      "this device's HAL1 camera leaves 2 threads running until the app "
      'restarts\n'
      '\tat dalvik.system.VMStack.getThreadStackTrace(Native Method)\n',
    ).single;
    expect(wd.deliberate, isTrue);
    expect(wd.watchdog, isTrue);
    expect(wd.reportable, isTrue);
  });

  test('a crash a shell asked for is journaled but not reported', () {
    final adb = parseCrashJournal(
      '=== crash at 2026-09-12 17:58:00 (app 2026.9.44, thread main) ===\n'
      'android.app.RemoteServiceException\$CrashedByAdbException: '
      'shell-induced crash\n'
      '\tat android.app.ActivityThread.throwRemoteServiceException'
      '(ActivityThread.java:2107)\n',
    ).single;
    expect(adb.deliberate, isFalse);
    expect(adb.shellInduced, isTrue);
    expect(adb.reportable, isFalse);
    // The other RemoteServiceException kinds are app faults and stay.
    final fgs = parseCrashJournal(
      '=== crash at 2026-09-12 17:59:00 (app 2026.9.44, thread main) ===\n'
      'android.app.RemoteServiceException\$ForegroundServiceDidNotStart'
      'InTimeException: Context.startForegroundService() did not then call '
      'Service.startForeground()\n',
    ).single;
    expect(fgs.shellInduced, isFalse);
    expect(fgs.reportable, isTrue);
  });

  test('text without a header is one entry', () {
    final entries = parseCrashJournal('FATAL EXCEPTION: main\njava.lang.X: y');
    expect(entries, hasLength(1));
    expect(entries.single.appVersion, isNull);
    expect(entries.single.headline, 'java.lang.X: y');
    expect(parseCrashJournal('  \n'), isEmpty);
  });
}
