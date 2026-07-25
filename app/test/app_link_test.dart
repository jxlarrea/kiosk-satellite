import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/kiosk/app_link.dart';

void main() {
  group('appLinkPackage', () {
    test('reads the package from the usual form', () {
      expect(
        appLinkPackage('app://com.android.deskclock'),
        'com.android.deskclock',
      );
    });

    test('tolerates a trailing slash and surrounding space', () {
      expect(appLinkPackage(' app://com.android.deskclock/ '),
          'com.android.deskclock');
    });

    test('accepts the hostless form', () {
      expect(appLinkPackage('app:com.android.deskclock'), 'com.android.deskclock');
    });

    test('keeps the case, which Uri.host would not', () {
      expect(
        appLinkPackage('app://com.Example.MyApp'),
        'com.Example.MyApp',
      );
    });

    test('accepts digits and underscores inside segments', () {
      expect(appLinkPackage('app://com.foo_bar.app2'), 'com.foo_bar.app2');
    });

    test('leaves other schemes alone', () {
      expect(appLinkPackage('https://home.example/lovelace'), isNull);
      expect(appLinkPackage('intent://scan/#Intent;end'), isNull);
      expect(appLinkPackage(''), isNull);
    });

    test('refuses anything that is not just a package', () {
      // A path, query or fragment cannot be passed on, so it is not silently
      // dropped in favour of opening the app.
      expect(appLinkPackage('app://com.android.deskclock/alarms'), isNull);
      expect(appLinkPackage('app://com.android.deskclock?x=1'), isNull);
      // A single segment is not a package name.
      expect(appLinkPackage('app://deskclock'), isNull);
      // Segments must start with a letter.
      expect(appLinkPackage('app://com.1foo'), isNull);
    });
  });
}
