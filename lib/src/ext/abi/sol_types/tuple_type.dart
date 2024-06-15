import 'dart:typed_data';

import '../sol_type.dart';

class SolTuple extends SolType {
  final List<SolType> components;
  final List<String>? names;

  SolTuple(this.components, {this.names}) {
    if (names != null && names!.length != components.length) {
      throw ArgumentError(
          'names length (${names!.length}) must match components length (${components.length})');
    }
  }

  @override
  String get name {
    final inner = components.map((c) => c.name).join(',');
    return '($inner)';
  }

  @override
  bool get isDynamic => components.any((c) => c.isDynamic);

  @override
  Uint8List encode(dynamic value) {
    final List<dynamic> values;
    if (value is List) {
      values = value;
    } else if (value is Map<String, dynamic> && names != null) {
      values = names!.map((n) => value[n]).toList();
    } else {
      throw ArgumentError('Expected List or Map for tuple encoding');
    }

    if (values.length != components.length) {
      throw ArgumentError(
          'Expected ${components.length} values, got ${values.length}');
    }

    return _encodeTuple(components, values);
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    return _decodeTuple(components, data, offset);
  }

  static Uint8List encodeTuple(List<SolType> types, List<dynamic> values) {
    return _encodeTuple(types, values);
  }

  static (List<dynamic>, int) decodeTuple(
      List<SolType> types, Uint8List data, int offset) {
    return _decodeTuple(types, data, offset);
  }

  static Uint8List _encodeTuple(List<SolType> types, List<dynamic> values) {
    // Head = encoded value (static) or offset (dynamic). Tail = dynamic data.
    final heads = <Uint8List?>[];
    final tails = <Uint8List>[];
    final encoded = <Uint8List>[];

    for (var i = 0; i < types.length; i++) {
      encoded.add(types[i].encode(values[i]));
    }

    var tailOffset = types.length * 32;

    for (var i = 0; i < types.length; i++) {
      if (!types[i].isDynamic) {
        heads.add(encoded[i]);
      } else {
        heads.add(_uint256(BigInt.from(tailOffset)));
        tails.add(encoded[i]);
        tailOffset += encoded[i].length;
      }
    }

    final parts = <Uint8List>[
      for (final h in heads) h!,
      ...tails,
    ];
    return _concat(parts);
  }

  static (List<dynamic>, int) _decodeTuple(
      List<SolType> types, Uint8List data, int offset) {
    final values = <dynamic>[];
    final baseOffset = offset;
    var headPos = offset;
    var maxEnd = offset + types.length * 32;

    for (var i = 0; i < types.length; i++) {
      if (!types[i].isDynamic) {
        final (val, _) = types[i].decode(data, headPos);
        values.add(val);
        headPos += 32;
      } else {
        final dataOffset = _readUint256(data, headPos).toInt();
        final (val, consumed) = types[i].decode(data, baseOffset + dataOffset);
        values.add(val);
        headPos += 32;
        final end = baseOffset + dataOffset + consumed;
        if (end > maxEnd) maxEnd = end;
      }
    }

    return (values, maxEnd - offset);
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
