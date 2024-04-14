import 'dart:typed_data';

import 'utxo_models.dart';

/// Common UTXO query interface backed by Electrum or a block explorer.
abstract class UtxoMethods {
  Future<List<UtxoRef>> getUtxos(String address);
  Future<BalanceInfo> getBalance(String address);
  Future<TxInfo> getTransaction(String txid);
  Future<Uint8List> getRawTransaction(String txid);

  /// Broadcasts a signed tx; returns the txid.
  Future<String> broadcastTransaction(Uint8List rawTx);

  Future<int> getBlockHeight();

  /// Fee rate in sat/vbyte for confirmation within [targetBlocks].
  Future<int> estimateFeeRate({int targetBlocks = 6});

  Future<List<TxInfo>> getHistory(String address);
}
