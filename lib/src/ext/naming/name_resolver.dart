import 'dart:typed_data';

import '../evm/evm_addr.dart';

/// ENS name resolution and reverse lookup.
class NameResolver {
  final EvmAddr registryAddress;

  NameResolver({EvmAddr? registryAddress})
      : registryAddress = registryAddress ??
            EvmAddr.fromHex('0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e');

  Future<EvmAddr?> resolve(String name) {
    throw UnimplementedError('NameResolver.resolve not yet implemented');
  }

  Future<String?> reverseLookup(EvmAddr address) {
    throw UnimplementedError('NameResolver.reverseLookup not yet implemented');
  }

  Future<Uint8List?> resolveContentHash(String name) {
    throw UnimplementedError(
        'NameResolver.resolveContentHash not yet implemented');
  }

  Future<EvmAddr?> resolverFor(String name) {
    throw UnimplementedError('NameResolver.resolverFor not yet implemented');
  }

  /// ENS namehash: recursively hashes labels from right to left.
  ///   namehash("") = 0x00...00
  ///   namehash("eth") = keccak256(namehash("") + keccak256("eth"))
  static Uint8List namehash(String name) {
    throw UnimplementedError('NameResolver.namehash not yet implemented');
  }
}
