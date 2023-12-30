import 'dart:typed_data';
import '../gates/curve_gate.dart';

class NativeCurveGateWeb implements CurveGate {
  NativeCurveGateWeb._();

  static Future<NativeCurveGateWeb> create() async {
    final gate = NativeCurveGateWeb._();
    await gate.load();
    return gate;
  }

  @override
  Future<void> load() async {
    throw UnimplementedError(
        'WASM backend not yet built. Use SoftCurveGate instead.');
  }

  @override
  bool isValidPrivateKey(Uint8List privKey) =>
      throw UnimplementedError();

  @override
  Uint8List derivePublicKey(Uint8List privKey, {bool compressed = true}) =>
      throw UnimplementedError();

  @override
  Uint8List ecdsaSign(Uint8List hash32, Uint8List privKey) =>
      throw UnimplementedError();

  @override
  bool ecdsaVerify(Uint8List signature, Uint8List hash32, Uint8List pubKey) =>
      throw UnimplementedError();

  @override
  (Uint8List, int) ecdsaSignRecoverable(Uint8List hash32, Uint8List privKey) =>
      throw UnimplementedError();

  @override
  Uint8List ecdsaRecover(Uint8List signature, int recId, Uint8List hash32,
          {bool compressed = true}) =>
      throw UnimplementedError();

  @override
  Uint8List schnorrSign(Uint8List hash32, Uint8List privKey,
          {Uint8List? auxRand}) =>
      throw UnimplementedError();

  @override
  bool schnorrVerify(Uint8List signature, Uint8List hash32,
          Uint8List xPubKey) =>
      throw UnimplementedError();

  @override
  Uint8List? privateKeyTweakAdd(Uint8List privKey, Uint8List scalar) =>
      throw UnimplementedError();

  @override
  Uint8List? publicKeyTweakAdd(Uint8List pubKey, Uint8List scalar,
          {bool compressed = true}) =>
      throw UnimplementedError();

  @override
  Uint8List privateKeyNegate(Uint8List privKey) =>
      throw UnimplementedError();

  @override
  Uint8List ecdh(Uint8List privKey, Uint8List pubKey) =>
      throw UnimplementedError();

  @override
  Uint8List ecdsaCompactToDer(Uint8List compact) =>
      throw UnimplementedError();

  @override
  Uint8List ecdsaDerToCompact(Uint8List der) =>
      throw UnimplementedError();

  @override
  Uint8List ecdsaNormalize(Uint8List signature) =>
      throw UnimplementedError();
}
