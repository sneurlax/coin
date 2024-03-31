import 'dart:typed_data';

import '../../tx/inputs/tx_input.dart';
import '../../tx/outpoint.dart';
import '../../tx/tx.dart';
import '../../tx/tx_output.dart';
import '../../tx/sighash/sighash_type.dart';
import '../chains/chain_params.dart';
import 'forked_hasher.dart';

/// Transaction builder with SIGHASH_FORKID support for BCH / BSV.
class ForkedBuilder {
  final ChainParams chainParams;
  final int version;
  int locktime;

  final List<_PendingInput> _inputs = [];
  final List<TxOutput> _outputs = [];

  ForkedBuilder({
    required this.chainParams,
    this.version = Tx.currentVersion,
    this.locktime = 0,
  }) {
    if (!chainParams.usesForkId) {
      throw ArgumentError(
        'ForkedBuilder requires a chain with usesForkId=true, '
        'got ${chainParams.chainName}',
      );
    }
  }

  void addInput({
    required Outpoint outpoint,
    required BigInt value,
    required Uint8List scriptPubKey,
    int sequence = TxInput.sequenceFinal,
    SigHashType hashType = SigHashType.all,
  }) {
    _inputs.add(_PendingInput(
      outpoint: outpoint,
      value: value,
      scriptPubKey: scriptPubKey,
      sequence: sequence,
      hashType: hashType,
    ));
  }

  void addOutput(TxOutput output) {
    _outputs.add(output);
  }

  Tx buildUnsigned() {
    final rawInputs = _inputs
        .map((i) => RawInput(prevOut: i.outpoint, sequence: i.sequence))
        .toList();
    return Tx(
      version: version,
      inputs: rawInputs,
      outputs: List.unmodifiable(_outputs),
      locktime: locktime,
    );
  }

  Uint8List sigHash(Tx tx, int inputIndex, {int forkId = 0}) {
    final pending = _inputs[inputIndex];
    final hasher = ForkedHasher(forkId: forkId);
    return hasher.hash(
      tx,
      inputIndex,
      pending.hashType,
      prevScript: pending.scriptPubKey,
      amount: pending.value,
    );
  }

  int get inputCount => _inputs.length;

  int get outputCount => _outputs.length;
}

class _PendingInput {
  final Outpoint outpoint;
  final BigInt value;
  final Uint8List scriptPubKey;
  final int sequence;
  final SigHashType hashType;

  const _PendingInput({
    required this.outpoint,
    required this.value,
    required this.scriptPubKey,
    required this.sequence,
    required this.hashType,
  });
}
