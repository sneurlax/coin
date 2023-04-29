import 'dart:typed_data';
import '../crypto/vault_keeper.dart';

String base58Encode(Uint8List payload) =>
    VaultKeeper.vault.codec.base58CheckEncode(payload);

Uint8List base58Decode(String encoded) =>
    VaultKeeper.vault.codec.base58CheckDecode(encoded);
