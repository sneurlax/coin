import 'crypto_vault.dart';
import 'gates/curve_gate.dart';
import 'gates/digest_gate.dart';
import 'gates/ed25519_gate.dart';
import 'gates/key_forge.dart';
import 'gates/codec_gate.dart';
import 'soft/soft_curve_gate.dart';
import 'soft/soft_digest_gate.dart';
import 'soft/soft_ed25519_gate.dart';
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
  static Ed25519Gate Function()? _ed25519Factory;
  static DigestGate Function()? _digestFactory;
  static KeyForge Function()? _keyForgeFactory;
  static CodecGate Function()? _codecFactory;

  static Future<CurveGate> Function()? _asyncCurveFactory;
  static Future<Ed25519Gate> Function()? _asyncEd25519Factory;

  static CryptoVault get vault {
    if (!_initialized || _vault == null) {
      throw StateError(
          'VaultKeeper not initialized. Call VaultKeeper.initialize() first.');
    }
    return _vault!;
  }

  static void register({
    CurveGate Function()? curve,
    Ed25519Gate Function()? ed25519,
    DigestGate Function()? digest,
    KeyForge Function()? keyForge,
    CodecGate Function()? codec,
  }) {
    _curveFactory = curve ?? _curveFactory;
    _ed25519Factory = ed25519 ?? _ed25519Factory;
    _digestFactory = digest ?? _digestFactory;
    _keyForgeFactory = keyForge ?? _keyForgeFactory;
    _codecFactory = codec ?? _codecFactory;
  }

  static void registerAsync({
    Future<CurveGate> Function()? curve,
    Future<Ed25519Gate> Function()? ed25519,
  }) {
    _asyncCurveFactory = curve ?? _asyncCurveFactory;
    _asyncEd25519Factory = ed25519 ?? _asyncEd25519Factory;
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

    Ed25519Gate ed25519;
    if (_asyncEd25519Factory != null) {
      ed25519 = await _asyncEd25519Factory!();
    } else if (_ed25519Factory != null) {
      ed25519 = _ed25519Factory!();
    } else {
      ed25519 = SoftEd25519Gate();
    }
    await ed25519.load();

    final keyForge = _keyForgeFactory?.call() ??
        StandardKeyForge(curve: curve, digest: digest);
    final codec = _codecFactory?.call() ?? StandardCodecGate(digest: digest);

    _vault = CryptoVault(
      curve: curve,
      ed25519: ed25519,
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
    _ed25519Factory = null;
    _digestFactory = null;
    _keyForgeFactory = null;
    _codecFactory = null;
    _asyncCurveFactory = null;
    _asyncEd25519Factory = null;
  }
}
