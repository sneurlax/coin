import 'dart:typed_data';
import '../core/wire.dart';
import '../script/locking.dart';
import '../script/script.dart';

class TxOutput with Serializable {
  final BigInt value;
  final Uint8List scriptPubKey;
  final Locking? locking;

  TxOutput({
    required this.value,
    required this.scriptPubKey,
    this.locking,
  });

  factory TxOutput.fromLocking(BigInt value, Locking locking) => TxOutput(
        value: value,
        scriptPubKey: locking.compiled,
        locking: locking,
      );

  factory TxOutput.fromReader(WireReader reader) {
    final value = reader.readUInt64();
    final scriptPubKey = reader.readVarSlice();
    return TxOutput(value: value, scriptPubKey: scriptPubKey);
  }

  Script get script => Script.decompile(scriptPubKey);

  @override
  void writeTo(WireWriting writer) {
    writer.writeUInt64(value);
    writer.writeVarSlice(scriptPubKey);
  }
}
