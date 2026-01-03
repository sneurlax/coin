import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import '../../core/random.dart';
import '../gates/curve_gate.dart';
import 'native_heap_ffi.dart';
import 'secp256k1_ffi_bindings.g.dart';

const _libName = 'secp256k1';

String _libraryPath() {
  final String localLib, flutterLib;
  if (Platform.isLinux || Platform.isAndroid) {
    flutterLib = localLib = 'lib$_libName.so';
  } else if (Platform.isMacOS || Platform.isIOS) {
    localLib = 'lib$_libName.dylib';
    flutterLib = '$_libName.framework/$_libName';
  } else if (Platform.isWindows) {
    flutterLib = localLib = '$_libName.dll';
  } else {
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  final libBuildPath = '${Directory.current.path}/build/$localLib';
  if (File(libBuildPath).existsSync()) return libBuildPath;
  return flutterLib;
}

/// Native FFI backend for secp256k1 operations via libsecp256k1.
class NativeCurveGateIo implements CurveGate {
  late final NativeSecp256k1 _lib;
  late final Pointer<secp256k1_context> _ctx;

  // Heap arrays for data transfer across FFI boundary
  late final HeapArrayFfi _key32;
  late final HeapArrayFfi _scalar;
  late final HeapArrayFfi _serializedPubKey;
  late final HeapArrayFfi _hash;
  late final HeapArrayFfi _entropy;
  late final HeapArrayFfi _serializedSig;
  late final HeapArrayFfi _derSig;

  // Struct pointers allocated on C heap
  late final Pointer<secp256k1_pubkey> _pubKeyPtr;
  late final Pointer<Size> _sizeTPtr;
  late final Pointer<secp256k1_ecdsa_signature> _sigPtr;
  late final Pointer<secp256k1_ecdsa_recoverable_signature> _recSigPtr;
  late final Pointer<secp256k1_keypair> _keyPairPtr;
  late final Pointer<secp256k1_xonly_pubkey> _xPubKeyPtr;
  late final Pointer<Int> _recIdPtr;

  bool _loaded = false;

  NativeCurveGateIo._();

  static Future<NativeCurveGateIo> create() async {
    final gate = NativeCurveGateIo._();
    await gate.load();
    return gate;
  }

  @override
  Future<void> load() async {
    if (_loaded) return;

    _lib = NativeSecp256k1(DynamicLibrary.open(_libraryPath()));

    // Allocate heap arrays
    _key32 = HeapArrayFfi(32);
    _scalar = HeapArrayFfi(32);
    _serializedPubKey = HeapArrayFfi(65);
    _hash = HeapArrayFfi(32);
    _entropy = HeapArrayFfi(32);
    _serializedSig = HeapArrayFfi(64);
    _derSig = HeapArrayFfi(72);

    // Allocate struct pointers
    _pubKeyPtr = malloc<secp256k1_pubkey>();
    _sizeTPtr = malloc<Size>();
    _sigPtr = malloc<secp256k1_ecdsa_signature>();
    _recSigPtr = malloc<secp256k1_ecdsa_recoverable_signature>();
    _keyPairPtr = malloc<secp256k1_keypair>();
    _xPubKeyPtr = malloc<secp256k1_xonly_pubkey>();
    _recIdPtr = malloc<Int>();

    // Create and randomize context for side-channel protection
    _ctx = _lib.secp256k1_context_create(1); // SECP256K1_CONTEXT_NONE
    final randArray = HeapArrayFfi(32);
    randArray.load(generateSecureBytes(32));
    if (_lib.secp256k1_context_randomize(_ctx, randArray.ffiPtr) != 1) {
      throw StateError('secp256k1 context randomization failed');
    }

    _loaded = true;
  }

  void _requireLoad() {
    if (!_loaded) throw StateError('NativeCurveGateIo.load() not called');
  }

  // -- Serialization helpers --

  Uint8List _serializePubKey(bool compressed) {
    final size = compressed ? 33 : 65;
    _sizeTPtr.value = size;
    final flags = compressed ? 258 : 2; // COMPRESSED / UNCOMPRESSED
    _lib.secp256k1_ec_pubkey_serialize(
      _ctx, _serializedPubKey.ffiPtr, _sizeTPtr, _pubKeyPtr, flags,
    );
    return _serializedPubKey.list.sublist(0, _sizeTPtr.value);
  }

  void _parsePubKey(Uint8List pubKey) {
    _serializedPubKey.load(pubKey);
    if (_lib.secp256k1_ec_pubkey_parse(
          _ctx, _pubKeyPtr, _serializedPubKey.ffiPtr, pubKey.length,
        ) != 1) {
      throw ArgumentError('Invalid public key');
    }
  }

  Uint8List _serializeSig() {
    _lib.secp256k1_ecdsa_signature_serialize_compact(
      _ctx, _serializedSig.ffiPtr, _sigPtr,
    );
    return Uint8List.fromList(_serializedSig.list);
  }

  void _parseSig(Uint8List sig) {
    _serializedSig.load(sig);
    if (_lib.secp256k1_ecdsa_signature_parse_compact(
          _ctx, _sigPtr, _serializedSig.ffiPtr,
        ) != 1) {
      throw ArgumentError('Invalid compact signature');
    }
  }

  void _parseRecoverableSig(Uint8List sig, int recId) {
    _serializedSig.load(sig);
    if (_lib.secp256k1_ecdsa_recoverable_signature_parse_compact(
          _ctx, _recSigPtr, _serializedSig.ffiPtr, recId,
        ) != 1) {
      throw ArgumentError('Invalid recoverable signature');
    }
  }

  // -- CurveGate implementation --

  @override
  bool isValidPrivateKey(Uint8List privKey) {
    _requireLoad();
    if (privKey.length != 32) return false;
    _key32.load(privKey);
    return _lib.secp256k1_ec_seckey_verify(_ctx, _key32.ffiPtr) == 1;
  }

  @override
  Uint8List derivePublicKey(Uint8List privKey, {bool compressed = true}) {
    _requireLoad();
    _key32.load(privKey);
    if (_lib.secp256k1_ec_pubkey_create(_ctx, _pubKeyPtr, _key32.ffiPtr) != 1) {
      throw ArgumentError('Cannot derive public key from private key');
    }
    return _serializePubKey(compressed);
  }

  @override
  Uint8List ecdsaSign(Uint8List hash32, Uint8List privKey) {
    _requireLoad();
    _key32.load(privKey);
    _hash.load(hash32);
    if (_lib.secp256k1_ecdsa_sign(
          _ctx, _sigPtr, _hash.ffiPtr, _key32.ffiPtr, nullptr, nullptr,
        ) != 1) {
      throw StateError('ECDSA signing failed');
    }
    return _serializeSig();
  }

  @override
  bool ecdsaVerify(Uint8List signature, Uint8List hash32, Uint8List pubKey) {
    _requireLoad();
    _parseSig(signature);
    _parsePubKey(pubKey);
    _hash.load(hash32);
    return _lib.secp256k1_ecdsa_verify(_ctx, _sigPtr, _hash.ffiPtr, _pubKeyPtr) == 1;
  }

  @override
  (Uint8List, int) ecdsaSignRecoverable(Uint8List hash32, Uint8List privKey) {
    _requireLoad();
    _key32.load(privKey);
    _hash.load(hash32);
    if (_lib.secp256k1_ecdsa_sign_recoverable(
          _ctx, _recSigPtr, _hash.ffiPtr, _key32.ffiPtr, nullptr, nullptr,
        ) != 1) {
      throw StateError('Recoverable ECDSA signing failed');
    }
    _lib.secp256k1_ecdsa_recoverable_signature_serialize_compact(
      _ctx, _serializedSig.ffiPtr, _recIdPtr, _recSigPtr,
    );
    return (Uint8List.fromList(_serializedSig.list), _recIdPtr.value);
  }

  @override
  Uint8List ecdsaRecover(Uint8List signature, int recId, Uint8List hash32,
      {bool compressed = true}) {
    _requireLoad();
    _parseRecoverableSig(signature, recId);
    _hash.load(hash32);
    if (_lib.secp256k1_ecdsa_recover(
          _ctx, _pubKeyPtr, _recSigPtr, _hash.ffiPtr,
        ) != 1) {
      throw StateError('ECDSA recovery failed');
    }
    return _serializePubKey(compressed);
  }

  @override
  Uint8List schnorrSign(Uint8List hash32, Uint8List privKey,
      {Uint8List? auxRand}) {
    _requireLoad();
    // Create keypair from private key
    _key32.load(privKey);
    if (_lib.secp256k1_keypair_create(_ctx, _keyPairPtr, _key32.ffiPtr) != 1) {
      throw ArgumentError('Invalid private key for Schnorr signing');
    }
    _hash.load(hash32);
    if (auxRand != null) _entropy.load(auxRand);

    if (_lib.secp256k1_schnorrsig_sign32(
          _ctx,
          _serializedSig.ffiPtr,
          _hash.ffiPtr,
          _keyPairPtr,
          auxRand == null ? nullptr : _entropy.ffiPtr,
        ) != 1) {
      throw StateError('Schnorr signing failed');
    }
    return Uint8List.fromList(_serializedSig.list);
  }

  @override
  bool schnorrVerify(Uint8List signature, Uint8List hash32, Uint8List xPubKey) {
    _requireLoad();
    _serializedSig.load(signature);
    _hash.load(hash32);
    _key32.load(xPubKey);
    if (_lib.secp256k1_xonly_pubkey_parse(_ctx, _xPubKeyPtr, _key32.ffiPtr) != 1) {
      return false;
    }
    return _lib.secp256k1_schnorrsig_verify(
          _ctx, _serializedSig.ffiPtr, _hash.ffiPtr, 32, _xPubKeyPtr,
        ) == 1;
  }

  @override
  Uint8List? privateKeyTweakAdd(Uint8List privKey, Uint8List scalar) {
    _requireLoad();
    _key32.load(privKey);
    _scalar.load(scalar);
    if (_lib.secp256k1_ec_seckey_tweak_add(_ctx, _key32.ffiPtr, _scalar.ffiPtr) != 1) {
      return null;
    }
    return Uint8List.fromList(_key32.list);
  }

  @override
  Uint8List? publicKeyTweakAdd(Uint8List pubKey, Uint8List scalar,
      {bool compressed = true}) {
    _requireLoad();
    _parsePubKey(pubKey);
    _scalar.load(scalar);
    if (_lib.secp256k1_ec_pubkey_tweak_add(_ctx, _pubKeyPtr, _scalar.ffiPtr) != 1) {
      return null;
    }
    return _serializePubKey(compressed);
  }

  @override
  Uint8List privateKeyNegate(Uint8List privKey) {
    _requireLoad();
    _key32.load(privKey);
    if (_lib.secp256k1_ec_seckey_negate(_ctx, _key32.ffiPtr) != 1) {
      throw StateError('Private key negation failed');
    }
    return Uint8List.fromList(_key32.list);
  }

  @override
  Uint8List ecdh(Uint8List privKey, Uint8List pubKey) {
    _requireLoad();
    _key32.load(privKey);
    _parsePubKey(pubKey);
    if (_lib.secp256k1_ecdh(
          _ctx, _hash.ffiPtr, _pubKeyPtr, _key32.ffiPtr, nullptr, nullptr,
        ) != 1) {
      throw StateError('ECDH failed');
    }
    return Uint8List.fromList(_hash.list);
  }

  @override
  Uint8List ecdsaCompactToDer(Uint8List compact) {
    _requireLoad();
    _parseSig(compact);
    _sizeTPtr.value = 72;
    _lib.secp256k1_ecdsa_signature_serialize_der(
      _ctx, _derSig.ffiPtr, _sizeTPtr, _sigPtr,
    );
    return _derSig.list.sublist(0, _sizeTPtr.value);
  }

  @override
  Uint8List ecdsaDerToCompact(Uint8List der) {
    _requireLoad();
    _derSig.load(der);
    if (_lib.secp256k1_ecdsa_signature_parse_der(
          _ctx, _sigPtr, _derSig.ffiPtr, der.length,
        ) != 1) {
      throw ArgumentError('Invalid DER signature');
    }
    return _serializeSig();
  }

  @override
  Uint8List ecdsaNormalize(Uint8List signature) {
    _requireLoad();
    _parseSig(signature);
    _lib.secp256k1_ecdsa_signature_normalize(_ctx, _sigPtr, _sigPtr);
    return _serializeSig();
  }
}
