import 'dart:typed_data';

import '../../crypto/vault_keeper.dart';
import '../ed25519/ed25519_constants.dart';
import '../ed25519/ed25519_math.dart';

/// key_image = privateKey * Hp(publicKey). Deterministic per output,
/// so double-spends produce the same image and get rejected.
class KeyImage {
  KeyImage._();

  static Uint8List compute(
      Uint8List outputPrivateKey, Uint8List outputPublicKey) {
    final hp = hashToPoint(outputPublicKey);
    final scalar = edBytesToBigInt(outputPrivateKey) % ed25519L;
    final image = edScalarMult(scalar, hp);
    return edPointToBytes(image);
  }

  /// Keccak-256, decompress as Ed25519, retry on failure, then * 8 for subgroup.
  static EdPoint hashToPoint(Uint8List data) {
    var hash = VaultKeeper.vault.digest.keccak256(data);
    while (true) {
      try {
        final tryBytes = Uint8List.fromList(hash);
        tryBytes[31] &= 0x7f;
        final point = edBytesToPoint(tryBytes);
        final cleared = edScalarMult(BigInt.from(8), point);
        if (!cleared.isInfinity) return cleared;
      } catch (_) {}  // decompression failed, retry
      hash = VaultKeeper.vault.digest.keccak256(hash);
    }
  }
}
