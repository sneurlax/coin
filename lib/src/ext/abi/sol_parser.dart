import 'dart:convert';

import 'sol_type.dart';
import 'sol_function.dart';
import 'sol_types/uint_type.dart';
import 'sol_types/int_type.dart';
import 'sol_types/address_type.dart';
import 'sol_types/bool_type.dart';
import 'sol_types/bytes_type.dart';
import 'sol_types/string_type.dart';
import 'sol_types/array_type.dart';
import 'sol_types/tuple_type.dart';

class ParsedAbi {
  final List<SolFunction> functions;
  final List<SolEvent> events;
  final List<SolError> errors;

  ParsedAbi({
    required this.functions,
    required this.events,
    required this.errors,
  });

  SolFunction? function(String name) {
    for (final f in functions) {
      if (f.name == name) return f;
    }
    return null;
  }

  SolEvent? event(String name) {
    for (final e in events) {
      if (e.name == name) return e;
    }
    return null;
  }

  SolError? error(String name) {
    for (final e in errors) {
      if (e.name == name) return e;
    }
    return null;
  }
}

class SolParser {
  SolParser._();

  static ParsedAbi parse(String jsonAbi) {
    final list = json.decode(jsonAbi) as List<dynamic>;
    final functions = <SolFunction>[];
    final events = <SolEvent>[];
    final errors = <SolError>[];

    for (final entry in list) {
      final map = entry as Map<String, dynamic>;
      final type = map['type'] as String? ?? 'function';

      switch (type) {
        case 'function':
          functions.add(_parseFunction(map));
          break;
        case 'event':
          events.add(_parseEvent(map));
          break;
        case 'error':
          errors.add(_parseError(map));
          break;
        case 'constructor':
        case 'fallback':
        case 'receive':
          break;
      }
    }

    return ParsedAbi(functions: functions, events: events, errors: errors);
  }

  /// Parse a human-readable signature like
  /// `"function transfer(address to, uint256 amount) returns (bool)"`.
  static SolFunction parseFunction(String sig) {
    final trimmed = sig.trim();
    final withoutPrefix = trimmed.startsWith('function ')
        ? trimmed.substring(9).trim()
        : trimmed;

    final parenStart = withoutPrefix.indexOf('(');
    final name = withoutPrefix.substring(0, parenStart).trim();

    final inputEnd = _findMatchingParen(withoutPrefix, parenStart);
    final inputStr = withoutPrefix.substring(parenStart + 1, inputEnd);

    var outputStr = '';
    final returnsIdx = withoutPrefix.indexOf('returns', inputEnd);
    if (returnsIdx >= 0) {
      final outStart = withoutPrefix.indexOf('(', returnsIdx);
      final outEnd = _findMatchingParen(withoutPrefix, outStart);
      outputStr = withoutPrefix.substring(outStart + 1, outEnd);
    }

    final (inputTypes, inputNames) = _parseParams(inputStr);
    final (outputTypes, outputNames) = _parseParams(outputStr);

    return SolFunction(
      name: name,
      inputs: inputTypes,
      inputNames: inputNames,
      outputs: outputTypes,
      outputNames: outputNames,
    );
  }

  static SolFunction _parseFunction(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? '';
    final inputs = _parseInputs(map['inputs'] as List? ?? []);
    final outputs = _parseInputs(map['outputs'] as List? ?? []);
    final inputNames = _parseNames(map['inputs'] as List? ?? []);
    final outputNames = _parseNames(map['outputs'] as List? ?? []);
    final mutability = map['stateMutability'] as String? ?? 'nonpayable';

    return SolFunction(
      name: name,
      inputs: inputs,
      inputNames: inputNames,
      outputs: outputs,
      outputNames: outputNames,
      stateMutability: mutability,
    );
  }

  static SolEvent _parseEvent(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? '';
    final paramList = map['inputs'] as List? ?? [];
    final inputs = _parseInputs(paramList);
    final inputNames = _parseNames(paramList);
    final indexed = paramList
        .map((p) => (p as Map<String, dynamic>)['indexed'] == true)
        .toList();
    final anonymous = map['anonymous'] == true;

    return SolEvent(
      name: name,
      inputs: inputs,
      inputNames: inputNames,
      indexed: indexed,
      anonymous: anonymous,
    );
  }

  static SolError _parseError(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? '';
    final inputs = _parseInputs(map['inputs'] as List? ?? []);
    final inputNames = _parseNames(map['inputs'] as List? ?? []);

    return SolError(
      name: name,
      inputs: inputs,
      inputNames: inputNames,
    );
  }

  static List<SolType> _parseInputs(List<dynamic> params) {
    return params.map((p) {
      final map = p as Map<String, dynamic>;
      final type = map['type'] as String;
      final components = map['components'] as List?;
      return resolveType(type, components);
    }).toList();
  }

  static List<String> _parseNames(List<dynamic> params) {
    return params.map((p) {
      return (p as Map<String, dynamic>)['name'] as String? ?? '';
    }).toList();
  }

  static SolType resolveType(String type, [List<dynamic>? components]) {
    if (type.endsWith(']')) {
      final bracketStart = type.lastIndexOf('[');
      final inner = type.substring(0, bracketStart);
      final sizeStr = type.substring(bracketStart + 1, type.length - 1);
      final elementType = resolveType(inner, components);
      if (sizeStr.isEmpty) {
        return SolArray(elementType);
      }
      return SolArray(elementType, int.parse(sizeStr));
    }

    if (type == 'tuple') {
      final comps = (components ?? []).map((c) {
        final m = c as Map<String, dynamic>;
        return resolveType(m['type'] as String, m['components'] as List?);
      }).toList();
      final names = (components ?? [])
          .map((c) => (c as Map<String, dynamic>)['name'] as String? ?? '')
          .toList();
      return SolTuple(comps, names: names);
    }

    if (type == 'address') return SolAddress();
    if (type == 'bool') return SolBool();
    if (type == 'string') return SolString();
    if (type == 'bytes') return SolBytes();

    if (type.startsWith('uint')) {
      final bits = type.length > 4 ? int.parse(type.substring(4)) : 256;
      return SolUint(bits);
    }
    if (type.startsWith('int')) {
      final bits = type.length > 3 ? int.parse(type.substring(3)) : 256;
      return SolInt(bits);
    }
    if (type.startsWith('bytes')) {
      final len = int.parse(type.substring(5));
      return SolFixedBytes(len);
    }

    throw ArgumentError('Unknown Solidity type: $type');
  }

  static (List<SolType>, List<String>) _parseParams(String params) {
    final trimmed = params.trim();
    if (trimmed.isEmpty) return (<SolType>[], <String>[]);

    final types = <SolType>[];
    final names = <String>[];
    final parts = _splitParams(trimmed);

    for (final part in parts) {
      final tokens = part.trim().split(RegExp(r'\s+'));
      final typeName = tokens[0];
      final paramName = tokens.length > 1 ? tokens.last : '';
      types.add(resolveType(typeName));
      names.add(paramName);
    }

    return (types, names);
  }

  static List<String> _splitParams(String s) {
    final parts = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < s.length; i++) {
      if (s[i] == '(') depth++;
      if (s[i] == ')') depth--;
      if (s[i] == ',' && depth == 0) {
        parts.add(s.substring(start, i));
        start = i + 1;
      }
    }
    parts.add(s.substring(start));
    return parts;
  }

  static int _findMatchingParen(String s, int openIdx) {
    var depth = 0;
    for (var i = openIdx; i < s.length; i++) {
      if (s[i] == '(') depth++;
      if (s[i] == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    throw FormatException('Unmatched parenthesis in: $s');
  }
}
