import 'dart:typed_data';

import '../../crypto/secret_key.dart';
import '../../crypto/public_key.dart';

class SecretPoint {
  final Uint8List _secret;

  SecretPoint(SecretKey privateKey, PublicKey publicKey)
      : _secret = privateKey.ecdh(publicKey);

  Uint8List get ecdhSecret => Uint8List.fromList(_secret);
}
