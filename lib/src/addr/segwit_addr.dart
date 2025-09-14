import 'dart:typed_data';
import '../chain/chain.dart';
import '../crypto/vault_keeper.dart';
import '../script/locking.dart';
import '../script/lockings/pay_to_witness_pubkey.dart';
import '../script/lockings/pay_to_witness_script.dart';
import 'addr.dart';

abstract class SegwitAddr implements Addr {
  factory SegwitAddr.fromString(String address, Chain chain) {
    final (hrp, version, data) = VaultKeeper.vault.codec.bech32Decode(address);
    if (hrp != chain.bech32Hrp) throw FormatException('HRP mismatch');
    if (version != 0) throw FormatException('Not a segwit v0 address');
    if (data.length == 20) return P2wpkhAddr(data);
    if (data.length == 32) return P2wshAddr(data);
    throw FormatException('Invalid witness program length');
  }
}

class P2wpkhAddr implements SegwitAddr {
  @override
  final Uint8List hash;

  P2wpkhAddr(this.hash) {
    if (hash.length != 20) throw ArgumentError('P2WPKH hash must be 20 bytes');
  }

  @override
  Locking toLocking() => PayToWitnessPubKey(hash);

  @override
  Uint8List get scriptPubKey => toLocking().compiled;

  @override
  String encode(Chain chain) =>
      VaultKeeper.vault.codec.bech32Encode(chain.bech32Hrp!, hash, version: 0);
}

class P2wshAddr implements SegwitAddr {
  @override
  final Uint8List hash;

  P2wshAddr(this.hash) {
    if (hash.length != 32) throw ArgumentError('P2WSH hash must be 32 bytes');
  }

  @override
  Locking toLocking() => PayToWitnessScript(hash);

  @override
  Uint8List get scriptPubKey => toLocking().compiled;

  @override
  String encode(Chain chain) =>
      VaultKeeper.vault.codec.bech32Encode(chain.bech32Hrp!, hash, version: 0);
}
