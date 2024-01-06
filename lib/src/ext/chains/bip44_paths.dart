/// Path pattern: m / purpose' / coin_type' / account'
class Bip44Paths {
  Bip44Paths._();

  // BIP-44 (Legacy P2PKH)

  static const bitcoin = "m/44'/0'/0'";
  static const bitcoinTestnet = "m/44'/1'/0'";
  static const litecoin = "m/44'/2'/0'";
  static const litecoinTestnet = "m/44'/1'/0'";
  static const dogecoin = "m/44'/3'/0'";
  static const dogecoinTestnet = "m/44'/1'/0'";
  static const dash = "m/44'/5'/0'";
  static const dashTestnet = "m/44'/1'/0'";
  static const peercoin = "m/44'/6'/0'";
  static const peercoinTestnet = "m/44'/1'/0'";
  static const bitcoinCash = "m/44'/145'/0'";
  static const bitcoinCashTestnet = "m/44'/1'/0'";
  static const bitcoinSv = "m/44'/236'/0'";
  static const bitcoinSvTestnet = "m/44'/1'/0'";

  // BIP-49 (SegWit-in-P2SH)

  static const bitcoinSegwitCompat = "m/49'/0'/0'";
  static const bitcoinTestnetSegwitCompat = "m/49'/1'/0'";
  static const litecoinSegwitCompat = "m/49'/2'/0'";

  // BIP-84 (Native SegWit)

  static const bitcoinNativeSegwit = "m/84'/0'/0'";
  static const bitcoinTestnetNativeSegwit = "m/84'/1'/0'";
  static const litecoinNativeSegwit = "m/84'/2'/0'";

  // BIP-86 (Taproot)

  static const bitcoinTaproot = "m/86'/0'/0'";
  static const bitcoinTestnetTaproot = "m/86'/1'/0'";

  static String bip44(int coinType, {int account = 0}) =>
      "m/44'/$coinType'/$account'";

  static String bip49(int coinType, {int account = 0}) =>
      "m/49'/$coinType'/$account'";

  static String bip84(int coinType, {int account = 0}) =>
      "m/84'/$coinType'/$account'";

  static String bip86(int coinType, {int account = 0}) =>
      "m/86'/$coinType'/$account'";
}
