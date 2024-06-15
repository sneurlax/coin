import 'dart:typed_data';

import '../sol_type.dart';

class SolInt extends SolType {
  final int bits;

  SolInt(this.bits) {
    if (bits <= 0 || bits > 256 || bits % 8 != 0) {
      throw ArgumentError('int bits must be a multiple of 8 in [8..256], got $bits');
    }
  }

  factory SolInt.int256() => SolInt(256);

  @override
  String get name => 'int$bits';

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

    final minVal = -(BigInt.one << (bits - 1));
    final maxVal = (BigInt.one << (bits - 1)) - BigInt.one;
    if (v < minVal || v > maxVal) {
      throw ArgumentError('Value $v out of int$bits range [$minVal..$maxVal]');
    }

    // Two's complement into 256-bit slot.
    final encoded = v < BigInt.zero ? (BigInt.one << 256) + v : v;
    return _bigIntToBytes32(encoded);
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    final slice = data.sublist(offset, offset + 32);
    var raw = BigInt.zero;
    for (final b in slice) {
      raw = (raw << 8) | BigInt.from(b);
    }

    final mask = (BigInt.one << bits) - BigInt.one;
    raw = raw & mask;

    // Sign-extend if high bit set.
    if (raw >= (BigInt.one << (bits - 1))) {
      raw = raw - (BigInt.one << bits);
    }
    return (raw, 32);
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
