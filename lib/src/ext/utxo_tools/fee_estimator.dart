class TxSizeEstimate {
  final int baseSize;
  final int totalSize;
  /// BIP-141 weight units.
  final int weight;
  /// weight / 4, rounded up.
  final int vsize;

  const TxSizeEstimate({
    required this.baseSize,
    required this.totalSize,
    required this.weight,
    required this.vsize,
  });
}

class FeeEstimator {
  FeeEstimator._();

  // Typical input sizes (bytes).
  static const int p2pkhInputSize = 148;
  static const int p2shInputSize = 297; // 2-of-3 multisig estimate
  static const int p2wpkhInputSize = 68; // witness discount applied
  static const int p2trInputSize = 58; // key-path spend

  // Typical output sizes (bytes).
  static const int p2pkhOutputSize = 34;
  static const int p2shOutputSize = 32;
  static const int p2wpkhOutputSize = 31;
  static const int p2trOutputSize = 43;

  // Fixed overhead: version + locktime + varint counts.
  static const int txOverhead = 10;
  // Segwit marker + flag bytes.
  static const int segwitOverhead = 2;

  static TxSizeEstimate estimateSize({
    int numP2pkhInputs = 0,
    int numP2shInputs = 0,
    int numP2wpkhInputs = 0,
    int numP2trInputs = 0,
    int numP2pkhOutputs = 0,
    int numP2shOutputs = 0,
    int numP2wpkhOutputs = 0,
    int numP2trOutputs = 0,
  }) {
    final hasWitness = numP2wpkhInputs > 0 || numP2trInputs > 0;

    final baseInputs = numP2pkhInputs * p2pkhInputSize +
        numP2shInputs * p2shInputSize;

    final witnessInputs = numP2wpkhInputs * p2wpkhInputSize +
        numP2trInputs * p2trInputSize;

    final outputs = numP2pkhOutputs * p2pkhOutputSize +
        numP2shOutputs * p2shOutputSize +
        numP2wpkhOutputs * p2wpkhOutputSize +
        numP2trOutputs * p2trOutputSize;

    final overhead = txOverhead + (hasWitness ? segwitOverhead : 0);
    final baseSize = overhead + baseInputs + witnessInputs + outputs;
    final totalSize = baseSize; // simplified; witness discount handled via weight

    // Weight = base_size * 3 + total_size (BIP-141)
    final weight = hasWitness
        ? (overhead + baseInputs + outputs) * 4 +
            (segwitOverhead + witnessInputs) // witness at 1x
        : baseSize * 4;

    final vsize = (weight + 3) ~/ 4;

    return TxSizeEstimate(
      baseSize: baseSize,
      totalSize: totalSize,
      weight: weight,
      vsize: vsize,
    );
  }

  static BigInt estimateFee({
    required TxSizeEstimate sizeEstimate,
    required int satPerVbyte,
  }) {
    return BigInt.from(sizeEstimate.vsize) * BigInt.from(satPerVbyte);
  }

  /// Quick estimate assuming uniform input/output types.
  static BigInt quickEstimate({
    required int numInputs,
    required int numOutputs,
    required int satPerVbyte,
    bool segwit = true,
  }) {
    final inputSize = segwit ? p2wpkhInputSize : p2pkhInputSize;
    final outputSize = segwit ? p2wpkhOutputSize : p2pkhOutputSize;
    final overhead = txOverhead + (segwit ? segwitOverhead : 0);
    final vsize = overhead + numInputs * inputSize + numOutputs * outputSize;
    return BigInt.from(vsize) * BigInt.from(satPerVbyte);
  }
}
