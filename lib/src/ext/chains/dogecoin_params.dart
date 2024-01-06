import '../../chain/chain.dart';
import 'chain_params.dart';

extension DogecoinParams on ChainParams {
  static final dogecoin = ChainParams(
    chain: const Chain(
      wifPrefix: 0x9e,
      p2pkhPrefix: 0x1e,
      p2shPrefix: 0x16,
      bech32Hrp: null,
      name: 'Dogecoin',
      bip44CoinType: 3,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Dogecoin',
    ticker: 'DOGE',
    identifier: 'dogecoin',
    bip44CoinType: 3,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
    ],
    supportsSegwit: false,
    supportsTaproot: false,
  );

  static final dogecoinTestnet = ChainParams(
    chain: const Chain(
      wifPrefix: 0xf1,
      p2pkhPrefix: 0x71,
      p2shPrefix: 0xc4,
      bech32Hrp: null,
      name: 'Dogecoin Testnet',
      bip44CoinType: 1,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Dogecoin Testnet',
    ticker: 'tDOGE',
    identifier: 'dogecoin-testnet',
    bip44CoinType: 1,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
    ],
    supportsSegwit: false,
    supportsTaproot: false,
  );
}
