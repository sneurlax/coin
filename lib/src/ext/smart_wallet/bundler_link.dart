import 'dart:convert';

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

  Map<String, dynamic> _formatRequest(
      String method, List<dynamic> params, int id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };
  }

  List<dynamic> _userOpParams(UserIntent userOp) {
    return [userOp.toJson(), entryPointAddress];
  }

  // eth_sendUserOperation - returns UserOp hash
  Future<String> sendUserOperation(UserIntent userOp) {
    // Needs live RPC transport
    throw UnimplementedError(
      'BundlerLink.sendUserOperation: needs live RPC transport. '
      'Request body: ${jsonEncode(_formatRequest('eth_sendUserOperation', _userOpParams(userOp), 1))}',
    );
  }

  // eth_estimateUserOperationGas
  Future<Map<String, BigInt>> estimateUserOperationGas(UserIntent userOp) {
    // Needs live RPC transport
    throw UnimplementedError(
      'BundlerLink.estimateUserOperationGas: needs live RPC transport. '
      'Request body: ${jsonEncode(_formatRequest('eth_estimateUserOperationGas', _userOpParams(userOp), 1))}',
    );
  }

  Future<Map<String, dynamic>?> getUserOperationByHash(String hash) {
    // Needs live RPC transport
    throw UnimplementedError(
      'BundlerLink.getUserOperationByHash: needs live RPC transport. '
      'Request body: ${jsonEncode(_formatRequest('eth_getUserOperationByHash', [hash], 1))}',
    );
  }

  Future<Map<String, dynamic>?> getUserOperationReceipt(String hash) {
    // Needs live RPC transport
    throw UnimplementedError(
      'BundlerLink.getUserOperationReceipt: needs live RPC transport. '
      'Request body: ${jsonEncode(_formatRequest('eth_getUserOperationReceipt', [hash], 1))}',
    );
  }

  Future<List<String>> supportedEntryPoints() {
    // Needs live RPC transport
    throw UnimplementedError(
      'BundlerLink.supportedEntryPoints: needs live RPC transport. '
      'Request body: ${jsonEncode(_formatRequest('eth_supportedEntryPoints', [], 1))}',
    );
  }

  Future<BigInt> chainId() {
    // Needs live RPC transport
    throw UnimplementedError(
      'BundlerLink.chainId: needs live RPC transport. '
      'Request body: ${jsonEncode(_formatRequest('eth_chainId', [], 1))}',
    );
  }

  Map<String, dynamic> formatSendRequest(UserIntent userOp, {int id = 1}) {
    return _formatRequest('eth_sendUserOperation', _userOpParams(userOp), id);
  }

  Map<String, dynamic> formatEstimateRequest(UserIntent userOp,
      {int id = 1}) {
    return _formatRequest(
        'eth_estimateUserOperationGas', _userOpParams(userOp), id);
  }
}
