import 'dart:typed_data';

import '../../monero/ed25519/ed25519_constants.dart';
import '../../monero/ed25519/ed25519_math.dart';
import '../gates/ed25519_gate.dart';

/// Pure Dart Ed25519 gate backed by BigInt arithmetic.
class SoftEd25519Gate implements Ed25519Gate {
  @override
  Uint8List scalarMult(Uint8List scalar, Uint8List point) {
    final s = edBytesToBigInt(scalar) % ed25519L;
    final p = edBytesToPoint(point);
    final result = edScalarMult(s, p);
    return edPointToBytes(result);
  }

  @override
  Uint8List scalarMultBase(Uint8List scalar) {
    final s = edBytesToBigInt(scalar) % ed25519L;
    final result = edScalarMult(s, ed25519G);
    return edPointToBytes(result);
  }

  @override
  Uint8List pointAdd(Uint8List p1, Uint8List p2) {
    final point1 = edBytesToPoint(p1);
    final point2 = edBytesToPoint(p2);
    final result = edPointAdd(point1, point2);
    return edPointToBytes(result);
  }

  @override
  Uint8List pointToBytes(Uint8List point) {
    // Already compressed 32-byte form  -  validate and return.
    final p = edBytesToPoint(point);
    return edPointToBytes(p);
  }

  @override
  Uint8List validatePoint(Uint8List encoded) {
    final p = edBytesToPoint(encoded);
    if (!edIsOnCurve(p)) {
      throw ArgumentError('Point is not on the Ed25519 curve');
    }
    return edPointToBytes(p);
  }

  @override
  Uint8List scalarReduce(Uint8List input) {
    final s = edScalarReduce(input);
    return edBigIntToBytes(s, 32);
  }

  @override
  Uint8List scalarAdd(Uint8List a, Uint8List b) {
    final sa = edBytesToBigInt(a) % ed25519L;
    final sb = edBytesToBigInt(b) % ed25519L;
    final result = (sa + sb) % ed25519L;
    return edBigIntToBytes(result, 32);
  }

  @override
  Uint8List scalarMod(Uint8List scalar) {
    final s = edBytesToBigInt(scalar) % ed25519L;
    return edBigIntToBytes(s, 32);
  }

  @override
  bool isOnCurve(Uint8List encoded) {
    try {
      final p = edBytesToPoint(encoded);
      return edIsOnCurve(p);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> load() async {}
}
