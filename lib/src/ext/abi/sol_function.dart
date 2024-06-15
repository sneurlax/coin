import 'dart:typed_data';

import '../../core/bytes.dart';
import '../../hash/digest.dart';
import 'sol_type.dart';
import 'sol_types/tuple_type.dart';

class SolFunction {
  final String name;
  final List<SolType> inputs;
  final List<String> inputNames;
  final List<SolType> outputs;
  final List<String> outputNames;
  final String stateMutability;

  SolFunction({
    required this.name,
    required this.inputs,
    List<String>? inputNames,
    required this.outputs,
    List<String>? outputNames,
    this.stateMutability = 'nonpayable',
  })  : inputNames = inputNames ?? List.filled(inputs.length, ''),
        outputNames = outputNames ?? List.filled(outputs.length, '');

  String get signature {
    final params = inputs.map((t) => t.name).join(',');
    return '$name($params)';
  }

  Uint8List get selector {
    final hash = keccak256(Uint8List.fromList(signature.codeUnits));
    return hash.sublist(0, 4);
  }

  Uint8List encodeCall(List<dynamic> args) {
    final encoded = SolTuple.encodeTuple(inputs, args);
    return concatBytes([selector, encoded]);
  }

  List<dynamic> decodeResult(Uint8List data) {
    final (values, _) = SolTuple.decodeTuple(outputs, data, 0);
    return values;
  }

  bool get isReadOnly =>
      stateMutability == 'pure' || stateMutability == 'view';
}

class SolEvent {
  final String name;
  final List<SolType> inputs;
  final List<String> inputNames;
  final List<bool> indexed;
  final bool anonymous;

  SolEvent({
    required this.name,
    required this.inputs,
    List<String>? inputNames,
    List<bool>? indexed,
    this.anonymous = false,
  })  : inputNames = inputNames ?? List.filled(inputs.length, ''),
        indexed = indexed ?? List.filled(inputs.length, false);

  String get signature {
    final params = inputs.map((t) => t.name).join(',');
    return '$name($params)';
  }

  Uint8List get topic0 {
    return keccak256(Uint8List.fromList(signature.codeUnits));
  }

  List<dynamic> decode(List<Uint8List> topics, Uint8List data) {
    final results = <dynamic>[];
    var topicIdx = anonymous ? 0 : 1;
    var dataOffset = 0;

    for (var i = 0; i < inputs.length; i++) {
      if (indexed[i]) {
        if (topicIdx < topics.length) {
          if (inputs[i].isDynamic) {
            // Indexed dynamic types are stored as keccak256 hashes.
            results.add(topics[topicIdx]);
          } else {
            final (val, _) = inputs[i].decode(topics[topicIdx], 0);
            results.add(val);
          }
          topicIdx++;
        } else {
          results.add(null);
        }
      } else {
        final (val, consumed) = inputs[i].decode(data, dataOffset);
        results.add(val);
        dataOffset += consumed;
      }
    }
    return results;
  }
}

class SolError {
  final String name;
  final List<SolType> inputs;
  final List<String> inputNames;

  SolError({
    required this.name,
    required this.inputs,
    List<String>? inputNames,
  }) : inputNames = inputNames ?? List.filled(inputs.length, '');

  String get signature {
    final params = inputs.map((t) => t.name).join(',');
    return '$name($params)';
  }

  Uint8List get selector {
    final hash = keccak256(Uint8List.fromList(signature.codeUnits));
    return hash.sublist(0, 4);
  }

  List<dynamic> decode(Uint8List data) {
    final payload = data.sublist(4);
    final (values, _) = SolTuple.decodeTuple(inputs, payload, 0);
    return values;
  }
}
