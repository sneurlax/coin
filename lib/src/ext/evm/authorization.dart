import 'dart:typed_data';

/// EIP-7702 authorization tuple.
/// Authorizes a contract's code to execute on behalf of an EOA.
class Authorization {
  /// 0 = valid on any chain.
  final BigInt chainId;

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

  Uint8List signingHash() {
    throw UnimplementedError('Authorization.signingHash not yet implemented');
  }

  Authorization sign(Uint8List privateKey) {
    throw UnimplementedError('Authorization.sign not yet implemented');
  }

  List<dynamic> toRlpList() {
    throw UnimplementedError('Authorization.toRlpList not yet implemented');
  }
}
