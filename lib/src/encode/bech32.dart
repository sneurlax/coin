import 'dart:typed_data';
import '../crypto/vault_keeper.dart';

class Bech32 {
  Bech32._();

  static String encode(String hrp, Uint8List data, {int version = 0}) =>
      VaultKeeper.vault.codec.bech32Encode(hrp, data, version: version);

  static (String hrp, int version, Uint8List data) decode(String encoded) =>
      VaultKeeper.vault.codec.bech32Decode(encoded);

  static String encodem(String hrp, Uint8List data, {int version = 1}) =>
      VaultKeeper.vault.codec.bech32mEncode(hrp, data, version: version);
}
