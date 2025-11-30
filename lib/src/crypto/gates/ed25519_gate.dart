import 'dart:typed_data';

/// Pluggable backend for Ed25519 curve operations (Monero, etc.).
/// All inputs/outputs are byte arrays so native backends avoid BigInt conversion.
abstract class Ed25519Gate {
  /// Scalar multiplication: [scalar] * [point]. Both 32 bytes (compressed).
  Uint8List scalarMult(Uint8List scalar, Uint8List point);

  /// Scalar multiplication with the base point G: [scalar] * G.
  Uint8List scalarMultBase(Uint8List scalar);

  /// Point addition: [p1] + [p2]. Both 32 bytes (compressed).
  Uint8List pointAdd(Uint8List p1, Uint8List p2);

  /// Compress a point to 32 bytes. Input may already be compressed.
  /// Identity for most implementations since we work in compressed form.
  Uint8List pointToBytes(Uint8List point);

  /// Decompress a 32-byte encoded point and re-encode it.
  /// Throws on invalid points. Returns the validated 32-byte encoding.
  Uint8List validatePoint(Uint8List encoded);

  /// Reduce a byte array (up to 64 bytes) modulo the group order L.
  /// Returns a 32-byte scalar.
  Uint8List scalarReduce(Uint8List input);

  /// Scalar addition: (a + b) mod L. Both inputs 32 bytes.
  Uint8List scalarAdd(Uint8List a, Uint8List b);

  /// Scalar modular reduction of a 32-byte value by L.
  /// Unlike [scalarReduce], input must be exactly 32 bytes.
  Uint8List scalarMod(Uint8List scalar);

  /// Check whether [encoded] is a valid point on Ed25519.
  bool isOnCurve(Uint8List encoded);

  Future<void> load() async {}
}
