import 'dart:typed_data';

import '../sol_type.dart';

class SolBool extends SolType {
  @override
  String get name => 'bool';

  @override
  bool get isDynamic => false;

  @override
  Uint8List encode(dynamic value) {
    if (value is! bool) {
      throw ArgumentError('Expected bool, got ${value.runtimeType}');
    }
    final out = Uint8List(32);
    out[31] = value ? 1 : 0;
    return out;
  }

  @override
  (dynamic, int) decode(Uint8List data, int offset) {
    final val = data[offset + 31] != 0;
    return (val, 32);
  }
}
