import 'dart:typed_data';

import '../evm/evm_addr.dart';
import 'user_intent.dart';

/// ERC-4337 smart contract account that builds and signs UserOperations.
abstract class DelegatedAccount {
  EvmAddr get address;
  EvmAddr get ownerAddress;

  Future<bool> isDeployed();
  Future<BigInt> getNonce();

  /// InitCode for first-time deployment via the EntryPoint.
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
    throw UnimplementedError(
        'SimpleDelegatedAccount.isDeployed not yet implemented');
  }

  @override
  Future<BigInt> getNonce() {
    throw UnimplementedError(
        'SimpleDelegatedAccount.getNonce not yet implemented');
  }

  @override
  Uint8List buildInitCode() {
    throw UnimplementedError(
        'SimpleDelegatedAccount.buildInitCode not yet implemented');
  }

  @override
  Uint8List encodeExecute(EvmAddr target, BigInt value, Uint8List data) {
    throw UnimplementedError(
        'SimpleDelegatedAccount.encodeExecute not yet implemented');
  }

  @override
  Uint8List encodeBatchExecute(
    List<EvmAddr> targets,
    List<BigInt> values,
    List<Uint8List> datas,
  ) {
    throw UnimplementedError(
        'SimpleDelegatedAccount.encodeBatchExecute not yet implemented');
  }

  @override
  Future<UserIntent> buildUserIntent({
    required EvmAddr target,
    required BigInt value,
    required Uint8List data,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
  }) {
    throw UnimplementedError(
        'SimpleDelegatedAccount.buildUserIntent not yet implemented');
  }

  @override
  Future<Uint8List> signUserOpHash(Uint8List hash) {
    throw UnimplementedError(
        'SimpleDelegatedAccount.signUserOpHash not yet implemented');
  }
}
