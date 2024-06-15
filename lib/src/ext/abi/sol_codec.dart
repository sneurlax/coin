import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../core/hex.dart';
import '../../hash/digest.dart';
import 'sol_type.dart';
import 'sol_types/tuple_type.dart';

class SolCodec {
  SolCodec._();

  static Uint8List selector(String signature) {
    final hash = keccak256(Uint8List.fromList(signature.codeUnits));
    return hash.sublist(0, 4);
  }

  static Uint8List encodeCall(
    String sig,
    List<SolType> types,
    List<dynamic> values,
  ) {
    final sel = selector(sig);
    final encoded = SolTuple.encodeTuple(types, values);
    return concatBytes([sel, encoded]);
  }

  static List<dynamic> decodeResult(List<SolType> types, Uint8List data) {
    final (values, _) = SolTuple.decodeTuple(types, data, 0);
    return values;
  }

  static Uint8List encodeParameters(
      List<SolType> types, List<dynamic> values) {
    return SolTuple.encodeTuple(types, values);
  }

  static List<dynamic> decodeParameters(
      List<SolType> types, Uint8List data) {
    final (values, _) = SolTuple.decodeTuple(types, data, 0);
    return values;
  }

  /// Non-standard tight packing (`abi.encodePacked`).
  /// Static types use native width (no padding), dynamic types have no length
  /// prefix, arrays are packed element-by-element.
  static Uint8List encodePacked(List<SolType> types, List<dynamic> values) {
    if (types.length != values.length) {
      throw ArgumentError(
          'types.length (${types.length}) != values.length (${values.length})');
    }

    final parts = <Uint8List>[];
    for (var i = 0; i < types.length; i++) {
      parts.add(_packSingle(types[i], values[i]));
    }
    return concatBytes(parts);
  }

  static Uint8List _packSingle(SolType type, dynamic value) {
    final n = type.name;

    if (n == 'address') {
      if (value is String) return hexDecode(value);
      return (value as Uint8List).sublist(value.length - 20);
    }

    if (n == 'bool') {
      return Uint8List.fromList([value == true ? 1 : 0]);
    }

    if (n == 'string') {
      return Uint8List.fromList((value as String).codeUnits);
    }

    if (n == 'bytes') {
      if (value is Uint8List) return value;
      return hexDecode(value as String);
    }

    if (n.startsWith('bytes') && !type.isDynamic) {
      final len = int.parse(n.substring(5));
      if (value is Uint8List) return value.sublist(0, len);
      return hexDecode(value as String).sublist(0, len);
    }

    if (n.startsWith('uint')) {
      final bits = int.parse(n.substring(4));
      final byteLen = bits ~/ 8;
      final v = value is BigInt ? value : BigInt.from(value as int);
      return _bigIntToBytesBE(v, byteLen);
    }

    if (n.startsWith('int')) {
      final bits = int.parse(n.substring(3));
      final byteLen = bits ~/ 8;
      var v = value is BigInt ? value : BigInt.from(value as int);
      if (v < BigInt.zero) v = (BigInt.one << bits) + v;
      return _bigIntToBytesBE(v, byteLen);
    }

    return type.encode(value);
  }

  static Uint8List _bigIntToBytesBE(BigInt value, int length) {
    final out = Uint8List(length);
    var v = value;
    for (var i = length - 1; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
    return out;
  }
}
