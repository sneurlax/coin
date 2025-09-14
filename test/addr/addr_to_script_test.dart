import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:test/test.dart';

const _bitcoin = Chain(
  wifPrefix: 0x80,
  p2pkhPrefix: 0x00,
  p2shPrefix: 0x05,
  bech32Hrp: 'bc',
  name: 'Bitcoin',
  bip44CoinType: 0,
  supportsSegwit: true,
  supportsTaproot: true,
);

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  // pkHash: HASH160 of private-key-1's compressed pubkey (secp256k1 generator G).
  // p2shHash: encodes to 3J98t1Wp..., same pair as base58_test / script_test.
  final pkHash =
      hexDecode('751e76e8199196d454941c45d1b3a323f1433bd6');
  final p2shHash =
      hexDecode('b472a266d0bd89c13706a4132ccfb16f7c3b9fcb');

  group('P2PKH toLocking()', () {
    test('produces correct scriptPubKey', () {
      final addr = P2pkhAddr(pkHash);
      final spk = addr.toLocking().compiled;

      // OP_DUP OP_HASH160 <20 bytes> OP_EQUALVERIFY OP_CHECKSIG
      expect(spk.length, 25);
      expect(spk[0], Op.dup);
      expect(spk[1], Op.hash160);
      expect(spk[2], 0x14); // push 20 bytes
      expect(spk.sublist(3, 23), equals(pkHash));
      expect(spk[23], Op.equalVerify);
      expect(spk[24], Op.checkSig);
    });

    test('round-trip: parse address string then toScriptPubKey', () {
      final addr = Addr.fromString('1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH', _bitcoin);
      expect(addr, isA<P2pkhAddr>());
      final spk = addr.scriptPubKey;
      expect(spk.length, 25);
      expect(spk.sublist(3, 23), equals(pkHash));
    });
  });

  group('P2SH toLocking()', () {
    test('produces correct scriptPubKey', () {
      final addr = P2shAddr(p2shHash);
      final spk = addr.toLocking().compiled;

      // OP_HASH160 <20 bytes> OP_EQUAL
      expect(spk.length, 23);
      expect(spk[0], Op.hash160);
      expect(spk[1], 0x14); // push 20 bytes
      expect(spk.sublist(2, 22), equals(p2shHash));
      expect(spk[22], Op.equal);
    });

    test('round-trip: parse address string then toScriptPubKey', () {
      final addr =
          Addr.fromString('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy', _bitcoin);
      expect(addr, isA<P2shAddr>());
      final spk = addr.scriptPubKey;
      expect(spk.length, 23);
      expect(spk.sublist(2, 22), equals(p2shHash));
    });
  });

  group('P2WPKH toLocking()', () {
    test('produces correct scriptPubKey', () {
      final addr = P2wpkhAddr(pkHash);
      final spk = addr.toLocking().compiled;

      // OP_0 <20 bytes>
      expect(spk.length, 22);
      expect(spk[0], Op.op0);
      expect(spk[1], 0x14); // push 20 bytes
      expect(spk.sublist(2, 22), equals(pkHash));
    });

    test('round-trip: parse address string then toScriptPubKey', () {
      final addr = Addr.fromString(
          'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4', _bitcoin);
      expect(addr, isA<P2wpkhAddr>());
      final spk = addr.scriptPubKey;
      expect(spk.length, 22);
      expect(spk.sublist(2, 22), equals(pkHash));
    });
  });

  group('P2WSH toLocking()', () {
    test('produces correct scriptPubKey', () {
      final wshHash = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        wshHash[i] = i;
      }
      final addr = P2wshAddr(wshHash);
      final spk = addr.toLocking().compiled;

      // OP_0 <32 bytes>
      expect(spk.length, 34);
      expect(spk[0], Op.op0);
      expect(spk[1], 0x20); // push 32 bytes
      expect(spk.sublist(2, 34), equals(wshHash));
    });
  });

  group('P2TR toLocking()', () {
    test('produces correct scriptPubKey', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final xOnly = sk.xOnly;
      final addr = TaprootAddr(xOnly);
      final spk = addr.toLocking().compiled;

      // OP_1 <32 bytes>
      expect(spk.length, 34);
      expect(spk[0], Op.op1);
      expect(spk[1], 0x20); // push 32 bytes
      expect(spk.sublist(2, 34), equals(xOnly));
    });

    test('round-trip: parse taproot address then toScriptPubKey', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final xOnly = sk.xOnly;
      final encoded = TaprootAddr(xOnly).encode(_bitcoin);
      final addr = Addr.fromString(encoded, _bitcoin);
      expect(addr, isA<TaprootAddr>());
      final spk = addr.scriptPubKey;
      expect(spk.length, 34);
      expect(spk[0], Op.op1);
      expect(spk.sublist(2, 34), equals(xOnly));
    });
  });

  group('scriptPubKey convenience getter', () {
    test('returns same bytes as toLocking().compiled', () {
      final addr = P2pkhAddr(pkHash);
      expect(addr.scriptPubKey, equals(addr.toLocking().compiled));
    });

    test('works on all address types', () {
      final wshHash = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        wshHash[i] = i;
      }

      final addrs = <Addr>[
        P2pkhAddr(pkHash),
        P2shAddr(p2shHash),
        P2wpkhAddr(pkHash),
        P2wshAddr(wshHash),
        TaprootAddr(wshHash),
      ];

      for (final addr in addrs) {
        expect(addr.scriptPubKey, equals(addr.toLocking().compiled));
      }
    });
  });
}
