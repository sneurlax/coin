import '../../chain/chain.dart';
import 'chain_params.dart';

extension BitcoinCashParams on ChainParams {
  static final bitcoinCash = ChainParams(
    chain: const Chain(
      wifPrefix: 0x80,
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      bech32Hrp: null,
      name: 'Bitcoin Cash',
      bip44CoinType: 145,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Bitcoin Cash',
    ticker: 'BCH',
    identifier: 'bitcoin-cash',
    bip44CoinType: 145,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
    ],
    supportsSegwit: false,
    supportsTaproot: false,
    usesForkId: true,
  );

  static final bitcoinCashTestnet = ChainParams(
    chain: const Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0xc4,
      bech32Hrp: null,
      name: 'Bitcoin Cash Testnet',
      bip44CoinType: 1,
      supportsSegwit: false,
      supportsTaproot: false,
    ),
    chainName: 'Bitcoin Cash Testnet',
    ticker: 'tBCH',
    identifier: 'bitcoin-cash-testnet',
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
