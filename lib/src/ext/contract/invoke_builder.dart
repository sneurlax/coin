import 'dart:typed_data';

import '../abi/sol_function.dart';
import '../evm/evm_addr.dart';
import '../evm/evm_tx.dart';
import 'deployed_contract.dart';

class InvokeBuilder {
  final DeployedContract contract;
  final SolFunction function_;
  final List<dynamic> args;
  EvmAddr? from;
  BigInt? value;
  BigInt? gasLimit;
  BigInt? nonce;
  BigInt? maxFeePerGas;
  BigInt? maxPriorityFeePerGas;
  BigInt? gasPrice;
  BigInt? chainId;

  InvokeBuilder({
    required this.contract,
    required this.function_,
    required this.args,
    this.from,
    this.value,
    this.gasLimit,
    this.nonce,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    this.gasPrice,
    this.chainId,
  });

  InvokeBuilder withFrom(EvmAddr addr) {
    from = addr;
    return this;
  }

  InvokeBuilder withValue(BigInt val) {
    value = val;
    return this;
  }

  InvokeBuilder withGasLimit(BigInt limit) {
    gasLimit = limit;
    return this;
  }

  InvokeBuilder withNonce(BigInt n) {
    nonce = n;
    return this;
  }

  InvokeBuilder withEip1559Fees({
    required BigInt maxFee,
    required BigInt maxPriorityFee,
  }) {
    maxFeePerGas = maxFee;
    maxPriorityFeePerGas = maxPriorityFee;
    return this;
  }

  Uint8List encodeCalldata() {
    return function_.encodeCall(args);
  }

  Envelope toEnvelope() {
    final calldata = encodeCalldata();
    final isEip1559 = maxFeePerGas != null || maxPriorityFeePerGas != null;

    return Envelope(
      kind: isEip1559 ? EnvelopeKind.eip1559 : EnvelopeKind.legacy,
      to: contract.address.bytes,
      value: value ?? BigInt.zero,
      data: calldata,
      gasLimit: gasLimit,
      nonce: nonce,
      chainId: chainId,
      gasPrice: gasPrice,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    );
  }

  Map<String, dynamic> toTransactionParams() {
    final calldata = encodeCalldata();
    final params = <String, dynamic>{
      'to': contract.address.toChecksumHex(),
      'data': '0x${_hexEncode(calldata)}',
    };
    if (from != null) params['from'] = from!.toChecksumHex();
    if (value != null) params['value'] = '0x${value!.toRadixString(16)}';
    if (gasLimit != null) params['gas'] = '0x${gasLimit!.toRadixString(16)}';
    if (nonce != null) params['nonce'] = '0x${nonce!.toRadixString(16)}';
    if (maxFeePerGas != null) {
      params['maxFeePerGas'] = '0x${maxFeePerGas!.toRadixString(16)}';
    }
    if (maxPriorityFeePerGas != null) {
      params['maxPriorityFeePerGas'] =
          '0x${maxPriorityFeePerGas!.toRadixString(16)}';
    }
    if (gasPrice != null) {
      params['gasPrice'] = '0x${gasPrice!.toRadixString(16)}';
    }
    return params;
  }

  static String _hexEncode(Uint8List bytes) {
    const chars = '0123456789abcdef';
    final buf = StringBuffer();
    for (final b in bytes) {
      buf.write(chars[b >> 4]);
      buf.write(chars[b & 0xf]);
    }
    return buf.toString();
  }
}
