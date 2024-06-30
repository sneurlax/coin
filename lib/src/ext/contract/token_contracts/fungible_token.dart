import 'dart:typed_data';

import '../../abi/sol_function.dart';
import '../../abi/sol_parser.dart';
import '../../abi/sol_types/uint_type.dart';
import '../../abi/sol_types/address_type.dart';
import '../../abi/sol_types/bool_type.dart';
import '../../abi/sol_types/string_type.dart';
import '../../evm/evm_addr.dart';
import '../deployed_contract.dart';
import '../call_builder.dart';
import '../invoke_builder.dart';

/// ERC-20 interface.
class FungibleToken {
  final DeployedContract contract;

  FungibleToken(this.contract);

  factory FungibleToken.at(EvmAddr address) {
    return FungibleToken(DeployedContract(
      address: address,
      abi: _parsedAbi,
    ));
  }

  factory FungibleToken.atHex(String address) {
    return FungibleToken.at(EvmAddr.fromHex(address));
  }

  EvmAddr get address => contract.address;

  CallBuilder name() => _call(_nameFunc, []);
  CallBuilder symbol() => _call(_symbolFunc, []);
  CallBuilder decimals() => _call(_decimalsFunc, []);
  CallBuilder totalSupply() => _call(_totalSupplyFunc, []);

  CallBuilder balanceOf(EvmAddr owner) =>
      _call(_balanceOfFunc, [owner.bytes]);

  CallBuilder allowance(EvmAddr owner, EvmAddr spender) =>
      _call(_allowanceFunc, [owner.bytes, spender.bytes]);

  InvokeBuilder transfer(EvmAddr to, BigInt amount) =>
      _invoke(_transferFunc, [to.bytes, amount]);

  InvokeBuilder approve(EvmAddr spender, BigInt amount) =>
      _invoke(_approveFunc, [spender.bytes, amount]);

  InvokeBuilder transferFrom(EvmAddr from, EvmAddr to, BigInt amount) =>
      _invoke(_transferFromFunc, [from.bytes, to.bytes, amount]);

  Uint8List encodeTransfer(EvmAddr to, BigInt amount) =>
      _transferFunc.encodeCall([to.bytes, amount]);

  Uint8List encodeApprove(EvmAddr spender, BigInt amount) =>
      _approveFunc.encodeCall([spender.bytes, amount]);

  CallBuilder _call(SolFunction func, List<dynamic> args) {
    return CallBuilder(
      contract: contract,
      function_: func,
      args: args,
    );
  }

  InvokeBuilder _invoke(SolFunction func, List<dynamic> args) {
    return InvokeBuilder(
      contract: contract,
      function_: func,
      args: args,
    );
  }

  static final _nameFunc = SolFunction(
    name: 'name',
    inputs: [],
    outputs: [SolString()],
    stateMutability: 'view',
  );

  static final _symbolFunc = SolFunction(
    name: 'symbol',
    inputs: [],
    outputs: [SolString()],
    stateMutability: 'view',
  );

  static final _decimalsFunc = SolFunction(
    name: 'decimals',
    inputs: [],
    outputs: [SolUint(8)],
    stateMutability: 'view',
  );

  static final _totalSupplyFunc = SolFunction(
    name: 'totalSupply',
    inputs: [],
    outputs: [SolUint(256)],
    stateMutability: 'view',
  );

  static final _balanceOfFunc = SolFunction(
    name: 'balanceOf',
    inputs: [SolAddress()],
    inputNames: ['account'],
    outputs: [SolUint(256)],
    stateMutability: 'view',
  );

  static final _allowanceFunc = SolFunction(
    name: 'allowance',
    inputs: [SolAddress(), SolAddress()],
    inputNames: ['owner', 'spender'],
    outputs: [SolUint(256)],
    stateMutability: 'view',
  );

  static final _transferFunc = SolFunction(
    name: 'transfer',
    inputs: [SolAddress(), SolUint(256)],
    inputNames: ['to', 'amount'],
    outputs: [SolBool()],
  );

  static final _approveFunc = SolFunction(
    name: 'approve',
    inputs: [SolAddress(), SolUint(256)],
    inputNames: ['spender', 'amount'],
    outputs: [SolBool()],
  );

  static final _transferFromFunc = SolFunction(
    name: 'transferFrom',
    inputs: [SolAddress(), SolAddress(), SolUint(256)],
    inputNames: ['from', 'to', 'amount'],
    outputs: [SolBool()],
  );

  static final ParsedAbi _parsedAbi = ParsedAbi(
    functions: [
      _nameFunc,
      _symbolFunc,
      _decimalsFunc,
      _totalSupplyFunc,
      _balanceOfFunc,
      _allowanceFunc,
      _transferFunc,
      _approveFunc,
      _transferFromFunc,
    ],
    events: [],
    errors: [],
  );
}
