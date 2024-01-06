import '../../chain/chain.dart';
import 'chain_params.dart';

extension BitcoinSvParams on ChainParams {
  static final bitcoinSv = ChainParams(
    chain: const Chain(
      wifPrefix: 0x80,
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      bech32Hrp: null,
      name: 'Bitcoin SV',
      bip44CoinType: 236,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Bitcoin SV',
    ticker: 'BSV',
    identifier: 'bitcoin-sv',
    bip44CoinType: 236,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
    ],
    supportsSegwit: false,
    supportsTaproot: false,
    usesForkId: true,
  );

  static final bitcoinSvTestnet = ChainParams(
    chain: const Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0xc4,
      bech32Hrp: null,
      name: 'Bitcoin SV Testnet',
      bip44CoinType: 1,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Bitcoin SV Testnet',
    ticker: 'tBSV',
    identifier: 'bitcoin-sv-testnet',
    bip44CoinType: 1,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
    ],
    supportsSegwit: false,
    supportsTaproot: false,
    usesForkId: true,
  );
}
