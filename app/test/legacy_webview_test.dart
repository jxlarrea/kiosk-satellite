import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;

/// Issue #302: old GPUs that cannot hand Flutter's overlay frames back abort
/// the process the moment the dashboard appears, so the WebView has to be
/// drawn through a texture there instead. The switch is written natively,
/// before Dart runs, which makes the key a contract between the two.
void main() {
  test('the legacy WebView renderer is a Device setting, off by default', () {
    expect(defs.allSettings, contains(defs.legacyWebView));
    expect(defs.legacyWebView.key, 'render.legacy_webview');
    expect(defs.legacyWebView.defaultValue, isFalse);
    expect(defs.legacyWebView.category, 'Device');
  });

  test('the native probe writes the key this setting reads', () {
    final guard = File(
      'android/app/src/main/kotlin/me/jxl/kiosk_satellite/'
      'WebViewCompositingGuard.kt',
    ).readAsStringSync();
    // shared_preferences prefixes its own keys with "flutter.", the
    // settings store prefixes its own with "ks.".
    expect(guard, contains('"flutter.ks.${defs.legacyWebView.key}"'));
    // The stamp is committed before the probe runs: a driver that dies
    // inside EGL must take the app down once, not at every launch.
    final stamp = guard.indexOf('putLong(PROBED');
    final probe = guard.indexOf('producerFormatMismatches()');
    expect(stamp, greaterThan(0));
    expect(stamp, lessThan(probe));
  });

  test('both WebViews follow the setting', () {
    final screen = File('lib/ui/kiosk_screen.dart').readAsStringSync();
    expect(screen.contains('useHybridComposition: true'), isFalse);
    // The dashboard and the excursion WebView, both negated from the
    // setting rather than hard-coded.
    expect('useHybridComposition: !'.allMatches(screen).length, 2);
  });
}
