import 'dart:typed_data';

import '../../tx/outpoint.dart';
import '../chains/chain_params.dart';
import 'spendable.dart';

class WatchUtxo {
  final Outpoint outpoint;
  final BigInt value;
  final Uint8List scriptPubKey;
  final int? blockHeight;
  bool spent;

  WatchUtxo({
    required this.outpoint,
    required this.value,
    required this.scriptPubKey,
    this.blockHeight,
    this.spent = false,
  });

  bool get isConfirmed => blockHeight != null;
}

/// Tracks UTXOs without private keys -- for balance monitoring
/// or building transactions before offline signing.
class WatchOnlyTracker {
  final ChainParams chainParams;
  final Map<String, WatchUtxo> _utxos = {};

  WatchOnlyTracker({required this.chainParams});

  void add(WatchUtxo utxo) {
    final key = _outpointKey(utxo.outpoint);
    _utxos[key] = utxo;
  }

  void markSpent(Outpoint outpoint) {
    final key = _outpointKey(outpoint);
    _utxos[key]?.spent = true;
  }

  void remove(Outpoint outpoint) {
    _utxos.remove(_outpointKey(outpoint));
  }

  List<WatchUtxo> get unspent =>
      _utxos.values.where((u) => !u.spent).toList();

  List<WatchUtxo> get confirmedUnspent =>
      unspent.where((u) => u.isConfirmed).toList();

  BigInt get balance =>
      unspent.fold(BigInt.zero, (sum, u) => sum + u.value);

  BigInt get confirmedBalance =>
      confirmedUnspent.fold(BigInt.zero, (sum, u) => sum + u.value);

  int get totalCount => _utxos.length;
  int get unspentCount => unspent.length;

  /// Converts to [SpendableUtxo] list (without owner key info).
  List<SpendableUtxo> toSpendable() {
    return unspent
        .map((u) => SpendableUtxo(
              outpoint: u.outpoint,
              value: u.value,
              scriptPubKey: u.scriptPubKey,
              blockHeight: u.blockHeight,
              chainParams: chainParams,
            ))
        .toList();
  }

  String _outpointKey(Outpoint op) => '${op.txidHex}:${op.vout}';
}
