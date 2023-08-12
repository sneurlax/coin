import 'dart:typed_data';
import '../chain/chain.dart';
import '../crypto/vault_keeper.dart';
import 'addr.dart';

abstract class LegacyAddr implements Addr {
  factory LegacyAddr.fromString(String address, Chain chain) {
    final payload = VaultKeeper.vault.codec.base58CheckDecode(address);
    if (payload.isEmpty) throw FormatException('Empty address payload');
    final version = payload[0];
    final hash = payload.sublist(1);
    if (version == chain.p2pkhPrefix) return P2pkhAddr(hash);
    if (version == chain.p2shPrefix) return P2shAddr(hash);
    throw FormatException('Unknown address version: $version');
  }
}

class P2pkhAddr implements LegacyAddr {
  @override
  final Uint8List hash;

  P2pkhAddr(this.hash) {
    if (hash.length != 20) throw ArgumentError('P2PKH hash must be 20 bytes');
  }

  @override
  String encode(Chain chain) {
    final payload = Uint8List(21);
    payload[0] = chain.p2pkhPrefix;
    payload.setRange(1, 21, hash);
    return VaultKeeper.vault.codec.base58CheckEncode(payload);
  }
}

class P2shAddr implements LegacyAddr {
  @override
  final Uint8List hash;

  P2shAddr(this.hash) {
    if (hash.length != 20) throw ArgumentError('P2SH hash must be 20 bytes');
  }

  @override
  String encode(Chain chain) {
    final payload = Uint8List(21);
    payload[0] = chain.p2shPrefix;
    payload.setRange(1, 21, hash);
    return VaultKeeper.vault.codec.base58CheckEncode(payload);
  }
}
