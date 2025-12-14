import 'dart:typed_data';

import '../../core/hex.dart';
import '../../core/random.dart';
import '../../crypto/vault_keeper.dart';

/// Spend and view key pairs on Ed25519. From a seed: spendPriv = reduce(seed),
/// viewPriv = reduce(keccak(spendPriv)), public keys = scalar * G.
class MoneroKeys {
  final Uint8List privateSpendKey;
  final Uint8List publicSpendKey;
  final Uint8List privateViewKey;
  final Uint8List publicViewKey;

  MoneroKeys._({
    required this.privateSpendKey,
    required this.publicSpendKey,
    required this.privateViewKey,
    required this.publicViewKey,
  });

  factory MoneroKeys.fromSeed(Uint8List seed) {
    if (seed.length != 32) {
      throw ArgumentError('Seed must be 32 bytes, got ${seed.length}');
    }
    final spendKeyBytes = VaultKeeper.vault.ed25519.scalarReduce(seed);
    return MoneroKeys.fromSpendKey(spendKeyBytes);
  }

  factory MoneroKeys.fromSpendKey(Uint8List privateSpendKey) {
    if (privateSpendKey.length != 32) {
      throw ArgumentError(
          'Private spend key must be 32 bytes, got ${privateSpendKey.length}');
    }

    final spendBytes = Uint8List.fromList(privateSpendKey);

    // Validate: must be a reduced non-zero scalar.
    final reduced = VaultKeeper.vault.ed25519.scalarMod(spendBytes);
    final isZero = reduced.every((b) => b == 0);
    // Check scalar == reduced (already in canonical form).
    var isReduced = true;
    for (var i = 0; i < 32; i++) {
      if (spendBytes[i] != reduced[i]) {
        isReduced = false;
        break;
      }
    }
    if (isZero || !isReduced) {
      throw ArgumentError('Private spend key is not a valid Ed25519 scalar');
    }

    final ed = VaultKeeper.vault.ed25519;
    final pubSpendBytes = ed.scalarMultBase(spendBytes);

    final viewHash = VaultKeeper.vault.digest.keccak256(spendBytes);
    final viewKeyBytes = ed.scalarReduce(viewHash);

    final pubViewBytes = ed.scalarMultBase(viewKeyBytes);

    return MoneroKeys._(
      privateSpendKey: spendBytes,
      publicSpendKey: pubSpendBytes,
      privateViewKey: viewKeyBytes,
      publicViewKey: pubViewBytes,
    );
  }

  factory MoneroKeys.generate() => MoneroKeys.fromSeed(generateSecureBytes(32));

  String get privateSpendKeyHex => hexEncode(privateSpendKey);
  String get publicSpendKeyHex => hexEncode(publicSpendKey);
  String get privateViewKeyHex => hexEncode(privateViewKey);
  String get publicViewKeyHex => hexEncode(publicViewKey);
}
