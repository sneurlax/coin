import 'dart:typed_data';

import 'package:coin/coin_chains.dart';

Future<void> main() async {
  await VaultKeeper.initialize();

  // --- BIP-39 mnemonic ---
  final mnemonic = Mnemonic.generate();
  // ignore: avoid_print
  print('Mnemonic: ${mnemonic.phrase}');

  final seed = mnemonic.toSeed();
  final master = DerivedKey.fromSeed(seed) as DerivedSecretKey;

  // --- BIP-84 native SegWit receiving address ---
  final child = master.derivePath("m/84'/0'/0'/0/0") as DerivedSecretKey;
  final pkHash = hash160(child.publicKey.bytes);
  final chain = BitcoinParams.bitcoin.chain;
  final p2wpkhAddr = P2wpkhAddr(pkHash).encode(chain);
  // ignore: avoid_print
  print('P2WPKH address: $p2wpkhAddr');

  // --- Taproot (P2TR) address ---
  final taprootChild = master.derivePath("m/86'/0'/0'/0/0") as DerivedSecretKey;
  final taprootAddr = TaprootAddr(taprootChild.secretKey.xOnly).encode(chain);
  // ignore: avoid_print
  print('Taproot address: $taprootAddr');

  // --- Schnorr signing (BIP-340) ---
  final sk = SecretKey.generate();
  final msg = sha256(Uint8List.fromList('hello world'.codeUnits));
  final sig = SchnorrSig.sign(msg, sk.bytes);
  final valid = sig.verify(msg, sk.xOnly);
  // ignore: avoid_print
  print('Schnorr signature valid: $valid');
}
