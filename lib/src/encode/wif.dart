import 'dart:typed_data';
import '../crypto/vault_keeper.dart';
import '../chain/chain.dart';

String wifEncode(Uint8List privKey, Chain chain, {bool compressed = true}) {
  final prefix = chain.wifPrefix;
  final payload = Uint8List(compressed ? 34 : 33);
  payload[0] = prefix;
  payload.setRange(1, 33, privKey);
  if (compressed) payload[33] = 0x01;
  return VaultKeeper.vault.codec.base58CheckEncode(payload);
}

(Uint8List privKey, bool compressed) wifDecode(String wif, Chain chain) {
  final payload = VaultKeeper.vault.codec.base58CheckDecode(wif);
  if (payload[0] != chain.wifPrefix) {
    throw FormatException('WIF prefix mismatch');
  }
  if (payload.length == 34 && payload[33] == 0x01) {
    return (payload.sublist(1, 33), true);
  } else if (payload.length == 33) {
    return (payload.sublist(1, 33), false);
  }
  throw FormatException('Invalid WIF length');
}
