/// PSBT global key types (BIP-174 Table 1).
enum PsbtGlobal {
  /// 0x00 - unsigned transaction (v0 only)
  unsignedTx(0x00),
  /// 0x01 - extended public key
  xpub(0x01),
  /// 0x02 - transaction version (v2)
  txVersion(0x02),
  /// 0x03 - fallback locktime (v2)
  fallbackLocktime(0x03),
  /// 0x04 - input count (v2)
  inputCount(0x04),
  /// 0x05 - output count (v2)
  outputCount(0x05),
  /// 0x06 - tx modifiable flags (v2)
  txModifiable(0x06),
  /// 0xfb - PSBT version
  version(0xfb),
  /// 0xfc - proprietary
  proprietary(0xfc);

  final int keyType;
  const PsbtGlobal(this.keyType);
}

/// PSBT per-input key types (BIP-174 Table 2).
enum PsbtInputEntry {
  /// 0x00 - non-witness UTXO (full prev tx)
  nonWitnessUtxo(0x00),
  /// 0x01 - witness UTXO (single output)
  witnessUtxo(0x01),
  /// 0x02 - partial signature
  partialSig(0x02),
  /// 0x03 - sighash type
  sighashType(0x03),
  /// 0x04 - redeem script (P2SH)
  redeemScript(0x04),
  /// 0x05 - witness script (P2WSH)
  witnessScript(0x05),
  /// 0x06 - BIP-32 derivation path
  bip32Derivation(0x06),
  /// 0x07 - finalized scriptSig
  finalScriptSig(0x07),
  /// 0x08 - finalized witness
  finalScriptWitness(0x08),
  /// 0x0e - previous txid (v2)
  previousTxid(0x0e),
  /// 0x0f - previous output index (v2)
  outputIndex(0x0f),
  /// 0x10 - sequence number (v2)
  sequence(0x10),
  /// 0x11 - required time locktime (v2)
  requiredTimeLocktime(0x11),
  /// 0x12 - required height locktime (v2)
  requiredHeightLocktime(0x12),
  /// 0x13 - taproot key spend sig
  tapKeySig(0x13),
  /// 0x14 - taproot script spend sig
  tapScriptSig(0x14),
  /// 0x15 - taproot leaf script
  tapLeafScript(0x15),
  /// 0x16 - taproot BIP-32 derivation
  tapBip32Derivation(0x16),
  /// 0x17 - taproot internal key
  tapInternalKey(0x17),
  /// 0x18 - taproot Merkle root
  tapMerkleRoot(0x18),
  /// 0xfc - proprietary
  proprietary(0xfc);

  final int keyType;
  const PsbtInputEntry(this.keyType);
}

/// PSBT per-output key types (BIP-174 Table 3).
enum PsbtOutputEntry {
  /// 0x00 - redeem script (P2SH)
  redeemScript(0x00),
  /// 0x01 - witness script (P2WSH)
  witnessScript(0x01),
  /// 0x02 - BIP-32 derivation path
  bip32Derivation(0x02),
  /// 0x03 - output amount (v2)
  amount(0x03),
  /// 0x04 - output scriptPubKey (v2)
  script(0x04),
  /// 0x05 - taproot internal key
  tapInternalKey(0x05),
  /// 0x06 - taproot tree
  tapTree(0x06),
  /// 0x07 - taproot BIP-32 derivation
  tapBip32Derivation(0x07),
  /// 0xfc - proprietary
  proprietary(0xfc);

  final int keyType;
  const PsbtOutputEntry(this.keyType);
}
