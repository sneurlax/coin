import 'dart:typed_data';
import 'sighash_type.dart';
import '../tx.dart';

abstract class SigHasher {
  Uint8List hash(Tx tx, int inputIndex, SigHashType hashType,
      {Uint8List? prevScript, BigInt? amount});
}
