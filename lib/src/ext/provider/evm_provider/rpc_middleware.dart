import 'dart:async';

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
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await next(method, params);
      } catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          await Future<void>.delayed(retryDelay * (attempt + 1));
        }
      }
    }
    throw lastError!;
  }
}

class CacheMiddleware extends Middleware {
  final Set<String> cacheableMethods;

  final Duration ttl;

  final _cache = <String, _CacheEntry>{};

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
    if (!cacheableMethods.contains(method)) {
      return next(method, params);
    }
    final key = '$method:${params ?? []}';
    final existing = _cache[key];
    if (existing != null && !existing.isExpired) {
      return existing.value;
    }
    _evictExpired();
    final result = await next(method, params);
    _cache[key] = _CacheEntry(result, DateTime.now().add(ttl));
    return result;
  }

  void _evictExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  void clear() => _cache.clear();
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
