import 'dart:typed_data';

import '../ed25519/ed25519_constants.dart';
import '../ed25519/ed25519_math.dart';
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

  static EdPoint? _hCache;
  static EdPoint get h => _hCache ??= _computeH();

  static Uint8List commit(BigInt amount, Uint8List mask) {
    final maskScalar = edBytesToBigInt(mask) % ed25519L;
    final amountH = edScalarMult(amount % ed25519L, h);
    final maskG = edScalarMult(maskScalar, ed25519G);
    final c = edPointAdd(amountH, maskG);
    return edPointToBytes(c);
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

  static EdPoint _computeH() {
    final gBytes = edPointToBytes(ed25519G);
    return KeyImage.hashToPoint(gBytes);
  }
}
