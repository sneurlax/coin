import 'dart:typed_data';

import '../../core/bytes.dart';
import '../encode/monero_base58.dart';

enum MoneroAddrType { standard, integrated, subaddress }

/// Monero addresses encode two Ed25519 public keys (spend + view) rather
/// than a single hash, so they don't share the Bitcoin [Addr] interface.
abstract class MoneroAddr {
  Uint8List get publicSpendKey;
  Uint8List get publicViewKey;
  MoneroAddrType get addrType;
  String encode(int networkByte);

  /// Network bytes distinguish address types during decoding.
  factory MoneroAddr.fromString(
    String address, {
    required int standardByte,
    required int integratedByte,
    required int subaddrByte,
  }) {
    final raw = moneroBase58Decode(address);
    if (raw.length < 5) {
      throw FormatException(
          'Monero address too short: ${raw.length} bytes');
    }

    // Split payload and checksum.
    final payload = Uint8List.sublistView(raw, 0, raw.length - 4);
    final checksum = Uint8List.sublistView(raw, raw.length - 4);
    final expected = moneroChecksum(payload);

    if (!bytesEqual(checksum, expected)) {
      throw const FormatException('Monero address checksum mismatch');
    }

    final netByte = payload[0];

    if (netByte == standardByte) {
      if (payload.length != 65) {
        throw FormatException(
            'Standard address payload must be 65 bytes, got ${payload.length}');
      }
      return MoneroStandardAddr(
        Uint8List.fromList(payload.sublist(1, 33)),
        Uint8List.fromList(payload.sublist(33, 65)),
      );
    }

    if (netByte == subaddrByte) {
      if (payload.length != 65) {
        throw FormatException(
            'Subaddress payload must be 65 bytes, got ${payload.length}');
      }
      return MoneroSubaddr(
        Uint8List.fromList(payload.sublist(1, 33)),
        Uint8List.fromList(payload.sublist(33, 65)),
      );
    }

    if (netByte == integratedByte) {
      if (payload.length != 73) {
        throw FormatException(
            'Integrated address payload must be 73 bytes, got ${payload.length}');
      }
      return MoneroIntegratedAddr(
        Uint8List.fromList(payload.sublist(1, 33)),
        Uint8List.fromList(payload.sublist(33, 65)),
        Uint8List.fromList(payload.sublist(65, 73)),
      );
    }

    throw FormatException('Unknown Monero network byte: 0x${netByte.toRadixString(16)}');
  }

  factory MoneroAddr.mainnet(String address) => MoneroAddr.fromString(
        address,
        standardByte: 0x12,
        integratedByte: 0x13,
        subaddrByte: 0x2a,
      );

  factory MoneroAddr.testnet(String address) => MoneroAddr.fromString(
        address,
        standardByte: 0x35,
        integratedByte: 0x36,
        subaddrByte: 0x3f,
      );

  factory MoneroAddr.stagenet(String address) => MoneroAddr.fromString(
        address,
        standardByte: 0x18,
        integratedByte: 0x19,
        subaddrByte: 0x24,
      );
}

/// Standard address: net_byte(1) || spend_key(32) || view_key(32) || checksum(4).
class MoneroStandardAddr implements MoneroAddr {
  @override
  final Uint8List publicSpendKey;

  @override
  final Uint8List publicViewKey;

  @override
  MoneroAddrType get addrType => MoneroAddrType.standard;

  MoneroStandardAddr(Uint8List spendKey, Uint8List viewKey)
      : publicSpendKey = copyCheckBytes(spendKey, 32, 'publicSpendKey'),
        publicViewKey = copyCheckBytes(viewKey, 32, 'publicViewKey');

  @override
  String encode(int networkByte) {
    final payload = Uint8List(65);
    payload[0] = networkByte;
    payload.setRange(1, 33, publicSpendKey);
    payload.setRange(33, 65, publicViewKey);
    final checksum = moneroChecksum(payload);
    return moneroBase58Encode(concatBytes([payload, checksum]));
  }

  String encodeMainnet() => encode(0x12);
  String encodeTestnet() => encode(0x35);
  String encodeStagenet() => encode(0x18);
}

/// Integrated address: net_byte(1) || spend_key(32) || view_key(32) || payment_id(8) || checksum(4).
class MoneroIntegratedAddr implements MoneroAddr {
  @override
  final Uint8List publicSpendKey;

  @override
  final Uint8List publicViewKey;

  final Uint8List paymentId;

  @override
  MoneroAddrType get addrType => MoneroAddrType.integrated;

  MoneroIntegratedAddr(
      Uint8List spendKey, Uint8List viewKey, Uint8List paymentId)
      : publicSpendKey = copyCheckBytes(spendKey, 32, 'publicSpendKey'),
        publicViewKey = copyCheckBytes(viewKey, 32, 'publicViewKey'),
        paymentId = copyCheckBytes(paymentId, 8, 'paymentId');

  @override
  String encode(int networkByte) {
    final payload = Uint8List(73);
    payload[0] = networkByte;
    payload.setRange(1, 33, publicSpendKey);
    payload.setRange(33, 65, publicViewKey);
    payload.setRange(65, 73, paymentId);
    final checksum = moneroChecksum(payload);
    return moneroBase58Encode(concatBytes([payload, checksum]));
  }

  String encodeMainnet() => encode(0x13);
  String encodeTestnet() => encode(0x36);
  String encodeStagenet() => encode(0x19);
}

/// Subaddress: same layout as standard but different network byte prefix.
class MoneroSubaddr implements MoneroAddr {
  @override
  final Uint8List publicSpendKey;

  @override
  final Uint8List publicViewKey;

  @override
  MoneroAddrType get addrType => MoneroAddrType.subaddress;

  MoneroSubaddr(Uint8List spendKey, Uint8List viewKey)
      : publicSpendKey = copyCheckBytes(spendKey, 32, 'publicSpendKey'),
        publicViewKey = copyCheckBytes(viewKey, 32, 'publicViewKey');

  @override
  String encode(int networkByte) {
    final payload = Uint8List(65);
    payload[0] = networkByte;
    payload.setRange(1, 33, publicSpendKey);
    payload.setRange(33, 65, publicViewKey);
    final checksum = moneroChecksum(payload);
    return moneroBase58Encode(concatBytes([payload, checksum]));
  }

  String encodeMainnet() => encode(0x2a);
  String encodeTestnet() => encode(0x3f);
  String encodeStagenet() => encode(0x24);
}
