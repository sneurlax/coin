import 'dart:typed_data';

import '../../abi/sol_function.dart';
import '../../abi/sol_parser.dart';
import '../../abi/sol_types/uint_type.dart';
import '../../abi/sol_types/address_type.dart';
import '../../abi/sol_types/bool_type.dart';
import '../../abi/sol_types/bytes_type.dart';
import '../../abi/sol_types/string_type.dart';
import '../../abi/sol_types/array_type.dart';
import '../../evm/evm_addr.dart';
import '../deployed_contract.dart';
import '../call_builder.dart';
import '../invoke_builder.dart';

/// ERC-1155 interface.
class MultiToken {
  final DeployedContract contract;

  MultiToken(this.contract);

  factory MultiToken.at(EvmAddr address) {
    return MultiToken(DeployedContract(
      address: address,
      abi: _parsedAbi,
    ));
  }

  factory MultiToken.atHex(String address) =>
      MultiToken.at(EvmAddr.fromHex(address));

  EvmAddr get address => contract.address;

  CallBuilder uri(BigInt tokenId) => _call(_uriFunc, [tokenId]);

  CallBuilder balanceOf(EvmAddr owner, BigInt id) =>
      _call(_balanceOfFunc, [owner.bytes, id]);

  CallBuilder balanceOfBatch(List<EvmAddr> owners, List<BigInt> ids) =>
      _call(_balanceOfBatchFunc, [
        owners.map((o) => o.bytes).toList(),
        ids,
      ]);

  CallBuilder isApprovedForAll(EvmAddr owner, EvmAddr operator_) =>
      _call(_isApprovedForAllFunc, [owner.bytes, operator_.bytes]);

  InvokeBuilder setApprovalForAll(EvmAddr operator_, bool approved) =>
      _invoke(_setApprovalForAllFunc, [operator_.bytes, approved]);

  InvokeBuilder safeTransferFrom(
    EvmAddr from,
    EvmAddr to,
    BigInt id,
    BigInt amount,
    Uint8List data,
  ) =>
      _invoke(_safeTransferFromFunc, [from.bytes, to.bytes, id, amount, data]);

  InvokeBuilder safeBatchTransferFrom(
    EvmAddr from,
    EvmAddr to,
    List<BigInt> ids,
    List<BigInt> amounts,
    Uint8List data,
  ) =>
      _invoke(_safeBatchTransferFromFunc,
          [from.bytes, to.bytes, ids, amounts, data]);

  CallBuilder _call(SolFunction func, List<dynamic> args) =>
      CallBuilder(contract: contract, function_: func, args: args);

  InvokeBuilder _invoke(SolFunction func, List<dynamic> args) =>
      InvokeBuilder(contract: contract, function_: func, args: args);

  static final _uriFunc = SolFunction(
    name: 'uri',
    inputs: [SolUint(256)],
    inputNames: ['id'],
    outputs: [SolString()],
    stateMutability: 'view',
  );

  static final _balanceOfFunc = SolFunction(
    name: 'balanceOf',
    inputs: [SolAddress(), SolUint(256)],
    inputNames: ['account', 'id'],
    outputs: [SolUint(256)],
    stateMutability: 'view',
  );

  static final _balanceOfBatchFunc = SolFunction(
    name: 'balanceOfBatch',
    inputs: [SolArray(SolAddress()), SolArray(SolUint(256))],
    inputNames: ['accounts', 'ids'],
    outputs: [SolArray(SolUint(256))],
    stateMutability: 'view',
  );

  static final _isApprovedForAllFunc = SolFunction(
    name: 'isApprovedForAll',
    inputs: [SolAddress(), SolAddress()],
    inputNames: ['account', 'operator'],
    outputs: [SolBool()],
    stateMutability: 'view',
  );

  static final _setApprovalForAllFunc = SolFunction(
    name: 'setApprovalForAll',
    inputs: [SolAddress(), SolBool()],
    inputNames: ['operator', 'approved'],
    outputs: [],
  );

  static final _safeTransferFromFunc = SolFunction(
    name: 'safeTransferFrom',
    inputs: [
      SolAddress(),
      SolAddress(),
      SolUint(256),
      SolUint(256),
      SolBytes(),
    ],
    inputNames: ['from', 'to', 'id', 'amount', 'data'],
    outputs: [],
  );

  static final _safeBatchTransferFromFunc = SolFunction(
    name: 'safeBatchTransferFrom',
    inputs: [
      SolAddress(),
      SolAddress(),
      SolArray(SolUint(256)),
      SolArray(SolUint(256)),
      SolBytes(),
    ],
    inputNames: ['from', 'to', 'ids', 'amounts', 'data'],
    outputs: [],
  );

  static final ParsedAbi _parsedAbi = ParsedAbi(
    functions: [
      _uriFunc,
      _balanceOfFunc,
      _balanceOfBatchFunc,
      _isApprovedForAllFunc,
      _setApprovalForAllFunc,
      _safeTransferFromFunc,
      _safeBatchTransferFromFunc,
    ],
    events: [],
    errors: [],
  );
}
