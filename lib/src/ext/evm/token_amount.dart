class TokenAmount {
  final BigInt wei;

  const TokenAmount._(this.wei);

  factory TokenAmount.fromWei(BigInt wei) => TokenAmount._(wei);

  factory TokenAmount.fromWeiInt(int wei) => TokenAmount._(BigInt.from(wei));

  factory TokenAmount.fromGwei(num gwei) {
    final bi = BigInt.from((gwei * 1e9).truncate());
    return TokenAmount._(bi);
  }

  factory TokenAmount.fromEther(num ether) {
    final bi = BigInt.from((ether * 1e18).truncate());
    return TokenAmount._(bi);
  }

  /// Full precision from a decimal string (e.g. "1.5").
  factory TokenAmount.fromEtherString(String ether) {
    final parts = ether.split('.');
    final wholePart = BigInt.parse(parts[0]) * _etherScale;
    if (parts.length == 1) return TokenAmount._(wholePart);

    var fracStr = parts[1];
    if (fracStr.length > 18) {
      fracStr = fracStr.substring(0, 18);
    }
    fracStr = fracStr.padRight(18, '0');
    final fracPart = BigInt.parse(fracStr);

    final sign = ether.startsWith('-') ? -BigInt.one : BigInt.one;
    return TokenAmount._(wholePart.abs() * sign + fracPart * sign);
  }

  static final BigInt _gweiScale = BigInt.from(1000000000);
  static final BigInt _etherScale = BigInt.parse('1000000000000000000');

  BigInt get gwei => wei ~/ _gweiScale;

  /// May lose precision for very large values.
  double get ether => wei / _etherScale;

  /// Up to 18 decimal places, trailing zeros stripped.
  String toEtherString() {
    final isNeg = wei < BigInt.zero;
    final abs = wei.abs();
    final whole = abs ~/ _etherScale;
    final frac = abs % _etherScale;

    if (frac == BigInt.zero) {
      return '${isNeg ? '-' : ''}$whole.0';
    }

    var fracStr = frac.toString().padLeft(18, '0');
    fracStr = fracStr.replaceAll(RegExp(r'0+$'), '');
    return '${isNeg ? '-' : ''}$whole.$fracStr';
  }

  TokenAmount operator +(TokenAmount other) =>
      TokenAmount._(wei + other.wei);

  TokenAmount operator -(TokenAmount other) =>
      TokenAmount._(wei - other.wei);

  TokenAmount operator *(int scalar) =>
      TokenAmount._(wei * BigInt.from(scalar));

  bool operator <(TokenAmount other) => wei < other.wei;
  bool operator <=(TokenAmount other) => wei <= other.wei;
  bool operator >(TokenAmount other) => wei > other.wei;
  bool operator >=(TokenAmount other) => wei >= other.wei;

  @override
  bool operator ==(Object other) =>
      other is TokenAmount && wei == other.wei;

  @override
  int get hashCode => wei.hashCode;

  @override
  String toString() => '$wei wei';
}
