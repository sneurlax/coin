import 'dart:convert';
import 'dart:typed_data';

import '../../../core/hex.dart';
import '../../../hash/digest.dart';
import 'utxo_methods.dart';
import 'utxo_models.dart';

class ElectrumLink implements UtxoMethods {
  final String host;
  final int port;
  final bool useSsl;
  final int timeoutMs;
  int _nextId = 1;

  ElectrumLink({
    required this.host,
    required this.port,
    this.useSsl = true,
    this.timeoutMs = 10000,
  });

  Future<void> connect() async {
    throw UnimplementedError(
      'TCP/SSL transport not configured -- '
      'connect to $host:$port (ssl=$useSsl)',
    );
  }

  Future<void> disconnect() async {
    throw UnimplementedError(
      'TCP/SSL transport not configured -- '
      'disconnect from $host:$port',
    );
  }

  bool get isConnected => false;

  Future<void> subscribeAddress(
    String address,
    void Function(String status) onStatus,
  ) async {
    final scriptHash = _addressToScriptHash(address);
    _buildRequest('blockchain.scripthash.subscribe', [scriptHash]);
    throw UnimplementedError(
      'TCP/SSL transport not configured -- '
      'subscription for scripthash $scriptHash',
    );
  }

  Future<List<String>> serverVersion({
    String clientName = 'coin-dart',
    String protocolMin = '1.4',
    String protocolMax = '1.4.2',
  }) async {
    final result = await _rpc(
      'server.version',
      [clientName, [protocolMin, protocolMax]],
    );
    return List<String>.from(result as List);
  }

  // -- UtxoMethods --

  @override
  Future<List<UtxoRef>> getUtxos(String address) async {
    final scriptHash = _addressToScriptHash(address);
    final result = await _rpc(
      'blockchain.scripthash.listunspent',
      [scriptHash],
    );
    return (result as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return UtxoRef(
        txid: m['tx_hash'] as String,
        vout: m['tx_pos'] as int,
        value: BigInt.from(m['value'] as int),
        scriptPubKeyHex: address,
        blockHeight: (m['height'] as int?) == 0 ? null : m['height'] as int?,
      );
    }).toList();
  }

  @override
  Future<BalanceInfo> getBalance(String address) async {
    final scriptHash = _addressToScriptHash(address);
    final result = await _rpc(
      'blockchain.scripthash.get_balance',
      [scriptHash],
    );
    final m = Map<String, dynamic>.from(result as Map);
    return BalanceInfo(
      address: address,
      confirmed: BigInt.from(m['confirmed'] as int),
      unconfirmed: BigInt.from(m['unconfirmed'] as int),
    );
  }

  @override
  Future<TxInfo> getTransaction(String txid) async {
    final result = await _rpc(
      'blockchain.transaction.get',
      [txid, true],
    );
    final m = Map<String, dynamic>.from(result as Map);
    return TxInfo(
      txid: m['txid'] as String,
      blockHeight: m['confirmations'] != null && (m['confirmations'] as int) > 0
          ? m['height'] as int?
          : null,
      blockHash: m['blockhash'] as String?,
      timestamp: m['time'] as int?,
    );
  }

  @override
  Future<Uint8List> getRawTransaction(String txid) async {
    final result = await _rpc(
      'blockchain.transaction.get',
      [txid, false],
    );
    return hexDecode(result as String);
  }

  @override
  Future<String> broadcastTransaction(Uint8List rawTx) async {
    final hex = hexEncode(rawTx);
    final result = await _rpc(
      'blockchain.transaction.broadcast',
      [hex],
    );
    return result as String;
  }

  @override
  Future<int> getBlockHeight() async {
    final result = await _rpc('blockchain.headers.subscribe', []);
    final m = Map<String, dynamic>.from(result as Map);
    return m['height'] as int;
  }

  @override
  Future<int> estimateFeeRate({int targetBlocks = 6}) async {
    final result = await _rpc('blockchain.estimatefee', [targetBlocks]);
    final btcPerKb = (result is int) ? result.toDouble() : (result as num).toDouble();
    if (btcPerKb < 0) return 1;
    final satPerKb = (btcPerKb * 100000000).round();
    final satPerVbyte = (satPerKb / 1000).ceil();
    return satPerVbyte < 1 ? 1 : satPerVbyte;
  }

  @override
  Future<List<TxInfo>> getHistory(String address) async {
    final scriptHash = _addressToScriptHash(address);
    final result = await _rpc(
      'blockchain.scripthash.get_history',
      [scriptHash],
    );
    return (result as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final height = m['height'] as int;
      return TxInfo(
        txid: m['tx_hash'] as String,
        blockHeight: height > 0 ? height : null,
        fee: m['fee'] != null ? BigInt.from(m['fee'] as int) : null,
      );
    }).toList();
  }

  String _addressToScriptHash(String scriptPubKeyHex) {
    final script = hexDecode(scriptPubKeyHex);
    final hash = sha256(script);
    final reversed = Uint8List.fromList(hash.reversed.toList());
    return hexEncode(reversed);
  }

  Map<String, dynamic> _buildRequest(String method, List<dynamic> params) {
    return {
      'jsonrpc': '2.0',
      'id': _nextId++,
      'method': method,
      'params': params,
    };
  }

  Future<dynamic> _rpc(String method, List<dynamic> params) async {
    final request = _buildRequest(method, params);
    final body = jsonEncode(request);
    final responseBody = await _send(body);
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    if (json.containsKey('error') && json['error'] != null) {
      final err = json['error'];
      throw Exception('Electrum RPC error: $err');
    }
    return json['result'];
  }

  Future<String> _send(String body) async {
    throw UnimplementedError(
      'TCP/SSL transport not configured -- '
      'send to $host:$port body length ${body.length}',
    );
  }
}
