class SigHashType {
  final int flag;
  const SigHashType._(this.flag);

  static const all = SigHashType._(0x01);
  static const none = SigHashType._(0x02);
  static const single = SigHashType._(0x03);

  bool get anyoneCanPay => (flag & 0x80) != 0;

  SigHashType withAnyoneCanPay() => SigHashType._(flag | 0x80);

  static const allAnyoneCanPay = SigHashType._(0x81);
  static const noneAnyoneCanPay = SigHashType._(0x82);
  static const singleAnyoneCanPay = SigHashType._(0x83);

  factory SigHashType.fromFlag(int flag) => SigHashType._(flag);

  int get baseType => flag & 0x1f;

  @override
  bool operator ==(Object other) =>
      other is SigHashType && flag == other.flag;

  @override
  int get hashCode => flag;
}
