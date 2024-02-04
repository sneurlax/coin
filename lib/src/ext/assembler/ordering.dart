/// Input/output ordering strategies.
enum TxOrdering {
  /// BIP-69 lexicographic ordering.
  bip69,

  /// Random shuffle for privacy.
  shuffle,

  /// Preserve caller-provided order.
  none,
}
