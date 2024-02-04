import 'dart:typed_data';

import '../../tx/tx.dart';
import '../../tx/tx_output.dart';
import '../../tx/inputs/tx_input.dart';
import '../../tx/outpoint.dart';
import '../../tx/sighash/hasher.dart';
import '../../tx/sighash/legacy_hasher.dart';
import '../../tx/sighash/sighash_type.dart';
import '../../tx/sighash/witness_hasher.dart';
import '../chains/chain_params.dart';
import 'ordering.dart';
import 'signing_callback.dart';

/// Metadata for a UTXO being spent.
class AssemblerInput {
  final Outpoint outpoint;
  final BigInt value;
  final Uint8List scriptPubKey;
  final int sequence;
  final SigHashType hashType;

  const AssemblerInput({
    required this.outpoint,
    required this.value,
    required this.scriptPubKey,
    this.sequence = TxInput.sequenceFinal,
    this.hashType = SigHashType.all,
  });
}

/// High-level transaction builder that takes UTXOs, outputs, and a chain
/// config to produce a signed [Tx].
class TxAssembler {
  final ChainParams chainParams;
  final List<AssemblerInput> inputs;
  final List<TxOutput> outputs;
  final int version;
  final int locktime;
  final TxOrdering ordering;

  TxAssembler({
    required this.chainParams,
    required this.inputs,
    required this.outputs,
    this.version = Tx.currentVersion,
    this.locktime = 0,
    this.ordering = TxOrdering.bip69,
  });

  Tx build(SignerCallback signer) {
    final rawInputs = inputs
        .map((i) => RawInput(prevOut: i.outpoint, sequence: i.sequence))
        .toList();

    var tx = Tx(
      version: version,
      inputs: rawInputs,
      outputs: List.of(outputs),
      locktime: locktime,
    );

    final sigs = <int, Uint8List>{};
    for (var i = 0; i < inputs.length; i++) {
      final meta = inputs[i];
      final hasWitness = meta.scriptPubKey.isNotEmpty &&
          meta.scriptPubKey.length >= 2 &&
          meta.scriptPubKey[0] == 0x00;
      final SigHasher hasher =
          hasWitness ? WitnessSigHasher() : LegacySigHasher();
      final digest = hasher.hash(
        tx,
        i,
        meta.hashType,
        prevScript: meta.scriptPubKey,
        amount: meta.value,
      );
      sigs[i] = signer(tx, i, digest, meta.hashType);
    }

    return tx;
  }

  Future<Tx> buildAsync(AsyncSignerCallback signer) async {
    final rawInputs = inputs
        .map((i) => RawInput(prevOut: i.outpoint, sequence: i.sequence))
        .toList();

    var tx = Tx(
      version: version,
      inputs: rawInputs,
      outputs: List.of(outputs),
      locktime: locktime,
    );

    for (var i = 0; i < inputs.length; i++) {
      final meta = inputs[i];
      final hasWitness = meta.scriptPubKey.isNotEmpty &&
          meta.scriptPubKey.length >= 2 &&
          meta.scriptPubKey[0] == 0x00;
      final SigHasher hasher =
          hasWitness ? WitnessSigHasher() : LegacySigHasher();
      final digest = hasher.hash(
        tx,
        i,
        meta.hashType,
        prevScript: meta.scriptPubKey,
        amount: meta.value,
      );
      await signer(tx, i, digest, meta.hashType);
    }

    return tx;
  }
}
