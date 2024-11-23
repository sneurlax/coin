import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../encode/rlp.dart';
import '../../hash/digest.dart';
import '../../crypto/ecdsa_sig.dart';

/// EIP-7702 authorization tuple.
/// Authorizes a contract's code to execute on behalf of an EOA.
class Authorization {
  final BigInt chainId; // 0 = valid on any chain

  final Uint8List address;
  final BigInt nonce;
  final int? v;
  final Uint8List? r;
  final Uint8List? s;

  Authorization({
    required this.chainId,
    required this.address,
    required this.nonce,
    this.v,
    this.r,
    this.s,
  }) {
    if (address.length != 20) {
      throw ArgumentError('Address must be 20 bytes, got ${address.length}');
    }
  }

  // keccak256(0x05 || RLP([chainId, address, nonce]))
  Uint8List signingHash() {
    final payload = Rlp.encode([chainId, address, nonce]);
    return keccak256(concatBytes([Uint8List.fromList([0x05]), payload]));
  }

  Authorization sign(Uint8List privateKey) {
    final hash = signingHash();
    final sig = RecoverableEcdsaSig.sign(hash, privateKey);

    final sigR = _padTo32(sig.bytes.sublist(0, 32));
    final sigS = _padTo32(sig.bytes.sublist(32, 64));

    return Authorization(
      chainId: chainId,
      address: address,
      nonce: nonce,
      v: sig.recId,
      r: sigR,
      s: sigS,
    );
  }

  List<dynamic> toRlpList() {
    return [
      chainId,
      address,
      nonce,
      v ?? 0,
      _trimLeadingZeros(r ?? Uint8List(0)),
      _trimLeadingZeros(s ?? Uint8List(0)),
    ];
  }

  static Uint8List _padTo32(Uint8List bytes) {
    if (bytes.length == 32) return bytes;
    if (bytes.length > 32) return bytes.sublist(bytes.length - 32);
    final out = Uint8List(32);
    out.setRange(32 - bytes.length, 32, bytes);
    return out;
  }

  static Uint8List _trimLeadingZeros(Uint8List bytes) {
    if (bytes.isEmpty) return bytes;
    var start = 0;
    while (start < bytes.length - 1 && bytes[start] == 0) {
      start++;
    }
    if (start == 0) return bytes;
    return bytes.sublist(start);
  }
}
