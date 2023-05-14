import 'dart:convert';
import 'dart:typed_data';

import '../core/bytes.dart';
import '../hash/digest.dart';
import 'vault_keeper.dart';

class MessageSig {
  final Uint8List signature;
  final int recId;
  final bool compressed;

  MessageSig({
    required this.signature,
    required this.recId,
    required this.compressed,
  });

  factory MessageSig.sign(String message, Uint8List privKey,
      {bool compressed = true}) {
    final hash = _messageHash(message);
    final (sig, rec) =
        VaultKeeper.vault.curve.ecdsaSignRecoverable(hash, privKey);
    return MessageSig(
        signature: sig, recId: rec, compressed: compressed);
  }

  Uint8List recoverPublicKey(String message) {
    final hash = _messageHash(message);
    return VaultKeeper.vault.curve.ecdsaRecover(
        signature, recId, hash, compressed: compressed);
  }

  bool verify(String message, Uint8List pubKey) {
    final hash = _messageHash(message);
    return VaultKeeper.vault.curve.ecdsaVerify(signature, hash, pubKey);
  }

  Uint8List toBytes() {
    final out = Uint8List(65);
    final header = 27 + recId + (compressed ? 4 : 0);
    out[0] = header;
    out.setRange(1, 65, signature);
    return out;
  }

  factory MessageSig.fromBytes(Uint8List bytes) {
    if (bytes.length != 65) throw ArgumentError('Expected 65 bytes');
    final header = bytes[0];
    final comp = header >= 31;
    final rec = (header - 27) & 3;
    return MessageSig(
      signature: bytes.sublist(1, 65),
      recId: rec,
      compressed: comp,
    );
  }

  static Uint8List _messageHash(String message) {
    final prefix = utf8.encode('\x18Bitcoin Signed Message:\n');
    final msgBytes = utf8.encode(message);
    final lenBytes = _encodeVarInt(msgBytes.length);
    final payload = concatBytes([
      Uint8List.fromList(prefix),
      Uint8List.fromList(lenBytes),
      Uint8List.fromList(msgBytes),
    ]);
    return sha256d(payload);
  }

  static List<int> _encodeVarInt(int n) {
    if (n < 0xfd) return [n];
    if (n <= 0xffff) return [0xfd, n & 0xff, (n >> 8) & 0xff];
    return [0xfe, n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >> 24) & 0xff];
  }
}
