import 'dart:typed_data';
import '../crypto/vault_keeper.dart';

Uint8List taggedHash(String tag, Uint8List data) =>
    VaultKeeper.vault.digest.taggedHash(tag, data);
