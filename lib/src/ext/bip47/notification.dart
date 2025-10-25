import 'dart:typed_data';

import '../../hash/hmac.dart';

Uint8List blindingMask(Uint8List ecdhSecret, Uint8List outpoint) {
  return hmacSha512(ecdhSecret, outpoint);
}

/// XOR-blinds (or unblinds) a payment code payload.
///
/// Bytes 3..34 (pubkey x-coordinate) are XORed with mask[0..31].
/// Bytes 35..66 (chain code) are XORed with mask[32..63].
Uint8List blindPayload({
  required Uint8List payload,
  required Uint8List mask,
}) {
  if (payload.length != 80) {
    throw ArgumentError('Payload must be 80 bytes');
  }
  if (mask.length != 64) {
    throw ArgumentError('Mask must be 64 bytes');
  }

  final result = Uint8List.fromList(payload);

  for (var i = 0; i < 32; i++) {
    result[3 + i] ^= mask[i];
  }

  for (var i = 0; i < 32; i++) {
    result[35 + i] ^= mask[32 + i];
  }

  return result;
}
