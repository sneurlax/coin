import 'dart:typed_data';

import '../../tx/outpoint.dart';
import '../chains/chain_params.dart';

class SpendableUtxo {
  final Outpoint outpoint;
  final BigInt value;
  final Uint8List scriptPubKey;
  final String? derivationPath;
  final Uint8List? ownerPubKey;
  final ChainParams? chainParams;
  final int? blockHeight;
  final bool isCoinbase;

  const SpendableUtxo({
    required this.outpoint,
    required this.value,
    required this.scriptPubKey,
    this.derivationPath,
    this.ownerPubKey,
    this.chainParams,
    this.blockHeight,
    this.isCoinbase = false,
  });

  bool get isConfirmed => blockHeight != null;
  String get txidHex => outpoint.txidHex;
  int get vout => outpoint.vout;
}
