import 'dart:async';

/// Intercepts RPC calls to inspect, modify, cache, or retry them.
abstract class Middleware {
  Future<dynamic> process(
    String method,
    List<dynamic>? params,
    Future<dynamic> Function(String method, List<dynamic>? params) next,
  );
}

class MiddlewareChain {
  final List<Middleware> _middlewares;

  MiddlewareChain([List<Middleware>? middlewares])
      : _middlewares = middlewares ?? [];

  void add(Middleware middleware) {
    _middlewares.add(middleware);
  }

  void remove(Middleware middleware) {
    _middlewares.remove(middleware);
  }

  Future<dynamic> execute(
    String method,
    List<dynamic>? params,
    Future<dynamic> Function(String method, List<dynamic>? params) finalHandler,
  ) {
    if (_middlewares.isEmpty) {
      return finalHandler(method, params);
    }

    Future<dynamic> buildChain(int index, String m, List<dynamic>? p) {
      if (index >= _middlewares.length) {
        return finalHandler(m, p);
      }
      return _middlewares[index].process(
        m,
        p,
        (nextMethod, nextParams) => buildChain(index + 1, nextMethod, nextParams),
      );
    }

    return buildChain(0, method, params);
  }
}

class LoggingMiddleware extends Middleware {
  @override
  Future<dynamic> process(
    String method,
    List<dynamic>? params,
    Future<dynamic> Function(String method, List<dynamic>? params) next,
  ) async {
    return next(method, params);
  }
}

class RetryMiddleware extends Middleware {
  final int maxRetries;
  final Duration retryDelay;

  RetryMiddleware({this.maxRetries = 3, this.retryDelay = const Duration(seconds: 1)});

  @override
  Future<dynamic> process(
    String method,
    List<dynamic>? params,
    Future<dynamic> Function(String method, List<dynamic>? params) next,
  ) async {
    throw UnimplementedError('RetryMiddleware.process not yet implemented');
  }
}

class CacheMiddleware extends Middleware {
  /// Methods safe to cache (e.g. `eth_chainId`, `net_version`).
  final Set<String> cacheableMethods;

  final Duration ttl;

  CacheMiddleware({
    Set<String>? cacheableMethods,
    this.ttl = const Duration(seconds: 15),
  }) : cacheableMethods = cacheableMethods ?? {'eth_chainId', 'net_version'};

  @override
  Future<dynamic> process(
    String method,
    List<dynamic>? params,
    Future<dynamic> Function(String method, List<dynamic>? params) next,
  ) async {
    throw UnimplementedError('CacheMiddleware.process not yet implemented');
  }
}
