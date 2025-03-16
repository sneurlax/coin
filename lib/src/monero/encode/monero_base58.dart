import 'dart:typed_data';

import '../../crypto/vault_keeper.dart';

const String _alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

final Map<int, int> _alphabetMap = () {
  final map = <int, int>{};
  for (var i = 0; i < _alphabet.length; i++) {
    map[_alphabet.codeUnitAt(i)] = i;
  }
  return map;
}();

// Chars per block of N bytes (index 0 unused). 8 bytes -> 11 chars.
const List<int> _encodedBlockSizes = [0, 2, 3, 5, 6, 7, 9, 10, 11];
const int _fullBlockSize = 8;
const int _fullEncodedBlockSize = 11;

final Map<int, int> _decodedBlockSizes = () {
  final map = <int, int>{};
  for (var i = 1; i < _encodedBlockSizes.length; i++) {
    map[_encodedBlockSizes[i]] = i;
  }
  return map;
}();

String _encodeBlock(Uint8List block) {
  final charCount = _encodedBlockSizes[block.length];
  var num = BigInt.zero;
  for (var i = 0; i < block.length; i++) {
    num = (num << 8) | BigInt.from(block[i]);
  }

  final digits = <int>[];
  while (num > BigInt.zero) {
    digits.add((num % BigInt.from(58)).toInt());
    num = num ~/ BigInt.from(58);
  }
  while (digits.length < charCount) {
    digits.add(0);
  }
  final buf = StringBuffer();
  for (var i = digits.length - 1; i >= 0; i--) {
    buf.write(_alphabet[digits[i]]);
  }
  return buf.toString();
}

Uint8List _decodeBlock(String encoded) {
  final byteCount = _decodedBlockSizes[encoded.length];
  if (byteCount == null) {
    throw FormatException(
        'Invalid Monero base58 block length: ${encoded.length}');
  }

  var num = BigInt.zero;
  for (var i = 0; i < encoded.length; i++) {
    final digit = _alphabetMap[encoded.codeUnitAt(i)];
    if (digit == null) {
      throw FormatException(
          'Invalid base58 character: "${encoded[i]}" at position $i');
    }
    num = num * BigInt.from(58) + BigInt.from(digit);
  }

  final bytes = Uint8List(byteCount);
  for (var i = byteCount - 1; i >= 0; i--) {
    bytes[i] = (num & BigInt.from(0xff)).toInt();
    num = num >> 8;
  }

  if (num != BigInt.zero) {
    throw const FormatException('Monero base58 block value overflow');
  }

  return bytes;
}

/// Monero's block-based base58: input split into 8-byte blocks, each
/// independently encoded to a fixed number of base58 chars.
String moneroBase58Encode(Uint8List data) {
  if (data.isEmpty) return '';

  final buf = StringBuffer();
  final fullBlocks = data.length ~/ _fullBlockSize;
  final remainder = data.length % _fullBlockSize;

  for (var i = 0; i < fullBlocks; i++) {
    final start = i * _fullBlockSize;
    buf.write(_encodeBlock(
        Uint8List.sublistView(data, start, start + _fullBlockSize)));
  }

  if (remainder > 0) {
    final start = fullBlocks * _fullBlockSize;
    buf.write(
        _encodeBlock(Uint8List.sublistView(data, start, start + remainder)));
  }

  return buf.toString();
}

Uint8List moneroBase58Decode(String encoded) {
  if (encoded.isEmpty) return Uint8List(0);

  final fullBlocks = encoded.length ~/ _fullEncodedBlockSize;
  final remainderChars = encoded.length % _fullEncodedBlockSize;

  if (remainderChars != 0 && !_decodedBlockSizes.containsKey(remainderChars)) {
    throw FormatException(
        'Invalid Monero base58 string length: ${encoded.length}');
  }

  final remainderBytes =
      remainderChars > 0 ? _decodedBlockSizes[remainderChars]! : 0;
  final totalBytes = fullBlocks * _fullBlockSize + remainderBytes;
  final result = Uint8List(totalBytes);
  var offset = 0;

  for (var i = 0; i < fullBlocks; i++) {
    final start = i * _fullEncodedBlockSize;
    final block = _decodeBlock(
        encoded.substring(start, start + _fullEncodedBlockSize));
    result.setRange(offset, offset + _fullBlockSize, block);
    offset += _fullBlockSize;
  }

  if (remainderChars > 0) {
    final start = fullBlocks * _fullEncodedBlockSize;
    final block = _decodeBlock(encoded.substring(start));
    result.setRange(offset, offset + remainderBytes, block);
  }

  return result;
}

Uint8List moneroChecksum(Uint8List data) {
  final hash = VaultKeeper.vault.digest.keccak256(data);
  return Uint8List.sublistView(hash, 0, 4);
}
