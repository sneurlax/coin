import 'dart:typed_data';
import '../opcodes.dart';
import '../operations.dart';
import '../script.dart';
import '../locking.dart';

/// P2PKH: OP_DUP OP_HASH160 <20> OP_EQUALVERIFY OP_CHECKSIG
class PayToPubKeyHash implements Locking {
  final Uint8List pubKeyHash;

  PayToPubKeyHash(this.pubKeyHash) {
    if (pubKeyHash.length != 20) {
      throw ArgumentError('P2PKH hash must be 20 bytes');
    }
  }

  static final _pattern = Script([
    OpCode(Op.dup),
    OpCode(Op.hash160),
    PushDataMatcher(20),
    OpCode(Op.equalVerify),
    OpCode(Op.checkSig),
  ]);

  static PayToPubKeyHash? match(Script s) {
    if (!s.match(_pattern)) return null;
    final hash = (s.ops[2] as PushData).data;
    return PayToPubKeyHash(hash);
  }

  @override
  Script get script => Script([
        OpCode(Op.dup),
        OpCode(Op.hash160),
        PushData(pubKeyHash),
        OpCode(Op.equalVerify),
        OpCode(Op.checkSig),
      ]);

  @override
  Uint8List get compiled => script.compiled;
}
