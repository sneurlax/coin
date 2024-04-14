import 'dart:math';

import 'spendable.dart';

class CoinSelection {
  final List<SpendableUtxo> selected;
  final BigInt totalInput;
  final BigInt targetAmount;
  final BigInt fee;

  const CoinSelection({
    required this.selected,
    required this.totalInput,
    required this.targetAmount,
    required this.fee,
  });

  BigInt get change => totalInput - targetAmount - fee;
  bool get needsChange => change > BigInt.zero;
}

enum CoinSelectionStrategy {
  largestFirst,
  smallestFirst,
  random,

  /// Attempts to find an exact-match input set to avoid change outputs.
  branchAndBound,
}

class CoinPicker {
  CoinPicker._();

  static CoinSelection select({
    required List<SpendableUtxo> utxos,
    required BigInt target,
    required BigInt feePerUtxo,
    required BigInt baseFee,
    CoinSelectionStrategy strategy = CoinSelectionStrategy.largestFirst,
    Random? rng,
    BigInt? dustThreshold,
  }) {
    switch (strategy) {
      case CoinSelectionStrategy.largestFirst:
        return _largestFirst(utxos, target, feePerUtxo, baseFee, dustThreshold);
      case CoinSelectionStrategy.smallestFirst:
        return _smallestFirst(
            utxos, target, feePerUtxo, baseFee, dustThreshold);
      case CoinSelectionStrategy.random:
        return _random(
            utxos, target, feePerUtxo, baseFee, rng ?? Random.secure(),
            dustThreshold);
      case CoinSelectionStrategy.branchAndBound:
        return _branchAndBound(
            utxos, target, feePerUtxo, baseFee, dustThreshold);
    }
  }

  static CoinSelection _largestFirst(
    List<SpendableUtxo> utxos,
    BigInt target,
    BigInt feePerUtxo,
    BigInt baseFee,
    BigInt? dustThreshold,
  ) {
    final sorted = List<SpendableUtxo>.from(utxos)
      ..sort((a, b) => b.value.compareTo(a.value));
    return _accumulate(sorted, target, feePerUtxo, baseFee);
  }

  static CoinSelection _smallestFirst(
    List<SpendableUtxo> utxos,
    BigInt target,
    BigInt feePerUtxo,
    BigInt baseFee,
    BigInt? dustThreshold,
  ) {
    final sorted = List<SpendableUtxo>.from(utxos)
      ..sort((a, b) => a.value.compareTo(b.value));
    return _accumulate(sorted, target, feePerUtxo, baseFee);
  }

  static CoinSelection _random(
    List<SpendableUtxo> utxos,
    BigInt target,
    BigInt feePerUtxo,
    BigInt baseFee,
    Random rng,
    BigInt? dustThreshold,
  ) {
    final shuffled = List<SpendableUtxo>.from(utxos)..shuffle(rng);
    return _accumulate(shuffled, target, feePerUtxo, baseFee);
  }

  static CoinSelection _branchAndBound(
    List<SpendableUtxo> utxos,
    BigInt target,
    BigInt feePerUtxo,
    BigInt baseFee,
    BigInt? dustThreshold,
  ) {
    // Fallback to largest-first for the stub.
    return _largestFirst(utxos, target, feePerUtxo, baseFee, dustThreshold);
  }

  static CoinSelection _accumulate(
    List<SpendableUtxo> ordered,
    BigInt target,
    BigInt feePerUtxo,
    BigInt baseFee,
  ) {
    final selected = <SpendableUtxo>[];
    var total = BigInt.zero;
    var fee = baseFee;

    for (final utxo in ordered) {
      selected.add(utxo);
      total += utxo.value;
      fee += feePerUtxo;
      if (total >= target + fee) break;
    }

    if (total < target + fee) {
      throw StateError(
        'Insufficient funds: have $total, need ${target + fee}',
      );
    }

    return CoinSelection(
      selected: selected,
      totalInput: total,
      targetAmount: target,
      fee: fee,
    );
  }
}
