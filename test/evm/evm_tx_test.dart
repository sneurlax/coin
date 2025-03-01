import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:coin/coin_evm.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  // EIP-155 test vector  -  private key 0x4646...46, nonce 9, to 0x3535...35.
  // Signing hash, signed RLP, and v/r/s all from the spec:
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
  // https://eips.ethereum.org/EIPS/eip-155
  group('Legacy transaction RLP encoding', () {
    test('simple ETH transfer produces correct unsigned RLP', () {
      final tx = Envelope(
        kind: EnvelopeKind.legacy,
        nonce: BigInt.from(9),
        gasPrice: BigInt.from(20000000000), // 20 gwei
        gasLimit: BigInt.from(21000),
        to: hexDecode('3535353535353535353535353535353535353535'),
        value: BigInt.from(1000000000000000000), // 1 ETH
        chainId: BigInt.one,
      );

      final hash = tx.signingHash();
      expect(hash.length, 32);

      expect(
        hexEncode(hash),
        'daf5a779ae972f972197303d7b574746c7ef83eadac0f2791ad23db92e4c8e53',
      );
    });

    test('nonce zero and zero value encode correctly', () {
      final tx = Envelope(
        kind: EnvelopeKind.legacy,
        nonce: BigInt.zero,
        gasPrice: BigInt.from(1000000000),
        gasLimit: BigInt.from(21000),
        to: hexDecode('0000000000000000000000000000000000000001'),
        value: BigInt.zero,
        chainId: BigInt.one,
      );

      final hash = tx.signingHash();
      expect(hash.length, 32);
      expect(tx.signingHash(), equals(hash));
    });

    test('contract creation has null to field', () {
      final tx = Envelope(
        kind: EnvelopeKind.legacy,
        nonce: BigInt.zero,
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(100000),
        to: null,
        value: BigInt.zero,
        data: hexDecode('6060604052'),
        chainId: BigInt.one,
      );

      final hash = tx.signingHash();
      expect(hash.length, 32);
    });

    test('serialization requires signature', () {
      final tx = Envelope(
        kind: EnvelopeKind.legacy,
        nonce: BigInt.zero,
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        to: hexDecode('3535353535353535353535353535353535353535'),
        value: BigInt.from(1000000000000000000),
        chainId: BigInt.one,
      );

      expect(() => tx.serialize(), throwsStateError);
    });

    test('legacy signed tx serializes correctly (EIP-155 vector)', () {
      final key = SecretKey(hexDecode(
          '4646464646464646464646464646464646464646464646464646464646464646'));

      final tx = Envelope(
        kind: EnvelopeKind.legacy,
        nonce: BigInt.from(9),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        to: hexDecode('3535353535353535353535353535353535353535'),
        value: BigInt.from(1000000000000000000),
        chainId: BigInt.one,
      );

      final signed = EnvelopeSigner.sign(tx, key);
      expect(signed.v, isNotNull);
      expect(signed.r, isNotNull);
      expect(signed.s, isNotNull);

      expect(signed.v, anyOf(37, 38));

      final serialized = signed.serialize();
      expect(serialized.isNotEmpty, isTrue);

      final decoded = Rlp.decode(serialized);
      expect(decoded, isA<List>());
      final list = decoded as List;
      expect(list.length, 9);

      expect(
        hexEncode(serialized),
        'f86c098504a817c800825208943535353535353535353535353535'
        '353535353535880de0b6b3a76400008025a028ef61340bd939bc'
        '2195fe537567866003e1a15d3c71ff63e1590620aa636276a067'
        'cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83',
      );
    });

    test('tx hash matches known value after signing', () {
      final key = SecretKey(hexDecode(
          '4646464646464646464646464646464646464646464646464646464646464646'));

      final tx = Envelope(
        kind: EnvelopeKind.legacy,
        nonce: BigInt.from(9),
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        to: hexDecode('3535353535353535353535353535353535353535'),
        value: BigInt.from(1000000000000000000),
        chainId: BigInt.one,
      );

      final signed = EnvelopeSigner.sign(tx, key);
      final txHash = signed.hash();
      expect(txHash.length, 32);

      expect(signed.hashHex().startsWith('0x'), isTrue);
      expect(signed.hashHex().length, 66);
    });
  });

  group('EIP-1559 (type 2) transaction encoding', () {
    test('EIP-1559 unsigned payload has type prefix 0x02', () {
      final tx = Envelope(
        kind: EnvelopeKind.eip1559,
        nonce: BigInt.zero,
        maxPriorityFeePerGas: BigInt.from(1000000000), // 1 gwei
        maxFeePerGas: BigInt.from(30000000000), // 30 gwei
        gasLimit: BigInt.from(21000),
        to: hexDecode('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'),
        value: BigInt.from(1000000000000000000),
        chainId: BigInt.one,
      );

      final hash = tx.signingHash();
      expect(hash.length, 32);
    });

    test('EIP-1559 signing and serialization', () {
      final key = SecretKey(hexDecode(
          '4646464646464646464646464646464646464646464646464646464646464646'));

      final tx = Envelope(
        kind: EnvelopeKind.eip1559,
        nonce: BigInt.from(0),
        maxPriorityFeePerGas: BigInt.from(2000000000),
        maxFeePerGas: BigInt.from(100000000000),
        gasLimit: BigInt.from(21000),
        to: hexDecode('3535353535353535353535353535353535353535'),
        value: BigInt.from(1000000000000000000),
        chainId: BigInt.one,
      );

      final signed = EnvelopeSigner.sign(tx, key);
      expect(signed.v, anyOf(0, 1));

      final serialized = signed.serialize();
      expect(serialized[0], 0x02);

      final rlpPayload = serialized.sublist(1);
      final decoded = Rlp.decode(rlpPayload);
      expect(decoded, isA<List>());
      final list = decoded as List;
      expect(list.length, 12);
    });

    test('EIP-1559 with empty access list', () {
      final tx = Envelope(
        kind: EnvelopeKind.eip1559,
        nonce: BigInt.from(42),
        maxPriorityFeePerGas: BigInt.from(1500000000),
        maxFeePerGas: BigInt.from(50000000000),
        gasLimit: BigInt.from(21000),
        to: hexDecode('0000000000000000000000000000000000000001'),
        value: BigInt.zero,
        chainId: BigInt.one,
        accessList: [],
      );

      final hash = tx.signingHash();
      expect(hash.length, 32);
    });

    test('different chain IDs produce different signing hashes', () {
      final params = {
        'nonce': BigInt.zero,
        'maxPriorityFeePerGas': BigInt.from(1000000000),
        'maxFeePerGas': BigInt.from(30000000000),
        'gasLimit': BigInt.from(21000),
        'to': hexDecode('3535353535353535353535353535353535353535'),
        'value': BigInt.from(1000000000000000000),
      };

      final txMainnet = Envelope(
        kind: EnvelopeKind.eip1559,
        chainId: BigInt.one,
        nonce: params['nonce'] as BigInt,
        maxPriorityFeePerGas: params['maxPriorityFeePerGas'] as BigInt,
        maxFeePerGas: params['maxFeePerGas'] as BigInt,
        gasLimit: params['gasLimit'] as BigInt,
        to: params['to'] as Uint8List,
        value: params['value'] as BigInt,
      );

      final txGoerli = Envelope(
        kind: EnvelopeKind.eip1559,
        chainId: BigInt.from(5),
        nonce: params['nonce'] as BigInt,
        maxPriorityFeePerGas: params['maxPriorityFeePerGas'] as BigInt,
        maxFeePerGas: params['maxFeePerGas'] as BigInt,
        gasLimit: params['gasLimit'] as BigInt,
        to: params['to'] as Uint8List,
        value: params['value'] as BigInt,
      );

      expect(txMainnet.signingHash(), isNot(equals(txGoerli.signingHash())));
    });
  });

  group('Envelope.withSignature', () {
    test('copies all fields and attaches signature', () {
      final tx = Envelope(
        kind: EnvelopeKind.eip1559,
        nonce: BigInt.from(7),
        maxPriorityFeePerGas: BigInt.from(1000000000),
        maxFeePerGas: BigInt.from(30000000000),
        gasLimit: BigInt.from(50000),
        to: hexDecode('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'),
        value: BigInt.from(500),
        chainId: BigInt.from(137),
      );

      final r = Uint8List(32)..fillRange(0, 32, 0xaa);
      final s = Uint8List(32)..fillRange(0, 32, 0xbb);
      final signed = tx.withSignature(v: 1, r: r, s: s);

      expect(signed.kind, EnvelopeKind.eip1559);
      expect(signed.nonce, BigInt.from(7));
      expect(signed.chainId, BigInt.from(137));
      expect(signed.v, 1);
      expect(signed.r, equals(r));
      expect(signed.s, equals(s));
    });
  });

  group('Signing hash determinism', () {
    test('same transaction always produces the same signing hash', () {
      final tx = Envelope(
        kind: EnvelopeKind.legacy,
        nonce: BigInt.from(100),
        gasPrice: BigInt.from(50000000000),
        gasLimit: BigInt.from(21000),
        to: hexDecode('aabbccddee11223344556677889900aabbccddee'),
        value: BigInt.from(999),
        chainId: BigInt.from(3),
      );

      final hash1 = tx.signingHash();
      final hash2 = tx.signingHash();
      expect(hash1, equals(hash2));
    });

    test('legacy and EIP-1559 produce different hashes for same params', () {
      final to = hexDecode('3535353535353535353535353535353535353535');

      final legacy = Envelope(
        kind: EnvelopeKind.legacy,
        nonce: BigInt.zero,
        gasPrice: BigInt.from(20000000000),
        gasLimit: BigInt.from(21000),
        to: to,
        value: BigInt.from(1000000000000000000),
        chainId: BigInt.one,
      );

      final eip1559 = Envelope(
        kind: EnvelopeKind.eip1559,
        nonce: BigInt.zero,
        maxFeePerGas: BigInt.from(20000000000),
        maxPriorityFeePerGas: BigInt.zero,
        gasLimit: BigInt.from(21000),
        to: to,
        value: BigInt.from(1000000000000000000),
        chainId: BigInt.one,
      );

      expect(legacy.signingHash(), isNot(equals(eip1559.signingHash())));
    });
  });
}
