import 'dart:typed_data';

import '../../evm/evm_addr.dart';
import '../../evm/evm_tx.dart';
import '../../key_agent/key_agent.dart';
import 'chain_reader.dart';

/// Signing and state-mutating chain interactions.
class ChainWriter {
  final Future<dynamic> Function(String method, List<dynamic>? params) _rpc;
  final ChainReader reader;
  final KeyAgent signer;

  ChainWriter({
    required Future<dynamic> Function(String method, List<dynamic>? params) rpc,
    required this.reader,
    required this.signer,
  }) : _rpc = rpc;

  /// Returns the transaction hash.
  Future<String> sendRawTransaction(Uint8List signedTx) {
    throw UnimplementedError(
        'ChainWriter.sendRawTransaction not yet implemented');
  }

  /// Auto-populates nonce, gas, and chain ID if not specified.
  Future<String> sendTransaction(Envelope envelope) {
    throw UnimplementedError(
        'ChainWriter.sendTransaction not yet implemented');
  }

  Future<Uint8List> signTransaction(Envelope envelope) {
    throw UnimplementedError(
        'ChainWriter.signTransaction not yet implemented');
  }

  /// EIP-191 personal_sign.
  Future<Uint8List> signMessage(Uint8List message) {
    throw UnimplementedError('ChainWriter.signMessage not yet implemented');
  }

  /// EIP-712 typed data signing.
  Future<Uint8List> signTypedData(Map<String, dynamic> typedData) {
    throw UnimplementedError(
        'ChainWriter.signTypedData not yet implemented');
  }

  Future<Map<String, dynamic>> waitForTransaction(
    String txHash, {
    int confirmations = 1,
    Duration timeout = const Duration(minutes: 5),
  }) {
    throw UnimplementedError(
        'ChainWriter.waitForTransaction not yet implemented');
  }

  Future<EvmAddr> getAddress() {
    throw UnimplementedError('ChainWriter.getAddress not yet implemented');
  }
}
