import 'dart:typed_data';

import '../../hash/digest.dart';

/// EIP-4844 blob data. 128 KiB chunks carried by type-3 transactions.
/// KZG commitment/proof must be supplied externally (via a KZG library or
/// precomputed values). [computeVersionedHash] derives the hash locally.
class BlobData {
  final Uint8List data;
  final Uint8List? commitment;
  final Uint8List? proof;
  final Uint8List? versionedHash;

  BlobData({
    required this.data,
    this.commitment,
    this.proof,
    this.versionedHash,
  });

  Uint8List computeCommitment() {
    if (commitment != null) return commitment!;
    throw StateError(
        'No commitment available. Supply a KZG commitment via the constructor.');
  }

  Uint8List computeProof() {
    if (proof != null) return proof!;
    throw StateError(
        'No proof available. Supply a KZG proof via the constructor.');
  }

  // version_byte (0x01) || sha256(commitment)[1:]
  Uint8List computeVersionedHash() {
    if (versionedHash != null) return versionedHash!;
    final c = computeCommitment();
    final hash = sha256(c);
    hash[0] = 0x01;
    return hash;
  }
}
