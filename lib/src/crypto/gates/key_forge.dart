import 'dart:typed_data';

class DerivedKeyMaterial {
  final Uint8List key;
  final Uint8List chainCode;
  DerivedKeyMaterial(this.key, this.chainCode);
}

abstract class KeyForge {
  DerivedKeyMaterial masterFromSeed(Uint8List seed);

  DerivedKeyMaterial deriveChild({
    required Uint8List parentKey,
    required Uint8List parentChainCode,
    required int index,
    required bool hardened,
    required bool isPrivate,
    required Uint8List parentPublicKey,
  });

  Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''});
}
