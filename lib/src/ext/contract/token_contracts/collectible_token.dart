import 'dart:typed_data';

import '../../abi/sol_function.dart';
import '../../abi/sol_parser.dart';
import '../../abi/sol_types/uint_type.dart';
import '../../abi/sol_types/address_type.dart';
import '../../abi/sol_types/bool_type.dart';
import '../../abi/sol_types/bytes_type.dart';
import '../../abi/sol_types/string_type.dart';
import '../../evm/evm_addr.dart';
import '../deployed_contract.dart';
import '../call_builder.dart';
import '../invoke_builder.dart';

/// ERC-721 interface.
class CollectibleToken {
  final DeployedContract contract;

  CollectibleToken(this.contract);

  factory CollectibleToken.at(EvmAddr address) {
    return CollectibleToken(DeployedContract(
      address: address,
      abi: _parsedAbi,
    ));
  }

  factory CollectibleToken.atHex(String address) =>
      CollectibleToken.at(EvmAddr.fromHex(address));

  EvmAddr get address => contract.address;

  CallBuilder name() => _call(_nameFunc, []);
  CallBuilder symbol() => _call(_symbolFunc, []);
  CallBuilder tokenURI(BigInt tokenId) => _call(_tokenURIFunc, [tokenId]);
  CallBuilder balanceOf(EvmAddr owner) => _call(_balanceOfFunc, [owner.bytes]);
  CallBuilder ownerOf(BigInt tokenId) => _call(_ownerOfFunc, [tokenId]);
  CallBuilder getApproved(BigInt tokenId) =>
      _call(_getApprovedFunc, [tokenId]);
  CallBuilder isApprovedForAll(EvmAddr owner, EvmAddr operator_) =>
      _call(_isApprovedForAllFunc, [owner.bytes, operator_.bytes]);

  InvokeBuilder approve(EvmAddr to, BigInt tokenId) =>
      _invoke(_approveFunc, [to.bytes, tokenId]);

  InvokeBuilder setApprovalForAll(EvmAddr operator_, bool approved) =>
      _invoke(_setApprovalForAllFunc, [operator_.bytes, approved]);

  InvokeBuilder transferFrom(EvmAddr from, EvmAddr to, BigInt tokenId) =>
      _invoke(_transferFromFunc, [from.bytes, to.bytes, tokenId]);

  InvokeBuilder safeTransferFrom(EvmAddr from, EvmAddr to, BigInt tokenId,
      [Uint8List? data]) {
    if (data != null) {
      return _invoke(
          _safeTransferFromDataFunc, [from.bytes, to.bytes, tokenId, data]);
    }
    return _invoke(_safeTransferFromFunc, [from.bytes, to.bytes, tokenId]);
  }

  CallBuilder _call(SolFunction func, List<dynamic> args) =>
      CallBuilder(contract: contract, function_: func, args: args);

  InvokeBuilder _invoke(SolFunction func, List<dynamic> args) =>
      InvokeBuilder(contract: contract, function_: func, args: args);

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

  static final _tokenURIFunc = SolFunction(
    name: 'tokenURI',
    inputs: [SolUint(256)],
    inputNames: ['tokenId'],
    outputs: [SolString()],
    stateMutability: 'view',
  );

  static final _balanceOfFunc = SolFunction(
    name: 'balanceOf',
    inputs: [SolAddress()],
    inputNames: ['owner'],
    outputs: [SolUint(256)],
    stateMutability: 'view',
  );

  static final _ownerOfFunc = SolFunction(
    name: 'ownerOf',
    inputs: [SolUint(256)],
    inputNames: ['tokenId'],
    outputs: [SolAddress()],
    stateMutability: 'view',
  );

  static final _getApprovedFunc = SolFunction(
    name: 'getApproved',
    inputs: [SolUint(256)],
    inputNames: ['tokenId'],
    outputs: [SolAddress()],
    stateMutability: 'view',
  );

  static final _isApprovedForAllFunc = SolFunction(
    name: 'isApprovedForAll',
    inputs: [SolAddress(), SolAddress()],
    inputNames: ['owner', 'operator'],
    outputs: [SolBool()],
    stateMutability: 'view',
  );

  static final _approveFunc = SolFunction(
    name: 'approve',
    inputs: [SolAddress(), SolUint(256)],
    inputNames: ['to', 'tokenId'],
    outputs: [],
  );

  static final _setApprovalForAllFunc = SolFunction(
    name: 'setApprovalForAll',
    inputs: [SolAddress(), SolBool()],
    inputNames: ['operator', 'approved'],
    outputs: [],
  );

  static final _transferFromFunc = SolFunction(
    name: 'transferFrom',
    inputs: [SolAddress(), SolAddress(), SolUint(256)],
    inputNames: ['from', 'to', 'tokenId'],
    outputs: [],
  );

  static final _safeTransferFromFunc = SolFunction(
    name: 'safeTransferFrom',
    inputs: [SolAddress(), SolAddress(), SolUint(256)],
    inputNames: ['from', 'to', 'tokenId'],
    outputs: [],
  );

  static final _safeTransferFromDataFunc = SolFunction(
    name: 'safeTransferFrom',
    inputs: [SolAddress(), SolAddress(), SolUint(256), SolBytes()],
    inputNames: ['from', 'to', 'tokenId', 'data'],
    outputs: [],
  );

  static final ParsedAbi _parsedAbi = ParsedAbi(
    functions: [
      _nameFunc,
      _symbolFunc,
      _tokenURIFunc,
      _balanceOfFunc,
      _ownerOfFunc,
      _getApprovedFunc,
      _isApprovedForAllFunc,
      _approveFunc,
      _setApprovalForAllFunc,
      _transferFromFunc,
      _safeTransferFromFunc,
      _safeTransferFromDataFunc,
    ],
    events: [],
    errors: [],
  );
}
