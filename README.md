# coin

A cross-platform, multi-coin cryptocurrency toolkit for Dart.

## Features

- **Bitcoin**: P2PKH, P2SH, P2WPKH, P2WSH, P2TR (Taproot), legacy and SegWit signing
- **Bitcoin forks**: BCH (SIGHASH_FORKID), BSV, Litecoin, Dogecoin, and any UTXO chain
- **Ethereum / EVM**: EIP-55 addresses, EIP-1559/legacy transaction signing, ABI codec
- **Monero**: Ed25519, Pedersen commitments, ring signature primitives
- **HD keys**: BIP-32 key derivation, BIP-39 mnemonics, BIP-44/49/84/86 paths
- **Schnorr**: BIP-340-compliant signing and verification
- **PSBT**: BIP-174 partially-signed transaction builder
- **BIP-47**: Payment codes and stealth address derivation
- **MuSig2**: Multi-signature key aggregation (BIP-327)
- **Crypto primitives**: SHA-256, SHA-512, RIPEMD-160, HMAC, PBKDF2, secp256k1, Ed25519

The secp256k1 operations use a native FFI binding to `libsecp256k1` on native targets, with a pure-Dart fallback for web.

## Getting started

```yaml
dependencies:
  coin: ^0.1.0
```

## Usage

### Mnemonic / HD wallet

```dart
import 'package:coin/coin.dart';

await VaultKeeper.initialize();

// Generate a 12-word BIP-39 mnemonic
final mnemonic = Mnemonic.generate();
print(mnemonic.phrase);

// Derive a BIP-32 master key from the seed
final seed = mnemonic.toSeed(passphrase: 'optional');
final master = DerivedKey.fromSeed(seed) as DerivedSecretKey;

// Derive a Bitcoin receiving address (BIP-84 native SegWit path)
final child = master.derivePath("m/84'/0'/0'/0/0") as DerivedSecretKey;
final pkHash = hash160(child.publicKey.bytes);
final addr = P2wpkhAddr(pkHash).encode(bitcoin);
print(addr); // bc1q...
```

### Schnorr / Taproot

```dart
import 'package:coin/coin.dart';

await VaultKeeper.initialize();

final sk = SecretKey.generate();
final msg = sha256(Uint8List.fromList('hello'.codeUnits));

final sig = SchnorrSig.sign(msg, sk.bytes);
print(sig.verify(msg, sk.xOnly)); // true

// Taproot address
final taprootAddr = TaprootAddr(sk.xOnly).encode(bitcoin);
print(taprootAddr); // bc1p...
```

### EVM / Ethereum

```dart
import 'package:coin/coin_evm.dart';

await VaultKeeper.initialize();

final sk = SecretKey.generate();
final addr = EvmAddr.fromPublicKey(sk.publicKey);
print(addr.checksummed); // 0x...

final tx = EvmTx.eip1559(
  chainId: BigInt.from(1),
  nonce: BigInt.zero,
  maxFeePerGas: BigInt.from(20000000000),
  maxPriorityFeePerGas: BigInt.from(1000000000),
  gasLimit: BigInt.from(21000),
  to: addr,
  value: BigInt.from(1000000000000000000), // 1 ETH
);
final signed = tx.sign(sk.bytes);
print(hexEncode(signed.encoded));
```

### Monero

```dart
import 'package:coin/coin_monero.dart';

await VaultKeeper.initialize();

final keys = MoneroKeys.generate();
print(keys.primaryAddress); // 4...
```

## Initialization

All cryptographic operations require `VaultKeeper.initialize()` to be called once at app startup (or test `setUpAll`):

```dart
await VaultKeeper.initialize();
```

## Barrel exports

| Import | Contents |
|--------|----------|
| `package:coin/coin.dart` | Core: Bitcoin, HD keys, Schnorr, mnemonics, primitives |
| `package:coin/coin_chains.dart` | UTXO chains: BCH, Litecoin, Dogecoin, PSBT, BIP-47 |
| `package:coin/coin_evm.dart` | Ethereum / EVM: transactions, ABI codec, ENS |
| `package:coin/coin_monero.dart` | Monero: keys, addresses, ring signatures |
