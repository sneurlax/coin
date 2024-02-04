import '../../tx/tx.dart';
import '../../tx/tx_output.dart';
import '../chains/chain_params.dart';
import 'ordering.dart';
import 'signing_callback.dart';
import 'tx_assembler.dart';

/// Transaction assembler for chains that use SIGHASH_FORKID (BCH / BSV).
///
/// Extends [TxAssembler] with fork-id aware sighash computation.
class ForkedTxAssembler extends TxAssembler {
  /// The fork-id value to embed in the sighash type byte.
  /// BCH uses 0x00, BSV uses 0x00 (fork-id is the upper 24 bits).
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
    throw UnimplementedError('ForkedTxAssembler.build');
  }

  @override
  Future<Tx> buildAsync(AsyncSignerCallback signer) {
    throw UnimplementedError('ForkedTxAssembler.buildAsync');
  }
}
