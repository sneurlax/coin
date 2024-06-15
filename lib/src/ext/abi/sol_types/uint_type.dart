import 'dart:typed_data';

import '../sol_type.dart';

class SolUint extends SolType {
  final int bits;

  SolUint(this.bits) {
    if (bits <= 0 || bits > 256 || bits % 8 != 0) {
      throw ArgumentError('uint bits must be a multiple of 8 in [8..256], got $bits');
    }
  }

  factory SolUint.uint256() => SolUint(256);

  @override
  String get name => 'uint$bits';

  @override
  bool get isDynamic => false;

  @override
  Uint8List encode(dynamic value) {
    final BigInt v;
    if (value is BigInt) {
      v = value;
    } else if (value is int) {
      v = BigInt.from(value);
    } else {
      throw ArgumentError('Expected int or BigInt, got ${value.runtimeType}');
    }

    if (v < BigInt.zero) {
      throw ArgumentError('uint$bits cannot encode negative value: $v');
    }
    final maxVal = (BigInt.one << bits) - BigInt.one;
    if (v > maxVal) {
      throw ArgumentError('Value $v exceeds uint$bits max ($maxVal)');
    }

    return _bigIntToBytes32(v);
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    final slice = data.sublist(offset, offset + 32);
    var result = BigInt.zero;
    for (final b in slice) {
      result = (result << 8) | BigInt.from(b);
    }
    final mask = (BigInt.one << bits) - BigInt.one;
    result = result & mask;
    return (result, 32);
  }

  static Uint8List _bigIntToBytes32(BigInt value) {
    final out = Uint8List(32);
    var v = value;
    for (var i = 31; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
    return out;
  }
}
