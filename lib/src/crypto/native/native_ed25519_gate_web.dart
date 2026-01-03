import 'dart:typed_data';
import '../gates/ed25519_gate.dart';

/// WASM backend for Ed25519 operations (web platform).
class NativeEd25519GateWeb implements Ed25519Gate {
  NativeEd25519GateWeb._();

  static Future<NativeEd25519GateWeb> create() async {
    final gate = NativeEd25519GateWeb._();
    await gate.load();
    return gate;
  }

  @override
  Future<void> load() async {
    throw UnimplementedError(
        'WASM Ed25519 backend not yet built. Use SoftEd25519Gate.');
  }

  @override
  Uint8List scalarMult(Uint8List scalar, Uint8List point) =>
      throw UnimplementedError();

  @override
  Uint8List scalarMultBase(Uint8List scalar) => throw UnimplementedError();

  @override
  Uint8List pointAdd(Uint8List p1, Uint8List p2) =>
      throw UnimplementedError();

  @override
  Uint8List pointToBytes(Uint8List point) => throw UnimplementedError();

  @override
  Uint8List validatePoint(Uint8List encoded) => throw UnimplementedError();

  @override
  Uint8List scalarReduce(Uint8List input) => throw UnimplementedError();

  @override
  Uint8List scalarAdd(Uint8List a, Uint8List b) =>
      throw UnimplementedError();

  @override
  Uint8List scalarMod(Uint8List scalar) => throw UnimplementedError();

  @override
  bool isOnCurve(Uint8List encoded) => throw UnimplementedError();
}
