import 'gates/curve_gate.dart';
import 'gates/digest_gate.dart';
import 'gates/key_forge.dart';
import 'gates/codec_gate.dart';

class CryptoVault {
  final CurveGate curve;
  final DigestGate digest;
  final KeyForge keyForge;
  final CodecGate codec;

  CryptoVault({
    required this.curve,
    required this.digest,
    required this.keyForge,
    required this.codec,
  });
}
