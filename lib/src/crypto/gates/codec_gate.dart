import 'dart:typed_data';

abstract class CodecGate {
  String base58CheckEncode(Uint8List payload);
  Uint8List base58CheckDecode(String encoded);
  String bech32Encode(String hrp, Uint8List data, {int version = 0});
  (String hrp, int version, Uint8List data) bech32Decode(String encoded);
  String bech32mEncode(String hrp, Uint8List data, {int version = 1});
  Uint8List convertBits(Uint8List data, int fromBits, int toBits,
      {bool pad = true});
}
