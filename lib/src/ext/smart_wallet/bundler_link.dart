import 'dart:typed_data';

import 'user_intent.dart';

/// ERC-4337 bundler JSON-RPC client.
///
/// Submits UserOperations to a bundler, which batches them into a single
/// on-chain transaction via the EntryPoint contract.
class BundlerLink {
  final String rpcUrl;
  final String entryPointAddress;

  BundlerLink({
    required this.rpcUrl,
    this.entryPointAddress = '0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789',
  });

  /// `eth_sendUserOperation` -- returns the UserOperation hash.
  Future<String> sendUserOperation(UserIntent userOp) {
    throw UnimplementedError(
        'BundlerLink.sendUserOperation not yet implemented');
  }

  /// `eth_estimateUserOperationGas` -- returns callGasLimit,
  /// verificationGasLimit, and preVerificationGas.
  Future<Map<String, BigInt>> estimateUserOperationGas(UserIntent userOp) {
    throw UnimplementedError(
        'BundlerLink.estimateUserOperationGas not yet implemented');
  }

  Future<Map<String, dynamic>?> getUserOperationByHash(String hash) {
    throw UnimplementedError(
        'BundlerLink.getUserOperationByHash not yet implemented');
  }

  Future<Map<String, dynamic>?> getUserOperationReceipt(String hash) {
    throw UnimplementedError(
        'BundlerLink.getUserOperationReceipt not yet implemented');
  }

  Future<List<String>> supportedEntryPoints() {
    throw UnimplementedError(
        'BundlerLink.supportedEntryPoints not yet implemented');
  }

  Future<BigInt> chainId() {
    throw UnimplementedError('BundlerLink.chainId not yet implemented');
  }
}
