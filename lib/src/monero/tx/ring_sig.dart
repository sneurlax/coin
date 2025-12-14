import 'dart:typed_data';

import '../../crypto/vault_keeper.dart';
import 'key_image.dart';

class OutputReference {
  final Uint8List txHash;
  final int outputIndex;
  /// Always 0 for RingCT (amount hidden).
  final BigInt amount;
  final Uint8List outputKey;

  OutputReference({
    required this.txHash,
    required this.outputIndex,
    required this.amount,
    required this.outputKey,
  });
}

class RingMember {
  final OutputReference reference;
  final Uint8List commitment;

  RingMember({required this.reference, required this.commitment});
}

class MoneroTxInput {
  final List<RingMember> ring;
  final Uint8List keyImage;
  /// Private knowledge of the sender; never serialized on chain.
  final int realIndex;

  MoneroTxInput({
    required this.ring,
    required this.keyImage,
    this.realIndex = -1,
  });
}

class MoneroTxOutput {
  final Uint8List oneTimeKey;
  final Uint8List commitment;
  final Uint8List encryptedAmount;

  MoneroTxOutput({
    required this.oneTimeKey,
    required this.commitment,
    required this.encryptedAmount,
  });
}

/// C = amount * H + mask * G. H = hashToPoint(G), so DL(G,H) is unknown.
class PedersenCommitment {
  PedersenCommitment._();

  static Uint8List? _hCache;

  /// The alternate generator H = hashToPoint(G). Public for testing.
  static Uint8List get h => _hCache ??= _computeH();

  static Uint8List commit(BigInt amount, Uint8List mask) {
    final ed = VaultKeeper.vault.ed25519;

    // Encode amount as a 32-byte LE scalar.
    final amountBytes = Uint8List(32);
    var a = amount;
    for (var i = 0; i < 32 && a > BigInt.zero; i++) {
      amountBytes[i] = (a & BigInt.from(0xFF)).toInt();
      a >>= 8;
    }

    final amountH = ed.scalarMult(amountBytes, h);
    final maskG = ed.scalarMultBase(mask);
    return ed.pointAdd(amountH, maskG);
  }

  static bool verify(Uint8List commitment, BigInt amount, Uint8List mask) {
    final expected = commit(amount, mask);
    if (expected.length != commitment.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected[i] ^ commitment[i];
    }
    return diff == 0;
  }

  static Uint8List _computeH() {
    final ed = VaultKeeper.vault.ed25519;
    final gBytes = ed.scalarMultBase(_oneScalar());
    return KeyImage.hashToPoint(gBytes);
  }

  static Uint8List _oneScalar() {
    final b = Uint8List(32);
    b[0] = 1;
    return b;
  }
}
