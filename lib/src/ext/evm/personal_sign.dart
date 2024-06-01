import 'dart:convert';
import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../hash/digest.dart';
import '../../crypto/ecdsa_sig.dart';
import '../../crypto/secret_key.dart';

/// EIP-191 personal message signing.
/// Prefixes with "\x19Ethereum Signed Message:\n<length>" before keccak256.
class PersonalSign {
  PersonalSign._();

  static Uint8List messageHash(Uint8List message) {
    final prefix = utf8.encode('\x19Ethereum Signed Message:\n${message.length}');
    return keccak256(concatBytes([
      Uint8List.fromList(prefix),
      message,
    ]));
  }

  static Uint8List messageHashString(String message) {
    return messageHash(Uint8List.fromList(utf8.encode(message)));
  }

  /// Returns 65 bytes: r (32) + s (32) + v (1, where v = recId + 27).
  static Uint8List sign(Uint8List message, SecretKey key) {
    final hash = messageHash(message);
    final sig = RecoverableEcdsaSig.sign(hash, key.bytes);
    final out = Uint8List(65);
    out.setRange(0, 64, sig.bytes);
    out[64] = sig.recId + 27;
    return out;
  }

  static Uint8List signString(String message, SecretKey key) {
    return sign(Uint8List.fromList(utf8.encode(message)), key);
  }

  static Uint8List recoverPublicKey(Uint8List message, Uint8List signature65) {
    if (signature65.length != 65) {
      throw ArgumentError('Signature must be 65 bytes');
    }
    final hash = messageHash(message);
    final sigBytes = signature65.sublist(0, 64);
    final v = signature65[64];
    final recId = v >= 27 ? v - 27 : v;
    final recSig = RecoverableEcdsaSig(sigBytes, recId);
    return recSig.recover(hash, compressed: false);
  }
}
