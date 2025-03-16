import 'dart:typed_data';

import '../../core/hex.dart';
import '../../core/random.dart';
import '../../crypto/vault_keeper.dart';
import '../ed25519/ed25519_constants.dart';
import '../ed25519/ed25519_math.dart';

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
    final spendScalar = edScalarReduce(seed);
    final spendKeyBytes = edBigIntToBytes(spendScalar, 32);
    return MoneroKeys.fromSpendKey(spendKeyBytes);
  }

  factory MoneroKeys.fromSpendKey(Uint8List privateSpendKey) {
    if (privateSpendKey.length != 32) {
      throw ArgumentError(
          'Private spend key must be 32 bytes, got ${privateSpendKey.length}');
    }

    final spendBytes = Uint8List.fromList(privateSpendKey);
    final spendScalar = edBytesToBigInt(spendBytes);

    if (spendScalar == BigInt.zero || spendScalar >= ed25519L) {
      throw ArgumentError('Private spend key is not a valid Ed25519 scalar');
    }

    final pubSpendPoint = edScalarMult(spendScalar, ed25519G);
    final pubSpendBytes = edPointToBytes(pubSpendPoint);

    final viewHash = VaultKeeper.vault.digest.keccak256(spendBytes);
    final viewScalar = edScalarReduce(viewHash);
    final viewKeyBytes = edBigIntToBytes(viewScalar, 32);

    final pubViewPoint = edScalarMult(viewScalar, ed25519G);
    final pubViewBytes = edPointToBytes(pubViewPoint);

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
