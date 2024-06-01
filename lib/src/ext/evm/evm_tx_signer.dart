import 'dart:typed_data';

import '../../crypto/ecdsa_sig.dart';
import '../../crypto/secret_key.dart';
import 'evm_tx.dart';

class EnvelopeSigner {
  EnvelopeSigner._();

  static Envelope sign(Envelope envelope, SecretKey key) {
    final hash = envelope.signingHash();
    final sig = RecoverableEcdsaSig.sign(hash, key.bytes);

    final r = _padTo32(sig.bytes.sublist(0, 32));
    final s = _padTo32(sig.bytes.sublist(32, 64));
    final recId = sig.recId;

    int v;
    switch (envelope.kind) {
      case EnvelopeKind.legacy:
        // EIP-155: v = chainId * 2 + 35 + recId
        v = (envelope.chainId * BigInt.two + BigInt.from(35) + BigInt.from(recId)).toInt();
        break;
      case EnvelopeKind.eip2930:
      case EnvelopeKind.eip1559:
      case EnvelopeKind.eip4844:
      case EnvelopeKind.eip7702:
        // Typed transactions use yParity directly (0 or 1).
        v = recId;
        break;
    }

    return envelope.withSignature(v: v, r: r, s: s);
  }

  static Uint8List _padTo32(Uint8List bytes) {
    if (bytes.length == 32) return bytes;
    if (bytes.length > 32) return bytes.sublist(bytes.length - 32);
    final out = Uint8List(32);
    out.setRange(32 - bytes.length, 32, bytes);
    return out;
  }
}
