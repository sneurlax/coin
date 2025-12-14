import 'dart:typed_data';

import '../../crypto/gates/ed25519_gate.dart';
import '../../crypto/vault_keeper.dart';

/// One-time output key: P = Hs(r*viewKey || i)*G + spendKey.
/// Recipient detects via P' = Hs(viewPriv*R || i)*G + spendKey, checks P'==P.
class StealthAddress {
  StealthAddress._();

  static final Uint8List _cofactor8 = _make8Scalar();

  static Uint8List _make8Scalar() {
    final b = Uint8List(32);
    b[0] = 8;
    return b;
  }

  static Uint8List deriveOutputKey({
    required Uint8List txSecretKey,
    required Uint8List recipientViewKey,
    required Uint8List recipientSpendKey,
    required int outputIndex,
  }) {
    final ed = VaultKeeper.vault.ed25519;

    // Cofactor-cleared ECDH: 8 * (r * viewKey)
    final rV = ed.scalarMult(txSecretKey, recipientViewKey);
    final shared = ed.scalarMult(_cofactor8, rV);

    final hs = _hashToScalar(ed, shared, outputIndex);
    final hsG = ed.scalarMultBase(hs);
    final outputPoint = ed.pointAdd(hsG, recipientSpendKey);
    return outputPoint;
  }

  static Uint8List txPublicKey(Uint8List txSecretKey) {
    return VaultKeeper.vault.ed25519.scalarMultBase(txSecretKey);
  }

  static bool isOurOutput({
    required Uint8List privateViewKey,
    required Uint8List publicSpendKey,
    required Uint8List txPublicKey,
    required Uint8List outputKey,
    required int outputIndex,
  }) {
    final ed = VaultKeeper.vault.ed25519;

    final aR = ed.scalarMult(privateViewKey, txPublicKey);
    final shared = ed.scalarMult(_cofactor8, aR);

    final hs = _hashToScalar(ed, shared, outputIndex);
    final hsG = ed.scalarMultBase(hs);
    final expected = ed.pointAdd(hsG, publicSpendKey);

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
    final ed = VaultKeeper.vault.ed25519;

    final aR = ed.scalarMult(privateViewKey, txPublicKey);
    final shared = ed.scalarMult(_cofactor8, aR);

    final hs = _hashToScalar(ed, shared, outputIndex);
    return ed.scalarAdd(hs, privateSpendKey);
  }

  static Uint8List _hashToScalar(
      Ed25519Gate ed, Uint8List sharedSecret, int outputIndex) {
    final indexBytes = _encodeVarint(outputIndex);
    final data = Uint8List(sharedSecret.length + indexBytes.length);
    data.setAll(0, sharedSecret);
    data.setAll(sharedSecret.length, indexBytes);
    final hash = VaultKeeper.vault.digest.keccak256(data);
    return ed.scalarReduce(hash);
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
