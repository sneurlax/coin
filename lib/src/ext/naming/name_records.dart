import 'dart:typed_data';

import '../../core/hex.dart';
import '../abi/sol_codec.dart';
import '../abi/sol_types/bytes_type.dart';
import '../abi/sol_types/string_type.dart';
import 'name_resolver.dart';

/// ENS text records and contenthash resolution.
class NameRecords {
  final String name;

  NameRecords(this.name);

  Uint8List get node => NameResolver.namehash(name);

  Future<String?> getText(String key) {
    // Needs live RPC transport to call resolver.text(node, key)
    throw UnimplementedError(
        'NameRecords.getText: needs live RPC transport. '
        'Calldata: 0x${hexEncode(encodeTextCall(node, key))}');
  }

  Future<void> setText(String key, String value) {
    // Needs live RPC transport to send a transaction calling resolver.setText
    throw UnimplementedError(
        'NameRecords.setText: needs live RPC transport. '
        'Calldata: 0x${hexEncode(encodeSetTextCall(node, key, value))}');
  }

  Future<Uint8List?> getContentHash() {
    // Needs live RPC transport to call resolver.contenthash(node)
    throw UnimplementedError(
        'NameRecords.getContentHash: needs live RPC transport. '
        'Calldata: 0x${hexEncode(NameResolver.encodeContenthashCall(node))}');
  }

  Future<void> setContentHash(Uint8List hash) {
    // Needs live RPC transport
    throw UnimplementedError(
        'NameRecords.setContentHash: needs live RPC transport. '
        'Calldata: 0x${hexEncode(encodeSetContenthashCall(node, hash))}');
  }

  Future<Uint8List?> getAbi() {
    // Needs live RPC transport to call resolver.ABI(node, contentType)
    throw UnimplementedError(
        'NameRecords.getAbi: needs live RPC transport. '
        'Calldata: 0x${hexEncode(encodeAbiCall(node))}');
  }

  Future<List<String>> getTextKeys() {
    // ENS does not natively support enumerating text keys on-chain.
    throw UnimplementedError(
        'NameRecords.getTextKeys: needs off-chain indexer. '
        'ENS does not support on-chain enumeration of text record keys.');
  }

  static Uint8List encodeTextCall(Uint8List node, String key) {
    return SolCodec.encodeCall(
      'text(bytes32,string)',
      [SolFixedBytes(32), SolString()],
      [node, key],
    );
  }

  static Uint8List encodeSetTextCall(
      Uint8List node, String key, String value) {
    return SolCodec.encodeCall(
      'setText(bytes32,string,string)',
      [SolFixedBytes(32), SolString(), SolString()],
      [node, key, value],
    );
  }

  static Uint8List encodeSetContenthashCall(Uint8List node, Uint8List hash) {
    return SolCodec.encodeCall(
      'setContenthash(bytes32,bytes)',
      [SolFixedBytes(32), SolBytes()],
      [node, hash],
    );
  }

  static Uint8List encodeAbiCall(Uint8List node) {
    return SolCodec.encodeCall(
      'ABI(bytes32,uint256)',
      [SolFixedBytes(32), SolFixedBytes(32)],
      [
        node,
        // Content type bitmask: 1 = JSON, 2 = zlib, 4 = CBOR, 8 = URI
        Uint8List(32)..[31] = 0xff,
      ],
    );
  }

  static String? decodeContentHash(Uint8List data) {
    if (data.isEmpty) return null;
    // IPFS: starts with 0xe3010170 (CIDv1 dag-pb)
    // or 0xe5010172 (CIDv1 libp2p-key for IPNS)
    if (data.length >= 2 && data[0] == 0xe3 && data[1] == 0x01) {
      return 'ipfs://${hexEncode(data.sublist(2))}';
    }
    if (data.length >= 2 && data[0] == 0xe5 && data[1] == 0x01) {
      return 'ipns://${hexEncode(data.sublist(2))}';
    }
    // Swarm: starts with 0xe4
    if (data.isNotEmpty && data[0] == 0xe4) {
      return 'bzz://${hexEncode(data.sublist(1))}';
    }
    return '0x${hexEncode(data)}';
  }
}
