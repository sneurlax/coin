import 'dart:typed_data';

/// ENSIP-9 multi-coin address resolution.
///
/// Resolves ENS names to addresses on any chain via SLIP-44 coin types.
class MultichainNames {
  final String name;

  MultichainNames(this.name);

  /// Resolve by SLIP-44 coin type (0 = BTC, 60 = ETH, 501 = SOL, etc.).
  Future<Uint8List?> getAddress(int coinType) {
    throw UnimplementedError('MultichainNames.getAddress not yet implemented');
  }

  Future<void> setAddress(int coinType, Uint8List address) {
    throw UnimplementedError('MultichainNames.setAddress not yet implemented');
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
}
