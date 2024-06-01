class EvmChain {
  final int chainId;
  final String name;
  final String symbol;
  final List<String> rpcUrls;
  final List<String> explorerUrls;

  /// Almost always 18.
  final int decimals;

  const EvmChain({
    required this.chainId,
    required this.name,
    required this.symbol,
    required this.rpcUrls,
    this.explorerUrls = const [],
    this.decimals = 18,
  });

  @override
  bool operator ==(Object other) =>
      other is EvmChain && chainId == other.chainId;

  @override
  int get hashCode => chainId.hashCode;

  @override
  String toString() => '$name ($chainId)';
}
