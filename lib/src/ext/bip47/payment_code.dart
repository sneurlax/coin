import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../core/hex.dart';
import '../../crypto/vault_keeper.dart';
import '../../crypto/public_key.dart';
import '../../hash/digest.dart';
import '../../hash/hmac.dart';
import '../../addr/legacy_addr.dart';
import '../../chain/chain.dart';

/// 80-byte payload:
/// ```
/// [0]      version (0x01)
/// [1]      features (bit 0 = segwit)
/// [2..34]  compressed public key (33 bytes)
/// [35..66] chain code (32 bytes)
/// [67..79] reserved zeros
/// ```
class PaymentCode {
  static const int version = 0x01;
  static const int _base58Version = 0x47;

  final Uint8List _payload;

  PaymentCode(Uint8List payload)
      : _payload = Uint8List.fromList(payload) {
    if (payload.length != 80) {
      throw ArgumentError('Payment code payload must be 80 bytes');
    }
    if (payload[0] != version) {
      throw ArgumentError('Unsupported payment code version');
    }
  }

  factory PaymentCode.fromPublicKey({
    required Uint8List pubKey,
    required Uint8List chainCode,
    bool segwit = false,
  }) {
    if (pubKey.length != 33) {
      throw ArgumentError('Public key must be 33 bytes (compressed)');
    }
    if (chainCode.length != 32) {
      throw ArgumentError('Chain code must be 32 bytes');
    }

    final payload = Uint8List(80);
    payload[0] = version;
    payload[1] = segwit ? 0x01 : 0x00;
    payload.setRange(2, 35, pubKey);
    payload.setRange(35, 67, chainCode);
    // 67..79 reserved
    return PaymentCode(payload);
  }

  factory PaymentCode.fromBase58(String encoded) {
    final decoded = VaultKeeper.vault.codec.base58CheckDecode(encoded);
    if (decoded.isEmpty) {
      throw FormatException('Empty payment code');
    }
    if (decoded[0] != _base58Version) {
      throw FormatException(
          'Invalid payment code version byte: 0x${decoded[0].toRadixString(16)}');
    }
    if (decoded.length != 81) {
      throw FormatException(
          'Payment code must be 81 bytes (1 version + 80 payload), '
          'got ${decoded.length}');
    }
    return PaymentCode(decoded.sublist(1));
  }

  String toBase58() {
    final data = Uint8List(81);
    data[0] = _base58Version;
    data.setRange(1, 81, _payload);
    return VaultKeeper.vault.codec.base58CheckEncode(data);
  }

  Uint8List get payload => Uint8List.fromList(_payload);

  Uint8List get notificationPublicKey =>
      Uint8List.fromList(_payload.sublist(2, 35));

  Uint8List get chainCode => Uint8List.fromList(_payload.sublist(35, 67));

  bool get isSegwit => (_payload[1] & 0x01) != 0;

  String notificationAddress(Chain chain) {
    final childKey = derivePublicKey(0);
    final pkHash = hash160(childKey.bytes);
    return P2pkhAddr(pkHash).encode(chain);
  }

  /// BIP32 public child derivation:
  /// ```
  /// I  = HMAC-SHA512(key=chainCode, data=pubKey || index_be32)
  /// IL = I[0..31]
  /// child = parent + IL*G
  /// ```
  PublicKey derivePublicKey(int index) {
    final pubKeyBytes = notificationPublicKey;
    final data = Uint8List(37);
    data.setRange(0, 33, pubKeyBytes);
    data.buffer.asByteData().setUint32(33, index, Endian.big);

    final I = hmacSha512(chainCode, data);
    final IL = I.sublist(0, 32);

    final parentPubKey = PublicKey(pubKeyBytes);
    final childPubKey = parentPubKey.tweak(IL);
    if (childPubKey == null) {
      throw StateError('Invalid child key derivation at index $index');
    }
    return childPubKey;
  }

  bool isValid() {
    if (_payload.length != 80) return false;
    if (_payload[0] != version) return false;

    final prefix = _payload[2];
    if (prefix != 0x02 && prefix != 0x03) return false;

    for (var i = 67; i < 80; i++) {
      if (_payload[i] != 0) return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentCode && bytesEqual(_payload, other._payload);

  @override
  int get hashCode => Object.hashAll(_payload);

  @override
  String toString() => toBase58();
}
