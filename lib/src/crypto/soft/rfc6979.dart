import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;

import 'ec_math.dart';

BigInt generateDeterministicK(Uint8List hash32, Uint8List privKey32) {
  var v = Uint8List(32)..fillRange(0, 32, 0x01);
  var k = Uint8List(32);

  // Step D
  k = _hmacSha256(k, _concat([v, Uint8List.fromList([0x00]), privKey32, hash32]));
  // Step E
  v = _hmacSha256(k, v);
  // Step F
  k = _hmacSha256(k, _concat([v, Uint8List.fromList([0x01]), privKey32, hash32]));
  // Step G
  v = _hmacSha256(k, v);

  while (true) {
    // Step H
    v = _hmacSha256(k, v);
    final candidate = bytesToBigInt(v);
    if (candidate > BigInt.zero && candidate < secp256k1N) {
      return candidate;
    }
    k = _hmacSha256(k, _concat([v, Uint8List.fromList([0x00])]));
    v = _hmacSha256(k, v);
  }
}

Uint8List _hmacSha256(Uint8List key, Uint8List data) {
  final hmac = crypto.Hmac(crypto.sha256, key);
  final digest = hmac.convert(data);
  return Uint8List.fromList(digest.bytes);
}

Uint8List _concat(List<Uint8List> parts) {
  var total = 0;
  for (final p in parts) {
    total += p.length;
  }
  final out = Uint8List(total);
  var offset = 0;
  for (final p in parts) {
    out.setAll(offset, p);
    offset += p.length;
  }
  return out;
}
