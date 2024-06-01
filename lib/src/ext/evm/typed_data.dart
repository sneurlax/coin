import 'dart:convert';
import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../core/hex.dart';
import '../../hash/digest.dart';
import '../../crypto/ecdsa_sig.dart';
import '../../crypto/secret_key.dart';

/// EIP-712 typed structured data hashing and signing.
class TypedPayload {
  final Map<String, dynamic> domain;
  final String primaryType;
  final Map<String, List<Map<String, String>>> types;
  final Map<String, dynamic> message;

  TypedPayload({
    required this.domain,
    required this.primaryType,
    required this.types,
    required this.message,
  });

  factory TypedPayload.fromJson(String jsonStr) {
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return TypedPayload(
      domain: map['domain'] as Map<String, dynamic>,
      primaryType: map['primaryType'] as String,
      types: (map['types'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList(),
        ),
      ),
      message: map['message'] as Map<String, dynamic>,
    );
  }

  Uint8List domainSeparator() {
    return _hashStruct('EIP712Domain', domain);
  }

  Uint8List structHash() {
    return _hashStruct(primaryType, message);
  }

  /// keccak256("\x19\x01" || domainSeparator || structHash).
  Uint8List signingHash() {
    final ds = domainSeparator();
    final sh = structHash();
    return keccak256(concatBytes([
      Uint8List.fromList([0x19, 0x01]),
      ds,
      sh,
    ]));
  }

  /// Returns 65 bytes: r (32) + s (32) + v (1).
  Uint8List sign(SecretKey key) {
    final hash = signingHash();
    final sig = RecoverableEcdsaSig.sign(hash, key.bytes);
    final out = Uint8List(65);
    out.setRange(0, 64, sig.bytes);
    out[64] = sig.recId + 27;
    return out;
  }

  Uint8List _hashStruct(String typeName, Map<String, dynamic> data) {
    final typeHash = _typeHash(typeName);
    final encodedValues = <Uint8List>[typeHash];

    final fields = types[typeName];
    if (fields == null) {
      throw ArgumentError('Unknown type: $typeName');
    }

    for (final field in fields) {
      final name = field['name']!;
      final type = field['type']!;
      encodedValues.add(_encodeValue(type, data[name]));
    }

    return keccak256(concatBytes(encodedValues));
  }

  Uint8List _typeHash(String typeName) {
    final encoded = _encodeType(typeName);
    return keccak256(Uint8List.fromList(utf8.encode(encoded)));
  }

  String _encodeType(String typeName) {
    final fields = types[typeName];
    if (fields == null) throw ArgumentError('Unknown type: $typeName');

    final fieldStr =
        fields.map((f) => '${f['type']} ${f['name']}').join(',');
    final primary = '$typeName($fieldStr)';

    final deps = <String>{};
    _collectDeps(typeName, deps);
    deps.remove(typeName);

    final sorted = deps.toList()..sort();
    final depStrs = sorted.map((t) {
      final f = types[t]!;
      final s = f.map((ff) => '${ff['type']} ${ff['name']}').join(',');
      return '$t($s)';
    });

    return '$primary${depStrs.join()}';
  }

  void _collectDeps(String typeName, Set<String> deps) {
    if (deps.contains(typeName)) return;
    final fields = types[typeName];
    if (fields == null) return;
    deps.add(typeName);
    for (final field in fields) {
      final type = _stripArray(field['type']!);
      if (types.containsKey(type)) {
        _collectDeps(type, deps);
      }
    }
  }

  static String _stripArray(String type) {
    final idx = type.indexOf('[');
    return idx >= 0 ? type.substring(0, idx) : type;
  }

  Uint8List _encodeValue(String type, dynamic value) {
    if (types.containsKey(type)) {
      return _hashStruct(type, value as Map<String, dynamic>);
    }

    if (type.endsWith('[]')) {
      final inner = type.substring(0, type.length - 2);
      final items = value as List;
      final encoded = items.map((v) => _encodeValue(inner, v)).toList();
      return keccak256(concatBytes(encoded));
    }

    if (type == 'address') {
      return _padLeft32(hexDecode(value as String));
    }
    if (type == 'bool') {
      return _padLeft32(Uint8List.fromList([value == true ? 1 : 0]));
    }
    if (type == 'string') {
      return keccak256(Uint8List.fromList(utf8.encode(value as String)));
    }
    if (type == 'bytes') {
      final bytes = value is Uint8List ? value : hexDecode(value as String);
      return keccak256(bytes);
    }
    if (type.startsWith('uint')) {
      final v = value is BigInt ? value : BigInt.from(value as int);
      return _bigIntTo32(v);
    }
    if (type.startsWith('int')) {
      final v = value is BigInt ? value : BigInt.from(value as int);
      return _signedBigIntTo32(v);
    }
    if (type.startsWith('bytes')) {
      final bytes = value is Uint8List ? value : hexDecode(value as String);
      final out = Uint8List(32);
      out.setRange(0, bytes.length, bytes);
      return out;
    }

    throw ArgumentError('Unsupported EIP-712 type: $type');
  }

  static Uint8List _padLeft32(Uint8List bytes) {
    final out = Uint8List(32);
    out.setRange(32 - bytes.length, 32, bytes);
    return out;
  }

  static Uint8List _bigIntTo32(BigInt value) {
    final out = Uint8List(32);
    var v = value;
    for (var i = 31; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v >>= 8;
    }
    return out;
  }

  static Uint8List _signedBigIntTo32(BigInt value) {
    // Two's complement, 256 bits.
    final v = value < BigInt.zero
        ? (BigInt.one << 256) + value
        : value;
    return _bigIntTo32(v);
  }
}
