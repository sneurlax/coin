import 'dart:typed_data';
import '../core/hex.dart';
import '../core/wire.dart';
import '../hash/digest.dart';
import 'inputs/tx_input.dart';
import 'tx_output.dart';

class Tx with Serializable {
  static const int currentVersion = 2;
  static const int maxSize = 1000000;

  final int version;
  final List<TxInput> inputs;
  final List<TxOutput> outputs;
  final int locktime;

  Tx({
    this.version = currentVersion,
    required this.inputs,
    required this.outputs,
    this.locktime = 0,
  });

  factory Tx.fromBytes(Uint8List bytes) =>
      Tx.fromReader(WireReader(bytes));

  factory Tx.fromHex(String hex) => Tx.fromBytes(hexDecode(hex));

  factory Tx.fromReader(WireReader reader) {
    final version = reader.readInt32();
    var marker = reader.readUInt8();
    var flag = 0;
    var isWitness = false;

    if (marker == 0x00) {
      flag = reader.readUInt8();
      if (flag != 0x01) throw FormatException('Invalid witness flag');
      isWitness = true;
      marker = reader.readVarInt().toInt();
    }

    final inputCount = isWitness
        ? marker
        : (marker < 0xfd
            ? marker
            : (marker == 0xfd
                ? reader.readUInt16()
                : reader.readUInt32()));

    final inputs = <TxInput>[];
    for (var i = 0; i < inputCount; i++) {
      inputs.add(RawInput.fromReader(reader));
    }

    final outputCount = reader.readVarInt().toInt();
    final outputs = <TxOutput>[];
    for (var i = 0; i < outputCount; i++) {
      outputs.add(TxOutput.fromReader(reader));
    }

    if (isWitness) {
      for (var i = 0; i < inputs.length; i++) {
        reader.readVector(); // witness data (consumed but not stored in RawInput)
      }
    }

    final locktime = reader.readUInt32();

    return Tx(
      version: version,
      inputs: inputs,
      outputs: outputs,
      locktime: locktime,
    );
  }

  bool get isWitness => inputs.any((i) => i.witness.isNotEmpty);

  bool get complete => inputs.every((i) => i.complete);

  String get txid {
    // Non-witness serialization, double-SHA256, reversed
    final measure = WireMeasure();
    _writeNonWitness(measure);
    final bytes = Uint8List(measure.size);
    _writeNonWitness(WireWriter(bytes));
    final hash = sha256d(bytes);
    return hexEncode(Uint8List.fromList(hash.reversed.toList()));
  }

  @override
  void writeTo(WireWriting writer) {
    final witness = isWitness;
    writer.writeInt32(version);

    if (witness) {
      writer.writeUInt8(0x00); // marker
      writer.writeUInt8(0x01); // flag
    }

    writer.writeVarInt(BigInt.from(inputs.length));
    for (final input in inputs) {
      input.writeTo(writer);
    }

    writer.writeVarInt(BigInt.from(outputs.length));
    for (final output in outputs) {
      output.writeTo(writer);
    }

    if (witness) {
      for (final input in inputs) {
        input.writeWitness(writer);
      }
    }

    writer.writeUInt32(locktime);
  }

  void _writeNonWitness(WireWriting writer) {
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
  }
}
