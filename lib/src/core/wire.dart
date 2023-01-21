import 'dart:typed_data';

import 'checks.dart';
import 'hex.dart';

class OutOfData implements Exception {
  final int position;
  final int readLength;
  final int bytesLength;
  OutOfData(this.position, this.readLength, this.bytesLength);
  @override
  String toString() =>
      'Cannot access $readLength bytes at position $position '
      'for buffer of length $bytesLength';
}

class WireReader {
  final ByteData _data;
  int offset;

  WireReader(Uint8List bytes, [this.offset = 0])
      : _data = bytes.buffer.asByteData(
            bytes.offsetInBytes, bytes.lengthInBytes);

  bool get atEnd => offset == _data.lengthInBytes;
  int get remaining => _data.lengthInBytes - offset;

  T _require<T>(int n, T Function() f) {
    if (offset + n > _data.lengthInBytes) {
      throw OutOfData(offset, n, _data.lengthInBytes);
    }
    return f();
  }

  int readUInt8() => _require(1, () => _data.getUint8(offset++));

  int readUInt16() => _require(
      2, () => _data.getUint16((offset += 2) - 2, Endian.little));

  int readUInt32() => _require(
      4, () => _data.getUint32((offset += 4) - 4, Endian.little));

  int readInt32() => _require(
      4, () => _data.getInt32((offset += 4) - 4, Endian.little));

  BigInt readUInt64() => _require(
      8, () => BigInt.from(readUInt32()) | (BigInt.from(readUInt32()) << 32));

  Uint8List readSlice(int n) => _require(
      n,
      () => Uint8List.fromList(
          _data.buffer.asUint8List(
              _data.offsetInBytes + (offset += n) - n, n)));

  BigInt readVarInt() {
    final first = readUInt8();
    if (first < 0xfd) return BigInt.from(first);
    if (first == 0xfd) return BigInt.from(readUInt16());
    if (first == 0xfe) return BigInt.from(readUInt32());
    return readUInt64();
  }

  Uint8List readVarSlice() => readSlice(readVarInt().toInt());

  List<Uint8List> readVector() =>
      List<Uint8List>.generate(readVarInt().toInt(), (_) => readVarSlice());
}

mixin WireWriting {
  void writeUInt8(int i);
  void writeUInt16(int i);
  void writeUInt32(int i);
  void writeInt32(int i);
  void writeUInt64(BigInt i);
  void writeSlice(Uint8List slice);
  void writeVarInt(BigInt i);

  void writeVarSlice(Uint8List slice) {
    writeVarInt(BigInt.from(slice.length));
    writeSlice(slice);
  }

  void writeVector(List<Uint8List> vector) {
    writeVarInt(BigInt.from(vector.length));
    for (final bytes in vector) {
      writeVarSlice(bytes);
    }
  }
}

class WireWriter with WireWriting {
  final ByteData _data;
  int offset;

  WireWriter(Uint8List bytes, [this.offset = 0])
      : _data = bytes.buffer.asByteData(
            bytes.offsetInBytes, bytes.lengthInBytes);

  void _require(int n, void Function() f) {
    if (offset + n > _data.lengthInBytes) {
      throw OutOfData(offset, n, _data.lengthInBytes);
    }
    f();
  }

  @override
  void writeUInt8(int i) {
    checkUint8(i);
    _require(1, () => _data.setUint8(offset++, i));
  }

  @override
  void writeUInt16(int i) {
    checkUint16(i);
    _require(2, () => _data.setUint16((offset += 2) - 2, i, Endian.little));
  }

  @override
  void writeUInt32(int i) {
    checkUint32(i);
    _require(4, () => _data.setUint32((offset += 4) - 4, i, Endian.little));
  }

  @override
  void writeInt32(int i) {
    checkInt32(i);
    _require(4, () => _data.setInt32((offset += 4) - 4, i, Endian.little));
  }

  @override
  void writeUInt64(BigInt i) {
    checkUint64(i);
    _require(8, () {
      writeUInt32(i.toUnsigned(32).toInt());
      writeUInt32((i >> 32).toUnsigned(32).toInt());
    });
  }

  @override
  void writeSlice(Uint8List slice) {
    _require(slice.length, () {
      _data.buffer.asUint8List(_data.offsetInBytes).setAll(offset, slice);
      offset += slice.length;
    });
  }

  @override
  void writeVarInt(BigInt i) {
    if (i < BigInt.from(0xfd)) {
      writeUInt8(i.toInt());
    } else if (i <= BigInt.from(0xffff)) {
      writeUInt8(0xfd);
      writeUInt16(i.toInt());
    } else if (i <= BigInt.from(0xffffffff)) {
      writeUInt8(0xfe);
      writeUInt32(i.toInt());
    } else {
      writeUInt8(0xff);
      writeUInt64(i);
    }
  }
}

/// Counts serialized size without allocating.
class WireMeasure with WireWriting {
  int size = 0;

  static int varIntSizeOf(BigInt i) {
    if (i < BigInt.from(0xfd)) return 1;
    if (i <= BigInt.from(0xffff)) return 3;
    if (i <= BigInt.from(0xffffffff)) return 5;
    return 9;
  }

  static int varIntSizeOfInt(int i) => varIntSizeOf(BigInt.from(i));

  @override
  void writeUInt8(int i) => size++;
  @override
  void writeUInt16(int i) => size += 2;
  @override
  void writeUInt32(int i) => size += 4;
  @override
  void writeInt32(int i) => size += 4;
  @override
  void writeUInt64(BigInt i) => size += 8;
  @override
  void writeSlice(Uint8List slice) => size += slice.length;
  @override
  void writeVarInt(BigInt i) => size += varIntSizeOf(i);
}

mixin Serializable {
  Uint8List? _cache;
  int? _sizeCache;

  void writeTo(WireWriting writer);

  Uint8List toBytes() {
    if (_cache != null) return _cache!;
    final bytes = Uint8List(wireSize);
    final writer = WireWriter(bytes);
    writeTo(writer);
    _sizeCache = bytes.length;
    return _cache = bytes;
  }

  String toHex() => hexEncode(toBytes());

  int get wireSize {
    if (_sizeCache != null) return _sizeCache!;
    final measure = WireMeasure();
    writeTo(measure);
    return _sizeCache = measure.size;
  }
}
