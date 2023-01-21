import 'dart:typed_data';

Uint8List copyCheckBytes(Uint8List bytes, int length, [String name = 'bytes']) {
  if (bytes.length != length) {
    throw ArgumentError('$name must be $length bytes, got ${bytes.length}');
  }
  return Uint8List.fromList(bytes);
}

bool bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int compareBytes(Uint8List a, Uint8List b) {
  final len = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return a.length.compareTo(b.length);
}

Uint8List concatBytes(List<Uint8List> parts) {
  var total = 0;
  for (final p in parts) {
    total += p.length;
  }
  final out = Uint8List(total);
  var offset = 0;
  for (final p in parts) {
    out.setAll(offset, p);
    offset += p.length;
  }
  return out;
}
