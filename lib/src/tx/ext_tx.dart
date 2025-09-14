import 'dart:typed_data';
import '../core/hex.dart';
import '../core/wire.dart';
import '../hash/digest.dart';
import 'inputs/tx_input.dart';
import 'tx_output.dart';
import 'tx.dart';

class ExTx extends Tx {
  final Uint8List payload;

  ExTx({
    super.version,
    required super.inputs,
    required super.outputs,
    super.locktime,
    Uint8List? payload,
  }) : payload = payload ?? Uint8List(0);

  bool get hasPayload => payload.isNotEmpty;

  int get txType => version & 0xffff;

  int get txExtraVersion => (version >> 16) & 0xffff;

  ExTx copyWith({
    int? version,
    List<TxInput>? inputs,
    List<TxOutput>? outputs,
    int? locktime,
    Uint8List? payload,
  }) => ExTx(
    version: version ?? this.version,
    inputs: inputs ?? this.inputs,
    outputs: outputs ?? this.outputs,
    locktime: locktime ?? this.locktime,
    payload: payload ?? this.payload,
  );

  ExTx addInput(TxInput input) => copyWith(
    inputs: [...inputs, input],
  );

  ExTx addOutput(TxOutput output) => copyWith(
    outputs: [...outputs, output],
  );

  ExTx setPayload(Uint8List newPayload) => copyWith(
    payload: newPayload,
  );

  @override
  String get txid {
    final measure = WireMeasure();
    _writeForTxid(measure);
    final bytes = Uint8List(measure.size);
    _writeForTxid(WireWriter(bytes));
    final hash = sha256d(bytes);
    return hexEncode(Uint8List.fromList(hash.reversed.toList()));
  }

  @override
  void writeTo(WireWriting writer) {
    super.writeTo(writer);
    if (hasPayload) {
      writer.writeVarSlice(payload);
    }
  }

  void _writeForTxid(WireWriting writer) {
    writer.writeInt32(version);
    writer.writeVarInt(BigInt.from(inputs.length));
    for (final input in inputs) {
      input.writeTo(writer);
    }
    writer.writeVarInt(BigInt.from(outputs.length));
    for (final output in outputs) {
      output.writeTo(writer);
    }
    writer.writeUInt32(locktime);
    if (hasPayload) {
      writer.writeVarSlice(payload);
    }
  }
}
