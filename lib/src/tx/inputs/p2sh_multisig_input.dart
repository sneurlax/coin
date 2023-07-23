import 'dart:typed_data';
import 'tx_input.dart';
import '../outpoint.dart';
import 'input_sig.dart';

class P2shMultisigInput extends TxInput {
  @override
  final Outpoint prevOut;
  @override
  final int sequence;
  final List<InputSig> signatures;
  final Uint8List redeemScript;

  P2shMultisigInput({
    required this.prevOut,
    required this.signatures,
    required this.redeemScript,
    this.sequence = TxInput.sequenceFinal,
  });

  @override
  Uint8List get scriptSig {
    final parts = <int>[0x00]; // OP_0 for CHECKMULTISIG bug
    for (final sig in signatures) {
      final sigBytes = sig.toBytes();
      parts.addAll([sigBytes.length, ...sigBytes]);
    }
    if (redeemScript.length <= 75) {
      parts.addAll([redeemScript.length, ...redeemScript]);
    } else {
      parts.addAll([0x4c, redeemScript.length, ...redeemScript]);
    }
    return Uint8List.fromList(parts);
  }

  @override
  List<Uint8List> get witness => const [];
  @override
  bool get complete => true;
  @override
  int get signedSize => 41 + scriptSig.length;
}
