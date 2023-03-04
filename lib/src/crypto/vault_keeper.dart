import 'crypto_vault.dart';
import 'gates/curve_gate.dart';
import 'gates/digest_gate.dart';
import 'gates/key_forge.dart';
import 'gates/codec_gate.dart';
import 'soft/soft_curve_gate.dart';
import 'soft/soft_digest_gate.dart';
import 'soft/standard_key_forge.dart';
import 'soft/standard_codec_gate.dart';

/// Call [initialize] once before using any crypto operations.
/// Defaults to pure Dart backends; register FFI backends with [register]
/// or [registerAsync] before calling [initialize].
class VaultKeeper {
  VaultKeeper._();

  static CryptoVault? _vault;
  static bool _initialized = false;

  static CurveGate Function()? _curveFactory;
  static DigestGate Function()? _digestFactory;
  static KeyForge Function()? _keyForgeFactory;
  static CodecGate Function()? _codecFactory;

  static Future<CurveGate> Function()? _asyncCurveFactory;

  static CryptoVault get vault {
    if (!_initialized || _vault == null) {
      throw StateError(
          'VaultKeeper not initialized. Call VaultKeeper.initialize() first.');
    }
    return _vault!;
  }

  static void register({
    CurveGate Function()? curve,
    DigestGate Function()? digest,
    KeyForge Function()? keyForge,
    CodecGate Function()? codec,
  }) {
    _curveFactory = curve ?? _curveFactory;
    _digestFactory = digest ?? _digestFactory;
    _keyForgeFactory = keyForge ?? _keyForgeFactory;
    _codecFactory = codec ?? _codecFactory;
  }

  static void registerAsync({
    Future<CurveGate> Function()? curve,
  }) {
    _asyncCurveFactory = curve ?? _asyncCurveFactory;
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    final digest = _digestFactory?.call() ?? SoftDigestGate();

    CurveGate curve;
    if (_asyncCurveFactory != null) {
      curve = await _asyncCurveFactory!();
    } else if (_curveFactory != null) {
      curve = _curveFactory!();
    } else {
      curve = SoftCurveGate();
    }
    await curve.load();

    final keyForge = _keyForgeFactory?.call() ??
        StandardKeyForge(curve: curve, digest: digest);
    final codec = _codecFactory?.call() ?? StandardCodecGate(digest: digest);

    _vault = CryptoVault(
      curve: curve,
      digest: digest,
      keyForge: keyForge,
      codec: codec,
    );
    _initialized = true;
  }

  static void reset() {
    _vault = null;
    _initialized = false;
    _curveFactory = null;
    _digestFactory = null;
    _keyForgeFactory = null;
    _codecFactory = null;
    _asyncCurveFactory = null;
  }
}
