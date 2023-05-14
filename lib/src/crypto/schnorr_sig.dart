import 'dart:typed_data';

import '../core/bytes.dart';
import '../core/hex.dart';
import 'vault_keeper.dart';

class SchnorrSig {
  final Uint8List _data;

  SchnorrSig(Uint8List bytes) : _data = copyCheckBytes(bytes, 64, 'signature');

  factory SchnorrSig.fromHex(String hex) => SchnorrSig(hexDecode(hex));

  factory SchnorrSig.sign(Uint8List hash32, Uint8List privKey,
          {Uint8List? auxRand}) =>
      SchnorrSig(VaultKeeper.vault.curve.schnorrSign(hash32, privKey,
          auxRand: auxRand));

  Uint8List get bytes => Uint8List.fromList(_data);

  bool verify(Uint8List hash32, Uint8List xPubKey) =>
      VaultKeeper.vault.curve.schnorrVerify(_data, hash32, xPubKey);

  String toHex() => hexEncode(_data);

  @override
  bool operator ==(Object other) =>
      other is SchnorrSig && bytesEqual(_data, other._data);

  @override
  int get hashCode => Object.hashAll(_data);
}
