import 'dart:typed_data';

/// Recursive Length Prefix encoding for EVM.
class Rlp {
  Rlp._();

  static Uint8List encode(dynamic data) {
    if (data is Uint8List) return _encodeBytes(data);
    if (data is List) return _encodeList(data);
    if (data is int) return _encodeBytes(_intToMinBytes(data));
    if (data is BigInt) return _encodeBytes(_bigIntToMinBytes(data));
    if (data is String) return _encodeBytes(Uint8List.fromList(data.codeUnits));
    if (data == null) return _encodeBytes(Uint8List(0));
    throw ArgumentError('Unsupported RLP type: ${data.runtimeType}');
  }

  static dynamic decode(Uint8List data) {
    final (result, _) = _decode(data, 0);
    return result;
  }

  static Uint8List _encodeBytes(Uint8List bytes) {
    if (bytes.length == 1 && bytes[0] <= 0x7f) return bytes;
    if (bytes.length <= 55) {
      return Uint8List.fromList([0x80 + bytes.length, ...bytes]);
    }
    final lenBytes = _intToMinBytes(bytes.length);
    return Uint8List.fromList([0xb7 + lenBytes.length, ...lenBytes, ...bytes]);
  }

  static Uint8List _encodeList(List items) {
    final encoded = <int>[];
    for (final item in items) {
      encoded.addAll(encode(item));
    }
    if (encoded.length <= 55) {
      return Uint8List.fromList([0xc0 + encoded.length, ...encoded]);
    }
    final lenBytes = _intToMinBytes(encoded.length);
    return Uint8List.fromList([0xf7 + lenBytes.length, ...lenBytes, ...encoded]);
  }

  static (dynamic, int) _decode(Uint8List data, int offset) {
    final prefix = data[offset];

    if (prefix <= 0x7f) {
      return (Uint8List.fromList([prefix]), offset + 1);
    }

    if (prefix <= 0xb7) {
      final len = prefix - 0x80;
      return (data.sublist(offset + 1, offset + 1 + len), offset + 1 + len);
    }

    if (prefix <= 0xbf) {
      final lenOfLen = prefix - 0xb7;
      final len = _bytesToInt(data.sublist(offset + 1, offset + 1 + lenOfLen));
      final start = offset + 1 + lenOfLen;
      return (data.sublist(start, start + len), start + len);
    }

    if (prefix <= 0xf7) {
      final len = prefix - 0xc0;
      return _decodeList(data, offset + 1, offset + 1 + len);
    }

    final lenOfLen = prefix - 0xf7;
    final len = _bytesToInt(data.sublist(offset + 1, offset + 1 + lenOfLen));
    final start = offset + 1 + lenOfLen;
    return _decodeList(data, start, start + len);
  }

  static (List, int) _decodeList(Uint8List data, int start, int end) {
    final items = <dynamic>[];
    var pos = start;
    while (pos < end) {
      final (item, newPos) = _decode(data, pos);
      items.add(item);
      pos = newPos;
    }
    return (items, end);
  }

  static Uint8List _intToMinBytes(int value) {
    if (value == 0) return Uint8List(0);
    final bytes = <int>[];
    var v = value;
    while (v > 0) {
      bytes.insert(0, v & 0xff);
      v >>= 8;
    }
    return Uint8List.fromList(bytes);
  }

  static Uint8List _bigIntToMinBytes(BigInt value) {
    if (value == BigInt.zero) return Uint8List(0);
    final bytes = <int>[];
    var v = value;
    while (v > BigInt.zero) {
      bytes.insert(0, (v & BigInt.from(0xff)).toInt());
      v >>= 8;
    }
    return Uint8List.fromList(bytes);
  }

  static int _bytesToInt(Uint8List bytes) {
    var result = 0;
    for (final b in bytes) {
      result = (result << 8) | b;
    }
    return result;
  }
}
