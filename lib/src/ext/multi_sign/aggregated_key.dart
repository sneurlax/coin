import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../crypto/public_key.dart';
import '../../crypto/soft/ec_math.dart';
import '../../hash/tagged.dart';

/// BIP-327 MuSig2 key aggregation: combines n public keys into one for
/// n-of-n Schnorr multi-signing.
class AggregatedKey {
  final List<PublicKey> publicKeys;
  final PublicKey aggregatedKey;
  final Uint8List? _secondKey;
  final Uint8List _keyAggList;

  AggregatedKey._({
    required this.publicKeys,
    required this.aggregatedKey,
    required Uint8List? secondKey,
    required Uint8List keyAggList,
  })  : _secondKey = secondKey,
        _keyAggList = keyAggList;

  /// Keys are sorted lexicographically before aggregation.
  factory AggregatedKey.fromKeys(List<PublicKey> keys) {
    if (keys.isEmpty) {
      throw ArgumentError('At least one public key is required');
    }

    final sorted = List<PublicKey>.from(keys);
    sorted.sort((a, b) => compareBytes(a.bytes, b.bytes));

    // L = H("KeyAgg list", pk1 || pk2 || ... || pkn)
    final allKeyBytes = <int>[];
    for (final key in sorted) {
      allKeyBytes.addAll(key.bytes);
    }
    final keyAggList = taggedHash(
      'KeyAgg list',
      Uint8List.fromList(allKeyBytes),
    );

    // Second unique key for the coefficient optimization (none if all identical).
    Uint8List? secondKey;
    for (int i = 1; i < sorted.length; i++) {
      if (!bytesEqual(sorted[i].bytes, sorted[0].bytes)) {
        secondKey = sorted[i].bytes;
        break;
      }
    }

    // Q = sum(a_i * P_i)
    EcPoint aggPoint = EcPoint.infinity();
    for (final key in sorted) {
      final coeff = _computeCoefficient(keyAggList, key.bytes, secondKey);
      final point = ecBytesToPoint(key.bytes);
      final tweaked = ecScalarMult(coeff, point);
      aggPoint = ecPointAdd(aggPoint, tweaked);
    }

    if (aggPoint.isInfinity) {
      throw StateError('Aggregated key is the point at infinity');
    }

    final aggKeyBytes = ecPointToBytes(aggPoint, compressed: true);

    return AggregatedKey._(
      publicKeys: sorted,
      aggregatedKey: PublicKey(aggKeyBytes),
      secondKey: secondKey,
      keyAggList: keyAggList,
    );
  }

  /// 32-byte x-only aggregated key for taproot.
  Uint8List get xOnly => aggregatedKey.xOnly;

  bool get yIsEven => aggregatedKey.yIsEven;

  Uint8List coefficient(PublicKey key) {
    final coeff = _computeCoefficient(_keyAggList, key.bytes, _secondKey);
    return bigIntToBytes(coeff, 32);
  }

  /// BIP-327 KeyAgg coefficient: 1 if this is the second key (optimization),
  /// otherwise a_i = H("KeyAgg coefficient", L || pk_i) mod n.
  static BigInt _computeCoefficient(
    Uint8List keyAggList,
    Uint8List compressedKey,
    Uint8List? secondKey,
  ) {
    if (secondKey != null && bytesEqual(compressedKey, secondKey)) {
      return BigInt.one;
    }

    final data = concatBytes([keyAggList, compressedKey]);
    final hash = taggedHash('KeyAgg coefficient', data);
    return bytesToBigInt(hash) % secp256k1N;
  }
}
