import 'dart:typed_data';

/// EIP-4844 blob data. 128 KiB chunks carried by type-3 transactions.
/// KZG commitment/proof generation not yet implemented.
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
    throw UnimplementedError('BlobData.computeCommitment not yet implemented');
  }

  Uint8List computeProof() {
    throw UnimplementedError('BlobData.computeProof not yet implemented');
  }

  Uint8List computeVersionedHash() {
    throw UnimplementedError(
        'BlobData.computeVersionedHash not yet implemented');
  }
}
