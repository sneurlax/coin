import 'dart:typed_data';

import '../../crypto/vault_keeper.dart';

/// key_image = privateKey * Hp(publicKey). Deterministic per output,
/// so double-spends produce the same image and get rejected.
class KeyImage {
  KeyImage._();

  static final Uint8List _cofactor8 = _make8Scalar();

  static Uint8List _make8Scalar() {
    final b = Uint8List(32);
    b[0] = 8;
    return b;
  }

  static Uint8List compute(
      Uint8List outputPrivateKey, Uint8List outputPublicKey) {
    final ed = VaultKeeper.vault.ed25519;
    final hp = hashToPoint(outputPublicKey);
    return ed.scalarMult(outputPrivateKey, hp);
  }

  /// Keccak-256, decompress as Ed25519, retry on failure, then * 8 for subgroup.
  static Uint8List hashToPoint(Uint8List data) {
    final ed = VaultKeeper.vault.ed25519;
    var hash = VaultKeeper.vault.digest.keccak256(data);
    while (true) {
      try {
        final tryBytes = Uint8List.fromList(hash);
        tryBytes[31] &= 0x7f;
        // validatePoint will throw on invalid
        final point = ed.validatePoint(tryBytes);
        final cleared = ed.scalarMult(_cofactor8, point);
        // Check non-identity (not all zeros except byte 0 which would be 0x01)
        if (cleared[0] != 0x01 || cleared.skip(1).any((b) => b != 0)) {
          return cleared;
        }
      } catch (_) {} // decompression failed, retry
      hash = VaultKeeper.vault.digest.keccak256(hash);
    }
  }
}
