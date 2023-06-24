import 'dart:typed_data';
import '../core/hex.dart';
import 'opcodes.dart';

abstract class ScriptOp {
  Uint8List compile();
  String get asm;
}

class OpCode extends ScriptOp {
  final int code;
  OpCode(this.code);

  @override
  Uint8List compile() => Uint8List.fromList([code]);

  @override
  String get asm => Op.name(code);

  @override
  bool operator ==(Object other) => other is OpCode && code == other.code;

  @override
  int get hashCode => code;
}

class PushData extends ScriptOp {
  final Uint8List data;
  PushData(this.data);

  @override
  Uint8List compile() {
    final len = data.length;
    if (len == 0) return Uint8List.fromList([Op.op0]);
    if (len == 1 && data[0] >= 1 && data[0] <= 16) {
      return Uint8List.fromList([Op.numberOp(data[0])]);
    }
    if (len <= 75) {
      return Uint8List.fromList([len, ...data]);
    }
    if (len <= 255) {
      return Uint8List.fromList([Op.pushData1, len, ...data]);
    }
    if (len <= 65535) {
      return Uint8List.fromList([
        Op.pushData2,
        len & 0xff, (len >> 8) & 0xff,
        ...data,
      ]);
    }
    return Uint8List.fromList([
      Op.pushData4,
      len & 0xff, (len >> 8) & 0xff, (len >> 16) & 0xff, (len >> 24) & 0xff,
      ...data,
    ]);
  }

  @override
  String get asm => hexEncode(data);

  @override
  bool operator ==(Object other) {
    if (other is! PushData) return false;
    if (data.length != other.data.length) return false;
    for (var i = 0; i < data.length; i++) {
      if (data[i] != other.data[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(data);
}

/// Matches any push of a given size, for pattern matching against scripts.
class PushDataMatcher extends ScriptOp {
  final int size;
  PushDataMatcher(this.size);

  @override
  Uint8List compile() => throw UnsupportedError('Cannot compile a matcher');

  @override
  String get asm => '<$size>';

  bool matches(ScriptOp other) =>
      other is PushData && other.data.length == size;
}
