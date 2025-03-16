final BigInt ed25519P =
    BigInt.two.pow(255) - BigInt.from(19);

final BigInt ed25519D = BigInt.parse(
    '37095705934669439343138083508754565189542113879843219016388785533085940283555');

final BigInt ed25519L = BigInt.two.pow(252) +
    BigInt.parse('27742317777372353535851937790883648493');

final BigInt ed25519HalfL = ed25519L >> 1;

final BigInt ed25519I = BigInt.parse(
    '19681161376707505956807079304988542015446066515923890162744021073123829784752');

class EdPoint {
  final BigInt x;
  final BigInt y;
  final bool isInfinity;

  EdPoint(this.x, this.y) : isInfinity = false;
  EdPoint.infinity()
      : x = BigInt.zero,
        y = BigInt.one,
        isInfinity = true;

  @override
  bool operator ==(Object other) {
    if (other is! EdPoint) return false;
    if (isInfinity && other.isInfinity) return true;
    if (isInfinity || other.isInfinity) return false;
    return x == other.x && y == other.y;
  }

  @override
  int get hashCode => isInfinity ? 0 : x.hashCode ^ y.hashCode;
}

final BigInt _ed25519Gx = BigInt.parse(
    '15112221349535400772501151409588531511454012693041857206046113283949847762202');
final BigInt _ed25519Gy = BigInt.parse(
    '46316835694926478169428394003475163141307993866256225615783033603165251855960');

final EdPoint ed25519G = EdPoint(_ed25519Gx, _ed25519Gy);
