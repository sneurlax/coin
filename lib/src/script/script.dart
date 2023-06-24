import 'dart:typed_data';

import '../core/hex.dart';
import 'opcodes.dart';
import 'operations.dart';

class Script {
  final List<ScriptOp> ops;

  Script(this.ops);

  factory Script.decompile(Uint8List bytes) {
    final ops = <ScriptOp>[];
    var i = 0;
    while (i < bytes.length) {
      final opcode = bytes[i++];

      if (opcode == Op.op0) {
        ops.add(PushData(Uint8List(0)));
      } else if (opcode >= 1 && opcode <= 75) {
        if (i + opcode > bytes.length) break;
        ops.add(PushData(Uint8List.fromList(bytes.sublist(i, i + opcode))));
        i += opcode;
      } else if (opcode == Op.pushData1) {
        if (i >= bytes.length) break;
        final len = bytes[i++];
        if (i + len > bytes.length) break;
        ops.add(PushData(Uint8List.fromList(bytes.sublist(i, i + len))));
        i += len;
      } else if (opcode == Op.pushData2) {
        if (i + 2 > bytes.length) break;
        final len = bytes[i] | (bytes[i + 1] << 8);
        i += 2;
        if (i + len > bytes.length) break;
        ops.add(PushData(Uint8List.fromList(bytes.sublist(i, i + len))));
        i += len;
      } else if (opcode == Op.pushData4) {
        if (i + 4 > bytes.length) break;
        final len = bytes[i] | (bytes[i + 1] << 8) |
            (bytes[i + 2] << 16) | (bytes[i + 3] << 24);
        i += 4;
        if (i + len > bytes.length) break;
        ops.add(PushData(Uint8List.fromList(bytes.sublist(i, i + len))));
        i += len;
      } else if (opcode >= Op.op1 && opcode <= Op.op16) {
        ops.add(OpCode(opcode));
      } else {
        ops.add(OpCode(opcode));
      }
    }
    return Script(ops);
  }

  factory Script.fromAsm(String asm) {
    final tokens = asm.trim().split(RegExp(r'\s+'));
    final ops = <ScriptOp>[];
    for (final token in tokens) {
      if (token.isEmpty) continue;
      final opcode = _asmToOpcode[token.toUpperCase()];
      if (opcode != null) {
        ops.add(OpCode(opcode));
      } else {
        ops.add(PushData(hexDecode(token)));
      }
    }
    return Script(ops);
  }

  Uint8List get compiled {
    final parts = <int>[];
    for (final op in ops) {
      parts.addAll(op.compile());
    }
    return Uint8List.fromList(parts);
  }

  String get asm => ops.map((o) => o.asm).join(' ');

  bool match(Script pattern) {
    if (ops.length != pattern.ops.length) return false;
    for (var i = 0; i < ops.length; i++) {
      final p = pattern.ops[i];
      final o = ops[i];
      if (p is PushDataMatcher) {
        if (!p.matches(o)) return false;
      } else if (p != o) {
        return false;
      }
    }
    return true;
  }

  Script fill(List<Uint8List> values) {
    var vi = 0;
    final filled = <ScriptOp>[];
    for (final op in ops) {
      if (op is PushDataMatcher) {
        if (vi >= values.length) {
          throw ArgumentError('Not enough values to fill script');
        }
        filled.add(PushData(values[vi++]));
      } else {
        filled.add(op);
      }
    }
    return Script(filled);
  }

  static final Map<String, int> _asmToOpcode = {
    for (final entry in Op.names.entries) entry.value: entry.key,
  };
}
