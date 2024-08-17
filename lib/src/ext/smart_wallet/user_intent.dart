import 'dart:typed_data';

import '../evm/evm_addr.dart';

/// ERC-4337 UserOperation struct.
class UserIntent {
  final EvmAddr sender;
  BigInt nonce;
  Uint8List initCode;
  Uint8List callData;
  BigInt callGasLimit;
  BigInt verificationGasLimit;
  BigInt preVerificationGas;
  BigInt maxFeePerGas;
  BigInt maxPriorityFeePerGas;
  Uint8List paymasterAndData;
  Uint8List signature;

  UserIntent({
    required this.sender,
    BigInt? nonce,
    Uint8List? initCode,
    Uint8List? callData,
    BigInt? callGasLimit,
    BigInt? verificationGasLimit,
    BigInt? preVerificationGas,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
    Uint8List? paymasterAndData,
    Uint8List? signature,
  })  : nonce = nonce ?? BigInt.zero,
        initCode = initCode ?? Uint8List(0),
        callData = callData ?? Uint8List(0),
        callGasLimit = callGasLimit ?? BigInt.from(200000),
        verificationGasLimit = verificationGasLimit ?? BigInt.from(100000),
        preVerificationGas = preVerificationGas ?? BigInt.from(21000),
        maxFeePerGas = maxFeePerGas ?? BigInt.zero,
        maxPriorityFeePerGas = maxPriorityFeePerGas ?? BigInt.zero,
        paymasterAndData = paymasterAndData ?? Uint8List(0),
        signature = signature ?? Uint8List(0);

  /// keccak256(abi.encode(packUserOp, entryPoint, chainId))
  Uint8List hash({required EvmAddr entryPoint, required BigInt chainId}) {
    throw UnimplementedError('UserIntent.hash not yet implemented');
  }

  Uint8List pack() {
    throw UnimplementedError('UserIntent.pack not yet implemented');
  }

  Map<String, String> toJson() {
    throw UnimplementedError('UserIntent.toJson not yet implemented');
  }

  UserIntent withSignature(Uint8List sig) {
    signature = sig;
    return this;
  }
}
