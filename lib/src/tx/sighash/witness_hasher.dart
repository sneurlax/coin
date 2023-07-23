import 'dart:typed_data';
import '../../core/wire.dart';
import '../../hash/digest.dart';
import 'hasher.dart';
import 'sighash_type.dart';
import '../tx.dart';

/// BIP-143 witness v0 sighash.
class WitnessSigHasher implements SigHasher {
  @override
  Uint8List hash(Tx tx, int inputIndex, SigHashType hashType,
      {Uint8List? prevScript, BigInt? amount}) {
    if (prevScript == null) throw ArgumentError('prevScript required');
    if (amount == null) throw ArgumentError('amount required for witness');

    final baseType = hashType.baseType;
    final anyoneCanPay = hashType.anyoneCanPay;

    // hashPrevouts
    Uint8List hashPrevouts;
    if (!anyoneCanPay) {
      final measure = WireMeasure();
      for (final inp in tx.inputs) {
        inp.prevOut.writeTo(measure);
      }
      final buf = Uint8List(measure.size);
      final w = WireWriter(buf);
      for (final inp in tx.inputs) {
        inp.prevOut.writeTo(w);
      }
      hashPrevouts = sha256d(buf);
    } else {
      hashPrevouts = Uint8List(32);
    }

    // hashSequence
    Uint8List hashSequence;
    if (!anyoneCanPay && baseType != 0x02 && baseType != 0x03) {
      final buf = Uint8List(tx.inputs.length * 4);
      final w = WireWriter(buf);
      for (final inp in tx.inputs) {
        w.writeUInt32(inp.sequence);
      }
      hashSequence = sha256d(buf);
    } else {
      hashSequence = Uint8List(32);
    }

    // hashOutputs
    Uint8List hashOutputs;
    if (baseType != 0x02 && baseType != 0x03) {
      final measure = WireMeasure();
      for (final out in tx.outputs) {
        out.writeTo(measure);
      }
      final buf = Uint8List(measure.size);
      final w = WireWriter(buf);
      for (final out in tx.outputs) {
        out.writeTo(w);
      }
      hashOutputs = sha256d(buf);
    } else if (baseType == 0x03 && inputIndex < tx.outputs.length) {
      final measure = WireMeasure();
      tx.outputs[inputIndex].writeTo(measure);
      final buf = Uint8List(measure.size);
      final w = WireWriter(buf);
      tx.outputs[inputIndex].writeTo(w);
      hashOutputs = sha256d(buf);
    } else {
      hashOutputs = Uint8List(32);
    }

    // Preimage
    final measure = WireMeasure();
    measure.writeInt32(0); // version
    measure.writeSlice(hashPrevouts);
    measure.writeSlice(hashSequence);
    tx.inputs[inputIndex].prevOut.writeTo(measure);
    measure.writeVarSlice(prevScript);
    measure.writeUInt64(BigInt.zero); // amount
    measure.writeUInt32(0); // sequence
    measure.writeSlice(hashOutputs);
    measure.writeUInt32(0); // locktime
    measure.writeUInt32(0); // hashType

    final preimage = Uint8List(measure.size);
    final pw = WireWriter(preimage);
    pw.writeInt32(tx.version);
    pw.writeSlice(hashPrevouts);
    pw.writeSlice(hashSequence);
    tx.inputs[inputIndex].prevOut.writeTo(pw);
    pw.writeVarSlice(prevScript);
    pw.writeUInt64(amount);
    pw.writeUInt32(tx.inputs[inputIndex].sequence);
    pw.writeSlice(hashOutputs);
    pw.writeUInt32(tx.locktime);
    pw.writeUInt32(hashType.flag);

    return sha256d(preimage);
  }
}
