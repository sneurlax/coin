import 'dart:typed_data';

const _hexChars = '0123456789abcdef';

String hexEncode(Uint8List bytes) {
  final buf = StringBuffer();
  for (final b in bytes) {
    buf.write(_hexChars[b >> 4]);
    buf.write(_hexChars[b & 0x0f]);
  }
  return buf.toString();
}

/// Accepts optional "0x" prefix.
Uint8List hexDecode(String hex) {
  var s = hex;
  if (s.startsWith('0x') || s.startsWith('0X')) {
    s = s.substring(2);
  }
  if (s.length.isOdd) {
    s = '0$s';
  }
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    final hi = _hexVal(s.codeUnitAt(i * 2));
    final lo = _hexVal(s.codeUnitAt(i * 2 + 1));
    out[i] = (hi << 4) | lo;
  }
  return out;
}

int _hexVal(int c) {
  if (c >= 0x30 && c <= 0x39) return c - 0x30; // 0-9
  if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10; // a-f
  if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10; // A-F
  throw FormatException('Invalid hex character: ${String.fromCharCode(c)}');
}
