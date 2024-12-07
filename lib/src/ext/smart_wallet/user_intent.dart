import 'dart:typed_data';

import '../../core/hex.dart';
import '../../hash/digest.dart';
import '../abi/sol_codec.dart';
import '../abi/sol_types/address_type.dart';
import '../abi/sol_types/bytes_type.dart';
import '../abi/sol_types/uint_type.dart';
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

  // keccak256(abi.encode(packed, entryPoint, chainId))
  Uint8List hash({required EvmAddr entryPoint, required BigInt chainId}) {
    final packed = pack();
    final packedHash = keccak256(packed);
    final encoded = SolCodec.encodeParameters(
      [SolFixedBytes(32), SolAddress(), SolUint(256)],
      [packedHash, entryPoint.bytes, chainId],
    );
    return keccak256(encoded);
  }

  Uint8List pack() {
    final initCodeHash = keccak256(initCode);
    final callDataHash = keccak256(callData);
    final paymasterAndDataHash = keccak256(paymasterAndData);
    return SolCodec.encodeParameters(
      [
        SolAddress(),
        SolUint(256),
        SolFixedBytes(32),
        SolFixedBytes(32),
        SolUint(256),
        SolUint(256),
        SolUint(256),
        SolUint(256),
        SolUint(256),
        SolFixedBytes(32),
      ],
      [
        sender.bytes,
        nonce,
        initCodeHash,
        callDataHash,
        callGasLimit,
        verificationGasLimit,
        preVerificationGas,
        maxFeePerGas,
        maxPriorityFeePerGas,
        paymasterAndDataHash,
      ],
    );
  }

  Map<String, String> toJson() {
    return {
      'sender': '0x${sender.toHex()}',
      'nonce': '0x${nonce.toRadixString(16)}',
      'initCode': '0x${hexEncode(initCode)}',
      'callData': '0x${hexEncode(callData)}',
      'callGasLimit': '0x${callGasLimit.toRadixString(16)}',
      'verificationGasLimit': '0x${verificationGasLimit.toRadixString(16)}',
      'preVerificationGas': '0x${preVerificationGas.toRadixString(16)}',
      'maxFeePerGas': '0x${maxFeePerGas.toRadixString(16)}',
      'maxPriorityFeePerGas': '0x${maxPriorityFeePerGas.toRadixString(16)}',
      'paymasterAndData': '0x${hexEncode(paymasterAndData)}',
      'signature': '0x${hexEncode(signature)}',
    };
  }

  UserIntent withSignature(Uint8List sig) {
    signature = sig;
    return this;
  }
}
