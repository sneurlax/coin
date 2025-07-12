class Denomination {
  final String name;
  final String symbol;
  final int decimalPlaces;

  const Denomination({
    required this.name,
    required this.symbol,
    required this.decimalPlaces,
  });

  BigInt get factor {
    var f = BigInt.one;
    for (var i = 0; i < decimalPlaces; i++) {
      f *= BigInt.from(10);
    }
    return f;
  }

  BigInt toMinor(String amount) {
    final parts = amount.split('.');
    final whole = BigInt.parse(parts[0]) * factor;
    if (parts.length == 1) return whole;
    var frac = parts[1];
    if (frac.length > decimalPlaces) {
      frac = frac.substring(0, decimalPlaces);
    }
    frac = frac.padRight(decimalPlaces, '0');
    return whole + BigInt.parse(frac);
  }

  String fromMinor(BigInt minor) {
    final isNeg = minor.isNegative;
    final abs = minor.abs();
    final whole = abs ~/ factor;
    final frac = (abs % factor).toString().padLeft(decimalPlaces, '0');
    final trimmed = frac.replaceAll(RegExp(r'0+$'), '');
    final prefix = isNeg ? '-' : '';
    if (trimmed.isEmpty) return '$prefix$whole';
    return '$prefix$whole.$trimmed';
  }

  static const satoshi = Denomination(
    name: 'Bitcoin', symbol: 'BTC', decimalPlaces: 8,
  );

  static const gwei = Denomination(
    name: 'Gwei', symbol: 'Gwei', decimalPlaces: 9,
  );

  static const wei = Denomination(
    name: 'Ether', symbol: 'ETH', decimalPlaces: 18,
  );

  static const piconero = Denomination(
    name: 'Monero', symbol: 'XMR', decimalPlaces: 12,
  );
}
