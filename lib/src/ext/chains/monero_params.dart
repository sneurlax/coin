import '../../chain/chain.dart';
import 'chain_params.dart';

extension MoneroParams on ChainParams {
  static final monero = ChainParams(
    chain: const Chain(
      wifPrefix: 0x00,
      p2pkhPrefix: 0x12,
      p2shPrefix: 0x2a,
      name: 'Monero',
      bip44CoinType: 128,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Monero',
    ticker: 'XMR',
    identifier: 'monero',
    bip44CoinType: 128,
    supportedAddrTypes: [AddrType.p2pkh],
    supportsSegwit: false,
    supportsTaproot: false,
  );

  static final moneroTestnet = ChainParams(
    chain: const Chain(
      wifPrefix: 0x00,
      p2pkhPrefix: 0x35,
      p2shPrefix: 0x3f,
      name: 'Monero Testnet',
      bip44CoinType: 1,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Monero Testnet',
    ticker: 'tXMR',
    identifier: 'monero-testnet',
    bip44CoinType: 1,
    supportedAddrTypes: [AddrType.p2pkh],
    supportsSegwit: false,
    supportsTaproot: false,
  );

  static final moneroStagenet = ChainParams(
    chain: const Chain(
      wifPrefix: 0x00,
      p2pkhPrefix: 0x18,
      p2shPrefix: 0x24,
      name: 'Monero Stagenet',
      bip44CoinType: 1,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Monero Stagenet',
    ticker: 'sXMR',
    identifier: 'monero-stagenet',
    bip44CoinType: 1,
    supportedAddrTypes: [AddrType.p2pkh],
    supportsSegwit: false,
    supportsTaproot: false,
  );
}
