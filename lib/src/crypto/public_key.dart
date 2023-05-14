import 'dart:typed_data';

import '../core/bytes.dart';
import '../core/hex.dart';
import 'vault_keeper.dart';

class PublicKey {
  final Uint8List _data;

  PublicKey(Uint8List bytes) : _data = Uint8List.fromList(bytes) {
    if (bytes.length != 33 && bytes.length != 65) {
      throw ArgumentError(
          'Public key must be 33 (compressed) or 65 (uncompressed) bytes, '
          'got ${bytes.length}');
    }
  }

  factory PublicKey.fromHex(String hex) => PublicKey(hexDecode(hex));

  Uint8List get bytes => Uint8List.fromList(_data);

  bool get isCompressed => _data.length == 33;

  Uint8List get x {
    if (_data.length == 33) return _data.sublist(1, 33);
    return _data.sublist(1, 33);
  }

  Uint8List get xOnly => x;

  bool get yIsEven =>
      _data.length == 33 ? _data[0] == 0x02 : _data[64].isEven;

  PublicKey? tweak(Uint8List scalar) {
    final result = VaultKeeper.vault.curve.publicKeyTweakAdd(_data, scalar);
    if (result == null) return null;
    return PublicKey(result);
  }

  String toHex() => hexEncode(_data);

  @override
  bool operator ==(Object other) =>
      other is PublicKey && bytesEqual(_data, other._data);

  @override
  int get hashCode => Object.hashAll(_data);
}
