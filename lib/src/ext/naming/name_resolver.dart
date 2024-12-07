import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../core/hex.dart';
import '../../hash/digest.dart';
import '../abi/sol_codec.dart';
import '../abi/sol_types/bytes_type.dart';
import '../evm/evm_addr.dart';

/// ENS name resolution and reverse lookup.
class NameResolver {
  final EvmAddr registryAddress;

  NameResolver({EvmAddr? registryAddress})
      : registryAddress = registryAddress ??
            EvmAddr.fromHex('0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e');

  Future<EvmAddr?> resolve(String name) {
    // Needs live RPC transport to call resolver(namehash).addr(namehash)
    throw UnimplementedError(
        'NameResolver.resolve: needs live RPC transport. '
        'Call registry.resolver(${hexEncode(namehash(name))}) then resolver.addr(node)');
  }

  Future<String?> reverseLookup(EvmAddr address) {
    final reverseName =
        '${address.toHex()}.addr.reverse';
    // Needs live RPC transport
    throw UnimplementedError(
        'NameResolver.reverseLookup: needs live RPC transport. '
        'Reverse name: $reverseName, node: ${hexEncode(namehash(reverseName))}');
  }

  Future<Uint8List?> resolveContentHash(String name) {
    // Needs live RPC transport to call resolver.contenthash(namehash)
    throw UnimplementedError(
        'NameResolver.resolveContentHash: needs live RPC transport');
  }

  Future<EvmAddr?> resolverFor(String name) {
    // Needs live RPC transport to call registry.resolver(namehash)
    throw UnimplementedError(
        'NameResolver.resolverFor: needs live RPC transport. '
        'Call registry(${hexEncode(registryAddress.bytes)}).resolver(${hexEncode(namehash(name))})');
  }

  // Recursively hash labels right-to-left: keccak256(parent || keccak256(label))
  static Uint8List namehash(String name) {
    var node = Uint8List(32);
    if (name.isEmpty) return node;

    final labels = name.split('.');
    for (var i = labels.length - 1; i >= 0; i--) {
      final labelHash =
          keccak256(Uint8List.fromList(labels[i].codeUnits));
      node = keccak256(concatBytes([node, labelHash]));
    }
    return node;
  }

  static Uint8List encodeResolverCall(Uint8List node) {
    // resolver(bytes32) selector: 0x0178b8bf
    return SolCodec.encodeCall(
      'resolver(bytes32)',
      [SolFixedBytes(32)],
      [node],
    );
  }

  static Uint8List encodeAddrCall(Uint8List node) {
    // addr(bytes32) selector: 0x3b3b57de
    return SolCodec.encodeCall(
      'addr(bytes32)',
      [SolFixedBytes(32)],
      [node],
    );
  }

  static Uint8List encodeContenthashCall(Uint8List node) {
    // contenthash(bytes32) selector: 0xbc1c58d1
    return SolCodec.encodeCall(
      'contenthash(bytes32)',
      [SolFixedBytes(32)],
      [node],
    );
  }

  static Uint8List encodeNameCall(Uint8List node) {
    return SolCodec.encodeCall(
      'name(bytes32)',
      [SolFixedBytes(32)],
      [node],
    );
  }
}
