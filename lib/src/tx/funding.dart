import 'dart:math';

class FundingPlan<T> {
  final List<T> selected;
  final BigInt totalInput;
  final BigInt targetAmount;
  final BigInt fee;

  FundingPlan({
    required this.selected,
    required this.totalInput,
    required this.targetAmount,
    required this.fee,
  });

  BigInt get change => totalInput - targetAmount - fee;
  bool get needsChange => change > BigInt.zero;

  static FundingPlan<T> largestFirst<T>({
    required List<T> utxos,
    required BigInt Function(T) valueOf,
    required BigInt target,
    required BigInt fee,
  }) {
    final sorted = List<T>.from(utxos)
      ..sort((a, b) => valueOf(b).compareTo(valueOf(a)));

    final selected = <T>[];
    var total = BigInt.zero;
    final needed = target + fee;

    for (final utxo in sorted) {
      selected.add(utxo);
      total += valueOf(utxo);
      if (total >= needed) break;
    }

    if (total < needed) {
      throw StateError('Insufficient funds: have $total, need $needed');
    }

    return FundingPlan(
      selected: selected,
      totalInput: total,
      targetAmount: target,
      fee: fee,
    );
  }

  static FundingPlan<T> random<T>({
    required List<T> utxos,
    required BigInt Function(T) valueOf,
    required BigInt target,
    required BigInt fee,
    Random? rng,
  }) {
    final shuffled = List<T>.from(utxos)..shuffle(rng ?? Random.secure());

    final selected = <T>[];
    var total = BigInt.zero;
    final needed = target + fee;

    for (final utxo in shuffled) {
      selected.add(utxo);
      total += valueOf(utxo);
      if (total >= needed) break;
    }

    if (total < needed) {
      throw StateError('Insufficient funds: have $total, need $needed');
    }

    return FundingPlan(
      selected: selected,
      totalInput: total,
      targetAmount: target,
      fee: fee,
    );
  }
}
