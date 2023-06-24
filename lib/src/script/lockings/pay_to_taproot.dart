import 'dart:typed_data';
import '../opcodes.dart';
import '../operations.dart';
import '../script.dart';
import '../locking.dart';

/// P2TR: OP_1 <32>
class PayToTaproot implements Locking {
  final Uint8List outputKey;

  PayToTaproot(this.outputKey) {
    if (outputKey.length != 32) {
      throw ArgumentError('P2TR key must be 32 bytes');
    }
  }

  static PayToTaproot? match(Script s) {
    if (s.ops.length != 2) return null;
    if (s.ops[0] is! OpCode || (s.ops[0] as OpCode).code != Op.op1) return null;
    if (s.ops[1] is! PushData || (s.ops[1] as PushData).data.length != 32) {
      return null;
    }
    return PayToTaproot((s.ops[1] as PushData).data);
  }

  @override
  Script get script => Script([
        OpCode(Op.op1),
        PushData(outputKey),
      ]);

  @override
  Uint8List get compiled => script.compiled;
}
