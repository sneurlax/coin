import 'dart:typed_data';

import '../../evm/evm_addr.dart';

/// Wraps common `eth_*` JSON-RPC read calls.
class ChainReader {
  final Future<dynamic> Function(String method, List<dynamic>? params) _rpc;

  ChainReader(this._rpc);

  Future<BigInt> getChainId() {
    throw UnimplementedError('ChainReader.getChainId not yet implemented');
  }

  Future<BigInt> getBlockNumber() {
    throw UnimplementedError('ChainReader.getBlockNumber not yet implemented');
  }

  /// Balance in wei.
  Future<BigInt> getBalance(EvmAddr address, {String block = 'latest'}) {
    throw UnimplementedError('ChainReader.getBalance not yet implemented');
  }

  /// Nonce for an address (`eth_getTransactionCount`).
  Future<BigInt> getTransactionCount(EvmAddr address,
      {String block = 'latest'}) {
    throw UnimplementedError(
        'ChainReader.getTransactionCount not yet implemented');
  }

  /// Contract code; empty for EOAs.
  Future<Uint8List> getCode(EvmAddr address, {String block = 'latest'}) {
    throw UnimplementedError('ChainReader.getCode not yet implemented');
  }

  Future<Uint8List> getStorageAt(EvmAddr address, BigInt slot,
      {String block = 'latest'}) {
    throw UnimplementedError('ChainReader.getStorageAt not yet implemented');
  }

  /// `eth_call` -- executes a read-only message call.
  Future<Uint8List> call(Map<String, dynamic> callParams,
      {String block = 'latest'}) {
    throw UnimplementedError('ChainReader.call not yet implemented');
  }

  Future<BigInt> estimateGas(Map<String, dynamic> txParams) {
    throw UnimplementedError('ChainReader.estimateGas not yet implemented');
  }

  /// Legacy gas price (`eth_gasPrice`).
  Future<BigInt> getGasPrice() {
    throw UnimplementedError('ChainReader.getGasPrice not yet implemented');
  }

  /// EIP-1559 priority fee (`eth_maxPriorityFeePerGas`).
  Future<BigInt> getMaxPriorityFeePerGas() {
    throw UnimplementedError(
        'ChainReader.getMaxPriorityFeePerGas not yet implemented');
  }

  Future<Map<String, dynamic>> getFeeHistory(
      int blockCount, String newestBlock, List<double> rewardPercentiles) {
    throw UnimplementedError('ChainReader.getFeeHistory not yet implemented');
  }

  Future<Map<String, dynamic>?> getBlockByNumber(String blockTag,
      {bool fullTransactions = false}) {
    throw UnimplementedError(
        'ChainReader.getBlockByNumber not yet implemented');
  }

  Future<Map<String, dynamic>?> getBlockByHash(String blockHash,
      {bool fullTransactions = false}) {
    throw UnimplementedError(
        'ChainReader.getBlockByHash not yet implemented');
  }

  Future<Map<String, dynamic>?> getTransactionByHash(String txHash) {
    throw UnimplementedError(
        'ChainReader.getTransactionByHash not yet implemented');
  }

  Future<Map<String, dynamic>?> getTransactionReceipt(String txHash) {
    throw UnimplementedError(
        'ChainReader.getTransactionReceipt not yet implemented');
  }

  Future<List<Map<String, dynamic>>> getLogs(Map<String, dynamic> filter) {
    throw UnimplementedError('ChainReader.getLogs not yet implemented');
  }
}
