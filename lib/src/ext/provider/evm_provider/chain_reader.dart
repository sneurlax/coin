import 'dart:typed_data';

import '../../../core/hex.dart';
import '../../evm/evm_addr.dart';

class ChainReader {
  final Future<dynamic> Function(String method, List<dynamic>? params) _rpc;

  ChainReader(this._rpc);

  Future<BigInt> getChainId() async {
    final result = await _rpc('eth_chainId', []) as String;
    return BigInt.parse(result.substring(2), radix: 16);
  }

  Future<BigInt> getBlockNumber() async {
    final result = await _rpc('eth_blockNumber', []) as String;
    return BigInt.parse(result.substring(2), radix: 16);
  }

  /// Balance in wei.
  Future<BigInt> getBalance(EvmAddr address, {String block = 'latest'}) async {
    final result =
        await _rpc('eth_getBalance', [address.toString(), block]) as String;
    return BigInt.parse(result.substring(2), radix: 16);
  }

  Future<BigInt> getTransactionCount(EvmAddr address,
      {String block = 'latest'}) async {
    final result = await _rpc(
        'eth_getTransactionCount', [address.toString(), block]) as String;
    return BigInt.parse(result.substring(2), radix: 16);
  }

  Future<Uint8List> getCode(EvmAddr address, {String block = 'latest'}) async {
    final result =
        await _rpc('eth_getCode', [address.toString(), block]) as String;
    if (result == '0x') return Uint8List(0);
    return hexDecode(result);
  }

  Future<Uint8List> getStorageAt(EvmAddr address, BigInt slot,
      {String block = 'latest'}) async {
    final slotHex = '0x${slot.toRadixString(16)}';
    final result = await _rpc(
        'eth_getStorageAt', [address.toString(), slotHex, block]) as String;
    return hexDecode(result);
  }

  Future<Uint8List> call(Map<String, dynamic> callParams,
      {String block = 'latest'}) async {
    final result = await _rpc('eth_call', [callParams, block]) as String;
    if (result == '0x') return Uint8List(0);
    return hexDecode(result);
  }

  Future<BigInt> estimateGas(Map<String, dynamic> txParams) async {
    final result = await _rpc('eth_estimateGas', [txParams]) as String;
    return BigInt.parse(result.substring(2), radix: 16);
  }

  Future<BigInt> getGasPrice() async {
    final result = await _rpc('eth_gasPrice', []) as String;
    return BigInt.parse(result.substring(2), radix: 16);
  }

  Future<BigInt> getMaxPriorityFeePerGas() async {
    final result = await _rpc('eth_maxPriorityFeePerGas', []) as String;
    return BigInt.parse(result.substring(2), radix: 16);
  }

  Future<Map<String, dynamic>> getFeeHistory(
      int blockCount, String newestBlock, List<double> rewardPercentiles) async {
    final result = await _rpc('eth_feeHistory',
        ['0x${blockCount.toRadixString(16)}', newestBlock, rewardPercentiles]);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> getBlockByNumber(String blockTag,
      {bool fullTransactions = false}) async {
    final result =
        await _rpc('eth_getBlockByNumber', [blockTag, fullTransactions]);
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> getBlockByHash(String blockHash,
      {bool fullTransactions = false}) async {
    final result =
        await _rpc('eth_getBlockByHash', [blockHash, fullTransactions]);
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> getTransactionByHash(String txHash) async {
    final result = await _rpc('eth_getTransactionByHash', [txHash]);
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> getTransactionReceipt(String txHash) async {
    final result = await _rpc('eth_getTransactionReceipt', [txHash]);
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> getLogs(
      Map<String, dynamic> filter) async {
    final result = await _rpc('eth_getLogs', [filter]);
    return (result as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
