import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../crypto/vault_keeper.dart';
import 'monero_keys.dart';

/// Subaddress (i, j): m = Hs("SubAddr\0" || viewKey || i || j),
/// subSpend = m*G + mainSpend, subView = viewKey * subSpend.
/// (0, 0) returns the main keys directly.
class MoneroSubaddress {
  final Uint8List publicSpendKey;
  final Uint8List publicViewKey;
  final int accountIndex;
  final int addressIndex;

  MoneroSubaddress._({
    required this.publicSpendKey,
    required this.publicViewKey,
    required this.accountIndex,
    required this.addressIndex,
  });

  static MoneroSubaddress derive(
    MoneroKeys keys,
    int accountIndex,
    int addressIndex,
  ) {
    if (accountIndex == 0 && addressIndex == 0) {
      return MoneroSubaddress._(
        publicSpendKey: Uint8List.fromList(keys.publicSpendKey),
        publicViewKey: Uint8List.fromList(keys.publicViewKey),
        accountIndex: 0,
        addressIndex: 0,
      );
    }

    final prefix = Uint8List.fromList('SubAddr\x00'.codeUnits);
    final indexBytes = Uint8List(8);
    ByteData.sublistView(indexBytes)
        .setUint32(0, accountIndex, Endian.little);
    ByteData.sublistView(indexBytes)
        .setUint32(4, addressIndex, Endian.little);

    final hashInput = concatBytes([prefix, keys.privateViewKey, indexBytes]);

    final ed = VaultKeeper.vault.ed25519;
    final hash = VaultKeeper.vault.digest.keccak256(hashInput);
    final mBytes = ed.scalarReduce(hash);

    final mG = ed.scalarMultBase(mBytes);
    final subSpendBytes = ed.pointAdd(mG, keys.publicSpendKey);

    final subViewBytes = ed.scalarMult(keys.privateViewKey, subSpendBytes);

    return MoneroSubaddress._(
      publicSpendKey: subSpendBytes,
      publicViewKey: subViewBytes,
      accountIndex: accountIndex,
      addressIndex: addressIndex,
    );
  }
}
