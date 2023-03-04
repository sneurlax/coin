import 'dart:typed_data';

import '../gates/curve_gate.dart';
import '../gates/digest_gate.dart';
import '../gates/key_forge.dart';
import 'pbkdf2.dart';

class StandardKeyForge implements KeyForge {
  final CurveGate curve;
  final DigestGate digest;

  static const int _hardenBit = 0x80000000;

  StandardKeyForge({required this.curve, required this.digest});

  @override
  DerivedKeyMaterial masterFromSeed(Uint8List seed) {
    final hmac = digest.hmacSha512(
        Uint8List.fromList('Bitcoin seed'.codeUnits), seed);
    final key = hmac.sublist(0, 32);
    final chainCode = hmac.sublist(32, 64);
    return DerivedKeyMaterial(key, chainCode);
  }

  @override
  DerivedKeyMaterial deriveChild({
    required Uint8List parentKey,
    required Uint8List parentChainCode,
    required int index,
    required bool hardened,
    required bool isPrivate,
    required Uint8List parentPublicKey,
  }) {
    final data = Uint8List(37);
    final actualIndex = hardened ? index | _hardenBit : index;

    if (hardened) {
      data[0] = 0x00;
      data.setRange(1, 33, parentKey);
    } else {
      data.setRange(0, 33, parentPublicKey);
    }
    data[33] = (actualIndex >> 24) & 0xff;
    data[34] = (actualIndex >> 16) & 0xff;
    data[35] = (actualIndex >> 8) & 0xff;
    data[36] = actualIndex & 0xff;

    final hmac = digest.hmacSha512(parentChainCode, data);
    final il = hmac.sublist(0, 32);
    final ir = hmac.sublist(32, 64);

    if (isPrivate) {
      final childKey = curve.privateKeyTweakAdd(parentKey, il);
      if (childKey == null) throw StateError('Invalid child key');
      return DerivedKeyMaterial(childKey, ir);
    } else {
      final childPub = curve.publicKeyTweakAdd(parentPublicKey, il);
      if (childPub == null) throw StateError('Invalid child public key');
      return DerivedKeyMaterial(childPub, ir);
    }
  }

  @override
  Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    return mnemonicToSeedBytes(mnemonic, passphrase: passphrase);
  }
}
