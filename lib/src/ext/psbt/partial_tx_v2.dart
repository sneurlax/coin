import 'dart:convert';
import 'dart:typed_data';

import '../../core/wire.dart';
import '../../tx/inputs/tx_input.dart';
import '../../tx/outpoint.dart';
import '../../tx/tx.dart';
import '../../tx/tx_output.dart';
import 'partial_tx.dart';
import 'psbt_codec.dart';
import 'psbt_types.dart';

/// BIP-370 PSBT version 2 implementation. Per-input and per-output fields
/// live directly in their own sections instead of inside a global unsigned tx.
class PartialTxV2 implements PartialTx {
  int _txVersion;
  int _locktime;
  int _inputCount;
  int _outputCount;

  List<List<PsbtKeyValue>> _sections;

  PartialTxV2({
    int txVersion = 2,
    int locktime = 0,
  })  : _txVersion = txVersion,
        _locktime = locktime,
        _inputCount = 0,
        _outputCount = 0,
        _sections = [];

  factory PartialTxV2.fromBytes(Uint8List bytes) {
    final sections = PsbtCodec.decode(bytes);
    if (sections.isEmpty) {
      throw FormatException('Invalid PSBT v2: no global section');
    }

    final global = sections[0];
    int txVersion = 2;
    int locktime = 0;
    int inputCount = 0;
    int outputCount = 0;

    for (final kv in global) {
      if (kv.key.isEmpty) continue;
      final keyType = kv.key[0];
      if (keyType == PsbtGlobal.txVersion.keyType && kv.value.length >= 4) {
        txVersion = kv.value[0] |
            (kv.value[1] << 8) |
            (kv.value[2] << 16) |
            (kv.value[3] << 24);
      } else if (keyType == PsbtGlobal.fallbackLocktime.keyType &&
          kv.value.length >= 4) {
        locktime = kv.value[0] |
            (kv.value[1] << 8) |
            (kv.value[2] << 16) |
            (kv.value[3] << 24);
      } else if (keyType == PsbtGlobal.inputCount.keyType) {
        inputCount = _readCompactSize(kv.value);
      } else if (keyType == PsbtGlobal.outputCount.keyType) {
        outputCount = _readCompactSize(kv.value);
      }
    }

    final result = PartialTxV2(txVersion: txVersion, locktime: locktime);
    result._inputCount = inputCount;
    result._outputCount = outputCount;
    result._sections = sections;
    return result;
  }

  @override
  int get version => 2;

  @override
  Tx? get unsignedTx => null; // v2 does not carry a global unsigned tx.

  @override
  int get inputCount => _inputCount;

  @override
  int get outputCount => _outputCount;

  int get txVersion => _txVersion;

  int get locktime => _locktime;

