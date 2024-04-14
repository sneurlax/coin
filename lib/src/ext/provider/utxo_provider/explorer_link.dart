import 'dart:typed_data';

import 'utxo_methods.dart';
import 'utxo_models.dart';

/// REST/JSON block explorer client (Blockbook, Esplora, etc.).
class ExplorerLink implements UtxoMethods {
  final String baseUrl;
  final String? apiKey;
  final int timeoutMs;

  ExplorerLink({
    required this.baseUrl,
    this.apiKey,
    this.timeoutMs = 15000,
  });

  // -- UtxoMethods --

  @override
  Future<List<UtxoRef>> getUtxos(String address) {
    throw UnimplementedError('ExplorerLink.getUtxos');
  }

  @override
  Future<BalanceInfo> getBalance(String address) {
    throw UnimplementedError('ExplorerLink.getBalance');
  }

  @override
  Future<TxInfo> getTransaction(String txid) {
    throw UnimplementedError('ExplorerLink.getTransaction');
  }

  @override
  Future<Uint8List> getRawTransaction(String txid) {
    throw UnimplementedError('ExplorerLink.getRawTransaction');
  }

  @override
  Future<String> broadcastTransaction(Uint8List rawTx) {
    throw UnimplementedError('ExplorerLink.broadcastTransaction');
  }

  @override
  Future<int> getBlockHeight() {
    throw UnimplementedError('ExplorerLink.getBlockHeight');
  }

  @override
  Future<int> estimateFeeRate({int targetBlocks = 6}) {
    throw UnimplementedError('ExplorerLink.estimateFeeRate');
  }

  @override
  Future<List<TxInfo>> getHistory(String address) {
    throw UnimplementedError('ExplorerLink.getHistory');
  }
}
