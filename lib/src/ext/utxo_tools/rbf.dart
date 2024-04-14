import '../../tx/inputs/tx_input.dart';

/// BIP-125 Replace-By-Fee helpers. RBF is signaled when any input
/// has sequence < 0xfffffffe.
class Rbf {
  Rbf._();

  static const int sequenceFinal = TxInput.sequenceFinal; // 0xffffffff
  static const int sequenceLocktimeOnly = 0xfffffffe; // no RBF, allows locktime
  static const int sequenceRbfDefault = 0xfffffffd;

  static bool isRbfSignaled(int sequence) => sequence < sequenceLocktimeOnly;

  static int sequenceFor({bool enableRbf = true}) =>
      enableRbf ? sequenceRbfDefault : sequenceFinal;

  static bool transactionIsRbf(List<int> sequences) =>
      sequences.any(isRbfSignaled);

  /// Bump sequence for a replacement tx. BIP-125 rule 4 requires
  /// sequence >= original (miners mostly just check fee, though).
  static int bumpSequence(int currentSequence) {
    if (currentSequence >= sequenceLocktimeOnly) {
      return sequenceRbfDefault;
    }
    // Increment by 1 if there is room.
    if (currentSequence < sequenceLocktimeOnly - 1) {
      return currentSequence + 1;
    }
    return currentSequence;
  }
}
