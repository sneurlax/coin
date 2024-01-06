import '../../chain/chain.dart';
import 'chain_params.dart';

extension DashParams on ChainParams {
  static final dash = ChainParams(
    chain: const Chain(
      wifPrefix: 0xcc,
      p2pkhPrefix: 0x4c,
      p2shPrefix: 0x10,
      bech32Hrp: null,
      name: 'Dash',
      bip44CoinType: 5,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Dash',
    ticker: 'DASH',
    identifier: 'dash',
    bip44CoinType: 5,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
    ],
    supportsSegwit: false,
    supportsTaproot: false,
  );

  static final dashTestnet = ChainParams(
    chain: const Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x8c,
      p2shPrefix: 0x13,
      bech32Hrp: null,
      name: 'Dash Testnet',
      bip44CoinType: 1,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Dash Testnet',
    ticker: 'tDASH',
    identifier: 'dash-testnet',
    bip44CoinType: 1,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
    ],
    supportsSegwit: false,
    supportsTaproot: false,
  );
}
