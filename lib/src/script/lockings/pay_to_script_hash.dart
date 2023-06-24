import 'dart:typed_data';
import '../opcodes.dart';
import '../operations.dart';
import '../script.dart';
import '../locking.dart';

/// P2SH: OP_HASH160 <20> OP_EQUAL
class PayToScriptHash implements Locking {
  final Uint8List scriptHash;

  PayToScriptHash(this.scriptHash) {
    if (scriptHash.length != 20) {
      throw ArgumentError('P2SH hash must be 20 bytes');
    }
  }

  static final _pattern = Script([
    OpCode(Op.hash160),
    PushDataMatcher(20),
    OpCode(Op.equal),
  ]);

  static PayToScriptHash? match(Script s) {
    if (!s.match(_pattern)) return null;
    return PayToScriptHash((s.ops[1] as PushData).data);
  }

  @override
  Script get script => Script([
        OpCode(Op.hash160),
        PushData(scriptHash),
        OpCode(Op.equal),
      ]);

  @override
  Uint8List get compiled => script.compiled;
}
