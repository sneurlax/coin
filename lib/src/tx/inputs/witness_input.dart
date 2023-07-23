import 'dart:typed_data';
import 'tx_input.dart';
import '../outpoint.dart';

abstract class WitnessInput extends TxInput {
  @override
  final Outpoint prevOut;
  @override
  final int sequence;

  WitnessInput({
    required this.prevOut,
    this.sequence = TxInput.sequenceFinal,
  });

  @override
  Uint8List get scriptSig => Uint8List(0);
}
