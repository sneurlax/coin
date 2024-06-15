import 'dart:typed_data';

import '../../../core/hex.dart';
import '../sol_type.dart';

/// 20 bytes, left-padded to 32.
class SolAddress extends SolType {
  @override
  String get name => 'address';

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
    if (bytes.length != 20) {
      throw ArgumentError('Address must be 20 bytes, got ${bytes.length}');
    }
    final out = Uint8List(32);
    out.setRange(12, 32, bytes);
    return out;
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    final addr = data.sublist(offset + 12, offset + 32);
    return (addr, 32);
  }
}
