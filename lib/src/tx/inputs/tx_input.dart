import 'dart:typed_data';
import '../../core/wire.dart';
import '../outpoint.dart';

abstract class TxInput {
  static const int sequenceFinal = 0xffffffff;

  Outpoint get prevOut;
  Uint8List get scriptSig;
  int get sequence;
  List<Uint8List> get witness;
  bool get complete;
  int get signedSize;

  void writeTo(WireWriting writer) {
    prevOut.writeTo(writer);
    writer.writeVarSlice(scriptSig);
    writer.writeUInt32(sequence);
  }

  void writeWitness(WireWriting writer) {
    writer.writeVector(witness);
  }
}

class RawInput extends TxInput {
  @override
  final Outpoint prevOut;
  @override
  final Uint8List scriptSig;
  @override
  final int sequence;

  RawInput({
    required this.prevOut,
    Uint8List? scriptSig,
    this.sequence = TxInput.sequenceFinal,
  }) : scriptSig = scriptSig ?? Uint8List(0);

  factory RawInput.fromReader(WireReader reader) => RawInput(
        prevOut: Outpoint.fromReader(reader),
        scriptSig: reader.readVarSlice(),
        sequence: reader.readUInt32(),
      );

  @override
  List<Uint8List> get witness => const [];
  @override
  bool get complete => false;
  @override
  int get signedSize => 0;
}
