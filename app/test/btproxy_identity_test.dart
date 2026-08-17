import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/btproxy/ble_identity.dart';

Map<String, Object?> raw({
  String address = '5C:E7:53:E7:A1:6B',
  int addressType = 0,
  String? name,
  List<int> companies = const [],
  Map<String, int> firstBytes = const {},
  List<String> uuids = const [],
  int rssi = -60,
}) => {
  'address': address,
  'addressType': addressType,
  'name': name,
  'companies': companies,
  'firstBytes': firstBytes,
  'uuids': uuids,
  'rssi': rssi,
  'lastSeenAt': DateTime(2026, 8, 17).millisecondsSinceEpoch,
  'count': 3,
};

void main() {
  test('broadcast name wins over everything', () {
    final d = classify(raw(name: 'Govee_H6604_BABB', companies: [34883]));
    expect(d.identity, 'Govee_H6604_BABB');
    expect(d.vendor, 'Govee');
  });

  test('service UUID identifies a class on anonymous devices', () {
    final d = classify(raw(uuids: ['fcd2']));
    expect(d.identity, 'BTHome sensor');
  });

  test('Apple frame types tell an AirTag from an idle iPhone', () {
    expect(
      classify(raw(companies: [76], firstBytes: {'76': 0x12})).identity,
      'Apple Find My device',
    );
    expect(
      classify(raw(companies: [76], firstBytes: {'76': 0x10})).identity,
      'Apple device',
    );
    // Unknown frame type still lands on the vendor, never on Unknown.
    expect(
      classify(raw(companies: [76], firstBytes: {'76': 0x42})).identity,
      'Apple device',
    );
  });

  test('company table names common vendors', () {
    expect(classify(raw(companies: [6])).identity, 'Windows PC');
    expect(classify(raw(companies: [117])).identity, 'Samsung device');
    expect(
      classify(raw(companies: [1744])).identity,
      'VeSync (Levoit/Etekcity) device',
    );
  });

  test('nothing known stays honestly unknown', () {
    final d = classify(raw(companies: [65535]));
    expect(d.identity, 'Unknown device');
    expect(d.vendor, isNull);
  });

  test('OUI vendor fills in when the tables have nothing', () {
    final d = classify(raw(companies: [65535]), ouiVendor: 'Espressif Inc.');
    expect(d.vendor, 'Espressif Inc.');
    expect(d.identity, 'Espressif Inc. device');
  });

  test('rotating flag set for resolvable private addresses only', () {
    // Top bits 01: a resolvable private address, rotates periodically.
    expect(
      classify(raw(address: '6B:0E:08:3D:0C:C9', addressType: 1)).rotating,
      isTrue,
    );
    // Top bits 11: static random, stable for the device's lifetime (the
    // address style Govee and Nordic sensors use). Not rotating.
    expect(
      classify(raw(address: 'CB:B1:AA:46:32:4C', addressType: 1)).rotating,
      isFalse,
    );
    // Public address stays stable whatever the type claims.
    expect(
      classify(raw(address: '5C:E7:53:E7:A1:6B', addressType: 0)).rotating,
      isFalse,
    );
    // A named device never gets the mark: real public OUIs can share the
    // 01 top bits with private addresses (Govee's 5C:E7:53 does), and the
    // anonymous rotating crowd never broadcasts a name.
    expect(
      classify(
        raw(address: '5C:E7:53:F1:5D:89', addressType: 1, name: 'GVH14015D89'),
      ).rotating,
      isFalse,
    );
  });

  test('hasRealOui rejects locally administered and multicast addresses', () {
    expect(hasRealOui('5C:E7:53:E7:A1:6B'), isTrue); // real Govee OUI
    expect(hasRealOui('7A:43:83:0B:9A:6E'), isFalse); // locally administered
    expect(hasRealOui('DA:2B:09:B3:6D:4F'), isFalse); // locally administered
    expect(hasRealOui('01:00:5E:00:00:01'), isFalse); // multicast
  });

  test('ouiOf yields the uppercase 3-byte prefix', () {
    expect(ouiOf('5c:e7:53:e7:a1:6b'), '5C:E7:53');
  });

  test('toJson carries the fields the MQTT attributes need', () {
    final json = classify(
      raw(name: 'GVH1401A16B', companies: [34883], rssi: -61),
    ).toJson();
    expect(json['mac'], '5C:E7:53:E7:A1:6B');
    expect(json['identity'], 'GVH1401A16B');
    expect(json['vendor'], 'Govee');
    expect(json['rssi'], -61);
    expect(json.containsKey('rotating'), isFalse);
    expect(json['last_seen'], isNotNull);
  });
}
