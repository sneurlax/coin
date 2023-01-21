import 'dart:math';
import 'dart:typed_data';

Uint8List generateSecureBytes(int n) {
  final rng = Random.secure();
  final bytes = Uint8List(n);
  for (var i = 0; i < n; i++) {
    bytes[i] = rng.nextInt(256);
  }
  return bytes;
}
