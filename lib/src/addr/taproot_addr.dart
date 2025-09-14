import 'dart:typed_data';
import '../chain/chain.dart';
import '../crypto/vault_keeper.dart';
import '../script/locking.dart';
import '../script/lockings/pay_to_taproot.dart';
import 'addr.dart';

/// Taproot address (bech32m, witness v1).
class TaprootAddr implements Addr {
  @override
  final Uint8List hash;

  TaprootAddr(this.hash) {
    if (hash.length != 32) throw ArgumentError('Taproot key must be 32 bytes');
  }

  @override
  Locking toLocking() => PayToTaproot(hash);

  @override
  Uint8List get scriptPubKey => toLocking().compiled;

  factory TaprootAddr.fromString(String address, Chain chain) {
    final (hrp, version, data) = VaultKeeper.vault.codec.bech32Decode(address);
    if (hrp != chain.bech32Hrp) throw FormatException('HRP mismatch');
    if (version != 1) throw FormatException('Not a taproot address');
    if (data.length != 32) throw FormatException('Invalid taproot program');
    return TaprootAddr(data);
  }

  @override
  String encode(Chain chain) =>
      VaultKeeper.vault.codec.bech32mEncode(chain.bech32Hrp!, hash, version: 1);
}
