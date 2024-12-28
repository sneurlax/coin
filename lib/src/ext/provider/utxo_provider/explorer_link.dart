import 'dart:convert';
import 'dart:typed_data';

import '../../../core/hex.dart';
import 'utxo_methods.dart';
import 'utxo_models.dart';

class ExplorerLink implements UtxoMethods {
  final String baseUrl;
  final String? apiKey;
  final int timeoutMs;

  ExplorerLink({
    required this.baseUrl,
    this.apiKey,
    this.timeoutMs = 15000,
  });

  // -- UtxoMethods --

  @override
  Future<List<UtxoRef>> getUtxos(String address) async {
    final url = _url('/address/$address/utxo');
    final data = await _getJson(url);
    final list = data as List;
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return UtxoRef(
        txid: m['txid'] as String,
        vout: m['vout'] as int,
        value: BigInt.from(m['value'] as num),
        scriptPubKeyHex: (m['scriptPubKey'] as String?) ?? '',
        blockHeight: m['status'] is Map
            ? (m['status'] as Map)['block_height'] as int?
            : m['block_height'] as int?,
      );
    }).toList();
  }

  @override
  Future<BalanceInfo> getBalance(String address) async {
    final url = _url('/address/$address');
    final data = await _getJson(url) as Map<String, dynamic>;
    final confirmed = _parseSats(data, 'chain_stats', 'funded_txo_sum') -
        _parseSats(data, 'chain_stats', 'spent_txo_sum');
    final unconfirmed = _parseSats(data, 'mempool_stats', 'funded_txo_sum') -
        _parseSats(data, 'mempool_stats', 'spent_txo_sum');
    return BalanceInfo(
      address: address,
      confirmed: confirmed,
      unconfirmed: unconfirmed,
    );
  }

  @override
  Future<TxInfo> getTransaction(String txid) async {
    final url = _url('/tx/$txid');
    final data = await _getJson(url) as Map<String, dynamic>;
    final status = data['status'] as Map<String, dynamic>?;
    return TxInfo(
      txid: data['txid'] as String,
      blockHeight: status?['block_height'] as int?,
      blockHash: status?['block_hash'] as String?,
      fee: data['fee'] != null ? BigInt.from(data['fee'] as num) : null,
      timestamp: status?['block_time'] as int?,
    );
  }

  @override
  Future<Uint8List> getRawTransaction(String txid) async {
    final url = _url('/tx/$txid/hex');
    final hex = await _getString(url);
    return hexDecode(hex.trim());
  }

  @override
  Future<String> broadcastTransaction(Uint8List rawTx) async {
    final url = _url('/tx');
    final hex = hexEncode(rawTx);
    final txid = await _postString(url, hex);
    return txid.trim();
  }

  @override
  Future<int> getBlockHeight() async {
    final url = _url('/blocks/tip/height');
    final text = await _getString(url);
    return int.parse(text.trim());
  }

  @override
  Future<int> estimateFeeRate({int targetBlocks = 6}) async {
    final url = _url('/v1/fees/recommended');
    final data = await _getJson(url) as Map<String, dynamic>;
    final key = targetBlocks <= 1
        ? 'fastestFee'
        : targetBlocks <= 3
            ? 'halfHourFee'
            : targetBlocks <= 6
                ? 'hourFee'
                : 'economyFee';
    final rate = data[key];
    if (rate == null) {
      return data.values.first as int;
    }
    return rate as int;
  }

  @override
  Future<List<TxInfo>> getHistory(String address) async {
    final url = _url('/address/$address/txs');
    final data = await _getJson(url) as List;
    return data.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final status = m['status'] as Map<String, dynamic>?;
      return TxInfo(
        txid: m['txid'] as String,
        blockHeight: status?['block_height'] as int?,
        blockHash: status?['block_hash'] as String?,
        fee: m['fee'] != null ? BigInt.from(m['fee'] as num) : null,
        timestamp: status?['block_time'] as int?,
      );
    }).toList();
  }

  // -- Helpers --

  String _url(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final suffix = apiKey != null ? '?apiKey=$apiKey' : '';
    return '$base$path$suffix';
  }

  BigInt _parseSats(Map<String, dynamic> data, String section, String field) {
    final s = data[section] as Map<String, dynamic>?;
    if (s == null) return BigInt.zero;
    final v = s[field];
    if (v == null) return BigInt.zero;
    return BigInt.from(v as num);
  }

  Future<dynamic> _getJson(String url) async {
    final body = await _getString(url);
    return jsonDecode(body);
  }

  Future<String> _getString(String url) async {
    throw UnimplementedError(
      'HTTP transport not configured -- GET $url',
    );
  }

  Future<String> _postString(String url, String body) async {
    throw UnimplementedError(
      'HTTP transport not configured -- POST $url body length ${body.length}',
    );
  }
}
