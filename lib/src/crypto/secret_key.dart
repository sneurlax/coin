import 'dart:typed_data';

import '../core/bytes.dart';
import '../core/hex.dart';
import '../core/random.dart';
import 'vault_keeper.dart';
import 'public_key.dart';

class SecretKey {
  final Uint8List _data;
  PublicKey? _pubCache;

  SecretKey(Uint8List bytes) : _data = copyCheckBytes(bytes, 32, 'privKey') {
    if (!VaultKeeper.vault.curve.isValidPrivateKey(_data)) {
      throw ArgumentError('Invalid secp256k1 private key');
    }
  }

  factory SecretKey.fromHex(String hex) => SecretKey(hexDecode(hex));

  factory SecretKey.generate() => SecretKey(generateSecureBytes(32));

  Uint8List get bytes => Uint8List.fromList(_data);

  PublicKey get publicKey =>
      _pubCache ??= PublicKey(VaultKeeper.vault.curve.derivePublicKey(_data));

  Uint8List get xOnly => publicKey.xOnly;

  SecretKey? tweak(Uint8List scalar) {
    final result = VaultKeeper.vault.curve.privateKeyTweakAdd(_data, scalar);
    if (result == null) return null;
    return SecretKey(result);
  }

  SecretKey negate() =>
      SecretKey(VaultKeeper.vault.curve.privateKeyNegate(_data));

  Uint8List ecdh(PublicKey other) =>
      VaultKeeper.vault.curve.ecdh(_data, other.bytes);

  String toHex() => hexEncode(_data);

  @override
  bool operator ==(Object other) =>
      other is SecretKey && bytesEqual(_data, other._data);

  @override
  int get hashCode => Object.hashAll(_data);
}
