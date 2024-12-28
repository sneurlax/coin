import 'dart:typed_data';

import '../../../core/hex.dart';
import '../../evm/evm_addr.dart';
import '../../evm/evm_tx.dart';
import '../../key_agent/key_agent.dart';
import 'chain_reader.dart';

class ChainWriter {
  final Future<dynamic> Function(String method, List<dynamic>? params) _rpc;
  final ChainReader reader;
  final KeyAgent signer;

  ChainWriter({
    required Future<dynamic> Function(String method, List<dynamic>? params) rpc,
    required this.reader,
    required this.signer,
  }) : _rpc = rpc;

  Future<String> sendRawTransaction(Uint8List signedTx) async {
    final hex = '0x${hexEncode(signedTx)}';
    final result = await _rpc('eth_sendRawTransaction', [hex]) as String;
    return result;
  }

  Future<String> sendTransaction(Envelope envelope) async {
    final signed = await signTransaction(envelope);
    return sendRawTransaction(signed);
  }

  Future<Uint8List> signTransaction(Envelope envelope) async {
    var env = envelope;
    final address = await signer.getAddress();

    if (env.nonce == BigInt.zero) {
      final nonce = await reader.getTransactionCount(address);
      env = Envelope(
        kind: env.kind,
        to: env.to,
        value: env.value,
        data: env.data,
        gasLimit: env.gasLimit,
        nonce: nonce,
        chainId: env.chainId,
        gasPrice: env.gasPrice,
        maxFeePerGas: env.maxFeePerGas,
        maxPriorityFeePerGas: env.maxPriorityFeePerGas,
        maxFeePerBlobGas: env.maxFeePerBlobGas,
        blobVersionedHashes: env.blobVersionedHashes,
        blobs: env.blobs,
        accessList: env.accessList,
        authorizationList: env.authorizationList,
      );
    }

    if (env.chainId == BigInt.one) {
      final chainId = await reader.getChainId();
      env = Envelope(
        kind: env.kind,
        to: env.to,
        value: env.value,
        data: env.data,
        gasLimit: env.gasLimit,
        nonce: env.nonce,
        chainId: chainId,
        gasPrice: env.gasPrice,
        maxFeePerGas: env.maxFeePerGas,
        maxPriorityFeePerGas: env.maxPriorityFeePerGas,
        maxFeePerBlobGas: env.maxFeePerBlobGas,
        blobVersionedHashes: env.blobVersionedHashes,
        blobs: env.blobs,
        accessList: env.accessList,
        authorizationList: env.authorizationList,
      );
    }

    if (env.gasLimit == BigInt.from(21000) && env.data.isNotEmpty) {
      final toHex = env.to != null ? '0x${hexEncode(env.to!)}' : null;
      final estimate = await reader.estimateGas({
        'from': address.toString(),
        if (toHex != null) 'to': toHex,
        'value': '0x${env.value.toRadixString(16)}',
        'data': '0x${hexEncode(env.data)}',
      });
      env = Envelope(
        kind: env.kind,
        to: env.to,
        value: env.value,
        data: env.data,
        gasLimit: estimate,
        nonce: env.nonce,
        chainId: env.chainId,
        gasPrice: env.gasPrice,
        maxFeePerGas: env.maxFeePerGas,
        maxPriorityFeePerGas: env.maxPriorityFeePerGas,
        maxFeePerBlobGas: env.maxFeePerBlobGas,
        blobVersionedHashes: env.blobVersionedHashes,
        blobs: env.blobs,
        accessList: env.accessList,
        authorizationList: env.authorizationList,
      );
    }

    return signer.signTransaction(env);
  }

  Future<Uint8List> signMessage(Uint8List message) {
    return signer.signMessage(message);
  }

  Future<Uint8List> signTypedData(Map<String, dynamic> typedData) {
    return signer.signTypedData(typedData);
  }

  Future<Map<String, dynamic>> waitForTransaction(
    String txHash, {
    int confirmations = 1,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final receipt = await reader.getTransactionReceipt(txHash);
      if (receipt != null) {
        if (confirmations <= 1) return receipt;
        final receiptBlock = receipt['blockNumber'] as String?;
        if (receiptBlock != null) {
          final receiptNum =
              BigInt.parse(receiptBlock.substring(2), radix: 16);
          final currentBlock = await reader.getBlockNumber();
          if (currentBlock - receiptNum + BigInt.one >=
              BigInt.from(confirmations)) {
            return receipt;
          }
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw TimeoutException(
      'Transaction $txHash not confirmed within $timeout',
    );
  }

  Future<EvmAddr> getAddress() {
    return signer.getAddress();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}
