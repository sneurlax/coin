import 'dart:typed_data';
import '../core/bytes.dart';
import '../core/hex.dart';
import '../core/wire.dart';

class Outpoint with Serializable {
  final Uint8List txid;
  final int vout;

  Outpoint({required Uint8List txid, required this.vout})
      : txid = copyCheckBytes(txid, 32, 'txid');

  factory Outpoint.fromReader(WireReader reader) => Outpoint(
        txid: reader.readSlice(32),
        vout: reader.readUInt32(),
      );

  String get txidHex => hexEncode(Uint8List.fromList(txid.reversed.toList()));

  @override
  void writeTo(WireWriting writer) {
    writer.writeSlice(txid);
    writer.writeUInt32(vout);
  }

  @override
  bool operator ==(Object other) =>
      other is Outpoint && vout == other.vout && bytesEqual(txid, other.txid);

  @override
  int get hashCode => Object.hash(Object.hashAll(txid), vout);
}
