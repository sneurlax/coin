import 'dart:typed_data';
import 'tx_input.dart';
import '../outpoint.dart';
import 'input_sig.dart';

/// scriptSig = [sig, pubkey]
class P2pkhInput extends TxInput {
  @override
  final Outpoint prevOut;
  @override
  final int sequence;
  final InputSig inputSig;
  final Uint8List publicKey;

  P2pkhInput({
    required this.prevOut,
    required this.inputSig,
    required this.publicKey,
    this.sequence = TxInput.sequenceFinal,
  });

  @override
  Uint8List get scriptSig {
    final sigBytes = inputSig.toBytes();
    final parts = <int>[
      sigBytes.length, ...sigBytes,
      publicKey.length, ...publicKey,
    ];
    return Uint8List.fromList(parts);
  }

  @override
  List<Uint8List> get witness => const [];
  @override
  bool get complete => true;
  @override
  int get signedSize => 148; // typical P2PKH input size
}
