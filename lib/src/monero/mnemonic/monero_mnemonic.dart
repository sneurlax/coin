import 'dart:typed_data';

import 'monero_wordlist.dart';

/// Electrum-style 25-word mnemonic. The spend key (32 bytes LE) is split into
/// eight 4-byte groups, each mapped to 3 word indices mod 1626. The 25th word
/// is a CRC-32 checksum over the unique prefixes of the first 24.
class MoneroMnemonic {
  MoneroMnemonic._();

  static const int _prefixLen = 4;
  static const int _wordCount = 1626;

  static List<String> encode(Uint8List privateSpendKey) {
    if (privateSpendKey.length != 32) {
      throw ArgumentError(
          'Private spend key must be 32 bytes, got ${privateSpendKey.length}');
    }

    final words = <String>[];
    final bd = ByteData.sublistView(privateSpendKey);

    for (var i = 0; i < 8; i++) {
      final value = bd.getUint32(i * 4, Endian.little);
      final w1 = value % _wordCount;
      final w2 = ((value ~/ _wordCount) + w1) % _wordCount;
      final w3 = ((value ~/ _wordCount ~/ _wordCount) + w2) % _wordCount;
      words.add(moneroEnglishWords[w1]);
      words.add(moneroEnglishWords[w2]);
      words.add(moneroEnglishWords[w3]);
    }

    // 25th word = checksum
    words.add(_checksumWord(words));
    return words;
  }

  static Uint8List decode(List<String> words) {
    if (words.length != 25) {
      throw ArgumentError('Mnemonic must be 25 words, got ${words.length}');
    }

    final seedWords = words.sublist(0, 24);
    final checksumWord = words[24];

    if (_checksumWord(seedWords) != checksumWord) {
      throw ArgumentError('Invalid mnemonic checksum');
    }

    final key = Uint8List(32);
    final bd = ByteData.sublistView(key);

    for (var i = 0; i < 8; i++) {
      final w1 = _indexOf(seedWords[i * 3]);
      final w2 = _indexOf(seedWords[i * 3 + 1]);
      final w3 = _indexOf(seedWords[i * 3 + 2]);

      final a = w1;
      final b = (w2 - w1 + _wordCount) % _wordCount;
      final c = (w3 - w2 + _wordCount) % _wordCount;
      final value = a + _wordCount * (b + _wordCount * c);

      bd.setUint32(i * 4, value, Endian.little);
    }

    return key;
  }

  static bool isValid(List<String> words) {
    if (words.length != 25) return false;
    try {
      final seedWords = words.sublist(0, 24);
      for (final w in seedWords) {
        _indexOf(w);
      }
      return _checksumWord(seedWords) == words[24];
    } catch (_) {
      return false;
    }
  }

  static int _indexOf(String word) {
    final idx = moneroEnglishWords.indexOf(word);
    if (idx < 0) {
      throw ArgumentError('Word "$word" is not in the Monero English wordlist');
    }
    return idx;
  }

  static String _trimmed(String word) =>
      word.length > _prefixLen ? word.substring(0, _prefixLen) : word;

  static String _checksumWord(List<String> words) {
    final trimmed = words.map(_trimmed).join();
    final crc = _crc32(trimmed);
    return words[crc % 24];
  }

  static int _crc32(String input) {
    var crc = 0xFFFFFFFF;
    for (var i = 0; i < input.length; i++) {
      crc ^= input.codeUnitAt(i);
      for (var j = 0; j < 8; j++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
