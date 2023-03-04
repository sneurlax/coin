import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;

Uint8List pbkdf2HmacSha512({
  required Uint8List password,
  required Uint8List salt,
  int iterations = 2048,
  int keyLength = 64,
}) {
  final hmac = crypto.Hmac(crypto.sha512, password);
  final numBlocks = (keyLength + 63) ~/ 64;
  final out = Uint8List(numBlocks * 64);

  for (var block = 1; block <= numBlocks; block++) {
    final blockBytes = Uint8List(4);
    blockBytes[0] = (block >> 24) & 0xff;
    blockBytes[1] = (block >> 16) & 0xff;
    blockBytes[2] = (block >> 8) & 0xff;
    blockBytes[3] = block & 0xff;

    final firstInput = Uint8List(salt.length + 4);
    firstInput.setAll(0, salt);
    firstInput.setAll(salt.length, blockBytes);

    var u = Uint8List.fromList(hmac.convert(firstInput).bytes);
    final t = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(
          crypto.Hmac(crypto.sha512, password).convert(u).bytes);
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }

    out.setAll((block - 1) * 64, t);
  }

  return Uint8List.fromList(out.sublist(0, keyLength));
}

Uint8List mnemonicToSeedBytes(String mnemonic, {String passphrase = ''}) {
  final password = Uint8List.fromList(utf8.encode(mnemonic.trim()));
  final salt = Uint8List.fromList(utf8.encode('mnemonic$passphrase'));
  return pbkdf2HmacSha512(
    password: password,
    salt: salt,
    iterations: 2048,
    keyLength: 64,
  );
}
