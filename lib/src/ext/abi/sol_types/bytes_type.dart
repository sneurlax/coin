import 'dart:typed_data';

import '../../../core/hex.dart';
import '../sol_type.dart';

/// Fixed-size `bytes1` .. `bytes32`.
class SolFixedBytes extends SolType {
  final int length;

  SolFixedBytes(this.length) {
    if (length <= 0 || length > 32) {
      throw ArgumentError('bytes length must be in [1..32], got $length');
    }
  }

  @override
  String get name => 'bytes$length';

  @override
  bool get isDynamic => false;

  @override
  Uint8List encode(dynamic value) {
    Uint8List bytes;
    if (value is Uint8List) {
      bytes = value;
    } else if (value is String) {
      bytes = hexDecode(value);
    } else {
      throw ArgumentError('Expected Uint8List or hex String, got ${value.runtimeType}');
    }
    if (bytes.length != length) {
      throw ArgumentError('bytes$length expects $length bytes, got ${bytes.length}');
    }
    // Right-padded to 32 bytes (per ABI spec, unlike address which is left-padded).
    final out = Uint8List(32);
    out.setRange(0, length, bytes);
    return out;
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    final bytes = Uint8List.fromList(data.sublist(offset, offset + length));
    return (bytes, 32);
  }
}

/// Dynamic `bytes`.
class SolBytes extends SolType {
  @override
  String get name => 'bytes';

  @override
  bool get isDynamic => true;

  @override
  Uint8List encode(dynamic value) {
    Uint8List bytes;
    if (value is Uint8List) {
      bytes = value;
    } else if (value is String) {
      bytes = hexDecode(value);
    } else {
      throw ArgumentError('Expected Uint8List or hex String, got ${value.runtimeType}');
    }

    // Length prefix (32 bytes) + data padded to 32-byte boundary.
    final paddedLen = _padTo32(bytes.length);
    final out = Uint8List(32 + paddedLen);
    _writeUint256(out, 0, BigInt.from(bytes.length));
    out.setRange(32, 32 + bytes.length, bytes);
    return out;
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    final length = _readUint256(data, offset).toInt();
    final bytes = Uint8List.fromList(data.sublist(offset + 32, offset + 32 + length));
    final consumed = 32 + _padTo32(length);
    return (bytes, consumed);
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
