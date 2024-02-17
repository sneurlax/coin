import 'dart:typed_data';

import '../../core/wire.dart';

/// Magic bytes: "psbt" + 0xff separator.
const List<int> psbtMagic = [0x70, 0x73, 0x62, 0x74, 0xff];

class PsbtKeyValue {
  final Uint8List key;
  final Uint8List value;

  const PsbtKeyValue({required this.key, required this.value});
}

/// Low-level PSBT wire-format codec (BIP-174 / BIP-370).
class PsbtCodec {
  PsbtCodec._();

  /// Decode into sections: [global, input0, ..., output0, ...].
  static List<List<PsbtKeyValue>> decode(Uint8List bytes) {
    if (!hasMagic(bytes)) {
      throw FormatException('Invalid PSBT: missing magic bytes');
    }
    final reader = WireReader(bytes, psbtMagic.length);
    final sections = <List<PsbtKeyValue>>[];

    // Each section is key-value pairs terminated by a 0x00 separator.
    while (!reader.atEnd) {
      final section = <PsbtKeyValue>[];
      while (!reader.atEnd) {
        final keyLen = reader.readVarInt().toInt();
        if (keyLen == 0) break; // separator
        final key = reader.readSlice(keyLen);
        final valueLen = reader.readVarInt().toInt();
        final value = reader.readSlice(valueLen);
        section.add(PsbtKeyValue(key: key, value: value));
      }
      sections.add(section);
    }

    return sections;
  }

  static Uint8List encode(List<List<PsbtKeyValue>> sections) {
    var totalSize = psbtMagic.length;
    for (final section in sections) {
      for (final kv in section) {
        totalSize += WireMeasure.varIntSizeOfInt(kv.key.length);
        totalSize += kv.key.length;
        totalSize += WireMeasure.varIntSizeOfInt(kv.value.length);
        totalSize += kv.value.length;
      }
      totalSize += 1; // 0x00 separator
    }

    final out = Uint8List(totalSize);
    final writer = WireWriter(out);
    writer.writeSlice(Uint8List.fromList(psbtMagic));
    for (final section in sections) {
      for (final kv in section) {
        writer.writeVarInt(BigInt.from(kv.key.length));
        writer.writeSlice(kv.key);
        writer.writeVarInt(BigInt.from(kv.value.length));
        writer.writeSlice(kv.value);
      }
      writer.writeUInt8(0x00); // separator
    }
    return out;
  }

  static bool hasMagic(Uint8List bytes) {
    if (bytes.length < psbtMagic.length) return false;
    for (var i = 0; i < psbtMagic.length; i++) {
      if (bytes[i] != psbtMagic[i]) return false;
    }
    return true;
  }
}
