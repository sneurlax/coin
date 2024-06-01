import 'evm_chain.dart';

class EvmChains {
  EvmChains._();

  static const ethereum = EvmChain(
    chainId: 1,
    name: 'Ethereum',
    symbol: 'ETH',
    rpcUrls: ['https://eth.llamarpc.com', 'https://rpc.ankr.com/eth'],
    explorerUrls: ['https://etherscan.io'],
  );

  static const sepolia = EvmChain(
    chainId: 11155111,
    name: 'Sepolia',
    symbol: 'ETH',
    rpcUrls: ['https://rpc.sepolia.org', 'https://rpc.ankr.com/eth_sepolia'],
    explorerUrls: ['https://sepolia.etherscan.io'],
  );

  static const polygon = EvmChain(
    chainId: 137,
    name: 'Polygon',
    symbol: 'MATIC',
    rpcUrls: ['https://polygon-rpc.com', 'https://rpc.ankr.com/polygon'],
    explorerUrls: ['https://polygonscan.com'],
  );

  static const bsc = EvmChain(
    chainId: 56,
    name: 'BNB Smart Chain',
    symbol: 'BNB',
    rpcUrls: ['https://bsc-dataseed.binance.org', 'https://rpc.ankr.com/bsc'],
    explorerUrls: ['https://bscscan.com'],
  );

  static const arbitrum = EvmChain(
    chainId: 42161,
    name: 'Arbitrum One',
    symbol: 'ETH',
    rpcUrls: ['https://arb1.arbitrum.io/rpc', 'https://rpc.ankr.com/arbitrum'],
    explorerUrls: ['https://arbiscan.io'],
  );

  static const optimism = EvmChain(
    chainId: 10,
    name: 'Optimism',
    symbol: 'ETH',
    rpcUrls: ['https://mainnet.optimism.io', 'https://rpc.ankr.com/optimism'],
    explorerUrls: ['https://optimistic.etherscan.io'],
  );

  static const base = EvmChain(
    chainId: 8453,
    name: 'Base',
    symbol: 'ETH',
    rpcUrls: ['https://mainnet.base.org', 'https://rpc.ankr.com/base'],
    explorerUrls: ['https://basescan.org'],
  );

  static const avalanche = EvmChain(
    chainId: 43114,
    name: 'Avalanche',
    symbol: 'AVAX',
    rpcUrls: [
      'https://api.avax.network/ext/bc/C/rpc',
      'https://rpc.ankr.com/avalanche',
    ],
    explorerUrls: ['https://snowtrace.io'],
  );

  static const Map<int, EvmChain> all = {
    1: ethereum,
    11155111: sepolia,
    137: polygon,
    56: bsc,
    42161: arbitrum,
    10: optimism,
    8453: base,
    43114: avalanche,
  };

  static EvmChain? byId(int chainId) => all[chainId];
}
