import 'dart:typed_data';
import '../sighash/sighash_type.dart';

/// DER-encoded ECDSA sig + sighash byte.
class InputSig {
  final Uint8List derSig;
  final SigHashType hashType;

  InputSig({required this.derSig, required this.hashType});

  Uint8List toBytes() =>
      Uint8List.fromList([...derSig, hashType.flag]);

  factory InputSig.fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) throw ArgumentError('Empty signature');
    final flag = bytes.last;
    return InputSig(
      derSig: bytes.sublist(0, bytes.length - 1),
      hashType: SigHashType.fromFlag(flag),
    );
  }
}

/// Schnorr sig: 64 bytes, or 65 with non-default sighash.
class SchnorrInputSig {
  final Uint8List sig;
  final SigHashType hashType;

  SchnorrInputSig({required this.sig, required this.hashType});

  Uint8List toBytes() {
    if (hashType == SigHashType.all) return sig; // 64 bytes, no suffix
    return Uint8List.fromList([...sig, hashType.flag]);
  }

  factory SchnorrInputSig.fromBytes(Uint8List bytes) {
    if (bytes.length == 64) {
      return SchnorrInputSig(sig: bytes, hashType: SigHashType.all);
    }
    if (bytes.length == 65) {
      return SchnorrInputSig(
        sig: bytes.sublist(0, 64),
        hashType: SigHashType.fromFlag(bytes[64]),
      );
    }
    throw ArgumentError('Invalid Schnorr signature length');
  }
}
