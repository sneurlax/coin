import 'package:coin/src/crypto/vault_keeper.dart';
import 'package:coin/src/ext/chains/chain_params.dart';
import 'package:coin/src/ext/chains/particl_params.dart';
import 'package:coin/src/ext/chains/registry.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  // Chain parameters sourced from particl-core chainparams.cpp:
  // https://github.com/particl/particl-core/blob/master/src/kernel/chainparams.cpp
  group('ParticlParams', () {
    test('particl mainnet has correct values', () {
      final p = ParticlParams.particl;
      expect(p.wifPrefix, 0x6c);
      expect(p.p2pkhPrefix, 0x38);
      expect(p.p2shPrefix, 0x3c);
      expect(p.bech32Hrp, 'pw');
      expect(p.chainName, 'Particl');
      expect(p.ticker, 'PART');
      expect(p.identifier, 'particl');
      expect(p.bip44CoinType, 44);
      expect(p.supportsSegwit, isTrue);
      expect(p.supportsTaproot, isFalse);
      expect(p.supportedAddrTypes, [
        AddrType.p2pkh,
        AddrType.p2sh,
        AddrType.p2wpkh,
        AddrType.p2wsh,
      ]);
    });

    test('particl testnet has correct values', () {
      final p = ParticlParams.particlTestnet;
      expect(p.wifPrefix, 0x2e);
      expect(p.p2pkhPrefix, 0x76);
      expect(p.p2shPrefix, 0x7a);
      expect(p.bech32Hrp, 'tpw');
      expect(p.chainName, 'Particl Testnet');
      expect(p.ticker, 'tPART');
      expect(p.identifier, 'particl-testnet');
      expect(p.bip44CoinType, 1);
      expect(p.supportsSegwit, isTrue);
      expect(p.supportsTaproot, isFalse);
      expect(p.supportedAddrTypes, [
        AddrType.p2pkh,
        AddrType.p2sh,
        AddrType.p2wpkh,
        AddrType.p2wsh,
      ]);
    });

    test('ChainRegistry.byTicker returns particl params', () {
      final p = ChainRegistry.byTicker('PART');
      expect(p, isNotNull);
      expect(p!.identifier, 'particl');
      expect(p.chainName, 'Particl');
    });

    test('ChainRegistry.byIdentifier returns particl params', () {
      final p = ChainRegistry.byIdentifier('particl');
      expect(p, isNotNull);
      expect(p!.ticker, 'PART');
      expect(p.chainName, 'Particl');
    });
  });
}
