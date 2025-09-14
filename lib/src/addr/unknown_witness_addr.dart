import 'dart:typed_data';
import '../chain/chain.dart';
import '../crypto/vault_keeper.dart';
import '../script/locking.dart';
import '../script/lockings/pay_to_witness.dart';
import 'addr.dart';

/// For witness versions 2-16 (future soft forks).
class UnknownWitnessAddr implements Addr {
  final int version;
  @override
  final Uint8List hash;

  UnknownWitnessAddr(this.version, this.hash) {
    if (version < 2 || version > 16) {
      throw ArgumentError('Version must be 2-16');
    }
  }

  @override
  Locking toLocking() => PayToWitness(version, hash);

  @override
  Uint8List get scriptPubKey => toLocking().compiled;

  @override
  String encode(Chain chain) => VaultKeeper.vault.codec
      .bech32mEncode(chain.bech32Hrp!, hash, version: version);
}
