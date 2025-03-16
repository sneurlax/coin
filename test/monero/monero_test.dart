import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:coin/coin.dart';
import 'package:coin/src/monero/ed25519/ed25519_constants.dart';
import 'package:coin/src/monero/ed25519/ed25519_math.dart';
import 'package:coin/src/monero/encode/monero_base58.dart';
import 'package:coin/src/monero/keys/monero_keys.dart';

// Ed25519 curve constants (G, l) from RFC 8032 §5.1:
// https://datatracker.ietf.org/doc/html/rfc8032#section-5.1
//
// Key-derivation vectors (spend key -> view key, address encoding) are
// cross-checked against the Cryptonote Address Tests tool by luigi1111:
// https://github.com/luigi1111/xmr.llcoins.net  (site/addresstests.html)
// and against monero-project/monero unit tests:
// https://github.com/monero-project/monero/tree/master/tests
//
// Pedersen commitment uses the standard Monero H generator; see
// https://github.com/monero-project/monero/blob/master/src/ringct/rctTypes.h
//
// Polyseed vectors (c584b326...) and subaddress stagenet strings are
// self-computed and verified against the official Monero CLI wallet.
void main() {
  setUpAll(() async {
    await initCoin();
  });

  // ---------------------------------------------------------------------------
  // 1. Ed25519 math tests
  // ---------------------------------------------------------------------------
  group('Ed25519 math', () {
    test('generator point G is on the curve', () {
      expect(edIsOnCurve(ed25519G), isTrue);
    });

    test('identity element: G + identity = G', () {
      final identity = EdPoint.infinity();
      final result = edPointAdd(ed25519G, identity);
      expect(result, equals(ed25519G));
    });

    test('identity element: identity + G = G', () {
      final identity = EdPoint.infinity();
      final result = edPointAdd(identity, ed25519G);
      expect(result, equals(ed25519G));
    });

    test('scalar mult: 0 * G = identity', () {
      final result = edScalarMult(BigInt.zero, ed25519G);
      expect(result.isInfinity, isTrue);
    });

    test('scalar mult: 1 * G = G', () {
      final result = edScalarMult(BigInt.one, ed25519G);
      expect(result, equals(ed25519G));
    });

    test('group order: l * G = identity', () {
      final result = edScalarMult(ed25519L, ed25519G);
      expect(result.isInfinity, isTrue);
    });

    test('point compression round-trip: compress(decompress(G_bytes)) == G_bytes', () {
      final gBytes = edPointToBytes(ed25519G);
      expect(gBytes.length, 32);
      final decompressed = edBytesToPoint(gBytes);
      expect(edIsOnCurve(decompressed), isTrue);
      final recompressed = edPointToBytes(decompressed);
      expect(recompressed, equals(gBytes));
    });

    test('edIsOnCurve returns false for invalid points', () {
      // A point with arbitrary coordinates should almost certainly not be on
      // the Ed25519 curve.
      final invalid = EdPoint(BigInt.from(42), BigInt.from(99));
      expect(edIsOnCurve(invalid), isFalse);
    });

    test('identity element is on the curve', () {
      expect(edIsOnCurve(EdPoint.infinity()), isTrue);
    });

    test('scalar reduce produces value less than l', () {
      // 64-byte input (like a hash)
      final bigBytes = Uint8List(64);
      for (var i = 0; i < 64; i++) {
        bigBytes[i] = 0xff;
      }
      final reduced = edScalarReduce(bigBytes);
      expect(reduced < ed25519L, isTrue);
      expect(reduced >= BigInt.zero, isTrue);
    });

    test('2 * G = G + G', () {
      final doubleG = edScalarMult(BigInt.two, ed25519G);
      final addGG = edPointAdd(ed25519G, ed25519G);
      expect(doubleG, equals(addGG));
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Key derivation tests
  // ---------------------------------------------------------------------------
  group('Key derivation', () {
    test('English seed: spend key -> view key derivation', () {
      final spendKey = hexDecode(
          'c0af65c0dd837e666b9d0dfed62745f4df35aed7ea619b2798a709f0fe545403');
      final expectedViewKey =
          '513ba91c538a5a9069e0094de90e927c0cd147fa10428ce3ac1afd49f63e3b01';

      final keys = MoneroKeys.fromSpendKey(spendKey);
      expect(hexEncode(keys.privateViewKey), expectedViewKey);
    });

    test('Chinese seed: entropy -> view key derivation', () {
      final entropy = hexDecode(
          'a5e4fff1706ef9212993a69f246f5c95ad6d84371692d63e9bb0ea112a58340d');
      final expectedViewKey =
          '1176c43ce541477ea2f3ef0b49b25112b084e26b8a843e1304ac4677b74cdf02';

      final keys = MoneroKeys.fromSpendKey(entropy);
      expect(hexEncode(keys.privateViewKey), expectedViewKey);
    });

    test('French seed: entropy -> view key derivation', () {
      final entropy = hexDecode(
          '2dd39ff1a4628a94b5c2ec3e42fb3dfe15c2b2f010154dc3b3de6791e805b904');
      final expectedViewKey =
          '6725b32230400a1032f31d622b44c3a227f88258939b14a7c72e00939e7bdf0e';

      final keys = MoneroKeys.fromSpendKey(entropy);
      expect(hexEncode(keys.privateViewKey), expectedViewKey);
    });

    test('Polyseed: spend key -> all key derivation', () {
      final spendKey = hexDecode(
          'c584b326f1a8472e210d80e4fc87271ffa371f94b95a0794eef80e851fb4e303');
      final expectedViewKey =
          '3b8ffd9a88e9cdbbd311629c38d696df07551bcea08e0df1942507db8f832007';
      final expectedPubSpend =
          '759ca40019178944aa2fe8062dfe61af1e3678be2ceed67fe83c34edde8492c9';
      final expectedPubView =
          '0d57d0165de6015305e5c1e2c54f75cc9a385348929980f1db140ac459e9958e';

      final keys = MoneroKeys.fromSpendKey(spendKey);
      expect(hexEncode(keys.privateViewKey), expectedViewKey);
      expect(hexEncode(keys.publicSpendKey), expectedPubSpend);
      expect(hexEncode(keys.publicViewKey), expectedPubView);
    });

    test('public key derivation: private * G produces correct public key', () {
      final spendKey = hexDecode(
          'c584b326f1a8472e210d80e4fc87271ffa371f94b95a0794eef80e851fb4e303');
      final keys = MoneroKeys.fromSpendKey(spendKey);

      // Verify by manually computing private spend key * G
      final spendScalar = edBytesToBigInt(keys.privateSpendKey);
      final pubPoint = edScalarMult(spendScalar, ed25519G);
      final pubBytes = edPointToBytes(pubPoint);
      expect(pubBytes, equals(keys.publicSpendKey));
    });

    test('generated keys have valid scalars (< l)', () {
      final keys = MoneroKeys.generate();
      final spendScalar = edBytesToBigInt(keys.privateSpendKey);
      final viewScalar = edBytesToBigInt(keys.privateViewKey);
      expect(spendScalar > BigInt.zero, isTrue);
      expect(spendScalar < ed25519L, isTrue);
      expect(viewScalar > BigInt.zero, isTrue);
      expect(viewScalar < ed25519L, isTrue);
    });

    test('public keys are valid curve points', () {
      final keys = MoneroKeys.generate();
      final spendPoint = edBytesToPoint(keys.publicSpendKey);
      final viewPoint = edBytesToPoint(keys.publicViewKey);
      expect(edIsOnCurve(spendPoint), isTrue);
      expect(edIsOnCurve(viewPoint), isTrue);
    });

    test('invalid seed length throws', () {
      expect(() => MoneroKeys.fromSeed(Uint8List(31)), throwsArgumentError);
      expect(() => MoneroKeys.fromSeed(Uint8List(33)), throwsArgumentError);
    });

    test('invalid spend key length throws', () {
      expect(
          () => MoneroKeys.fromSpendKey(Uint8List(31)), throwsArgumentError);
      expect(
          () => MoneroKeys.fromSpendKey(Uint8List(33)), throwsArgumentError);
    });

    test('zero spend key throws', () {
      expect(
          () => MoneroKeys.fromSpendKey(Uint8List(32)), throwsArgumentError);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Monero base58 tests
  // ---------------------------------------------------------------------------
  group('Monero base58', () {
    test('encode/decode empty data', () {
      final encoded = moneroBase58Encode(Uint8List(0));
      expect(encoded, '');
      final decoded = moneroBase58Decode('');
      expect(decoded, equals(Uint8List(0)));
    });

    test('encode/decode round-trip for 1 byte', () {
      final data = Uint8List.fromList([0x42]);
      final encoded = moneroBase58Encode(data);
      final decoded = moneroBase58Decode(encoded);
      expect(decoded, equals(data));
    });

    test('encode/decode round-trip for 8 bytes (full block)', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final encoded = moneroBase58Encode(data);
      expect(encoded.length, 11); // full block = 11 chars
      final decoded = moneroBase58Decode(encoded);
      expect(decoded, equals(data));
    });

    test('encode/decode round-trip for 32 bytes', () {
      final data = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        data[i] = i;
      }
      final encoded = moneroBase58Encode(data);
      final decoded = moneroBase58Decode(encoded);
      expect(decoded, equals(data));
    });

    test('encode/decode round-trip for 69 bytes (standard address payload)', () {
      // Standard address raw data is 69 bytes (1 net byte + 32 spend + 32 view + 4 checksum)
      final data = Uint8List(69);
      for (var i = 0; i < 69; i++) {
        data[i] = i & 0xff;
      }
      final encoded = moneroBase58Encode(data);
      final decoded = moneroBase58Decode(encoded);
      expect(decoded, equals(data));
    });

    test('encode/decode round-trip for 77 bytes (integrated address payload)', () {
      final data = Uint8List(77);
      for (var i = 0; i < 77; i++) {
        data[i] = (i * 7 + 3) & 0xff;
      }
      final encoded = moneroBase58Encode(data);
      final decoded = moneroBase58Decode(encoded);
      expect(decoded, equals(data));
    });

    test('decode a known address and re-encode matches', () {
      const addr =
          '4B33mFPMq6mKi7Eiyd5XuyKRVMGVZz1Rqb9ZTyGApXW5d1aT7UBDZ89ewmnWFkzJ5wPd2SFbn313vCT8a4E2Qf4KQH4pNey';
      final decoded = moneroBase58Decode(addr);
      final reencoded = moneroBase58Encode(decoded);
      expect(reencoded, addr);
    });

    test('all-zero bytes encode and decode correctly', () {
      final data = Uint8List(16);
      final encoded = moneroBase58Encode(data);
      final decoded = moneroBase58Decode(encoded);
      expect(decoded, equals(data));
    });

    test('all-0xFF bytes encode and decode correctly', () {
      final data = Uint8List(16);
      for (var i = 0; i < 16; i++) {
        data[i] = 0xff;
      }
      final encoded = moneroBase58Encode(data);
      final decoded = moneroBase58Decode(encoded);
      expect(decoded, equals(data));
    });

    test('invalid base58 character throws FormatException', () {
      // '0' is not in the base58 alphabet
      expect(
        () => moneroBase58Decode('00000000000'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
