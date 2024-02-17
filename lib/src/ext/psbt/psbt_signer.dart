import 'dart:typed_data';

import '../../core/wire.dart';
import '../../tx/sighash/legacy_hasher.dart';
import '../../tx/sighash/sighash_type.dart';
import '../../tx/sighash/witness_hasher.dart';
import '../../tx/tx.dart';
import '../../tx/tx_output.dart';
import '../assembler/signing_callback.dart';
import 'partial_tx.dart';
import 'partial_tx_v1.dart';
import 'partial_tx_v2.dart';
import 'psbt_codec.dart' show PsbtKeyValue;
import 'psbt_types.dart';

/// Computes sighashes and attaches partial signatures to a [PartialTx].
class PsbtSigner {
  final PartialTx psbt;
  final SigHashType defaultHashType;

  PsbtSigner({
    required this.psbt,
    this.defaultHashType = SigHashType.all,
  });

  void sign(SignerCallback signer) {
    for (var i = 0; i < psbt.inputCount; i++) {
      signInput(i, signer);
    }
  }

  Future<void> signAsync(AsyncSignerCallback signer) async {
    for (var i = 0; i < psbt.inputCount; i++) {
      await signInputAsync(i, signer);
    }
  }

  void signInput(int index, SignerCallback signer) {
    final inputSection = _getInputSection(index);
    final hashType = _getInputSighashType(inputSection) ?? defaultHashType;
    final tx = _buildUnsignedTx();
    final witnessUtxo = _findInputKv(
        inputSection, PsbtInputEntry.witnessUtxo.keyType);
    final digest = _computeDigest(tx, index, hashType, inputSection, witnessUtxo);
    final sig = signer(tx, index, digest, hashType);
    _storePartialSig(index, sig, hashType);
  }

  Future<void> signInputAsync(int index, AsyncSignerCallback signer) async {
    final inputSection = _getInputSection(index);
    final hashType = _getInputSighashType(inputSection) ?? defaultHashType;
    final tx = _buildUnsignedTx();
    final witnessUtxo = _findInputKv(
        inputSection, PsbtInputEntry.witnessUtxo.keyType);

    final digest = _computeDigest(tx, index, hashType, inputSection, witnessUtxo);
    final sig = await signer(tx, index, digest, hashType);
    _storePartialSig(index, sig, hashType);
  }

  Uint8List _computeDigest(
    Tx tx,
    int index,
    SigHashType hashType,
    List<PsbtKeyValue> inputSection,
    PsbtKeyValue? witnessUtxo,
  ) {
    if (witnessUtxo != null) {
      final utxoOutput = TxOutput.fromReader(WireReader(witnessUtxo.value));
      final hasher = WitnessSigHasher();
      return hasher.hash(
        tx,
        index,
        hashType,
        prevScript: utxoOutput.scriptPubKey,
        amount: utxoOutput.value,
      );
    } else {
      final nonWitnessKv = _findInputKv(
          inputSection, PsbtInputEntry.nonWitnessUtxo.keyType);
      if (nonWitnessKv == null) {
        throw StateError(
            'Input $index has neither witness UTXO nor non-witness UTXO');
      }
      final prevTx = Tx.fromBytes(nonWitnessKv.value);
      final prevOut = tx.inputs[index].prevOut;
      final prevScript = prevTx.outputs[prevOut.vout].scriptPubKey;
      final hasher = LegacySigHasher();
      return hasher.hash(tx, index, hashType, prevScript: prevScript);
    }
  }

  Tx _buildUnsignedTx() {
    if (psbt.unsignedTx != null) return psbt.unsignedTx!;
    if (psbt is PartialTxV2) {
      return (psbt as PartialTxV2).finalize();
    }
    throw StateError('Cannot build unsigned transaction');
  }

  List<PsbtKeyValue> _getInputSection(int index) {
    if (psbt is PartialTxV1) {
      return (psbt as PartialTxV1).getInputSection(index);
    }
    if (psbt is PartialTxV2) {
      return (psbt as PartialTxV2).getInputSection(index);
    }
    return const [];
  }

  PsbtKeyValue? _findInputKv(List<PsbtKeyValue> section, int keyType) {
    for (final kv in section) {
      if (kv.key.isNotEmpty && kv.key[0] == keyType) return kv;
    }
    return null;
  }

  SigHashType? _getInputSighashType(List<PsbtKeyValue> section) {
    final kv = _findInputKv(section, PsbtInputEntry.sighashType.keyType);
    if (kv == null || kv.value.length < 4) return null;
    final flag = kv.value[0] |
        (kv.value[1] << 8) |
        (kv.value[2] << 16) |
        (kv.value[3] << 24);
    return SigHashType.fromFlag(flag);
  }

  /// Appends the sighash type byte to the signature per BIP-174.
  void _storePartialSig(int index, Uint8List signature, SigHashType hashType) {
    final sigWithHashType = Uint8List(signature.length + 1);
    sigWithHashType.setAll(0, signature);
    sigWithHashType[signature.length] = hashType.flag;

    final partialSigKv = PsbtKeyValue(
      key: Uint8List.fromList([PsbtInputEntry.partialSig.keyType]),
      value: sigWithHashType,
    );

    if (psbt is PartialTxV1) {
      (psbt as PartialTxV1).addInputEntry(index, partialSigKv);
    } else if (psbt is PartialTxV2) {
      (psbt as PartialTxV2).addInputEntry(index, partialSigKv);
    }
  }
}
