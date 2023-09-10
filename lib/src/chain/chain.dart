class Chain {
  final int wifPrefix;
  final int p2pkhPrefix;
  final int p2shPrefix;
  final String? bech32Hrp;
  final String name;
  final int bip44CoinType;
  final bool supportsSegwit;
  final bool supportsTaproot;

  const Chain({
    required this.wifPrefix,
    required this.p2pkhPrefix,
    required this.p2shPrefix,
    this.bech32Hrp,
    required this.name,
    required this.bip44CoinType,
    this.supportsSegwit = true,
    this.supportsTaproot = true,
  });

  /// Peercoin -- the "original" coin supported by this package.
  static const peercoin = Chain(
    wifPrefix: 0xb7,
    p2pkhPrefix: 0x37,
    p2shPrefix: 0x75,
    bech32Hrp: 'pc',
    name: 'Peercoin',
    bip44CoinType: 6,
    supportsSegwit: true,
    supportsTaproot: true,
  );

  static const peercoinTestnet = Chain(
    wifPrefix: 0xef,
    p2pkhPrefix: 0x6f,
    p2shPrefix: 0xc4,
    bech32Hrp: 'tpc',
    name: 'Peercoin Testnet',
    bip44CoinType: 1,
    supportsSegwit: true,
    supportsTaproot: true,
  );
}
