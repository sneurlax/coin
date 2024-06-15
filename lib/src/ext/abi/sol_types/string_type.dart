import 'dart:convert';
import 'dart:typed_data';

import '../sol_type.dart';

class SolString extends SolType {
  @override
  String get name => 'string';

  @override
  bool get isDynamic => true;

  @override
  Uint8List encode(dynamic value) {
    if (value is! String) {
      throw ArgumentError('Expected String, got ${value.runtimeType}');
    }
    final bytes = Uint8List.fromList(utf8.encode(value));
    final paddedLen = _padTo32(bytes.length);
    final out = Uint8List(32 + paddedLen);
    _writeUint256(out, 0, BigInt.from(bytes.length));
    out.setRange(32, 32 + bytes.length, bytes);
    return out;
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    final length = _readUint256(data, offset).toInt();
    final strBytes = data.sublist(offset + 32, offset + 32 + length);
    final consumed = 32 + _padTo32(length);
    return (utf8.decode(strBytes), consumed);
  }

  static int _padTo32(int len) => (len + 31) & ~31;

  static void _writeUint256(Uint8List out, int offset, BigInt value) {
    var v = value;
    for (var i = 31; i >= 0; i--) {
      out[offset + i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
  }

  static BigInt _readUint256(Uint8List data, int offset) {
    var result = BigInt.zero;
    for (var i = 0; i < 32; i++) {
      result = (result << 8) | BigInt.from(data[offset + i]);
    }
    return result;
  }
}
