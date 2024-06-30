import 'dart:typed_data';

import '../abi/sol_function.dart';
import '../evm/evm_addr.dart';
import 'deployed_contract.dart';

class CallBuilder {
  final DeployedContract contract;
  final SolFunction function_;
  final List<dynamic> args;
  EvmAddr? from;
  String blockTag;

  CallBuilder({
    required this.contract,
    required this.function_,
    required this.args,
    this.from,
    this.blockTag = 'latest',
  });

  CallBuilder withFrom(EvmAddr addr) {
    from = addr;
    return this;
  }

  CallBuilder atBlock(String tag) {
    blockTag = tag;
    return this;
  }

  Uint8List encodeCalldata() {
    return function_.encodeCall(args);
  }

  Map<String, dynamic> toCallParams() {
    final calldata = encodeCalldata();
    final params = <String, dynamic>{
      'to': contract.address.toChecksumHex(),
      'data': '0x${_hexEncode(calldata)}',
    };
    if (from != null) {
      params['from'] = from!.toChecksumHex();
    }
    return params;
  }

  Future<List<dynamic>> call(Future<String> Function(Map<String, dynamic> params, String blockTag) callFn) async {
    final params = toCallParams();
    final resultHex = await callFn(params, blockTag);
    final resultBytes = _hexDecode(resultHex);
    return function_.decodeResult(resultBytes);
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

  static Uint8List _hexDecode(String hex) {
    var s = hex;
    if (s.startsWith('0x') || s.startsWith('0X')) s = s.substring(2);
    if (s.length.isOdd) s = '0$s';
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
