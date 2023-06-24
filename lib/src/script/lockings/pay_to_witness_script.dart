import 'dart:typed_data';
import '../opcodes.dart';
import '../operations.dart';
import '../script.dart';
import '../locking.dart';

/// P2WSH: OP_0 <32>
class PayToWitnessScript implements Locking {
  final Uint8List scriptHash;

  PayToWitnessScript(this.scriptHash) {
    if (scriptHash.length != 32) {
      throw ArgumentError('P2WSH hash must be 32 bytes');
    }
  }

  static PayToWitnessScript? match(Script s) {
    if (s.ops.length != 2) return null;
    if (s.ops[0] is! OpCode || (s.ops[0] as OpCode).code != Op.op0) return null;
    if (s.ops[1] is! PushData || (s.ops[1] as PushData).data.length != 32) {
      return null;
    }
    return PayToWitnessScript((s.ops[1] as PushData).data);
  }

  @override
  Script get script => Script([
        OpCode(Op.op0),
        PushData(scriptHash),
      ]);

  @override
  Uint8List get compiled => script.compiled;
}
