import 'dart:typed_data';
import '../opcodes.dart';
import '../operations.dart';
import '../script.dart';
import '../locking.dart';

/// Generic witness program (version 0-16).
class PayToWitness implements Locking {
  final int version;
  final Uint8List program;

  PayToWitness(this.version, this.program) {
    if (version < 0 || version > 16) {
      throw ArgumentError('Witness version must be 0-16');
    }
    if (program.length < 2 || program.length > 40) {
      throw ArgumentError('Witness program must be 2-40 bytes');
    }
  }

  static PayToWitness? match(Script s) {
    if (s.ops.length != 2) return null;
    final first = s.ops[0];
    if (first is! OpCode) return null;
    int version;
    if (first.code == Op.op0) {
      version = 0;
    } else if (first.code >= Op.op1 && first.code <= Op.op16) {
      version = first.code - Op.op1 + 1;
    } else {
      return null;
    }
    if (s.ops[1] is! PushData) return null;
    final program = (s.ops[1] as PushData).data;
    if (program.length < 2 || program.length > 40) return null;
    return PayToWitness(version, program);
  }

  @override
  Script get script => Script([
        OpCode(version == 0 ? Op.op0 : Op.numberOp(version)),
        PushData(program),
      ]);

  @override
  Uint8List get compiled => script.compiled;
}
