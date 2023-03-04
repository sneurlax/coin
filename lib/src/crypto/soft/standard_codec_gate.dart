import 'dart:typed_data';

import '../gates/codec_gate.dart';
import '../gates/digest_gate.dart';

const _base58Alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

class StandardCodecGate implements CodecGate {
  final DigestGate digest;

  StandardCodecGate({required this.digest});

  @override
  String base58CheckEncode(Uint8List payload) {
    final checksum = digest.sha256d(payload).sublist(0, 4);
    final data = Uint8List(payload.length + 4);
    data.setAll(0, payload);
    data.setAll(payload.length, checksum);
    return _base58Encode(data);
  }

  @override
  Uint8List base58CheckDecode(String encoded) {
    final data = _base58Decode(encoded);
    if (data.length < 4) throw FormatException('Base58Check too short');
    final payload = data.sublist(0, data.length - 4);
    final checksum = data.sublist(data.length - 4);
    final expected = digest.sha256d(payload).sublist(0, 4);
    for (var i = 0; i < 4; i++) {
      if (checksum[i] != expected[i]) {
        throw FormatException('Base58Check checksum mismatch');
      }
    }
    return payload;
  }

  @override
  String bech32Encode(String hrp, Uint8List data, {int version = 0}) {
    final converted = convertBits(data, 8, 5);
    final payload = Uint8List(1 + converted.length);
    payload[0] = version;
    payload.setRange(1, payload.length, converted);
    final checksum = _bech32Checksum(hrp, payload, 1); // bech32
    return '${hrp}1${_toChars(payload)}${_toChars(checksum)}';
  }

  @override
  (String, int, Uint8List) bech32Decode(String encoded) {
    // BIP-173: mixed-case strings are invalid
    // https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki#segwit-address-format
    if (encoded != encoded.toLowerCase() &&
        encoded != encoded.toUpperCase()) {
      throw FormatException('Bech32 mixed case');
    }
    final lower = encoded.toLowerCase();
    final sepIdx = lower.lastIndexOf('1');
    if (sepIdx < 1) throw FormatException('No separator in bech32');
    final hrp = lower.substring(0, sepIdx);
    final dataStr = lower.substring(sepIdx + 1);
    if (dataStr.length < 6) throw FormatException('Bech32 data too short');

    final data = _fromChars(dataStr);
    final payload = data.sublist(0, data.length - 6);
    final checksum = data.sublist(data.length - 6);

    // bech32 for version 0, bech32m for higher versions
    final enc = payload.isNotEmpty && payload[0] == 0 ? 1 : 0x2bc830a3;
    final expected = _bech32Checksum(hrp, payload, enc);
    for (var i = 0; i < 6; i++) {
      if (checksum[i] != expected[i]) {
        throw FormatException('Bech32 checksum mismatch');
      }
    }

    final version = payload[0];
    final program = convertBits(
        Uint8List.fromList(payload.sublist(1)), 5, 8, pad: false);
    return (hrp, version, program);
  }

  @override
  String bech32mEncode(String hrp, Uint8List data, {int version = 1}) {
    final converted = convertBits(data, 8, 5);
    final payload = Uint8List(1 + converted.length);
    payload[0] = version;
    payload.setRange(1, payload.length, converted);
    final checksum = _bech32Checksum(hrp, payload, 0x2bc830a3); // bech32m
    return '${hrp}1${_toChars(payload)}${_toChars(checksum)}';
  }

  @override
  Uint8List convertBits(Uint8List data, int fromBits, int toBits,
      {bool pad = true}) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxV = (1 << toBits) - 1;

    for (final value in data) {
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        result.add((acc >> bits) & maxV);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (toBits - bits)) & maxV);
      }
    } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxV) != 0) {
      throw FormatException('Invalid bit conversion padding');
    }

    return Uint8List.fromList(result);
  }

  // Base58
  String _base58Encode(Uint8List data) {
    var number = BigInt.zero;
    for (final b in data) {
      number = number * BigInt.from(256) + BigInt.from(b);
    }
    final chars = <String>[];
    final big58 = BigInt.from(58);
    while (number > BigInt.zero) {
      final rem = (number % big58).toInt();
      chars.add(_base58Alphabet[rem]);
      number ~/= big58;
    }
    for (final b in data) {
      if (b != 0) break;
      chars.add('1');
    }
    return chars.reversed.join();
  }

  Uint8List _base58Decode(String encoded) {
    var number = BigInt.zero;
    final big58 = BigInt.from(58);
    for (final c in encoded.codeUnits) {
      final idx = _base58Alphabet.indexOf(String.fromCharCode(c));
      if (idx < 0) throw FormatException('Invalid base58 character: ${String.fromCharCode(c)}');
      number = number * big58 + BigInt.from(idx);
    }

    var leadingZeros = 0;
    for (final c in encoded.codeUnits) {
      if (String.fromCharCode(c) == '1') {
        leadingZeros++;
      } else {
        break;
      }
    }

    final bytes = <int>[];
    final big256 = BigInt.from(256);
    while (number > BigInt.zero) {
      bytes.add((number % big256).toInt());
      number ~/= big256;
    }

    final result = Uint8List(leadingZeros + bytes.length);
    result.setRange(leadingZeros, result.length,
        bytes.reversed.toList());
    return result;
  }

  // Bech32
  static const _bech32Charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  Uint8List _bech32Checksum(String hrp, Uint8List data, int spec) {
    final values = _hrpExpand(hrp) +
        data.toList() +
        [0, 0, 0, 0, 0, 0];
    var polymod = _bech32Polymod(Uint8List.fromList(values)) ^ spec;
    final result = Uint8List(6);
    for (var i = 0; i < 6; i++) {
      result[i] = (polymod >> (5 * (5 - i))) & 31;
    }
    return result;
  }

  List<int> _hrpExpand(String hrp) {
    final result = <int>[];
    for (final c in hrp.codeUnits) {
      result.add(c >> 5);
    }
    result.add(0);
    for (final c in hrp.codeUnits) {
      result.add(c & 31);
    }
    return result;
  }

  int _bech32Polymod(Uint8List values) {
    const gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
    var chk = 1;
    for (final v in values) {
      final b = chk >> 25;
      chk = ((chk & 0x1ffffff) << 5) ^ v;
      for (var i = 0; i < 5; i++) {
        if (((b >> i) & 1) != 0) {
          chk ^= gen[i];
        }
      }
    }
    return chk;
  }

  String _toChars(Uint8List data) {
    final buf = StringBuffer();
    for (final d in data) {
      buf.write(_bech32Charset[d]);
    }
    return buf.toString();
  }

  Uint8List _fromChars(String str) {
    final result = Uint8List(str.length);
    for (var i = 0; i < str.length; i++) {
      final idx = _bech32Charset.indexOf(str[i]);
      if (idx < 0) throw FormatException('Invalid bech32 character: ${str[i]}');
      result[i] = idx;
    }
    return result;
  }
}
