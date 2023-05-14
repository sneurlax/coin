import 'dart:typed_data';

import '../core/bytes.dart';
import '../core/hex.dart';
import 'vault_keeper.dart';

class EcdsaSig {
  final Uint8List _data;

  EcdsaSig(Uint8List bytes) : _data = copyCheckBytes(bytes, 64, 'signature');

  factory EcdsaSig.fromHex(String hex) => EcdsaSig(hexDecode(hex));

  factory EcdsaSig.sign(Uint8List hash32, Uint8List privKey) =>
      EcdsaSig(VaultKeeper.vault.curve.ecdsaSign(hash32, privKey));

  Uint8List get bytes => Uint8List.fromList(_data);

  bool verify(Uint8List hash32, Uint8List pubKey) =>
      VaultKeeper.vault.curve.ecdsaVerify(_data, hash32, pubKey);

  Uint8List toDer() => VaultKeeper.vault.curve.ecdsaCompactToDer(_data);

  factory EcdsaSig.fromDer(Uint8List der) =>
      EcdsaSig(VaultKeeper.vault.curve.ecdsaDerToCompact(der));

  EcdsaSig normalize() =>
      EcdsaSig(VaultKeeper.vault.curve.ecdsaNormalize(_data));

  String toHex() => hexEncode(_data);

  @override
  bool operator ==(Object other) =>
      other is EcdsaSig && bytesEqual(_data, other._data);

  @override
  int get hashCode => Object.hashAll(_data);
}

class RecoverableEcdsaSig {
  final Uint8List _data;
  final int recId;

  RecoverableEcdsaSig(Uint8List bytes, this.recId)
      : _data = copyCheckBytes(bytes, 64, 'signature') {
    if (recId < 0 || recId > 3) {
      throw ArgumentError.value(recId, 'recId', 'Must be 0-3');
    }
  }

  factory RecoverableEcdsaSig.sign(Uint8List hash32, Uint8List privKey) {
    final (sig, recId) =
        VaultKeeper.vault.curve.ecdsaSignRecoverable(hash32, privKey);
    return RecoverableEcdsaSig(sig, recId);
  }

  Uint8List get bytes => Uint8List.fromList(_data);

  Uint8List recover(Uint8List hash32, {bool compressed = true}) =>
      VaultKeeper.vault.curve.ecdsaRecover(_data, recId, hash32,
          compressed: compressed);

  EcdsaSig toCompact() => EcdsaSig(_data);

  Uint8List toBytes65() {
    final out = Uint8List(65);
    out.setRange(0, 64, _data);
    out[64] = recId;
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is RecoverableEcdsaSig &&
      recId == other.recId &&
      bytesEqual(_data, other._data);

  @override
  int get hashCode => Object.hashAll([..._data, recId]);
}
