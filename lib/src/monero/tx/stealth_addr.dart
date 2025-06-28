import 'dart:typed_data';

import '../../crypto/vault_keeper.dart';
import '../ed25519/ed25519_constants.dart';
import '../ed25519/ed25519_math.dart';

/// One-time output key: P = Hs(r*viewKey || i)*G + spendKey.
/// Recipient detects via P' = Hs(viewPriv*R || i)*G + spendKey, checks P'==P.
class StealthAddress {
  StealthAddress._();

  static Uint8List deriveOutputKey({
    required Uint8List txSecretKey,
    required Uint8List recipientViewKey,
    required Uint8List recipientSpendKey,
    required int outputIndex,
  }) {
    // Cofactor-cleared ECDH: 8 * (r * viewKey)
    final rScalar = edBytesToBigInt(txSecretKey) % ed25519L;
    final viewPoint = edBytesToPoint(recipientViewKey);
    final shared = edPointToBytes(
        edScalarMult(BigInt.from(8), edScalarMult(rScalar, viewPoint)));

    final hs = _hashToScalar(shared, outputIndex);
    final hsG = edScalarMult(hs, ed25519G);
    final spendPoint = edBytesToPoint(recipientSpendKey);
    final outputPoint = edPointAdd(hsG, spendPoint);
    return edPointToBytes(outputPoint);
  }

  static Uint8List txPublicKey(Uint8List txSecretKey) {
    final rScalar = edBytesToBigInt(txSecretKey) % ed25519L;
    return edPointToBytes(edScalarMult(rScalar, ed25519G));
  }

  static bool isOurOutput({
    required Uint8List privateViewKey,
    required Uint8List publicSpendKey,
    required Uint8List txPublicKey,
    required Uint8List outputKey,
    required int outputIndex,
  }) {
    final aScalar = edBytesToBigInt(privateViewKey) % ed25519L;
    final rPoint = edBytesToPoint(txPublicKey);
    final shared = edPointToBytes(
        edScalarMult(BigInt.from(8), edScalarMult(aScalar, rPoint)));

    final hs = _hashToScalar(shared, outputIndex);
    final hsG = edScalarMult(hs, ed25519G);
    final spendPoint = edBytesToPoint(publicSpendKey);
    final expected = edPointToBytes(edPointAdd(hsG, spendPoint));

    if (expected.length != outputKey.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected[i] ^ outputKey[i];
    }
    return diff == 0;
  }

  /// x = Hs(viewKey * R || i) + spendKey (mod l)
  static Uint8List deriveOutputPrivateKey({
    required Uint8List privateSpendKey,
    required Uint8List privateViewKey,
    required Uint8List txPublicKey,
    required int outputIndex,
  }) {
    final aScalar = edBytesToBigInt(privateViewKey) % ed25519L;
    final rPoint = edBytesToPoint(txPublicKey);
    final shared = edPointToBytes(
        edScalarMult(BigInt.from(8), edScalarMult(aScalar, rPoint)));

    final hs = _hashToScalar(shared, outputIndex);
    final bScalar = edBytesToBigInt(privateSpendKey) % ed25519L;
    final outputScalar = (hs + bScalar) % ed25519L;
    return edBigIntToBytes(outputScalar, 32);
  }

  static BigInt _hashToScalar(Uint8List sharedSecret, int outputIndex) {
    final indexBytes = _encodeVarint(outputIndex);
    final data = Uint8List(sharedSecret.length + indexBytes.length);
    data.setAll(0, sharedSecret);
    data.setAll(sharedSecret.length, indexBytes);
    final hash = VaultKeeper.vault.digest.keccak256(data);
    return edScalarReduce(hash);
  }

  static Uint8List _encodeVarint(int value) {
    if (value < 0) throw ArgumentError('Negative varint');
    final result = <int>[];
    var v = value;
    while (v >= 0x80) {
      result.add((v & 0x7f) | 0x80);
      v >>= 7;
    }
    result.add(v);
    return Uint8List.fromList(result);
  }
}
