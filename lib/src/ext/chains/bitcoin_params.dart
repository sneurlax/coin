import '../../chain/chain.dart';
import 'chain_params.dart';

extension BitcoinParams on ChainParams {
  static final bitcoin = ChainParams(
    chain: const Chain(
      wifPrefix: 0x80,
      p2pkhPrefix: 0x00,
      p2shPrefix: 0x05,
      bech32Hrp: 'bc',
      name: 'Bitcoin',
      bip44CoinType: 0,
      supportsSegwit: true,
      supportsTaproot: true,
    ),
    chainName: 'Bitcoin',
    ticker: 'BTC',
    identifier: 'bitcoin',
    bip44CoinType: 0,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
      AddrType.p2wpkh,
      AddrType.p2wsh,
      AddrType.p2tr,
    ],
    supportsSegwit: true,
    supportsTaproot: true,
  );

  static final bitcoinTestnet = ChainParams(
    chain: const Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0xc4,
      bech32Hrp: 'tb',
      name: 'Bitcoin Testnet',
      bip44CoinType: 1,
      supportsSegwit: true,
      supportsTaproot: true,
    ),
    chainName: 'Bitcoin Testnet',
    ticker: 'tBTC',
    identifier: 'bitcoin-testnet',
    bip44CoinType: 1,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
      AddrType.p2wpkh,
      AddrType.p2wsh,
      AddrType.p2tr,
    ],
    supportsSegwit: true,
    supportsTaproot: true,
  );

  /// Same network bytes as testnet, different identity.
  static final bitcoinSignet = ChainParams(
    chain: const Chain(
      wifPrefix: 0xef,
      p2pkhPrefix: 0x6f,
      p2shPrefix: 0xc4,
      bech32Hrp: 'tb',
      name: 'Bitcoin Signet',
      bip44CoinType: 1,
      supportsSegwit: true,
      supportsTaproot: true,
    ),
    chainName: 'Bitcoin Signet',
    ticker: 'sBTC',
    identifier: 'bitcoin-signet',
    bip44CoinType: 1,
    supportedAddrTypes: [
      AddrType.p2pkh,
      AddrType.p2sh,
      AddrType.p2wpkh,
      AddrType.p2wsh,
      AddrType.p2tr,
    ],
    supportsSegwit: true,
    supportsTaproot: true,
  );
}
