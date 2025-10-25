import 'dart:typed_data';

import '../../crypto/secret_key.dart';
import '../../crypto/public_key.dart';
import '../../hash/digest.dart';
import '../../addr/legacy_addr.dart';
import '../../addr/segwit_addr.dart';
import '../../chain/chain.dart';
import 'payment_code.dart';
import 'secret_point.dart';

class PaymentAddress {
  /// Derive a send address at [index] (Alice -> Bob).
  ///
  /// [myKey] is the sender's notification private key (a_0).
  /// Bob's child pubkey B_n is derived from [theirPaymentCode] at [index],
  /// then tweaked with SHA256(ECDH(a_0, B_n)).
  static String deriveSendAddress({
    required SecretKey myKey,
    required PaymentCode theirPaymentCode,
    required int index,
    required Chain chain,
    bool segwit = false,
  }) {
    final theirChildPubKey = theirPaymentCode.derivePublicKey(index);
    final S = SecretPoint(myKey, theirChildPubKey);
    final s = sha256(S.ecdhSecret);

    final tweaked = theirChildPubKey.tweak(s);
    if (tweaked == null) {
      throw StateError('Invalid tweaked key at index $index');
    }

    final pkHash = hash160(tweaked.bytes);
    if (segwit) {
      return P2wpkhAddr(pkHash).encode(chain);
    }
    return P2pkhAddr(pkHash).encode(chain);
  }

  /// Derive a receive address at [index] (Bob <- Alice).
  ///
  /// [myKey] is the receiver's private key at [index] (b_n).
  /// The sender's notification pubkey A_0 is derived from
  /// [theirPaymentCode], then ECDH(b_n, A_0) == ECDH(a_0, B_n).
  static String deriveReceiveAddress({
    required SecretKey myKey,
    required PaymentCode theirPaymentCode,
    required int index,
    required Chain chain,
    bool segwit = false,
  }) {
    final theirNotificationPubKey = theirPaymentCode.derivePublicKey(0);
    final S = SecretPoint(myKey, theirNotificationPubKey);
    final s = sha256(S.ecdhSecret);

    final tweaked = myKey.publicKey.tweak(s);
    if (tweaked == null) {
      throw StateError('Invalid tweaked key at index $index');
    }

    final pkHash = hash160(tweaked.bytes);
    if (segwit) {
      return P2wpkhAddr(pkHash).encode(chain);
    }
    return P2pkhAddr(pkHash).encode(chain);
  }
}
