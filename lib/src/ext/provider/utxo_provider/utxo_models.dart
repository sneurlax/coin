import 'dart:typed_data';

class UtxoRef {
  final String txid;
  final int vout;
  final BigInt value;
  final String scriptPubKeyHex;
  final int? blockHeight;

  const UtxoRef({
    required this.txid,
    required this.vout,
    required this.value,
    required this.scriptPubKeyHex,
    this.blockHeight,
  });

  bool get isConfirmed => blockHeight != null;
}

class BalanceInfo {
  final String address;
  final BigInt confirmed;

  /// May be negative when unconfirmed spends exist.
  final BigInt unconfirmed;

  BalanceInfo({
    required this.address,
    required this.confirmed,
    BigInt? unconfirmed,
  }) : unconfirmed = unconfirmed ?? BigInt.zero;

  BigInt get total => confirmed + unconfirmed;
}

class TxInfo {
  final String txid;
  final int? blockHeight;
  final String? blockHash;
  final BigInt? fee;
  final Uint8List? rawTx;
  final int? timestamp;

  const TxInfo({
    required this.txid,
    this.blockHeight,
    this.blockHash,
    this.fee,
    this.rawTx,
    this.timestamp,
  });

  bool get isConfirmed => blockHeight != null;
}
