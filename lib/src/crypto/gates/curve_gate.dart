import 'dart:typed_data';

/// Implementations may use pure Dart math or native FFI/WASM bindings.
abstract class CurveGate {
  bool isValidPrivateKey(Uint8List privKey);
  Uint8List derivePublicKey(Uint8List privKey, {bool compressed = true});
  Uint8List ecdsaSign(Uint8List hash32, Uint8List privKey);
  bool ecdsaVerify(Uint8List signature, Uint8List hash32, Uint8List pubKey);

  (Uint8List signature, int recId) ecdsaSignRecoverable(
      Uint8List hash32, Uint8List privKey);

  Uint8List ecdsaRecover(
      Uint8List signature, int recId, Uint8List hash32,
      {bool compressed = true});

  Uint8List schnorrSign(Uint8List hash32, Uint8List privKey,
      {Uint8List? auxRand});
  bool schnorrVerify(
      Uint8List signature, Uint8List hash32, Uint8List xPubKey);

  /// Returns null on overflow.
  Uint8List? privateKeyTweakAdd(Uint8List privKey, Uint8List scalar);

  /// Returns null on overflow.
  Uint8List? publicKeyTweakAdd(Uint8List pubKey, Uint8List scalar,
      {bool compressed = true});

  Uint8List privateKeyNegate(Uint8List privKey);
  Uint8List ecdh(Uint8List privKey, Uint8List pubKey);
  Uint8List ecdsaCompactToDer(Uint8List compact);
  Uint8List ecdsaDerToCompact(Uint8List der);

  /// Normalizes to low-S form (BIP-62).
  Uint8List ecdsaNormalize(Uint8List signature);

  Future<void> load() async {}
}
