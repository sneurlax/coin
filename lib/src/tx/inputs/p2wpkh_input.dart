import 'dart:typed_data';
import 'witness_input.dart';
import '../outpoint.dart';
import 'input_sig.dart';

/// witness = [sig, pubkey]
class P2wpkhInput extends WitnessInput {
  final InputSig inputSig;
  final Uint8List publicKey;

  P2wpkhInput({
    required super.prevOut,
    required this.inputSig,
    required this.publicKey,
    super.sequence,
  });

  @override
  List<Uint8List> get witness => [inputSig.toBytes(), publicKey];
  @override
  bool get complete => true;
  @override
  int get signedSize => 68; // typical P2WPKH witness size / 4
}
