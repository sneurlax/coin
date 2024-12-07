import 'dart:typed_data';

import '../../core/hex.dart';
import '../abi/sol_codec.dart';
import '../abi/sol_types/bytes_type.dart';
import '../abi/sol_types/uint_type.dart';
import 'name_resolver.dart';

/// ENSIP-9 multi-coin address resolution.
///
/// Resolves ENS names to addresses on any chain via SLIP-44 coin types.
class MultichainNames {
  final String name;

  MultichainNames(this.name);

  Uint8List get node => NameResolver.namehash(name);

  // SLIP-44: 0=BTC, 60=ETH, 501=SOL, etc.
  Future<Uint8List?> getAddress(int coinType) {
    // Needs live RPC transport to call resolver.addr(node, coinType)
    throw UnimplementedError(
        'MultichainNames.getAddress: needs live RPC transport. '
        'Calldata: 0x${hexEncode(encodeMultichainAddrCall(node, coinType))}');
  }

  Future<void> setAddress(int coinType, Uint8List address) {
    // Needs live RPC transport to send a transaction
    throw UnimplementedError(
        'MultichainNames.setAddress: needs live RPC transport. '
        'Calldata: 0x${hexEncode(encodeSetAddrCall(node, coinType, address))}');
  }

  /// ENSIP-11: EVM coin type is `0x80000000 | chainId`.
  Future<Uint8List?> getEvmAddress(int chainId) {
    final coinType = 0x80000000 | chainId;
    return getAddress(coinType);
  }

  Future<void> setEvmAddress(int chainId, Uint8List address) {
    final coinType = 0x80000000 | chainId;
    return setAddress(coinType, address);
  }

  static int? coinTypeToChainId(int coinType) {
    if (coinType & 0x80000000 != 0) {
      return coinType & 0x7fffffff;
    }
    if (coinType == 60) return 1; // Ethereum mainnet.
    return null;
  }

  static const int btc = 0;
  static const int eth = 60;
  static const int ltc = 2;
  static const int doge = 3;
  static const int sol = 501;
  static const int matic = 966;
  static const int atom = 118;
  static const int dot = 354;
  static const int xrp = 144;
  static const int trx = 195;

  static Uint8List encodeMultichainAddrCall(Uint8List node, int coinType) {
    return SolCodec.encodeCall(
      'addr(bytes32,uint256)',
      [SolFixedBytes(32), SolUint(256)],
      [node, BigInt.from(coinType)],
    );
  }

  static Uint8List encodeSetAddrCall(
      Uint8List node, int coinType, Uint8List address) {
    return SolCodec.encodeCall(
      'setAddr(bytes32,uint256,bytes)',
      [SolFixedBytes(32), SolUint(256), SolBytes()],
      [node, BigInt.from(coinType), address],
    );
  }
}
