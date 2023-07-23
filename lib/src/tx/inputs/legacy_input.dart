import 'dart:typed_data';
import 'tx_input.dart';
import '../outpoint.dart';

class LegacyInput extends TxInput {
  @override
  final Outpoint prevOut;
  @override
  final Uint8List scriptSig;
  @override
  final int sequence;

  LegacyInput({
    required this.prevOut,
    required this.scriptSig,
    this.sequence = TxInput.sequenceFinal,
  });

  @override
  List<Uint8List> get witness => const [];
  @override
  bool get complete => scriptSig.isNotEmpty;
  @override
  int get signedSize => 41 + scriptSig.length; // outpoint(36) + seq(4) + varint + script
}
