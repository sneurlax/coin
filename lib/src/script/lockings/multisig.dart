import 'dart:typed_data';
import '../opcodes.dart';
import '../operations.dart';
import '../script.dart';
import '../locking.dart';

/// M-of-N multisig: OP_M <keys...> OP_N OP_CHECKMULTISIG
class MultiSig implements Locking {
  final int threshold;
  final List<Uint8List> publicKeys;

  MultiSig({required this.threshold, required this.publicKeys}) {
    if (threshold < 1 || threshold > publicKeys.length) {
      throw ArgumentError('Invalid threshold');
    }
    if (publicKeys.length > 20) {
      throw ArgumentError('Too many public keys');
    }
  }

  @override
  Script get script => Script([
        OpCode(Op.numberOp(threshold)),
        ...publicKeys.map((k) => PushData(k)),
        OpCode(Op.numberOp(publicKeys.length)),
        OpCode(Op.checkMultiSig),
      ]);

  @override
  Uint8List get compiled => script.compiled;
}
