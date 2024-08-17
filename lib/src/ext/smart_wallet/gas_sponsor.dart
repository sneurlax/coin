import 'dart:typed_data';

import 'user_intent.dart';

/// ERC-4337 paymaster -- sponsors gas so users can transact without ETH.
abstract class GasSponsor {
  String get paymasterAddress;
  Future<bool> willSponsor(UserIntent userOp);

  /// paymasterAndData field: paymaster address + approval signature +
  /// validity timestamps.
  Future<Uint8List> getPaymasterData(UserIntent userOp);

  /// Returns a new UserIntent with paymasterAndData populated.
  Future<UserIntent> sponsor(UserIntent userOp);
}

/// Verifying paymaster that checks a signature from a trusted off-chain signer.
class VerifyingGasSponsor implements GasSponsor {
  @override
  final String paymasterAddress;

  final String signerServiceUrl;

  VerifyingGasSponsor({
    required this.paymasterAddress,
    required this.signerServiceUrl,
  });

  @override
  Future<bool> willSponsor(UserIntent userOp) {
    throw UnimplementedError(
        'VerifyingGasSponsor.willSponsor not yet implemented');
  }

  @override
  Future<Uint8List> getPaymasterData(UserIntent userOp) {
    throw UnimplementedError(
        'VerifyingGasSponsor.getPaymasterData not yet implemented');
  }

  @override
  Future<UserIntent> sponsor(UserIntent userOp) {
    throw UnimplementedError(
        'VerifyingGasSponsor.sponsor not yet implemented');
  }
}

/// ERC-20 paymaster -- lets users pay gas in tokens instead of ETH.
class TokenGasSponsor implements GasSponsor {
  @override
  final String paymasterAddress;

  final String tokenAddress;

  TokenGasSponsor({
    required this.paymasterAddress,
    required this.tokenAddress,
  });

  @override
  Future<bool> willSponsor(UserIntent userOp) {
    throw UnimplementedError(
        'TokenGasSponsor.willSponsor not yet implemented');
  }

  @override
  Future<Uint8List> getPaymasterData(UserIntent userOp) {
    throw UnimplementedError(
        'TokenGasSponsor.getPaymasterData not yet implemented');
  }

  @override
  Future<UserIntent> sponsor(UserIntent userOp) {
    throw UnimplementedError(
        'TokenGasSponsor.sponsor not yet implemented');
  }
}
