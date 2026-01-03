import 'dart:typed_data';
import 'witness_input.dart';

/// Script-path spend; witness = [...stack, script, controlBlock].
class TaprootScriptInput extends WitnessInput {
  final List<Uint8List> stack;
  final Uint8List tapScript;
  final Uint8List controlBlock;

  TaprootScriptInput({
    required super.prevOut,
    required this.stack,
    required this.tapScript,
    required this.controlBlock,
    super.sequence,
  });

  @override
  List<Uint8List> get witness => [...stack, tapScript, controlBlock];
  @override
  bool get complete => true;
  @override
  int get signedSize {
    var size = 0;
    for (final item in witness) {
      size += item.length + 1;
    }
    return size ~/ 4;
  }
}
