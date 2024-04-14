import 'dart:typed_data';

import '../../tx/inputs/tx_input.dart';
import '../../tx/tx_output.dart';

/// BIP-69: deterministic ordering to prevent wallet fingerprinting.
class Bip69Ordering {
  Bip69Ordering._();

  static int compareInputs(TxInput a, TxInput b) {
    final txidCmp = _compareBytes(a.prevOut.txid, b.prevOut.txid);
    if (txidCmp != 0) return txidCmp;
    return a.prevOut.vout.compareTo(b.prevOut.vout);
  }

  static int compareOutputs(TxOutput a, TxOutput b) {
    final valueCmp = a.value.compareTo(b.value);
    if (valueCmp != 0) return valueCmp;
    return _compareBytes(a.scriptPubKey, b.scriptPubKey);
  }

  static void sortInputs(List<TxInput> inputs) {
    inputs.sort(compareInputs);
  }

  static void sortOutputs(List<TxOutput> outputs) {
    outputs.sort(compareOutputs);
  }

  static int _compareBytes(Uint8List a, Uint8List b) {
    final len = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    return a.length.compareTo(b.length);
  }
}
