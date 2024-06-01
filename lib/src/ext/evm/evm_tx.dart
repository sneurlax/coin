import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../core/hex.dart';
import '../../encode/rlp.dart';
import '../../hash/digest.dart';
import 'access_list.dart';
import 'blob.dart';
import 'authorization.dart';

enum EnvelopeKind {
  legacy,
  eip2930,
  eip1559,
  eip4844,
  eip7702,
}

class Envelope {
  final EnvelopeKind kind;

  /// Null for contract creation.
  final Uint8List? to;

  final BigInt value;
  final Uint8List data;
  final BigInt gasLimit;
  final BigInt nonce;
  final BigInt chainId;

  // Legacy / EIP-2930
  final BigInt? gasPrice;

  // EIP-1559+
  final BigInt? maxFeePerGas;
  final BigInt? maxPriorityFeePerGas;

  // EIP-4844
  final BigInt? maxFeePerBlobGas;
  final List<Uint8List>? blobVersionedHashes;

  /// Sidecar blobs -- not included in the signing hash.
  final List<BlobData>? blobs;

  // EIP-2930+
  final List<AccessListEntry>? accessList;

  // EIP-7702
  final List<Authorization>? authorizationList;

  // Signature (populated after signing)
  final int? v;
  final Uint8List? r;
  final Uint8List? s;

  Envelope({
    required this.kind,
    this.to,
    BigInt? value,
    Uint8List? data,
    BigInt? gasLimit,
    BigInt? nonce,
    BigInt? chainId,
    this.gasPrice,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    this.maxFeePerBlobGas,
    this.blobVersionedHashes,
    this.blobs,
    this.accessList,
    this.authorizationList,
    this.v,
    this.r,
    this.s,
  })  : value = value ?? BigInt.zero,
        data = data ?? Uint8List(0),
        gasLimit = gasLimit ?? BigInt.from(21000),
        nonce = nonce ?? BigInt.zero,
        chainId = chainId ?? BigInt.one;

  Envelope withSignature({required int v, required Uint8List r, required Uint8List s}) {
    return Envelope(
      kind: kind,
      to: to,
      value: value,
      data: data,
      gasLimit: gasLimit,
      nonce: nonce,
      chainId: chainId,
      gasPrice: gasPrice,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      maxFeePerBlobGas: maxFeePerBlobGas,
      blobVersionedHashes: blobVersionedHashes,
      blobs: blobs,
      accessList: accessList,
      authorizationList: authorizationList,
      v: v,
      r: r,
      s: s,
    );
  }

  Uint8List _unsignedPayload() {
    switch (kind) {
      case EnvelopeKind.legacy:
        return _legacyUnsigned();
      case EnvelopeKind.eip2930:
        return _typedUnsigned(0x01, _eip2930Fields());
      case EnvelopeKind.eip1559:
        return _typedUnsigned(0x02, _eip1559Fields());
      case EnvelopeKind.eip4844:
        return _typedUnsigned(0x03, _eip4844Fields());
      case EnvelopeKind.eip7702:
        return _typedUnsigned(0x04, _eip7702Fields());
    }
  }

  Uint8List _legacyUnsigned() {
    // EIP-155: include chainId, 0, 0 for replay protection.
    return Rlp.encode([
      nonce,
      gasPrice ?? BigInt.zero,
      gasLimit,
      to ?? Uint8List(0),
      value,
      data,
      chainId,
      BigInt.zero,
      BigInt.zero,
    ]);
  }

  List<dynamic> _accessListRlp() {
    return (accessList ?? []).map((e) => e.toRlpList()).toList();
  }

  List<dynamic> _eip2930Fields() {
    return [
      chainId,
      nonce,
      gasPrice ?? BigInt.zero,
      gasLimit,
      to ?? Uint8List(0),
      value,
      data,
      _accessListRlp(),
    ];
  }

  List<dynamic> _eip1559Fields() {
    return [
      chainId,
      nonce,
      maxPriorityFeePerGas ?? BigInt.zero,
      maxFeePerGas ?? BigInt.zero,
      gasLimit,
      to ?? Uint8List(0),
      value,
      data,
      _accessListRlp(),
    ];
  }

  List<dynamic> _eip4844Fields() {
    return [
      chainId,
      nonce,
      maxPriorityFeePerGas ?? BigInt.zero,
      maxFeePerGas ?? BigInt.zero,
      gasLimit,
      to ?? Uint8List(0),
      value,
      data,
      _accessListRlp(),
      maxFeePerBlobGas ?? BigInt.zero,
      blobVersionedHashes ?? <Uint8List>[],
    ];
  }

  List<dynamic> _eip7702Fields() {
    return [
      chainId,
      nonce,
      maxPriorityFeePerGas ?? BigInt.zero,
      maxFeePerGas ?? BigInt.zero,
      gasLimit,
      to ?? Uint8List(0),
      value,
      data,
      _accessListRlp(),
      (authorizationList ?? []).map((a) => a.toRlpList()).toList(),
    ];
  }

  Uint8List _typedUnsigned(int typeId, List<dynamic> fields) {
    final rlp = Rlp.encode(fields);
    return concatBytes([Uint8List.fromList([typeId]), rlp]);
  }

  Uint8List signingHash() {
    return keccak256(_unsignedPayload());
  }

  /// Serialize the signed transaction for broadcast.
  /// Legacy: plain RLP. Typed: `typeId || rlp(fields ++ sig)`.
  Uint8List serialize() {
    if (v == null || r == null || s == null) {
      throw StateError('Transaction must be signed before serializing');
    }

    switch (kind) {
      case EnvelopeKind.legacy:
        return _legacySigned();
      case EnvelopeKind.eip2930:
        return _typedSigned(0x01, _eip2930Fields());
      case EnvelopeKind.eip1559:
        return _typedSigned(0x02, _eip1559Fields());
      case EnvelopeKind.eip4844:
        return _typedSigned(0x03, _eip4844Fields());
      case EnvelopeKind.eip7702:
        return _typedSigned(0x04, _eip7702Fields());
    }
  }

  Uint8List _legacySigned() {
    // EIP-155: v = chainId * 2 + 35 + recId
    return Rlp.encode([
      nonce,
      gasPrice ?? BigInt.zero,
      gasLimit,
      to ?? Uint8List(0),
      value,
      data,
      BigInt.from(v!),
      _trimLeadingZeros(r!),
      _trimLeadingZeros(s!),
    ]);
  }

  Uint8List _typedSigned(int typeId, List<dynamic> fields) {
    final sigFields = [
      ...fields,
      BigInt.from(v!),
      _trimLeadingZeros(r!),
      _trimLeadingZeros(s!),
    ];
    final rlp = Rlp.encode(sigFields);
    return concatBytes([Uint8List.fromList([typeId]), rlp]);
  }

  Uint8List hash() => keccak256(serialize());

  String hashHex() => '0x${hexEncode(hash())}';

  static Uint8List _trimLeadingZeros(Uint8List bytes) {
    var start = 0;
    while (start < bytes.length - 1 && bytes[start] == 0) {
      start++;
    }
    if (start == 0) return bytes;
    return bytes.sublist(start);
  }
}
