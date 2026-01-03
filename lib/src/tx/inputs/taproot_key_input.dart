import 'dart:typed_data';
import 'witness_input.dart';
import 'input_sig.dart';

/// Key-path spend; witness = [schnorr_sig].
class TaprootKeyInput extends WitnessInput {
  final SchnorrInputSig inputSig;

  TaprootKeyInput({
    required super.prevOut,
    required this.inputSig,
    super.sequence,
  });

  @override
  List<Uint8List> get witness => [inputSig.toBytes()];
  @override
  bool get complete => true;
  @override
  int get signedSize => 58; // typical taproot key path
}
