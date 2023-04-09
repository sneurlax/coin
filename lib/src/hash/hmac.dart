import 'dart:typed_data';
import '../crypto/vault_keeper.dart';

Uint8List hmacSha512(Uint8List key, Uint8List data) =>
    VaultKeeper.vault.digest.hmacSha512(key, data);

Uint8List hmacSha256(Uint8List key, Uint8List data) =>
    VaultKeeper.vault.digest.hmacSha256(key, data);
