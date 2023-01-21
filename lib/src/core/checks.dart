void checkUint8(int i) {
  if (i < 0 || i > 0xff) {
    throw ArgumentError.value(i, 'value', 'Not a uint8');
  }
}

void checkUint16(int i) {
  if (i < 0 || i > 0xffff) {
    throw ArgumentError.value(i, 'value', 'Not a uint16');
  }
}

void checkUint32(int i) {
  if (i < 0 || i > 0xffffffff) {
    throw ArgumentError.value(i, 'value', 'Not a uint32');
  }
}

void checkInt32(int i) {
  if (i < -0x80000000 || i > 0x7fffffff) {
    throw ArgumentError.value(i, 'value', 'Not an int32');
  }
}

void checkUint64(BigInt i) {
  if (i.isNegative || i.bitLength > 64) {
    throw ArgumentError.value(i, 'value', 'Not a uint64');
  }
}
