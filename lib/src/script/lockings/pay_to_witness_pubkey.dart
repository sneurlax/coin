import 'dart:typed_data';
import '../opcodes.dart';
import '../operations.dart';
import '../script.dart';
import '../locking.dart';

/// P2WPKH: OP_0 <20>
class PayToWitnessPubKey implements Locking {
  final Uint8List pubKeyHash;

  PayToWitnessPubKey(this.pubKeyHash) {
    if (pubKeyHash.length != 20) {
      throw ArgumentError('P2WPKH hash must be 20 bytes');
    }
  }

  static final _pattern = Script([
    OpCode(Op.op0),
    PushDataMatcher(20),
  ]);

  static PayToWitnessPubKey? match(Script s) {
    if (s.ops.length != 2) return null;
    if (s.ops[0] is! OpCode || (s.ops[0] as OpCode).code != Op.op0) return null;
    if (s.ops[1] is! PushData || (s.ops[1] as PushData).data.length != 20) {
      return null;
    }
    return PayToWitnessPubKey((s.ops[1] as PushData).data);
  }

  @override
  Script get script => Script([
        OpCode(Op.op0),
        PushData(pubKeyHash),
      ]);

  @override
  Uint8List get compiled => script.compiled;
}
