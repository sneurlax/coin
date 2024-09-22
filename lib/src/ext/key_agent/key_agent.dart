import 'dart:typed_data';

import '../evm/evm_addr.dart';
import '../evm/evm_tx.dart';

/// Signing interface: in-memory, hardware, or remote.
abstract class KeyAgent {
  Future<EvmAddr> getAddress();
  Future<Uint8List> signTransaction(Envelope envelope);

  /// EIP-191 personal_sign. Returns 65-byte signature (r + s + v).
  Future<Uint8List> signMessage(Uint8List message);

  /// Sign a raw 32-byte hash. Returns 65-byte signature (r + s + v).
  Future<Uint8List> signHash(Uint8List hash32);

  /// EIP-712 typed data signing. Returns 65-byte signature (r + s + v).
  Future<Uint8List> signTypedData(Map<String, dynamic> typedData);
}
