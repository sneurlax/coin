import '../../tx/inputs/tx_input.dart';
import '../../tx/tx.dart';
import '../../tx/tx_output.dart';
import '../chains/chain_params.dart';
import 'ordering.dart';
import 'signing_callback.dart';
import 'tx_assembler.dart';
import '../forked_tx/forked_hasher.dart';

/// [TxAssembler] subclass for SIGHASH_FORKID chains (BCH / BSV).
class ForkedTxAssembler extends TxAssembler {
  /// Fork-id value embedded in the upper 24 bits of the sighash type word.
  final int forkId;

  ForkedTxAssembler({
    required super.chainParams,
    required super.inputs,
    required super.outputs,
    super.version,
    super.locktime,
    super.ordering,
    this.forkId = 0,
  });

  @override
  Tx build(SignerCallback signer) {
    final rawInputs = inputs
        .map((i) => RawInput(prevOut: i.outpoint, sequence: i.sequence))
        .toList();

    final tx = Tx(
      version: version,
      inputs: rawInputs,
      outputs: List.of(outputs),
      locktime: locktime,
    );

    final hasher = ForkedHasher(forkId: forkId);
    for (var i = 0; i < inputs.length; i++) {
      final meta = inputs[i];
      final digest = hasher.hash(
        tx,
        i,
        meta.hashType,
        prevScript: meta.scriptPubKey,
        amount: meta.value,
      );
      signer(tx, i, digest, meta.hashType);
    }

    return tx;
  }

  @override
  Future<Tx> buildAsync(AsyncSignerCallback signer) async {
    final rawInputs = inputs
        .map((i) => RawInput(prevOut: i.outpoint, sequence: i.sequence))
        .toList();

    final tx = Tx(
      version: version,
      inputs: rawInputs,
      outputs: List.of(outputs),
      locktime: locktime,
    );

    final hasher = ForkedHasher(forkId: forkId);
    for (var i = 0; i < inputs.length; i++) {
      final meta = inputs[i];
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
