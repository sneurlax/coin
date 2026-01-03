import 'dart:typed_data';
import '../gates/ed25519_gate.dart';

/// Native FFI backend for Ed25519 operations.
/// Requires a shared library exposing Ed25519 functions over C ABI.
class NativeEd25519GateIo implements Ed25519Gate {
  NativeEd25519GateIo._();

  static Future<NativeEd25519GateIo> create() async {
    final gate = NativeEd25519GateIo._();
    await gate.load();
    return gate;
  }

  @override
  Future<void> load() async {
    throw UnimplementedError(
        'Native Ed25519 FFI backend not yet built. Use SoftEd25519Gate.');
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
