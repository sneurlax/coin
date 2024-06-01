import 'dart:typed_data';

import '../../core/hex.dart';

/// EIP-2930 access list entry.
class AccessListEntry {
  final Uint8List address;
  final List<Uint8List> storageKeys;

  AccessListEntry({
    required this.address,
    List<Uint8List>? storageKeys,
  }) : storageKeys = storageKeys ?? [] {
    if (address.length != 20) {
      throw ArgumentError('Address must be 20 bytes, got ${address.length}');
    }
    for (var i = 0; i < this.storageKeys.length; i++) {
      if (this.storageKeys[i].length != 32) {
        throw ArgumentError(
          'Storage key $i must be 32 bytes, got ${this.storageKeys[i].length}',
        );
      }
    }
  }

  factory AccessListEntry.fromHex({
    required String address,
    List<String>? storageKeys,
  }) {
    return AccessListEntry(
      address: hexDecode(address),
      storageKeys: storageKeys?.map(hexDecode).toList(),
    );
  }

  List<dynamic> toRlpList() => [address, storageKeys];
}
