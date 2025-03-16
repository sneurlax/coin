import 'dart:typed_data';

import 'ed25519_constants.dart';

EdPoint edPointAdd(EdPoint p1, EdPoint p2) {
  if (p1.isInfinity) return p2;
  if (p2.isInfinity) return p1;

  final x1 = p1.x;
  final y1 = p1.y;
  final x2 = p2.x;
  final y2 = p2.y;

  final x1x2 = (x1 * x2) % ed25519P;
  final y1y2 = (y1 * y2) % ed25519P;
  final x1y2 = (x1 * y2) % ed25519P;
  final y1x2 = (y1 * x2) % ed25519P;

  final dxy = (ed25519D * x1x2 % ed25519P * y1y2) % ed25519P;

  final x3num = (x1y2 + y1x2) % ed25519P;
  final x3den = (BigInt.one + dxy) % ed25519P;

  final y3num = (y1y2 + x1x2) % ed25519P;
  final y3den = (BigInt.one - dxy + ed25519P) % ed25519P;

  final x3 = (x3num * x3den.modInverse(ed25519P)) % ed25519P;
  final y3 = (y3num * y3den.modInverse(ed25519P)) % ed25519P;
  return EdPoint(x3, y3);
}

EdPoint edScalarMult(BigInt k, EdPoint point) {
  if (k == BigInt.zero) return EdPoint.infinity();
  if (k == BigInt.one) return point;

  var result = EdPoint.infinity();
  var addend = point;
  var tempK = k % ed25519L;

  while (tempK > BigInt.zero) {
    if (tempK.isOdd) {
      result = edPointAdd(result, addend);
    }
    addend = edPointAdd(addend, addend);
    tempK >>= 1;
  }
  return result;
}

Uint8List edPointToBytes(EdPoint point) {
  if (point.isInfinity) {
    final bytes = Uint8List(32);
    bytes[0] = 0x01;
    return bytes;
  }
  final bytes = edBigIntToBytes(point.y, 32);
  if (point.x.isOdd) {
    bytes[31] |= 0x80;
  }
  return bytes;
}

EdPoint edBytesToPoint(Uint8List bytes) {
  if (bytes.length != 32) {
    throw ArgumentError('Invalid encoded point length (${bytes.length} bytes)');
  }

  final sign = (bytes[31] >> 7) & 1;
  final yBytes = Uint8List.fromList(bytes);
  yBytes[31] &= 0x7F;
  final y = edBytesToBigInt(yBytes);

  if (y >= ed25519P) {
    throw ArgumentError('Invalid point: y >= p');
  }

  final y2 = (y * y) % ed25519P;
  final u = (y2 - BigInt.one + ed25519P) % ed25519P;
  final v = (ed25519D * y2 + BigInt.one) % ed25519P;

  final v3 = (v * v % ed25519P * v) % ed25519P;
  final v7 = (v3 * v3 % ed25519P * v) % ed25519P;
  final uv7 = (u * v7) % ed25519P;

  final exp = (ed25519P - BigInt.from(5)) >> 3;
  var x = (u * v3 % ed25519P * uv7.modPow(exp, ed25519P)) % ed25519P;

  final vx2 = (v * x % ed25519P * x) % ed25519P;
  if (vx2 == u) {
    // x is correct
  } else if (vx2 == (ed25519P - u) % ed25519P) {
    x = (x * ed25519I) % ed25519P;
  } else {
    throw ArgumentError('Invalid point: no square root exists');
  }

  if (x == BigInt.zero && sign == 1) {
    throw ArgumentError('Invalid point: x is zero but sign bit is set');
  }

  if ((x.isOdd ? 1 : 0) != sign) {
    x = ed25519P - x;
  }

  return EdPoint(x, y);
}

BigInt edScalarReduce(Uint8List bytes) {
  return edBytesToBigInt(bytes) % ed25519L;
}

bool edIsOnCurve(EdPoint point) {
  if (point.isInfinity) return true;
  final x2 = (point.x * point.x) % ed25519P;
  final y2 = (point.y * point.y) % ed25519P;
  final left = (ed25519P - x2 + y2) % ed25519P;
  final right = (BigInt.one + ed25519D * x2 % ed25519P * y2) % ed25519P;
  return left == right;
}

BigInt edBytesToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (var i = bytes.length - 1; i >= 0; i--) {
    result = (result << 8) + BigInt.from(bytes[i]);
  }
  return result;
}

Uint8List edBigIntToBytes(BigInt value, int length) {
  final bytes = Uint8List(length);
  var temp = value;
  for (var i = 0; i < length; i++) {
    bytes[i] = (temp & BigInt.from(0xFF)).toInt();
    temp >>= 8;
  }
  return bytes;
}
