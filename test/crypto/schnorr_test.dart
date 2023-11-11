import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  group('Schnorr key generation', () {
    test('generate SecretKey and get x-only PublicKey', () {
      final sk = SecretKey.generate();
      final xOnly = sk.xOnly;
      expect(xOnly.length, 32);
    });

    test('x-only key matches PublicKey x coordinate', () {
      final sk = SecretKey.generate();
      final pk = sk.publicKey;
      final xOnly = sk.xOnly;
      expect(xOnly, equals(pk.xOnly));
      expect(xOnly, equals(pk.x));
    });

    test('known private key produces known x-only key', () {
      // private key = 1 => G point x-coordinate
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final xOnly = sk.xOnly;
      expect(hexEncode(xOnly),
          '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798');
    });
  });

  group('Schnorr signing and verification', () {
    late SecretKey sk;
    late Uint8List xPub;

    setUp(() {
      sk = SecretKey.fromHex(
          'e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35');
      xPub = sk.xOnly;
    });

    test('sign and verify succeeds', () {
      final msg = sha256(Uint8List.fromList('schnorr test'.codeUnits));
      final sig = SchnorrSig.sign(msg, sk.bytes);
      expect(sig.bytes.length, 64);
      expect(sig.verify(msg, xPub), isTrue);
    });

    test('verify fails with wrong message', () {
      final msg = sha256(Uint8List.fromList('correct'.codeUnits));
      final wrongMsg = sha256(Uint8List.fromList('incorrect'.codeUnits));
      final sig = SchnorrSig.sign(msg, sk.bytes);
      expect(sig.verify(wrongMsg, xPub), isFalse);
    });

    test('verify fails with wrong public key', () {
      final msg = sha256(Uint8List.fromList('schnorr wrong pk'.codeUnits));
      final sig = SchnorrSig.sign(msg, sk.bytes);
      final otherSk = SecretKey.generate();
      expect(sig.verify(msg, otherSk.xOnly), isFalse);
    });

    test('signature hex round-trips', () {
      final msg = sha256(Uint8List.fromList('hex round-trip'.codeUnits));
      final sig = SchnorrSig.sign(msg, sk.bytes);
      final hexStr = sig.toHex();
      expect(hexStr.length, 128);
      final restored = SchnorrSig.fromHex(hexStr);
      expect(restored, equals(sig));
    });

    test('sign with explicit auxRand', () {
      final msg = sha256(Uint8List.fromList('aux rand test'.codeUnits));
      final auxRand = Uint8List(32); // all zeros
      final sig = SchnorrSig.sign(msg, sk.bytes, auxRand: auxRand);
      expect(sig.verify(msg, xPub), isTrue);
    });
  });

  // BIP-340 test vectors from:
  // https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki
  // CSV: https://github.com/bitcoin/bips/blob/master/bip-0340/test-vectors.csv
  group('BIP-340 test vectors', () {
    // BIP-340 vector 0
    test('vector 0 - sign and verify', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000003');
      final xPub = sk.xOnly;
      expect(hexEncode(xPub),
          'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9');

      final msg = hexDecode(
          '0000000000000000000000000000000000000000000000000000000000000000');
      final auxRand = hexDecode(
          '0000000000000000000000000000000000000000000000000000000000000000');
      final sig = SchnorrSig.sign(msg, sk.bytes, auxRand: auxRand);

      expect(sig.verify(msg, xPub), isTrue);

      expect(
          sig.toHex(),
          'e907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca8215'
          '25f66a4a85ea8b71e482a74f382d2ce5ebeee8fdb2172f477df4900d310536c0');
    });

    // BIP-340 vector 1
    test('vector 1 - sign and verify', () {
      final sk = SecretKey.fromHex(
          'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef');
      final xPub = sk.xOnly;
      expect(hexEncode(xPub),
          'dff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659');

      final msg = hexDecode(
          '243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c89');
      final auxRand = hexDecode(
          '0000000000000000000000000000000000000000000000000000000000000001');
      final sig = SchnorrSig.sign(msg, sk.bytes, auxRand: auxRand);

      expect(sig.verify(msg, xPub), isTrue);

      expect(
          sig.toHex(),
          '6896bd60eeae296db48a229ff71dfe071bde413e6d43f917dc8dcf8c78de3341'
          '8906d11ac976abccb20b091292bff4ea897efcb639ea871cfa95f6de339e4b0a');
    });

    // BIP-340 vector 4 (verification only)
    test('vector 4 - verify only', () {
      final xPub = hexDecode(
          'd69c3509bb99e412e68b0fe8544e72837dfa30746d8be2aa65975f29d22dc7b9');
      final msg = hexDecode(
          '4df3c3f68fcc83b27e9d42c90431a72499f17875c81a599b566c9889b9696703');
      final sig = SchnorrSig.fromHex(
          '00000000000000000000003b78ce563f89a0ed9414f5aa28ad0d96d6795f9c63'
          '76afb1548af603b3eb45c9f8207dee1060cb71c04e80f593060b07d28308d7f4');
      expect(sig.verify(msg, xPub), isTrue);
    });
  });

  group('Schnorr edge cases', () {
    test('different messages produce different signatures', () {
      final sk = SecretKey.generate();
      final msg1 = sha256(Uint8List.fromList('message 1'.codeUnits));
      final msg2 = sha256(Uint8List.fromList('message 2'.codeUnits));
      final sig1 = SchnorrSig.sign(msg1, sk.bytes);
      final sig2 = SchnorrSig.sign(msg2, sk.bytes);
      expect(sig1, isNot(equals(sig2)));
    });

    test('same message with different keys produce different signatures', () {
      final sk1 = SecretKey.generate();
      final sk2 = SecretKey.generate();
      final msg = sha256(Uint8List.fromList('shared message'.codeUnits));
      final sig1 = SchnorrSig.sign(msg, sk1.bytes);
      final sig2 = SchnorrSig.sign(msg, sk2.bytes);
      expect(sig1, isNot(equals(sig2)));
    });

    test('invalid signature length throws', () {
      expect(() => SchnorrSig(Uint8List(63)), throwsArgumentError);
      expect(() => SchnorrSig(Uint8List(65)), throwsArgumentError);
    });

    test('sign is deterministic with same auxRand', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000003');
      final msg = Uint8List(32);
      final auxRand = Uint8List(32);
      final sig1 = SchnorrSig.sign(msg, sk.bytes, auxRand: auxRand);
      final sig2 = SchnorrSig.sign(msg, sk.bytes, auxRand: auxRand);
      expect(sig1, equals(sig2));
    });

    test('different auxRand produces different signature that still verifies', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000003');
      final msg = Uint8List(32);
      final aux1 = Uint8List(32);
      final aux2 = Uint8List(32)..[0] = 0x01;
      final sig1 = SchnorrSig.sign(msg, sk.bytes, auxRand: aux1);
      final sig2 = SchnorrSig.sign(msg, sk.bytes, auxRand: aux2);
      expect(sig1, isNot(equals(sig2)));
      expect(sig1.verify(msg, sk.xOnly), isTrue);
      expect(sig2.verify(msg, sk.xOnly), isTrue);
    });

    test('sign without explicit auxRand still verifies', () {
      final sk = SecretKey.fromHex(
          '0000000000000000000000000000000000000000000000000000000000000007');
      final msg = Uint8List(32)..[15] = 0x42;
      final sig = SchnorrSig.sign(msg, sk.bytes);
      expect(sig.verify(msg, sk.xOnly), isTrue);
    });
  });
}
