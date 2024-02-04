import 'dart:typed_data';

import '../../tx/tx.dart';
import '../../tx/sighash/sighash_type.dart';

/// Called per input. Returns DER-encoded signature bytes (no hash type suffix).
typedef SignerCallback = Uint8List Function(
  Tx tx,
  int inputIndex,
  Uint8List sigHash,
  SigHashType hashType,
);

/// Async version of [SignerCallback] for hardware wallets or remote signers.
typedef AsyncSignerCallback = Future<Uint8List> Function(
  Tx tx,
  int inputIndex,
  Uint8List sigHash,
  SigHashType hashType,
);
