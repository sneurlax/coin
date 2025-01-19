import 'package:coin/coin.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  group('Mnemonic generation', () {
    test('generate 12-word mnemonic (128 bits)', () {
      final m = Mnemonic.generate(strength: 128);
      expect(m.words.length, 12);
      expect(m.validate(), isTrue);
    });

    test('generate 15-word mnemonic (160 bits)', () {
      final m = Mnemonic.generate(strength: 160);
      expect(m.words.length, 15);
      expect(m.validate(), isTrue);
    });

    test('generate 18-word mnemonic (192 bits)', () {
      final m = Mnemonic.generate(strength: 192);
      expect(m.words.length, 18);
      expect(m.validate(), isTrue);
    });

    test('generate 21-word mnemonic (224 bits)', () {
      final m = Mnemonic.generate(strength: 224);
      expect(m.words.length, 21);
      expect(m.validate(), isTrue);
    });

    test('generate 24-word mnemonic (256 bits)', () {
      final m = Mnemonic.generate(strength: 256);
      expect(m.words.length, 24);
      expect(m.validate(), isTrue);
    });

    test('invalid strength throws', () {
      expect(() => Mnemonic.generate(strength: 100), throwsArgumentError);
      expect(() => Mnemonic.generate(strength: 127), throwsArgumentError);
      expect(() => Mnemonic.generate(strength: 129), throwsArgumentError);
      expect(() => Mnemonic.generate(strength: 512), throwsArgumentError);
    });

    test('two generated mnemonics are different', () {
      final m1 = Mnemonic.generate();
      final m2 = Mnemonic.generate();
      expect(m1.phrase, isNot(equals(m2.phrase)));
    });
  });

  group('Mnemonic.fromPhrase', () {
    test('parses space-separated words', () {
      const phrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final m = Mnemonic.fromPhrase(phrase);
      expect(m.words.length, 12);
      expect(m.words.first, 'abandon');
      expect(m.words.last, 'about');
    });

    test('trims leading/trailing whitespace', () {
      const phrase =
          '  abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about  ';
      final m = Mnemonic.fromPhrase(phrase);
      expect(m.words.length, 12);
    });

    test('handles multiple spaces between words', () {
      const phrase =
          'abandon  abandon   abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final m = Mnemonic.fromPhrase(phrase);
      expect(m.words.length, 12);
    });

    test('phrase round-trips', () {
      const phrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final m = Mnemonic.fromPhrase(phrase);
      expect(m.phrase, phrase);
    });
  });

  group('Mnemonic validation', () {
    test('valid 12-word mnemonic validates', () {
      final m = Mnemonic.fromPhrase(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      );
      expect(m.validate(), isTrue);
    });

    test('valid 24-word mnemonic validates', () {
      final m = Mnemonic.fromPhrase(
        'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote',
      );
      expect(m.validate(), isTrue);
    });

    test('invalid word count fails', () {
      final m = Mnemonic(['abandon', 'abandon', 'abandon']);
      expect(m.validate(), isFalse);
    });

    test('unknown word fails', () {
      final m = Mnemonic([
        'abandon', 'abandon', 'abandon', 'abandon', 'abandon', 'abandon',
        'abandon', 'abandon', 'abandon', 'abandon', 'abandon', 'zzzznotaword',
      ]);
      expect(m.validate(), isFalse);
    });

    test('empty phrase fails', () {
      final m = Mnemonic([]);
      expect(m.validate(), isFalse);
    });
  });

  group('Mnemonic toString', () {
    test('toString returns phrase', () {
      const phrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final m = Mnemonic.fromPhrase(phrase);
      expect(m.toString(), phrase);
    });
  });

  // BIP-39 seed vectors from the reference test suite maintained by Trezor:
  // https://github.com/trezor/python-mnemonic/blob/master/vectors.json
  group('BIP-39 seed derivation', () {
    test('12-word "abandon" mnemonic with empty passphrase', () {
      final m = Mnemonic.fromPhrase(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      );
      final seed = m.toSeed();
      expect(seed.length, 64);
      expect(
        hexEncode(seed),
        '5eb00bbddcf069084889a8ab9155568165f5c453ccb85e70811aaed6f6da5fc1'
        '9a5ac40b389cd370d086206dec8aa6c43daea6690f20ad3d8d48b2d2ce9e38e4',
      );
    });

    test('24-word "zoo" mnemonic with empty passphrase', () {
      final m = Mnemonic.fromPhrase(
        'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote',
      );
      final seed = m.toSeed();
      expect(seed.length, 64);
      expect(
        hexEncode(seed),
        'e28a37058c7f5112ec9e16a3437cf363a2572d70b6ceb3b6965447623d620f1'
        '4d06bb321a26b33ec15fcd84a3b5ddfd5520e230c924c87aaa0d559749e044fef',
      );
    });

    test('passphrase changes seed', () {
      final m = Mnemonic.fromPhrase(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      );
      final seedNoPass = m.toSeed();
      final seedWithPass = m.toSeed(passphrase: 'my secret');
      expect(seedNoPass, isNot(equals(seedWithPass)));
      expect(seedWithPass.length, 64);
    });

    test('12-word "abandon" mnemonic with "TREZOR" passphrase', () {
      final m = Mnemonic.fromPhrase(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      );
      final seed = m.toSeed(passphrase: 'TREZOR');
      expect(seed.length, 64);
      expect(
        hexEncode(seed),
        'c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e5349553'
        '1f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04',
      );
    });
  });

  group('Mnemonic to HD key integration', () {
    test('mnemonic seed produces valid master key', () {
      final m = Mnemonic.fromPhrase(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      );
      final seed = m.toSeed();
      final master = DerivedKey.fromSeed(seed) as DerivedSecretKey;
      expect(master.depth, 0);
      expect(master.secretKey.bytes.length, 32);
      expect(master.publicKey.bytes.length, 33);
    });

    test('different mnemonics produce different master keys', () {
      final m1 = Mnemonic.generate();
      final m2 = Mnemonic.generate();
      final master1 = DerivedKey.fromSeed(m1.toSeed()) as DerivedSecretKey;
      final master2 = DerivedKey.fromSeed(m2.toSeed()) as DerivedSecretKey;
      expect(master1.secretKey.toHex(), isNot(equals(master2.secretKey.toHex())));
    });
  });
}
