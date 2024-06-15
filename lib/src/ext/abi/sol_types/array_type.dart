import 'dart:typed_data';

import '../sol_type.dart';

/// Fixed-size `T[N]` or dynamic `T[]`.
class SolArray extends SolType {
  final SolType elementType;

  /// Null for dynamic arrays.
  final int? fixedLength;

  SolArray(this.elementType, [this.fixedLength]) {
    if (fixedLength != null && fixedLength! <= 0) {
      throw ArgumentError('Fixed array length must be > 0');
    }
  }

  @override
  String get name => fixedLength != null
      ? '${elementType.name}[$fixedLength]'
      : '${elementType.name}[]';

  @override
  bool get isDynamic => fixedLength == null || elementType.isDynamic;

  @override
  Uint8List encode(dynamic value) {
    final list = value as List;
    final length = fixedLength ?? list.length;
    if (fixedLength != null && list.length != fixedLength) {
      throw ArgumentError(
          '$name expects $fixedLength elements, got ${list.length}');
    }

    if (!elementType.isDynamic) {
      final parts = <Uint8List>[];
      if (fixedLength == null) {
        parts.add(_uint256(BigInt.from(length)));
      }
      for (var i = 0; i < length; i++) {
        parts.add(elementType.encode(list[i]));
      }
      return _concat(parts);
    }

    // Dynamic elements: offsets in head, data in tail.
    final heads = <Uint8List>[];
    final tails = <Uint8List>[];

    if (fixedLength == null) {
      heads.add(_uint256(BigInt.from(length)));
    }

    var tailOffset = length * 32;
    final encodedItems = <Uint8List>[];
    for (var i = 0; i < length; i++) {
      final encoded = elementType.encode(list[i]);
      encodedItems.add(encoded);
    }
    for (var i = 0; i < length; i++) {
      heads.add(_uint256(BigInt.from(tailOffset)));
      tailOffset += encodedItems[i].length;
      tails.add(encodedItems[i]);
    }

    return _concat([...heads, ...tails]);
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    var pos = offset;
    int length;

    if (fixedLength != null) {
      length = fixedLength!;
    } else {
      length = _readUint256(data, pos).toInt();
      pos += 32;
    }

    final baseOffset = pos;
    final results = <dynamic>[];

    if (!elementType.isDynamic) {
      for (var i = 0; i < length; i++) {
        final (val, consumed) = elementType.decode(data, pos);
        results.add(val);
        pos += consumed;
      }
      return (results, pos - offset);
    }

    final offsets = <int>[];
    for (var i = 0; i < length; i++) {
      offsets.add(_readUint256(data, pos).toInt());
      pos += 32;
    }
    var maxEnd = pos;
    for (var i = 0; i < length; i++) {
      final tailPos = baseOffset + offsets[i];
      final (val, consumed) = elementType.decode(data, tailPos);
      results.add(val);
      final end = tailPos + consumed;
      if (end > maxEnd) maxEnd = end;
    }
    return (results, maxEnd - offset);
  }

  static Uint8List _uint256(BigInt value) {
    final out = Uint8List(32);
    var v = value;
    for (var i = 31; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
    return out;
  }

  static BigInt _readUint256(Uint8List data, int offset) {
    var result = BigInt.zero;
    for (var i = 0; i < 32; i++) {
      result = (result << 8) | BigInt.from(data[offset + i]);
    }
    return result;
  }

  static Uint8List _concat(List<Uint8List> parts) {
    var total = 0;
    for (final p in parts) {
      total += p.length;
    }
    final out = Uint8List(total);
    var off = 0;
    for (final p in parts) {
      out.setAll(off, p);
      off += p.length;
    }
    return out;
  }
}
