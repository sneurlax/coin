import 'dart:typed_data';

import 'utxo_methods.dart';
import 'utxo_models.dart';

/// Electrum protocol client (TCP/SSL or WebSocket).
///
/// Implements [UtxoMethods] via Electrum's JSON-RPC interface, which
/// addresses UTXOs by scripthash rather than raw address string.
class ElectrumLink implements UtxoMethods {
  final String host;
  final int port;
  final bool useSsl;
  final int timeoutMs;

  ElectrumLink({
    required this.host,
    required this.port,
    this.useSsl = true,
    this.timeoutMs = 10000,
  });

  Future<void> connect() {
    throw UnimplementedError('ElectrumLink.connect');
  }

  Future<void> disconnect() {
    throw UnimplementedError('ElectrumLink.disconnect');
  }

  bool get isConnected => false;

  /// `blockchain.scripthash.subscribe` -- pushes status changes for an address.
  Future<void> subscribeAddress(
    String address,
    void Function(String status) onStatus,
  ) {
    throw UnimplementedError('ElectrumLink.subscribeAddress');
  }

  /// `server.version` -- negotiates the Electrum protocol version.
  Future<List<String>> serverVersion({
    String clientName = 'coin-dart',
    String protocolMin = '1.4',
    String protocolMax = '1.4.2',
  }) {
    throw UnimplementedError('ElectrumLink.serverVersion');
  }

  // -- UtxoMethods --

  @override
  Future<List<UtxoRef>> getUtxos(String address) {
    throw UnimplementedError('ElectrumLink.getUtxos');
  }

  @override
  Future<BalanceInfo> getBalance(String address) {
    throw UnimplementedError('ElectrumLink.getBalance');
  }

  @override
  Future<TxInfo> getTransaction(String txid) {
    throw UnimplementedError('ElectrumLink.getTransaction');
  }

  @override
  Future<Uint8List> getRawTransaction(String txid) {
    throw UnimplementedError('ElectrumLink.getRawTransaction');
  }

  @override
  Future<String> broadcastTransaction(Uint8List rawTx) {
    throw UnimplementedError('ElectrumLink.broadcastTransaction');
  }

  @override
  Future<int> getBlockHeight() {
    throw UnimplementedError('ElectrumLink.getBlockHeight');
  }

  @override
  Future<int> estimateFeeRate({int targetBlocks = 6}) {
    throw UnimplementedError('ElectrumLink.estimateFeeRate');
  }

  @override
  Future<List<TxInfo>> getHistory(String address) {
    throw UnimplementedError('ElectrumLink.getHistory');
  }
}
