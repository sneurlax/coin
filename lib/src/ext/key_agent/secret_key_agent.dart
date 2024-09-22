import 'dart:typed_data';

import '../../crypto/ecdsa_sig.dart';
import '../../crypto/secret_key.dart';
import '../../crypto/vault_keeper.dart';
import '../evm/evm_addr.dart';
import '../evm/evm_tx.dart';
import '../evm/evm_tx_signer.dart';
import '../evm/personal_sign.dart';
import '../evm/typed_data.dart';
import 'key_agent.dart';

/// In-memory key agent backed by a [SecretKey].
class SecretKeyAgent implements KeyAgent {
  final SecretKey _key;
  EvmAddr? _addrCache;

  SecretKeyAgent(this._key);

  factory SecretKeyAgent.fromHex(String hex) =>
      SecretKeyAgent(SecretKey.fromHex(hex));

  @override
  Future<EvmAddr> getAddress() async {
    if (_addrCache != null) return _addrCache!;
    final uncompressed =
        VaultKeeper.vault.curve.derivePublicKey(_key.bytes, compressed: false);
    _addrCache = EvmAddr.fromPublicKey(uncompressed);
    return _addrCache!;
  }

  @override
  Future<Uint8List> signTransaction(Envelope envelope) async {
    final signed = EnvelopeSigner.sign(envelope, _key);
    return signed.serialize();
  }

  @override
  Future<Uint8List> signMessage(Uint8List message) async {
    return PersonalSign.sign(message, _key);
  }

  @override
  Future<Uint8List> signHash(Uint8List hash32) async {
    if (hash32.length != 32) {
      throw ArgumentError('Hash must be 32 bytes, got ${hash32.length}');
    }
    final sig = RecoverableEcdsaSig.sign(hash32, _key.bytes);
    final out = Uint8List(65);
    out.setRange(0, 64, sig.bytes);
    out[64] = sig.recId + 27;
    return out;
  }

  @override
  Future<Uint8List> signTypedData(Map<String, dynamic> typedData) async {
    final payload = TypedPayload(
      domain: typedData['domain'] as Map<String, dynamic>,
      primaryType: typedData['primaryType'] as String,
      types: (typedData['types'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList(),
        ),
      ),
      message: typedData['message'] as Map<String, dynamic>,
    );
    return payload.sign(_key);
  }
}
