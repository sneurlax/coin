import 'dart:typed_data';

import '../core/random.dart';
import '../hash/digest.dart';
import 'bip39_english.dart';
import 'vault_keeper.dart';

class Mnemonic {
  final List<String> words;

  Mnemonic(this.words);

  factory Mnemonic.fromPhrase(String phrase) =>
      Mnemonic(phrase.trim().split(RegExp(r'\s+')));

  factory Mnemonic.generate({int strength = 128}) {
    if (strength % 32 != 0 || strength < 128 || strength > 256) {
      throw ArgumentError('Strength must be 128, 160, 192, 224, or 256');
    }
    final entropy = generateSecureBytes(strength ~/ 8);
    return Mnemonic._fromEntropy(entropy);
  }

  factory Mnemonic._fromEntropy(Uint8List entropy) {
    final hash = sha256(entropy);
    final bits = StringBuffer();
    for (final b in entropy) {
      bits.write(b.toRadixString(2).padLeft(8, '0'));
    }
    final checksumBits = entropy.length ~/ 4;
    for (var i = 0; i < checksumBits; i++) {
      bits.write(((hash[i ~/ 8] >> (7 - (i % 8))) & 1).toString());
    }

    final bitStr = bits.toString();
    final words = <String>[];
    for (var i = 0; i < bitStr.length; i += 11) {
      final idx = int.parse(bitStr.substring(i, i + 11), radix: 2);
      words.add(_wordlist[idx]);
    }
    return Mnemonic(words);
  }

  String get phrase => words.join(' ');

  Uint8List toSeed({String passphrase = ''}) =>
      VaultKeeper.vault.keyForge.mnemonicToSeed(phrase,
          passphrase: passphrase);

  bool validate() {
    if (![12, 15, 18, 21, 24].contains(words.length)) return false;
    for (final w in words) {
      if (!_wordSet.contains(w)) return false;
    }
    return true;
  }

  @override
  String toString() => phrase;

  static final List<String> _wordlist = bip39English;
  static final Set<String> _wordSet = _wordlist.toSet();
}
