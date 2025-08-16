import '../../chain/chain.dart';
import 'chain_params.dart';

extension ParticlParams on ChainParams {
  static final particl = ChainParams(
    chain: const Chain(
      wifPrefix: 0x6c,
      p2pkhPrefix: 0x38,
      p2shPrefix: 0x3c,
      bech32Hrp: 'pw',
      name: 'Particl',
      bip44CoinType: 44,
      supportsSegwit: true,
      supportsTaproot: false,
    ),
    chainName: 'Particl',
    ticker: 'PART',
    identifier: 'particl',
    bip44CoinType: 44,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
      AddrType.p2wpkh,
      AddrType.p2wsh,
    ],
    supportsSegwit: true,
    supportsTaproot: false,
  );

  static final particlTestnet = ChainParams(
    chain: const Chain(
      wifPrefix: 0x2e,
      p2pkhPrefix: 0x76,
      p2shPrefix: 0x7a,
      bech32Hrp: 'tpw',
      name: 'Particl Testnet',
      bip44CoinType: 1,
      supportsSegwit: true,
      supportsTaproot: false,
    ),
    chainName: 'Particl Testnet',
    ticker: 'tPART',
    identifier: 'particl-testnet',
    bip44CoinType: 1,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
      AddrType.p2wpkh,
      AddrType.p2wsh,
    ],
    supportsSegwit: true,
    supportsTaproot: false,
  );
}
