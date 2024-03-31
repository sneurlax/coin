import 'dart:typed_data';

/// CashToken capability flags.
enum CashTokenCapability {
  none(0x00),
  mutable(0x01),
  minting(0x02);

  final int flag;
  const CashTokenCapability(this.flag);

  factory CashTokenCapability.fromFlag(int flag) {
    for (final cap in values) {
      if (cap.flag == flag) return cap;
    }
    throw ArgumentError('Unknown CashToken capability flag: $flag');
  }
}

/// A CashToken attached to a UTXO. Can carry fungible amounts, an NFT, or both.
/// Identified by a 32-byte category ID (genesis txid).
class CashToken {
  /// 32-byte category ID (genesis txid).
  final Uint8List categoryId;

  final CashTokenCapability capability;

  /// NFT commitment (0-40 bytes), or null.
  final Uint8List? commitment;

  /// Fungible token amount (0 if NFT-only).
  final BigInt amount;

  CashToken({
    required Uint8List categoryId,
    this.capability = CashTokenCapability.none,
    this.commitment,
    BigInt? amount,
  }) : amount = amount ?? BigInt.zero,
       categoryId = Uint8List.fromList(categoryId) {
    if (categoryId.length != 32) {
      throw ArgumentError('categoryId must be 32 bytes');
    }
    if (commitment != null && commitment!.length > 40) {
      throw ArgumentError('commitment must be at most 40 bytes');
    }
  }

  bool get hasNft =>
      capability != CashTokenCapability.none || commitment != null;

  bool get hasFungible => amount > BigInt.zero;

  Uint8List serialize() {
    final parts = <int>[];
    parts.add(0xef); // PREFIX_TOKEN
    parts.addAll(categoryId);

    // Bitfield encoding: has_nft (bit 5), has_amount (bit 4), capability (bits 0-3)
    var bitfield = 0;
    if (hasNft) {
      bitfield |= 0x20;
      bitfield |= capability.flag & 0x0f;
    }
    if (hasFungible) {
      bitfield |= 0x10;
    }
    parts.add(bitfield);

    if (hasNft && commitment != null) {
      _writeCompactSize(parts, commitment!.length);
      parts.addAll(commitment!);
    } else if (hasNft) {
      parts.add(0); // zero-length commitment
    }

    if (hasFungible) {
      _writeCompactSize(parts, amount.toInt());
    }

    return Uint8List.fromList(parts);
  }

  static void _writeCompactSize(List<int> out, int value) {
    if (value < 0xfd) {
      out.add(value);
    } else if (value <= 0xffff) {
      out.add(0xfd);
      out.add(value & 0xff);
      out.add((value >> 8) & 0xff);
    } else {
      out.add(0xfe);
      out.add(value & 0xff);
      out.add((value >> 8) & 0xff);
      out.add((value >> 16) & 0xff);
      out.add((value >> 24) & 0xff);
    }
  }

  factory CashToken.deserialize(Uint8List bytes) {
    var offset = 0;
    if (bytes[offset] != 0xef) {
      throw FormatException('Missing CashToken prefix byte 0xEF');
    }
    offset++;

    final categoryId = bytes.sublist(offset, offset + 32);
    offset += 32;

    final bitfield = bytes[offset++];
    final hasNft = (bitfield & 0x20) != 0;
    final hasAmount = (bitfield & 0x10) != 0;
    final cap = hasNft
        ? CashTokenCapability.fromFlag(bitfield & 0x0f)
        : CashTokenCapability.none;

    Uint8List? commitment;
    if (hasNft) {
      final len = bytes[offset++];
      if (len > 0) {
        commitment = bytes.sublist(offset, offset + len);
        offset += len;
      }
    }

    var amount = BigInt.zero;
    if (hasAmount) {
      final first = bytes[offset++];
      if (first < 0xfd) {
        amount = BigInt.from(first);
      } else if (first == 0xfd) {
        amount = BigInt.from(bytes[offset] | (bytes[offset + 1] << 8));
        offset += 2;
      } else if (first == 0xfe) {
        amount = BigInt.from(bytes[offset] |
            (bytes[offset + 1] << 8) |
            (bytes[offset + 2] << 16) |
            (bytes[offset + 3] << 24));
        offset += 4;
      }
    }

    return CashToken(
      categoryId: categoryId,
      capability: cap,
      commitment: commitment,
      amount: amount,
    );
  }
}
