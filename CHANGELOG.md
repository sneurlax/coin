# Changelog

## 0.1.0

- Initial release.
- Bitcoin: P2PKH, P2SH, P2WPKH, P2WSH, P2TR address types and signing.
- BIP-32 HD key derivation (`DerivedKey`, `DerivedSecretKey`, `DerivedPublicKey`).
- BIP-39 mnemonic generation and BIP-39 seed derivation (PBKDF2-HMAC-SHA512).
- BIP-340 Schnorr signing and verification (`SchnorrSig`).
- BIP-143 witness sighash (`WitnessSigHasher`) and legacy sighash (`LegacySigHasher`).
- BIP-174 PSBT builder.
- BIP-47 payment codes and shared address derivation.
- BIP-327 MuSig2 key aggregation and partial signing.
- UTXO chain support: BCH (SIGHASH_FORKID), Litecoin, Dogecoin.
- Ethereum / EVM: EIP-55 addresses, EIP-1559 and legacy transactions, ABI codec.
- Monero: Ed25519 keys, primary and subaddresses, ring signature primitives.
- secp256k1 via native FFI (`libsecp256k1`) on native targets; pure-Dart fallback for web.
- Ed25519 via native FFI on native targets; pure-Dart fallback.
- Bech32 and Bech32m encode/decode (BIP-173, BIP-350).
- Base58Check encode/decode.
- Hash functions: SHA-256, SHA-512, RIPEMD-160, HMAC-SHA-256/512, PBKDF2.
