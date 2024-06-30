import 'dart:typed_data';

import '../abi/sol_function.dart';
import '../abi/sol_parser.dart';
import '../evm/evm_addr.dart';
import 'call_builder.dart';
import 'invoke_builder.dart';

class DeployedContract {
  final EvmAddr address;
  final ParsedAbi abi;

  DeployedContract({
    required this.address,
    required this.abi,
  });

  factory DeployedContract.fromJson({
    required String address,
    required String abiJson,
  }) {
    return DeployedContract(
      address: EvmAddr.fromHex(address),
      abi: SolParser.parse(abiJson),
    );
  }

  CallBuilder read(String functionName, [List<dynamic> args = const []]) {
    final func = abi.function(functionName);
    if (func == null) {
      throw ArgumentError('Function "$functionName" not found in ABI');
    }
    return CallBuilder(
      contract: this,
      function_: func,
      args: args,
    );
  }

  InvokeBuilder write(String functionName, [List<dynamic> args = const []]) {
    final func = abi.function(functionName);
    if (func == null) {
      throw ArgumentError('Function "$functionName" not found in ABI');
    }
    return InvokeBuilder(
      contract: this,
      function_: func,
      args: args,
    );
  }

  /// Dry-run a write function via eth_call (no transaction submitted).
  CallBuilder simulate(String functionName, [List<dynamic> args = const []]) {
    final func = abi.function(functionName);
    if (func == null) {
      throw ArgumentError('Function "$functionName" not found in ABI');
    }
    return CallBuilder(
      contract: this,
      function_: func,
      args: args,
    );
  }

  Uint8List encodeCall(String functionName, List<dynamic> args) {
    final func = abi.function(functionName);
    if (func == null) {
      throw ArgumentError('Function "$functionName" not found in ABI');
    }
    return func.encodeCall(args);
  }

  List<dynamic> decodeResult(String functionName, Uint8List data) {
    final func = abi.function(functionName);
    if (func == null) {
      throw ArgumentError('Function "$functionName" not found in ABI');
    }
    return func.decodeResult(data);
  }
}
