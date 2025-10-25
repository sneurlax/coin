import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:coin/src/ext/bip47/bip47.dart';
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
  // BIP-47 test vectors from Samourai Wallet:
  // https://gist.github.com/SamouraiDev/6aad669604c5930864bd
  // Spec: https://github.com/bitcoin/bips/blob/master/bip-0047.mediawiki

  final aliceSeed = hexDecode(
    '64dca76abc9c6f0cf3d212d248c380c4622c8f93b2c425ec6a5567fd5db57e10'
    'd3e6f94a2f6af4ac2edb8998072aad92098db73558c323777abf5bd1082d970a',
  );

  final bobSeed = hexDecode(
    '87eaaac5a539ab028df44d9110defbef3797ddb805ca309f61a69ff96dbaa7ab'
    '5b24038cf029edec5235d933110f0aea8aeecf939ed14fc20730bba71e4b1110',
  );

  const alicePaymentCodeBase58 =
      'PM8TJTLJbPRGxSbc8EJi42Wrr6QbNSaSSVJ5Y3E4pbCYiTHUskHg13935Ubb7q8tx9GVbh2UuRnBc3WSyJHhUrw8KhprKnn9eDznYGieTzFcwQRya4GA';

  const bobPaymentCodeBase58 =
      'PM8TJS2JxQ5ztXUpBBRnpTbcUXbUHy2T1abfrb3KkAAtMEGNbey4oumH7Hc578WgQJhPjBxteQ5GHHToTYHE3A1w6p7tU6KSoFmWBVbFGjKPisZDbP97';

  const aliceNotificationAddress = '1JDdmqFLhpzcUwPeinhJbUPw4Co3aWLyzW';

  const aliceA0PubHex =
      '0353883a146a23f988e0f381a9507cbdb3e3130cd81b3ce26daf2af088724ce683';
  const bobB0PubHex =
      '024ce8e3b04ea205ff49f529950616c3db615b1e37753858cc60c1ce64d17e2ad8';

  const receivingAddresses = [
    '141fi7TY3h936vRUKh1qfUZr8rSBuYbVBK',
    '12u3Uued2fuko2nY4SoSFGCoGLCBUGPkk6',
    '1FsBVhT5dQutGwaPePTYMe5qvYqqjxyftc',
    '1CZAmrbKL6fJ7wUxb99aETwXhcGeG3CpeA',
    '1KQvRShk6NqPfpr4Ehd53XUhpemBXtJPTL',
    '1KsLV2F47JAe6f8RtwzfqhjVa8mZEnTM7t',
    '1DdK9TknVwvBrJe7urqFmaxEtGF2TMWxzD',
    '16DpovNuhQJH7JUSZQFLBQgQYS4QB9Wy8e',
    '17qK2RPGZMDcci2BLQ6Ry2PDGJErrNojT5',
    '1GxfdfP286uE24qLZ9YRP3EWk2urqXgC4s',
  ];

  final outpoint = hexDecode(
    '86f411ab1c8e70ae8a0795ab7a6757aea6e4d5ae1826fc7b8f00c597d500609c'
    '01000000',
  );

  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  group('PaymentCode parsing', () {
    test('parse Alice payment code from Base58', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      expect(alice.notificationPublicKey.length, 33);
      expect(alice.chainCode.length, 32);
      expect(alice.isValid(), isTrue);
      expect(alice.isSegwit, isFalse);
    });

    test('parse Bob payment code from Base58', () {
      final bob = PaymentCode.fromBase58(bobPaymentCodeBase58);
      expect(bob.notificationPublicKey.length, 33);
      expect(bob.chainCode.length, 32);
      expect(bob.isValid(), isTrue);
      expect(bob.isSegwit, isFalse);
    });

    test('encode/decode round-trip for Alice', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final reEncoded = alice.toBase58();
      expect(reEncoded, alicePaymentCodeBase58);
    });

    test('encode/decode round-trip for Bob', () {
      final bob = PaymentCode.fromBase58(bobPaymentCodeBase58);
      final reEncoded = bob.toBase58();
      expect(reEncoded, bobPaymentCodeBase58);
    });

    test('payload round-trip', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final payload = alice.payload;
      final reconstructed = PaymentCode(payload);
      expect(reconstructed.toBase58(), alicePaymentCodeBase58);
    });
  });

  group('PaymentCode creation from seed', () {
    test('Alice payment code from seed matches test vector', () {
      final master = DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final bip47Node = master.derivePath("m/47'/0'/0'") as DerivedSecretKey;

      final paymentCode = PaymentCode.fromPublicKey(
        pubKey: bip47Node.publicKey.bytes,
        chainCode: bip47Node.chainCode,
      );

      expect(paymentCode.toBase58(), alicePaymentCodeBase58);
    });

    test('Bob payment code from seed matches test vector', () {
      final master = DerivedKey.fromSeed(bobSeed) as DerivedSecretKey;
      final bip47Node = master.derivePath("m/47'/0'/0'") as DerivedSecretKey;

      final paymentCode = PaymentCode.fromPublicKey(
        pubKey: bip47Node.publicKey.bytes,
        chainCode: bip47Node.chainCode,
      );

      expect(paymentCode.toBase58(), bobPaymentCodeBase58);
    });
  });

  group('Notification address', () {
    test('Alice notification address matches test vector', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final addr = alice.notificationAddress(_bitcoin);
      expect(addr, aliceNotificationAddress);
    });
  });

  group('Child key derivation from payment code', () {
    test('Alice A0 from payment code matches test vector', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final A0 = alice.derivePublicKey(0);
      expect(hexEncode(A0.bytes), aliceA0PubHex);
    });

    test('Bob B0 from payment code matches test vector', () {
      final bob = PaymentCode.fromBase58(bobPaymentCodeBase58);
      final B0 = bob.derivePublicKey(0);
      expect(hexEncode(B0.bytes), bobB0PubHex);
    });

    test('child key derivation matches BIP32 direct derivation', () {
      final master = DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final bip47Node = master.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final directChild = bip47Node.derive(0) as DerivedSecretKey;

      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final derivedChild = alice.derivePublicKey(0);

      expect(derivedChild.bytes, equals(directChild.publicKey.bytes));
    });

    test('different indices produce different keys', () {
      final bob = PaymentCode.fromBase58(bobPaymentCodeBase58);
      final key0 = bob.derivePublicKey(0);
      final key1 = bob.derivePublicKey(1);
      final key2 = bob.derivePublicKey(2);

      expect(key0, isNot(equals(key1)));
      expect(key1, isNot(equals(key2)));
      expect(key0, isNot(equals(key2)));
    });
  });

  group('PaymentCode.fromPublicKey', () {
    test('creates payment code with segwit flag', () {
      final master = DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final bip47Node = master.derivePath("m/47'/0'/0'") as DerivedSecretKey;

      final paymentCode = PaymentCode.fromPublicKey(
        pubKey: bip47Node.publicKey.bytes,
        chainCode: bip47Node.chainCode,
        segwit: true,
      );

      expect(paymentCode.isSegwit, isTrue);
      expect(paymentCode.isValid(), isTrue);
    });

    test('rejects invalid pubkey length', () {
      expect(
        () => PaymentCode.fromPublicKey(
          pubKey: Uint8List(32),
          chainCode: Uint8List(32),
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid chaincode length', () {
      final master = DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final bip47Node = master.derivePath("m/47'/0'/0'") as DerivedSecretKey;

      expect(
        () => PaymentCode.fromPublicKey(
          pubKey: bip47Node.publicKey.bytes,
          chainCode: Uint8List(16),
        ),
        throwsArgumentError,
      );
    });
  });

  group('PaymentCode validation', () {
    test('isValid returns true for valid payment code', () {
      final pc = PaymentCode.fromBase58(alicePaymentCodeBase58);
      expect(pc.isValid(), isTrue);
    });

    test('isValid returns false for invalid pubkey prefix', () {
      final pc = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final badPayload = pc.payload;
      badPayload[2] = 0x04; // invalid compressed prefix
      final badPc = PaymentCode(badPayload);
      expect(badPc.isValid(), isFalse);
    });

    test('isValid returns false for non-zero reserved bytes', () {
      final pc = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final badPayload = pc.payload;
      badPayload[70] = 0xff; // set a reserved byte
      final badPc = PaymentCode(badPayload);
      expect(badPc.isValid(), isFalse);
    });

    test('constructor rejects wrong version', () {
      final payload = Uint8List(80);
      payload[0] = 0x02; // wrong version
      expect(() => PaymentCode(payload), throwsArgumentError);
    });

    test('constructor rejects wrong length', () {
      expect(() => PaymentCode(Uint8List(79)), throwsArgumentError);
      expect(() => PaymentCode(Uint8List(81)), throwsArgumentError);
    });
  });

  group('SecretPoint', () {
    test('ECDH shared secret is 32 bytes', () {
      final aliceMaster =
          DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final aliceNode =
          aliceMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final aliceChild0 = aliceNode.derive(0) as DerivedSecretKey;

      final bob = PaymentCode.fromBase58(bobPaymentCodeBase58);
      final bobPubKey = bob.derivePublicKey(0);

      final sp = SecretPoint(aliceChild0.secretKey, bobPubKey);
      expect(sp.ecdhSecret.length, 32);
    });

    test('ECDH is symmetric between notification keys', () {
      final aliceMaster =
          DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final aliceNode =
          aliceMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final aliceChild0 = aliceNode.derive(0) as DerivedSecretKey;

      final bobMaster = DerivedKey.fromSeed(bobSeed) as DerivedSecretKey;
      final bobNode =
          bobMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final bobChild0 = bobNode.derive(0) as DerivedSecretKey;

      final bobPC = PaymentCode.fromBase58(bobPaymentCodeBase58);
      final B0 = bobPC.derivePublicKey(0);
      final sAlice = SecretPoint(aliceChild0.secretKey, B0); // a0 * B0

      final alicePC = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final A0 = alicePC.derivePublicKey(0);
      final sBob = SecretPoint(bobChild0.secretKey, A0); // b0 * A0

      expect(sAlice.ecdhSecret, equals(sBob.ecdhSecret));
    });
  });

  group('Notification blinding', () {
    test('blinding mask is 64 bytes', () {
      final aliceMaster =
          DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final aliceNode =
          aliceMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final aliceChild0 = aliceNode.derive(0) as DerivedSecretKey;

      final bob = PaymentCode.fromBase58(bobPaymentCodeBase58);
      final bobPubKey = bob.derivePublicKey(0);

      final sp = SecretPoint(aliceChild0.secretKey, bobPubKey);
      final mask = blindingMask(sp.ecdhSecret, outpoint);
      expect(mask.length, 64);
    });

    test('blind/unblind round-trip', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final originalPayload = alice.payload;

      final aliceMaster =
          DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final aliceNode =
          aliceMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final aliceChild0 = aliceNode.derive(0) as DerivedSecretKey;

      final bob = PaymentCode.fromBase58(bobPaymentCodeBase58);
      final bobPubKey = bob.derivePublicKey(0);

      final sp = SecretPoint(aliceChild0.secretKey, bobPubKey);
      final mask = blindingMask(sp.ecdhSecret, outpoint);

      // Blind the payload
      final blinded = blindPayload(payload: originalPayload, mask: mask);

      expect(blinded, isNot(equals(originalPayload)));

      // XOR is its own inverse
      final unblinded = blindPayload(payload: blinded, mask: mask);
      expect(unblinded, equals(originalPayload));
    });

    test('blinding preserves version, features, and pubkey prefix', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final originalPayload = alice.payload;

      final mask = Uint8List(64);
      for (var i = 0; i < 64; i++) {
        mask[i] = 0xff;
      }

      final blinded = blindPayload(payload: originalPayload, mask: mask);

      expect(blinded[0], originalPayload[0]); // version
      expect(blinded[1], originalPayload[1]); // features
      expect(blinded[2], originalPayload[2]); // pubkey prefix
    });

    test('blindPayload rejects wrong payload length', () {
      expect(
        () => blindPayload(payload: Uint8List(79), mask: Uint8List(64)),
        throwsArgumentError,
      );
    });

    test('blindPayload rejects wrong mask length', () {
      expect(
        () => blindPayload(payload: Uint8List(80), mask: Uint8List(63)),
        throwsArgumentError,
      );
    });
  });

  group('Shared address derivation (send)', () {
    test('Alice sends to Bob: first 10 addresses match test vectors', () {
      final aliceMaster =
          DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final aliceNode =
          aliceMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final aliceChild0 = aliceNode.derive(0) as DerivedSecretKey;

      final bobPC = PaymentCode.fromBase58(bobPaymentCodeBase58);

      for (var i = 0; i < receivingAddresses.length; i++) {
        final addr = PaymentAddress.deriveSendAddress(
          myKey: aliceChild0.secretKey,
          theirPaymentCode: bobPC,
          index: i,
          chain: _bitcoin,
        );
        expect(addr, receivingAddresses[i],
            reason: 'Address at index $i mismatch');
      }
    });
  });

  group('Shared address derivation (receive)', () {
    test('Bob receives from Alice: first 10 addresses match', () {
      final bobMaster = DerivedKey.fromSeed(bobSeed) as DerivedSecretKey;
      final bobNode =
          bobMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;

      final alicePC = PaymentCode.fromBase58(alicePaymentCodeBase58);

      for (var i = 0; i < receivingAddresses.length; i++) {
        final bobChildI = bobNode.derive(i) as DerivedSecretKey;
        final addr = PaymentAddress.deriveReceiveAddress(
          myKey: bobChildI.secretKey,
          theirPaymentCode: alicePC,
          index: i,
          chain: _bitcoin,
        );
        expect(addr, receivingAddresses[i],
            reason: 'Receive address at index $i mismatch');
      }
    });

    test('send and receive derive same address at each index', () {
      final aliceMaster =
          DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final aliceNode =
          aliceMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final aliceChild0 = aliceNode.derive(0) as DerivedSecretKey;

      final bobMaster = DerivedKey.fromSeed(bobSeed) as DerivedSecretKey;
      final bobNode =
          bobMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;

      final bobPC = PaymentCode.fromBase58(bobPaymentCodeBase58);
      final alicePC = PaymentCode.fromBase58(alicePaymentCodeBase58);

      for (var i = 0; i < 5; i++) {
        final sendAddr = PaymentAddress.deriveSendAddress(
          myKey: aliceChild0.secretKey,
          theirPaymentCode: bobPC,
          index: i,
          chain: _bitcoin,
        );

        final bobChildI = bobNode.derive(i) as DerivedSecretKey;
        final recvAddr = PaymentAddress.deriveReceiveAddress(
          myKey: bobChildI.secretKey,
          theirPaymentCode: alicePC,
          index: i,
          chain: _bitcoin,
        );

        expect(sendAddr, recvAddr,
            reason: 'Send/receive mismatch at index $i');
      }
    });
  });

  group('Segwit addresses', () {
    test('segwit send address starts with bc1q', () {
      final aliceMaster =
          DerivedKey.fromSeed(aliceSeed) as DerivedSecretKey;
      final aliceNode =
          aliceMaster.derivePath("m/47'/0'/0'") as DerivedSecretKey;
      final aliceChild0 = aliceNode.derive(0) as DerivedSecretKey;

      final bobPC = PaymentCode.fromBase58(bobPaymentCodeBase58);

      final addr = PaymentAddress.deriveSendAddress(
        myKey: aliceChild0.secretKey,
        theirPaymentCode: bobPC,
        index: 0,
        chain: _bitcoin,
        segwit: true,
      );

      expect(addr, startsWith('bc1q'));
    });
  });

  group('PaymentCode equality', () {
    test('same payment codes are equal', () {
      final a = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final b = PaymentCode.fromBase58(alicePaymentCodeBase58);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different payment codes are not equal', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      final bob = PaymentCode.fromBase58(bobPaymentCodeBase58);
      expect(alice, isNot(equals(bob)));
    });

    test('toString returns Base58 encoding', () {
      final alice = PaymentCode.fromBase58(alicePaymentCodeBase58);
      expect(alice.toString(), alicePaymentCodeBase58);
    });
  });
}
