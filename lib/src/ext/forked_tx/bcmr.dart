import 'dart:typed_data';

/// BCMR identity: metadata (name, symbol, icon, decimals) for a CashToken category.
class BcmrIdentity {
  /// 32-byte token category ID.
  final Uint8List categoryId;

  final String name;
  final String symbol;
  final int decimals;
  final String? description;
  final String? iconUri;

  const BcmrIdentity({
    required this.categoryId,
    required this.name,
    required this.symbol,
    this.decimals = 0,
    this.description,
    this.iconUri,
  });

  factory BcmrIdentity.fromJson(Map<String, dynamic> json) {
    final catHex = json['categoryId'] as String;
    final catBytes = Uint8List.fromList(
      List.generate(catHex.length ~/ 2,
          (i) => int.parse(catHex.substring(i * 2, i * 2 + 2), radix: 16)),
    );
    return BcmrIdentity(
      categoryId: catBytes,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      decimals: (json['decimals'] as int?) ?? 0,
      description: json['description'] as String?,
      iconUri: json['iconUri'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final catHex = categoryId
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return {
      'categoryId': catHex,
      'name': name,
      'symbol': symbol,
      'decimals': decimals,
      if (description != null) 'description': description,
      if (iconUri != null) 'iconUri': iconUri,
    };
  }
}

/// BCMR registry document containing token identity entries.
class BcmrRegistry {
  /// Schema version (e.g. "2.0.0").
  final String version;

  final List<BcmrIdentity> identities;

  const BcmrRegistry({
    this.version = '2.0.0',
    this.identities = const [],
  });

  factory BcmrRegistry.fromJson(Map<String, dynamic> json) {
    final version = (json['version'] as String?) ?? '2.0.0';
    final ids = <BcmrIdentity>[];
    final identitiesMap = json['identities'] as Map<String, dynamic>?;
    if (identitiesMap != null) {
      for (final entry in identitiesMap.entries) {
        final data = entry.value as Map<String, dynamic>;
        ids.add(BcmrIdentity.fromJson({...data, 'categoryId': entry.key}));
      }
    }
    return BcmrRegistry(version: version, identities: ids);
  }

  BcmrIdentity? findByCategory(Uint8List categoryId) {
    for (final id in identities) {
      if (id.categoryId.length == categoryId.length) {
        var match = true;
        for (var i = 0; i < categoryId.length; i++) {
          if (id.categoryId[i] != categoryId[i]) {
            match = false;
            break;
          }
        }
        if (match) return id;
      }
    }
    return null;
  }
}
