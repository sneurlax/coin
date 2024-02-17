import 'dart:convert';
import 'dart:typed_data';

import '../../tx/outpoint.dart';
import '../../tx/tx.dart';
import 'partial_tx_v1.dart';
import 'partial_tx_v2.dart';
import 'psbt_codec.dart';
import 'psbt_types.dart';

/// Version-agnostic PSBT facade for constructing, inspecting, and
/// finalizing partially signed transactions.
abstract class PartialTx {
  factory PartialTx.fromBase64(String encoded) {
    final bytes = base64Decode(encoded);
    return PartialTx.fromBytes(Uint8List.fromList(bytes));
  }

  factory PartialTx.fromBytes(Uint8List bytes) {
    if (!PsbtCodec.hasMagic(bytes)) {
      throw FormatException('Invalid PSBT: missing magic bytes');
    }
    final sections = PsbtCodec.decode(bytes);
    if (sections.isEmpty) {
      throw FormatException('Invalid PSBT: no global section');
    }
    final global = sections.first;
    // Look for version key type 0xfb in the global section.
    int psbtVersion = 0;
    for (final kv in global) {
      if (kv.key.isNotEmpty && kv.key[0] == PsbtGlobal.version.keyType) {
        if (kv.value.length >= 4) {
          psbtVersion = kv.value[0] |
              (kv.value[1] << 8) |
              (kv.value[2] << 16) |
              (kv.value[3] << 24);
        }
        break;
      }
    }
    if (psbtVersion == 2) {
      return PartialTxV2.fromBytes(bytes);
    }
    return PartialTxV1.fromBytes(bytes);
  }

  /// 0 for BIP-174, 2 for BIP-370.
  int get version;

  /// The global unsigned transaction (v0 only).
  Tx? get unsignedTx;

  int get inputCount;

  int get outputCount;

  void addInput({
    required Outpoint outpoint,
    Uint8List? witnessUtxoScript,
    BigInt? witnessUtxoValue,
    Tx? nonWitnessUtxo,
    int sequence,
  });

  void addOutput({
    required Uint8List scriptPubKey,
    required BigInt value,
  });

  Tx finalize();

  String toBase64();

  Uint8List toBytes();
}
