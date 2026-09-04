import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/device/ip_addresses.dart';

/// Issue #213: the ESPHome sensors carry this detail as entities of their
/// own, off one summary, so no two readers can lead with different
/// addresses.
void main() {
  test('the first address leads and the rest are the others', () {
    final family = summarizeIpFamily(const {
      'wlan0': ['192.168.1.50'],
      'eth0': ['10.0.3.2'],
    }, preferGlobal: false);
    expect(family.primary, '192.168.1.50');
    expect(family.others, ['10.0.3.2']);
    expect(family.byInterface['eth0'], ['10.0.3.2']);
    expect(family.oneLine, 'wlan0: 192.168.1.50; eth0: 10.0.3.2');
  });

  test('IPv6 prefers a routable address and drops the scope id', () {
    final family = summarizeIpFamily(const {
      'wlan0': ['fe80::1234%wlan0', '2001:db8::50'],
    }, preferGlobal: true);
    expect(family.primary, '2001:db8::50');
    expect(family.others, ['fe80::1234']);
    expect(family.oneLine, 'wlan0: fe80::1234, 2001:db8::50');
  });

  test('link-local leads when it is all the device has', () {
    final family = summarizeIpFamily(const {
      'wlan0': ['fe80::1'],
    }, preferGlobal: true);
    expect(family.primary, 'fe80::1');
    expect(family.others, isEmpty);
  });

  test('no address of the family reads empty, which HA takes as unknown', () {
    final family = summarizeIpFamily(const {}, preferGlobal: false);
    expect(family.primary, '');
    expect(family.oneLine, '');
    expect(summarizeIpFamily(null, preferGlobal: true).primary, '');
  });

  test(
    'the one-line form stays inside the state length Home Assistant takes',
    () {
      final family = summarizeIpFamily({
        for (var i = 0; i < 12; i++)
          'interface$i': ['2001:db8:$i::dead:beef:cafe:1234'],
      }, preferGlobal: true);
      expect(family.oneLine.length, lessThanOrEqualTo(255));
      expect(family.oneLine, endsWith('...'));
      // What survives is still readable, not a string cut mid-address.
      expect(family.oneLine, startsWith('interface0: 2001:db8:0::dead'));
    },
  );
}