  @override
  void addInput({
    required Outpoint outpoint,
    Uint8List? witnessUtxoScript,
    BigInt? witnessUtxoValue,
    Tx? nonWitnessUtxo,
    int sequence = 0xffffffff,
  }) {
    _ensureSections();

    final inputKvs = <PsbtKeyValue>[];

    // PSBT_IN_PREVIOUS_TXID (0x0e): 32-byte txid in internal byte order
    inputKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtInputEntry.previousTxid.keyType]),
      value: outpoint.txid,
    ));

    // PSBT_IN_OUTPUT_INDEX (0x0f): 4-byte LE vout
    final voutBytes = Uint8List(4);
    WireWriter(voutBytes).writeUInt32(outpoint.vout);
    inputKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtInputEntry.outputIndex.keyType]),
      value: voutBytes,
    ));

    // PSBT_IN_SEQUENCE (0x10): 4-byte LE sequence
    final seqBytes = Uint8List(4);
    WireWriter(seqBytes).writeUInt32(sequence);
    inputKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtInputEntry.sequence.keyType]),
      value: seqBytes,
    ));

    if (nonWitnessUtxo != null) {
      inputKvs.add(PsbtKeyValue(
        key: Uint8List.fromList([PsbtInputEntry.nonWitnessUtxo.keyType]),
        value: nonWitnessUtxo.toBytes(),
      ));
    }

    if (witnessUtxoScript != null && witnessUtxoValue != null) {
      final out = TxOutput(value: witnessUtxoValue, scriptPubKey: witnessUtxoScript);
      inputKvs.add(PsbtKeyValue(
        key: Uint8List.fromList([PsbtInputEntry.witnessUtxo.keyType]),
        value: out.toBytes(),
      ));
    }

    final insertIndex = 1 + _inputCount;
    _sections.insert(insertIndex, inputKvs);
    _inputCount++;
  }

  @override
  void addOutput({
    required Uint8List scriptPubKey,
    required BigInt value,
  }) {
    _ensureSections();

    final outputKvs = <PsbtKeyValue>[];

    // PSBT_OUT_AMOUNT (0x03): 8-byte LE value
    final amountBytes = Uint8List(8);
    WireWriter(amountBytes).writeUInt64(value);
    outputKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtOutputEntry.amount.keyType]),
      value: amountBytes,
    ));

    // PSBT_OUT_SCRIPT (0x04): scriptPubKey
    outputKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtOutputEntry.script.keyType]),
      value: scriptPubKey,
    ));

    _sections.add(outputKvs);
    _outputCount++;
  }

  @override
  Tx finalize() {
    final inputs = <TxInput>[];
    for (var i = 0; i < _inputCount; i++) {
      final section = getInputSection(i);
      Uint8List? txid;
      int vout = 0;
      int sequence = TxInput.sequenceFinal;
      Uint8List? finalScriptSig;

      for (final kv in section) {
        if (kv.key.isEmpty) continue;
        final keyType = kv.key[0];
        if (keyType == PsbtInputEntry.previousTxid.keyType) {
          txid = kv.value;
        } else if (keyType == PsbtInputEntry.outputIndex.keyType &&
            kv.value.length >= 4) {
          vout = kv.value[0] |
              (kv.value[1] << 8) |
              (kv.value[2] << 16) |
              (kv.value[3] << 24);
        } else if (keyType == PsbtInputEntry.sequence.keyType &&
            kv.value.length >= 4) {
          sequence = kv.value[0] |
              (kv.value[1] << 8) |
              (kv.value[2] << 16) |
              (kv.value[3] << 24);
        } else if (keyType == PsbtInputEntry.finalScriptSig.keyType) {
          finalScriptSig = kv.value;
        }
      }

      if (txid == null) {
        throw StateError('Input $i missing previous txid');
      }

      inputs.add(RawInput(
        prevOut: Outpoint(txid: txid, vout: vout),
        scriptSig: finalScriptSig,
        sequence: sequence,
      ));
    }

    final outputs = <TxOutput>[];
    for (var i = 0; i < _outputCount; i++) {
      final section = _getOutputSection(i);
      BigInt? amount;
      Uint8List? script;

      for (final kv in section) {
        if (kv.key.isEmpty) continue;
        final keyType = kv.key[0];
        if (keyType == PsbtOutputEntry.amount.keyType &&
            kv.value.length >= 8) {
          final reader = WireReader(kv.value);
          amount = reader.readUInt64();
        } else if (keyType == PsbtOutputEntry.script.keyType) {
          script = kv.value;
        }
      }

      if (amount == null || script == null) {
        throw StateError('Output $i missing amount or script');
      }

      outputs.add(TxOutput(value: amount, scriptPubKey: script));
    }

    return Tx(
      version: _txVersion,
      inputs: inputs,
      outputs: outputs,
      locktime: _locktime,
    );
  }

  @override
  String toBase64() => base64Encode(toBytes());

  @override
  Uint8List toBytes() {
    _ensureSections();
    _rebuildGlobal();
    return PsbtCodec.encode(_sections);
  }

  List<PsbtKeyValue> getInputSection(int index) {
    final sectionIndex = 1 + index;
    if (sectionIndex < _sections.length) {
      return _sections[sectionIndex];
    }
    return const [];
  }

  List<PsbtKeyValue> _getOutputSection(int index) {
    final sectionIndex = 1 + _inputCount + index;
    if (sectionIndex < _sections.length) {
      return _sections[sectionIndex];
    }
    return const [];
  }

  void addInputEntry(int index, PsbtKeyValue entry) {
    _ensureSections();
    final sectionIndex = 1 + index;
    if (sectionIndex < _sections.length) {
      _sections[sectionIndex].add(entry);
    }
  }

  void _ensureSections() {
    if (_sections.isEmpty) {
      _sections.add(<PsbtKeyValue>[]); // global
    }
  }

  void _rebuildGlobal() {
    final globalKvs = <PsbtKeyValue>[];

    final versionBytes = Uint8List(4);
    WireWriter(versionBytes).writeUInt32(2);
    globalKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtGlobal.version.keyType]),
      value: versionBytes,
    ));

    final txVerBytes = Uint8List(4);
    WireWriter(txVerBytes).writeUInt32(_txVersion);
    globalKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtGlobal.txVersion.keyType]),
      value: txVerBytes,
    ));

    if (_locktime != 0) {
      final ltBytes = Uint8List(4);
      WireWriter(ltBytes).writeUInt32(_locktime);
      globalKvs.add(PsbtKeyValue(
        key: Uint8List.fromList([PsbtGlobal.fallbackLocktime.keyType]),
        value: ltBytes,
      ));
    }

    globalKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtGlobal.inputCount.keyType]),
      value: _writeCompactSize(_inputCount),
    ));

    globalKvs.add(PsbtKeyValue(
      key: Uint8List.fromList([PsbtGlobal.outputCount.keyType]),
      value: _writeCompactSize(_outputCount),
    ));

    if (_sections.isNotEmpty) {
      final existingGlobal = _sections[0];
      final reservedKeys = {
        PsbtGlobal.version.keyType,
        PsbtGlobal.txVersion.keyType,
        PsbtGlobal.fallbackLocktime.keyType,
        PsbtGlobal.inputCount.keyType,
        PsbtGlobal.outputCount.keyType,
      };
      for (final kv in existingGlobal) {
        if (kv.key.isNotEmpty && !reservedKeys.contains(kv.key[0])) {
          globalKvs.add(kv);
        }
      }
    }

    _sections[0] = globalKvs;
  }

  static int _readCompactSize(Uint8List bytes) {
    if (bytes.isEmpty) return 0;
    final reader = WireReader(bytes);
    return reader.readVarInt().toInt();
  }

  static Uint8List _writeCompactSize(int value) {
    final size = WireMeasure.varIntSizeOfInt(value);
    final buf = Uint8List(size);
    WireWriter(buf).writeVarInt(BigInt.from(value));
    return buf;
  }
}
