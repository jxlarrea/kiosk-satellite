import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;

/// The custom update repository setting: a folder URL on the user's own
/// web server, revealed only while the source picker says Custom.
void main() {
  group('validateUpdateSourceUrl', () {
    test('accepts a folder URL with a path, on either scheme', () {
      expect(defs.validateUpdateSourceUrl(''), isNull);
      expect(
        defs.validateUpdateSourceUrl('http://nas.local/kiosk-satellite'),
        isNull,
      );
      expect(
        defs.validateUpdateSourceUrl('https://nas.local:8443/ks/'),
        isNull,
      );
      expect(defs.validateUpdateSourceUrl('http://10.0.0.5'), isNull);
    });

    test('rejects other schemes, bare paths and query tails', () {
      expect(defs.validateUpdateSourceUrl('smb://nas/ks'), isNotNull);
      expect(defs.validateUpdateSourceUrl('/volume1/ks'), isNotNull);
      expect(defs.validateUpdateSourceUrl('nas.local/ks'), isNotNull);
      expect(defs.validateUpdateSourceUrl('http://nas/ks?x=1'), isNotNull);
      expect(defs.validateUpdateSourceUrl('http://nas/ks#top'), isNotNull);
    });
  });

  group('normalizeUpdateSourceUrl', () {
    test('drops trailing slashes and a pasted releases.json', () {
      expect(
        defs.normalizeUpdateSourceUrl('http://nas.local/ks/'),
        'http://nas.local/ks',
      );
      expect(
        defs.normalizeUpdateSourceUrl(' http://nas.local/ks/releases.json '),
        'http://nas.local/ks',
      );
      expect(
        defs.normalizeUpdateSourceUrl('http://nas.local/'),
        'http://nas.local',
      );
    });
  });

  test('the URL row gates on the Custom Repository pick', () {
    expect(defs.updateSource.defaultValue, 'github');
    expect(defs.updateSource.options, ['github', 'custom']);
    expect(defs.updateSourceUrl.dependsOn, defs.updateSource.key);
    expect(defs.updateSourceUrl.dependsSatisfiedBy('custom'), isTrue);
    expect(defs.updateSourceUrl.dependsSatisfiedBy('github'), isFalse);
  });

  test('both rows share the Updates page under Device and ride fleet sync', () {
    for (final def in [defs.updateSource, defs.updateSourceUrl]) {
      expect(def.category, 'Device');
      expect(def.subpage, 'Updates');
      expect(def.section, 'Kiosk Satellite Updates');
      expect(def.perDevice, isFalse);
      expect(defs.allSettings, contains(def));
    }
    expect(defs.subpageHints, contains('Updates'));
    // The certificate page is inserted between these definition groups.
    final keys = defs.allSettings.map((d) => d.key).toList();
    expect(
      keys.indexOf(defs.updateSource.key),
      keys.indexOf(defs.remoteAdminUrl.key) + 1,
    );
  });
}
