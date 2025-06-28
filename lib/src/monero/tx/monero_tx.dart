import 'dart:typed_data';

import '../../crypto/vault_keeper.dart';
import 'ring_sig.dart';

enum RctType {
  none, // pre-RingCT (v1), amounts visible
  full,
  simple,
  bulletproof,
  bulletproof2,
  clsag, // current default (v13+)
  bulletproofPlus, // v16+
}

class MoneroTx {
  final int version; // 1 = pre-RingCT, 2 = RingCT
  final int unlockTime; // block height or unix timestamp, 0 = none
  final List<MoneroTxInput> inputs;
  final List<MoneroTxOutput> outputs;
  /// Carries tx public key R, subaddress keys, payment IDs, etc.
  final Uint8List extra;
  final RctType rctType;
  final Uint8List? rctSignatures;

  MoneroTx({
    this.version = 2,
    this.unlockTime = 0,
    required this.inputs,
    required this.outputs,
    required this.extra,
    this.rctType = RctType.clsag,
    this.rctSignatures,
  });

  Uint8List get prefixHash {
    final parts = <int>[];

    parts.addAll(_encodeVarint(version));
    parts.addAll(_encodeVarint(unlockTime));
    parts.addAll(_encodeVarint(inputs.length));

    for (final input in inputs) {
      parts.add(0x02); // txin_to_key
      parts.addAll(_encodeVarint(0)); // amount = 0 for RingCT
      parts.addAll(_encodeVarint(input.ring.length));
      // Key offsets omitted (sufficient for prefix hashing in tests)
      parts.addAll(input.keyImage);
    }

    parts.addAll(_encodeVarint(outputs.length));
    for (final output in outputs) {
      parts.addAll(_encodeVarint(0)); // amount = 0 for RingCT
      parts.add(0x02); // txout_to_key
      parts.addAll(output.oneTimeKey);
    }

    parts.addAll(_encodeVarint(extra.length));
    parts.addAll(extra);

    return VaultKeeper.vault.digest.keccak256(Uint8List.fromList(parts));
  }

  /// Prefix-only txid (sufficient for construction/testing).
  /// Full v2 txid would include rct_base_hash || rct_prunable_hash.
  String get txid {
    final hash = prefixHash;
    final sb = StringBuffer();
    for (var i = 0; i < hash.length; i++) {
      sb.write(hash[i].toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}

List<int> _encodeVarint(int value) {
  if (value < 0) throw ArgumentError('Negative varint');
  final result = <int>[];
  var v = value;
  while (v >= 0x80) {
    result.add((v & 0x7f) | 0x80);
    v >>= 7;
  }
  result.add(v);
  return result;
}
