import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../core/hex.dart';
import '../abi/sol_codec.dart';
import '../abi/sol_types/address_type.dart';
import '../abi/sol_types/bytes_type.dart';
import '../abi/sol_types/uint_type.dart';
import '../abi/sol_types/array_type.dart';
import '../evm/evm_addr.dart';
import 'user_intent.dart';

/// ERC-4337 smart contract account that builds and signs UserOperations.
abstract class DelegatedAccount {
  EvmAddr get address;
  EvmAddr get ownerAddress;

  Future<bool> isDeployed();
  Future<BigInt> getNonce();

  Uint8List buildInitCode();

  Uint8List encodeExecute(EvmAddr target, BigInt value, Uint8List data);

  Uint8List encodeBatchExecute(
    List<EvmAddr> targets,
    List<BigInt> values,
    List<Uint8List> datas,
  );

  Future<UserIntent> buildUserIntent({
    required EvmAddr target,
    required BigInt value,
    required Uint8List data,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
  });

  Future<Uint8List> signUserOpHash(Uint8List hash);
}

/// Simple EOA-owned smart account reference implementation.
class SimpleDelegatedAccount implements DelegatedAccount {
  @override
  final EvmAddr address;

  @override
  final EvmAddr ownerAddress;

  final EvmAddr factoryAddress;

  SimpleDelegatedAccount({
    required this.address,
    required this.ownerAddress,
    required this.factoryAddress,
  });

  @override
  Future<bool> isDeployed() {
    // Needs live RPC transport
    throw UnimplementedError(
        'SimpleDelegatedAccount.isDeployed: needs live RPC transport');
  }

  @override
  Future<BigInt> getNonce() {
    // Needs live RPC transport
    throw UnimplementedError(
        'SimpleDelegatedAccount.getNonce: needs live RPC transport');
  }

  @override
  Uint8List buildInitCode() {
    // createAccount(address,uint256) selector: 0x5fbfb9cf
    final selector = hexDecode('5fbfb9cf');
    final encoded = SolCodec.encodeParameters(
      [SolAddress(), SolUint(256)],
      [ownerAddress.bytes, BigInt.zero],
    );
    return concatBytes([factoryAddress.bytes, selector, encoded]);
  }

  @override
  Uint8List encodeExecute(EvmAddr target, BigInt value, Uint8List data) {
    // execute(address,uint256,bytes) selector: 0xb61d27f6
    return SolCodec.encodeCall(
      'execute(address,uint256,bytes)',
      [SolAddress(), SolUint(256), SolBytes()],
      [target.bytes, value, data],
    );
  }

  @override
  Uint8List encodeBatchExecute(
    List<EvmAddr> targets,
    List<BigInt> values,
    List<Uint8List> datas,
  ) {
    if (targets.length != values.length || values.length != datas.length) {
      throw ArgumentError('targets, values, and datas must have equal length');
    }
    // executeBatch(address[],uint256[],bytes[]) selector: 0x18dfb3c7
    return SolCodec.encodeCall(
      'executeBatch(address[],uint256[],bytes[])',
      [SolArray(SolAddress()), SolArray(SolUint(256)), SolArray(SolBytes())],
      [
        targets.map((t) => t.bytes).toList(),
        values,
        datas,
      ],
    );
  }

  @override
  Future<UserIntent> buildUserIntent({
    required EvmAddr target,
    required BigInt value,
    required Uint8List data,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
  }) async {
    final callData = encodeExecute(target, value, data);

    BigInt nonce;
    Uint8List initCode;
    try {
      nonce = await getNonce();
      initCode = Uint8List(0);
    } on UnimplementedError {
      nonce = BigInt.zero;
      initCode = buildInitCode();
    }

    bool deployed;
    try {
      deployed = await isDeployed();
    } on UnimplementedError {
      deployed = false;
    }

    return UserIntent(
      sender: address,
      nonce: nonce,
      initCode: deployed ? Uint8List(0) : initCode,
      callData: callData,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    );
  }

  @override
  Future<Uint8List> signUserOpHash(Uint8List hash) {
    // Needs access to private key signing
    throw UnimplementedError(
        'SimpleDelegatedAccount.signUserOpHash: needs signer integration');
  }
}
