import 'dart:typed_data';
import '../chain/chain.dart';
import 'legacy_addr.dart';
import 'segwit_addr.dart';
import 'taproot_addr.dart';

abstract class Addr {
  String encode(Chain chain);
  Uint8List get hash;

  factory Addr.fromString(String address, Chain chain) {
    // Try bech32m (taproot)
    try {
      return TaprootAddr.fromString(address, chain);
    } catch (_) {}

    // Try bech32 (segwit v0)
    try {
      return SegwitAddr.fromString(address, chain);
    } catch (_) {}

    // Try base58 (legacy)
    return LegacyAddr.fromString(address, chain);
  }
}
