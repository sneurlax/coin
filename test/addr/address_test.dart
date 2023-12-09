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

const _bitcoinTestnet = Chain(
  wifPrefix: 0xef,
  p2pkhPrefix: 0x6f,
  p2shPrefix: 0xc4,
  bech32Hrp: 'tb',
  name: 'Bitcoin Testnet',
  bip44CoinType: 1,
  supportsSegwit: true,
  supportsTaproot: true,
);

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  // Vectors derived from private key 1 (secp256k1 generator G).
  // HASH160 751e76e8... and address 1BgGZ9tc... are deterministic from the
  // curve; verifiable with Bitcoin Core or any BIP-173 implementation.
  // P2SH hash b472a266... encodes to 3J98t1Wp... (same pair used in
  // base58_test.dart and script_test.dart).
  // Taproot x-only key f9308a01... is the x-coordinate of 3*G
  // (private key 3), from BIP-340 vector 0:
  // https://github.com/bitcoin/bips/blob/master/bip-0340/test-vectors.csv
  group('P2PKH address', () {
    test('create from public key hash and encode', () {
      // private key = 1
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final pk = sk.publicKey;
      final pkHash = hash160(pk.bytes);

      final addr = P2pkhAddr(pkHash);
      final encoded = addr.encode(_bitcoin);

      expect(encoded, isNotEmpty);
      expect(encoded.startsWith('1'), isTrue);

      expect(hexEncode(pkHash),
          '751e76e8199196d454941c45d1b3a323f1433bd6');
      expect(encoded, '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH');
    });

    test('create from different key', () {
      final sk = SecretKey.fromHex(
          'e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35');
      final pk = sk.publicKey;
      final pkHash = hash160(pk.bytes);
      final addr = P2pkhAddr(pkHash);
      final encoded = addr.encode(_bitcoin);

      expect(encoded.startsWith('1'), isTrue);
      expect(encoded.length, inInclusiveRange(25, 34));
    });

    test('testnet P2PKH address starts with m or n', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final pkHash = hash160(sk.publicKey.bytes);
      final addr = P2pkhAddr(pkHash);
      final encoded = addr.encode(_bitcoinTestnet);

      expect(encoded[0], anyOf(equals('m'), equals('n')));
    });

    test('invalid hash length throws', () {
      expect(() => P2pkhAddr(Uint8List(19)), throwsArgumentError);
      expect(() => P2pkhAddr(Uint8List(21)), throwsArgumentError);
    });
  });

  group('P2WPKH address', () {
    test('create from public key hash and encode', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final pk = sk.publicKey;
      final pkHash = hash160(pk.bytes);

      final addr = P2wpkhAddr(pkHash);
      final encoded = addr.encode(_bitcoin);

      expect(encoded, startsWith('bc1q'));
      expect(encoded.toLowerCase(), encoded);

      // priv key 1 => known P2WPKH address
      expect(encoded, 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4');
    });

    test('testnet P2WPKH starts with tb1q', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final pkHash = hash160(sk.publicKey.bytes);
      final addr = P2wpkhAddr(pkHash);
      final encoded = addr.encode(_bitcoinTestnet);

      expect(encoded, startsWith('tb1q'));
    });

    test('invalid hash length throws', () {
      expect(() => P2wpkhAddr(Uint8List(19)), throwsArgumentError);
      expect(() => P2wpkhAddr(Uint8List(21)), throwsArgumentError);
    });
  });

  group('P2TR address', () {
    test('create from x-only public key and encode', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final xOnly = sk.xOnly;
      expect(xOnly.length, 32);

      final addr = TaprootAddr(xOnly);
      final encoded = addr.encode(_bitcoin);

      expect(encoded, startsWith('bc1p'));
      expect(encoded.toLowerCase(), encoded);
    });

    test('testnet P2TR starts with tb1p', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final xOnly = sk.xOnly;
      final addr = TaprootAddr(xOnly);
      final encoded = addr.encode(_bitcoinTestnet);

      expect(encoded, startsWith('tb1p'));
    });

    test('P2TR address round-trips', () {
      final sk = SecretKey.generate();
      final xOnly = sk.xOnly;
      final addr = TaprootAddr(xOnly);
      final encoded = addr.encode(_bitcoin);

      final parsed = TaprootAddr.fromString(encoded, _bitcoin);
      expect(parsed.hash, equals(xOnly));
    });

    test('invalid key length throws', () {
      expect(() => TaprootAddr(Uint8List(31)), throwsArgumentError);
      expect(() => TaprootAddr(Uint8List(33)), throwsArgumentError);
    });
  });

  group('Address parsing (Addr.fromString)', () {
    test('parse P2PKH address', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final pkHash = hash160(sk.publicKey.bytes);
      final original = P2pkhAddr(pkHash);
      final encoded = original.encode(_bitcoin);

      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<P2pkhAddr>());
      expect(parsed.hash, equals(pkHash));
    });

    test('parse P2WPKH address', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final pkHash = hash160(sk.publicKey.bytes);
      final original = P2wpkhAddr(pkHash);
      final encoded = original.encode(_bitcoin);

      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<P2wpkhAddr>());
      expect(parsed.hash, equals(pkHash));
    });

    test('parse P2TR address', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final xOnly = sk.xOnly;
      final original = TaprootAddr(xOnly);
      final encoded = original.encode(_bitcoin);

      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<TaprootAddr>());
      expect(parsed.hash, equals(xOnly));
    });

    test('parse testnet addresses', () {
      final sk = SecretKey.generate();
      final pkHash = hash160(sk.publicKey.bytes);

      // P2PKH testnet
      final p2pkh = P2pkhAddr(pkHash).encode(_bitcoinTestnet);
      final parsedLegacy = Addr.fromString(p2pkh, _bitcoinTestnet);
      expect(parsedLegacy, isA<P2pkhAddr>());

      // P2WPKH testnet
      final p2wpkh = P2wpkhAddr(pkHash).encode(_bitcoinTestnet);
      final parsedSegwit = Addr.fromString(p2wpkh, _bitcoinTestnet);
      expect(parsedSegwit, isA<P2wpkhAddr>());

      // P2TR testnet
      final p2tr = TaprootAddr(sk.xOnly).encode(_bitcoinTestnet);
      final parsedTaproot = Addr.fromString(p2tr, _bitcoinTestnet);
      expect(parsedTaproot, isA<TaprootAddr>());
    });

    test('address encode/parse round-trip preserves hash', () {
      final sk = SecretKey.generate();
      final pkHash = hash160(sk.publicKey.bytes);

      // P2PKH round-trip
      final p2pkhEncoded = P2pkhAddr(pkHash).encode(_bitcoin);
      final p2pkhParsed = Addr.fromString(p2pkhEncoded, _bitcoin);
      expect(p2pkhParsed.hash, equals(pkHash));

      // P2WPKH round-trip
      final p2wpkhEncoded = P2wpkhAddr(pkHash).encode(_bitcoin);
      final p2wpkhParsed = Addr.fromString(p2wpkhEncoded, _bitcoin);
      expect(p2wpkhParsed.hash, equals(pkHash));

      // P2TR round-trip
      final xOnly = sk.xOnly;
      final p2trEncoded = TaprootAddr(xOnly).encode(_bitcoin);
      final p2trParsed = Addr.fromString(p2trEncoded, _bitcoin);
      expect(p2trParsed.hash, equals(xOnly));
    });
  });

  group('Address type detection', () {
    test('P2PKH detected for base58 version 0x00 address', () {
      final pkHash = hash160(SecretKey.generate().publicKey.bytes);
      final encoded = P2pkhAddr(pkHash).encode(_bitcoin);
      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<P2pkhAddr>());
      expect(parsed, isNot(isA<P2wpkhAddr>()));
      expect(parsed, isNot(isA<TaprootAddr>()));
    });

    test('P2SH detected for base58 version 0x05 address', () {
      final hash = hexDecode('b472a266d0bd89c13706a4132ccfb16f7c3b9fcb');
      final encoded = P2shAddr(hash).encode(_bitcoin);
      expect(encoded, equals('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'));
      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<P2shAddr>());
    });

    test('P2WPKH detected for bech32 v0 address', () {
      final pkHash = hash160(SecretKey.generate().publicKey.bytes);
      final encoded = P2wpkhAddr(pkHash).encode(_bitcoin);
      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<P2wpkhAddr>());
      expect(parsed, isNot(isA<TaprootAddr>()));
    });

    test('P2TR detected for bech32m v1 address', () {
      final xOnly = SecretKey.generate().xOnly;
      final encoded = TaprootAddr(xOnly).encode(_bitcoin);
      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<TaprootAddr>());
      expect(parsed, isNot(isA<P2wpkhAddr>()));
    });

    test('invalid address string throws', () {
      expect(
        () => Addr.fromString('not_a_valid_address', _bitcoin),
        throwsA(anything),
      );
    });
  });

  group('P2SH address', () {
    test('create from hash and encode', () {
      final hash = hexDecode('b472a266d0bd89c13706a4132ccfb16f7c3b9fcb');
      final addr = P2shAddr(hash);
      final encoded = addr.encode(_bitcoin);
      expect(encoded, equals('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'));
    });

    test('parse P2SH address', () {
      final addr = Addr.fromString('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy', _bitcoin);
      expect(addr, isA<P2shAddr>());
      expect(hexEncode(addr.hash),
          equals('b472a266d0bd89c13706a4132ccfb16f7c3b9fcb'));
    });

    test('round-trip P2SH', () {
      final hash = hexDecode('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      final addr = P2shAddr(hash);
      final encoded = addr.encode(_bitcoin);
      expect(encoded.startsWith('3'), isTrue);
      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<P2shAddr>());
      expect(parsed.hash, equals(hash));
    });

    test('invalid hash length throws', () {
      expect(() => P2shAddr(Uint8List(19)), throwsArgumentError);
      expect(() => P2shAddr(Uint8List(21)), throwsArgumentError);
    });
  });

  group('P2WSH address', () {
    test('create from 32-byte hash and round-trip', () {
      final hash = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        hash[i] = i;
      }
      final addr = P2wshAddr(hash);
      final encoded = addr.encode(_bitcoin);
      expect(encoded.startsWith('bc1q'), isTrue);

      final parsed = Addr.fromString(encoded, _bitcoin);
      expect(parsed, isA<P2wshAddr>());
      expect(parsed.hash, equals(hash));
    });

    test('invalid hash length throws', () {
      expect(() => P2wshAddr(Uint8List(31)), throwsArgumentError);
      expect(() => P2wshAddr(Uint8List(33)), throwsArgumentError);
    });
  });

  group('Peercoin chain addresses', () {
    test('P2PKH roundtrip on Peercoin', () {
      final hash = hexDecode('89abcdefabbaabbaabbaabbaabbaabbaabbaabba');
      final addr = P2pkhAddr(hash);
      final encoded = addr.encode(Chain.peercoin);
      expect(encoded.startsWith('P'), isTrue);
      final parsed = Addr.fromString(encoded, Chain.peercoin);
      expect(parsed, isA<P2pkhAddr>());
      expect(parsed.hash, equals(hash));
    });

    test('P2WPKH roundtrip on Peercoin', () {
      final hash = hexDecode('751e76e8199196d454941c45d1b3a323f1433bd6');
      final addr = P2wpkhAddr(hash);
      final encoded = addr.encode(Chain.peercoin);
      expect(encoded.startsWith('pc1q'), isTrue);
      final parsed = Addr.fromString(encoded, Chain.peercoin);
      expect(parsed, isA<P2wpkhAddr>());
      expect(parsed.hash, equals(hash));
    });

    test('Taproot roundtrip on Peercoin', () {
      final xOnlyKey = hexDecode(
          'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9');
      final addr = TaprootAddr(xOnlyKey);
      final encoded = addr.encode(Chain.peercoin);
      expect(encoded.startsWith('pc1p'), isTrue);
      final parsed = Addr.fromString(encoded, Chain.peercoin);
      expect(parsed, isA<TaprootAddr>());
      expect(parsed.hash, equals(xOnlyKey));
    });
  });
}
