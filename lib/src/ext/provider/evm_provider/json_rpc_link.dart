import 'dart:convert';

class JsonRpcLink {
  final String url;
  final Duration timeout;
  int _nextId = 1;

  JsonRpcLink({
    required this.url,
    this.timeout = const Duration(seconds: 30),
  });

  Future<dynamic> call(String method, [List<dynamic>? params]) async {
    final id = nextId;
    final payload = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params ?? [],
    };
    final body = jsonEncode(payload);
    final responseBody = await _postJson(body);
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    if (json.containsKey('error') && json['error'] != null) {
      final err = json['error'] as Map<String, dynamic>;
      throw JsonRpcError(
        code: err['code'] as int,
        message: err['message'] as String,
        data: err['data'],
      );
    }
    return json['result'];
  }

  Future<List<dynamic>> batch(List<(String method, List<dynamic>? params)> requests) async {
    final payloads = <Map<String, dynamic>>[];
    final ids = <int>[];
    for (final (method, params) in requests) {
      final id = nextId;
      ids.add(id);
      payloads.add({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params ?? [],
      });
    }
    final body = jsonEncode(payloads);
    final responseBody = await _postJson(body);
    final responses = (jsonDecode(responseBody) as List).cast<Map<String, dynamic>>();
    final byId = <int, Map<String, dynamic>>{};
    for (final r in responses) {
      byId[r['id'] as int] = r;
    }
    final results = <dynamic>[];
    for (final id in ids) {
      final r = byId[id]!;
      if (r.containsKey('error') && r['error'] != null) {
        final err = r['error'] as Map<String, dynamic>;
        throw JsonRpcError(
          code: err['code'] as int,
          message: err['message'] as String,
          data: err['data'],
        );
      }
      results.add(r['result']);
    }
    return results;
  }

  Stream<dynamic> subscribe(String method, [List<dynamic>? params]) {
    if (!isWebSocket) {
      throw StateError('subscribe requires a WebSocket URL');
    }
    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'id': nextId,
      'method': method,
      'params': params ?? [],
    });
    // The subscription envelope is formatted; transport must be wired to
    // feed incoming notifications into the returned stream.
    throw UnimplementedError(
      'WebSocket transport not configured -- '
      'subscription payload ready: $payload',
    );
  }

  Future<bool> unsubscribe(String subscriptionId) async {
    final result = await call('eth_unsubscribe', [subscriptionId]);
    return result as bool;
  }

  Future<void> close() async {
    // No persistent connections to close in the HTTP-only stub.
  }

  bool get isWebSocket =>
      url.startsWith('ws://') || url.startsWith('wss://');

  int get nextId => _nextId++;

  Future<String> _postJson(String body) async {
    throw UnimplementedError(
      'HTTP transport not configured -- '
      'POST $url with body length ${body.length}',
    );
  }
}

class JsonRpcError implements Exception {
  final int code;
  final String message;
  final dynamic data;

  JsonRpcError({required this.code, required this.message, this.data});

  @override
  String toString() => 'JsonRpcError($code): $message';
}
