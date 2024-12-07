import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../core/hex.dart';
import 'user_intent.dart';

/// ERC-4337 paymaster -- sponsors gas so users can transact without ETH.
abstract class GasSponsor {
  String get paymasterAddress;
  Future<bool> willSponsor(UserIntent userOp);

  Future<Uint8List> getPaymasterData(UserIntent userOp);

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
    // Needs live RPC transport to query the signer service
    throw UnimplementedError(
        'VerifyingGasSponsor.willSponsor: needs live RPC transport');
  }

  @override
  Future<Uint8List> getPaymasterData(UserIntent userOp) {
    // Needs live RPC transport to get the off-chain signature
    throw UnimplementedError(
        'VerifyingGasSponsor.getPaymasterData: needs live RPC transport');
  }

  @override
  Future<UserIntent> sponsor(UserIntent userOp) async {
    final pmData = await getPaymasterData(userOp);
    userOp.paymasterAndData = pmData;
    return userOp;
  }

  Uint8List buildPaymasterAndData({
    required BigInt validUntil,
    required BigInt validAfter,
    required Uint8List signature,
  }) {
    final addressBytes = hexDecode(paymasterAddress);
    final timestamps = Uint8List(12);
    _writeBigInt(timestamps, 0, validUntil, 6);
    _writeBigInt(timestamps, 6, validAfter, 6);
    return concatBytes([addressBytes, timestamps, signature]);
  }

  static void _writeBigInt(Uint8List out, int offset, BigInt value, int len) {
    var v = value;
    for (var i = len - 1; i >= 0; i--) {
      out[offset + i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
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
    // Needs live RPC transport to check token allowance and balance
    throw UnimplementedError(
        'TokenGasSponsor.willSponsor: needs live RPC transport');
  }

  @override
  Future<Uint8List> getPaymasterData(UserIntent userOp) {
    // Needs live RPC transport to get token exchange rate and build approval
    throw UnimplementedError(
        'TokenGasSponsor.getPaymasterData: needs live RPC transport');
  }

  @override
  Future<UserIntent> sponsor(UserIntent userOp) async {
    final pmData = await getPaymasterData(userOp);
    userOp.paymasterAndData = pmData;
    return userOp;
  }

  Uint8List buildPaymasterAndData() {
    final pmBytes = hexDecode(paymasterAddress);
    final tokenBytes = hexDecode(tokenAddress);
    return concatBytes([pmBytes, tokenBytes]);
  }

  BigInt estimateTokenCost(UserIntent userOp, BigInt exchangeRate) {
    final totalGas =
        userOp.callGasLimit +
        userOp.verificationGasLimit +
        userOp.preVerificationGas;
    return totalGas * userOp.maxFeePerGas * exchangeRate ~/ BigInt.from(10).pow(18);
  }
}
