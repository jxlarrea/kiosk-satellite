import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Kiosk Satellite's Ground Control client key, from GroundControlBridge.
class ClientKey {
  ClientKey(this.id, List<int> seed) : _seed = List.unmodifiable(seed);

  final String id;
  final List<int> _seed;

  static const protocol = 'kiosk-satellite/ground-control/1';

  /// The kiosk socket's `proof`: the signature of the service's challenge
  /// for this kiosk.
  Future<Map<String, String>> proof(String nonce, String deviceId) async {
    final ed = Ed25519();
    final pair = await ed.newKeyPairFromSeed(_seed);
    final sig = await ed.sign(
      utf8.encode('$protocol\n$nonce\n$deviceId'),
      keyPair: pair,
    );
    return {'key': id, 'sig': base64Encode(sig.bytes)};
  }
}
