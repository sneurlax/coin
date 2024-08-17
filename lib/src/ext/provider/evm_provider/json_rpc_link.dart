import 'dart:async';

/// JSON-RPC transport for EVM nodes (HTTP and WebSocket).
class JsonRpcLink {
  final String url;
  final Duration timeout;
  int _nextId = 1;

  JsonRpcLink({
    required this.url,
    this.timeout = const Duration(seconds: 30),
  });

  Future<dynamic> call(String method, [List<dynamic>? params]) {
    throw UnimplementedError('JsonRpcLink.call not yet implemented');
  }

  /// Batches multiple JSON-RPC calls; returns results in request order.
  Future<List<dynamic>> batch(List<(String method, List<dynamic>? params)> requests) {
    throw UnimplementedError('JsonRpcLink.batch not yet implemented');
  }

  /// WebSocket-only `eth_subscribe`.
  Stream<dynamic> subscribe(String method, [List<dynamic>? params]) {
    throw UnimplementedError('JsonRpcLink.subscribe not yet implemented');
  }

  Future<bool> unsubscribe(String subscriptionId) {
    throw UnimplementedError('JsonRpcLink.unsubscribe not yet implemented');
  }

  Future<void> close() {
    throw UnimplementedError('JsonRpcLink.close not yet implemented');
  }

  bool get isWebSocket =>
      url.startsWith('ws://') || url.startsWith('wss://');

  int get nextId => _nextId++;
}

class JsonRpcError implements Exception {
  final int code;
  final String message;
  final dynamic data;

  JsonRpcError({required this.code, required this.message, this.data});

  @override
  String toString() => 'JsonRpcError($code): $message';
}
