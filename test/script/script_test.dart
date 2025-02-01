import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  // Hash 89abcdef... is an arbitrary placeholder for P2PKH structure tests.
  // Hash b472a266... is the P2SH hash for address 3J98t1Wp... (see base58_test).
  // Hash 751e76e8... is HASH160 of private-key-1's compressed pubkey.
  // Taproot key f9308a01... is the x-coordinate of 3*G (BIP-340 vector 0):
  // https://github.com/bitcoin/bips/blob/master/bip-0340/test-vectors.csv
  group('P2PKH locking script', () {
    test('produces correct scriptPubKey bytes', () {
      final hash = hexDecode('89abcdefabbaabbaabbaabbaabbaabbaabbaabba');
      final locking = PayToPubKeyHash(hash);
      final compiled = locking.compiled;

      expect(compiled.length, 25);
      expect(compiled[0], Op.dup);
      expect(compiled[1], Op.hash160);
      expect(compiled[2], 20);
      expect(compiled.sublist(3, 23), equals(hash));
      expect(compiled[23], Op.equalVerify);
      expect(compiled[24], Op.checkSig);
    });

    test('match round-trips via decompile', () {
      final hash = hexDecode('0000000000000000000000000000000000000000');
      final locking = PayToPubKeyHash(hash);
      final decompiled = Script.decompile(locking.compiled);
      final matched = PayToPubKeyHash.match(decompiled);
      expect(matched, isNotNull);
      expect(matched!.pubKeyHash, equals(hash));
    });

    test('rejects invalid hash length', () {
      expect(() => PayToPubKeyHash(Uint8List(19)), throwsArgumentError);
      expect(() => PayToPubKeyHash(Uint8List(21)), throwsArgumentError);
    });
  });

  group('P2SH locking script', () {
    test('produces correct scriptPubKey bytes', () {
      final hash = hexDecode('b472a266d0bd89c13706a4132ccfb16f7c3b9fcb');
      final locking = PayToScriptHash(hash);
      final compiled = locking.compiled;

      expect(compiled.length, 23);
      expect(compiled[0], Op.hash160);
      expect(compiled[1], 20);
      expect(compiled.sublist(2, 22), equals(hash));
      expect(compiled[22], Op.equal);
    });

    test('match round-trips via decompile', () {
      final hash = hexDecode('b472a266d0bd89c13706a4132ccfb16f7c3b9fcb');
      final locking = PayToScriptHash(hash);
      final decompiled = Script.decompile(locking.compiled);
      final matched = PayToScriptHash.match(decompiled);
      expect(matched, isNotNull);
      expect(matched!.scriptHash, equals(hash));
    });

    test('rejects invalid hash length', () {
      expect(() => PayToScriptHash(Uint8List(19)), throwsArgumentError);
      expect(() => PayToScriptHash(Uint8List(21)), throwsArgumentError);
    });
  });

  group('P2WPKH locking script', () {
    test('produces correct scriptPubKey bytes', () {
      final hash = hexDecode('751e76e8199196d454941c45d1b3a323f1433bd6');
      final locking = PayToWitnessPubKey(hash);
      final compiled = locking.compiled;

      expect(compiled.length, 22);
      expect(compiled[0], Op.op0);
      expect(compiled[1], 20);
      expect(compiled.sublist(2, 22), equals(hash));
    });

    test('match succeeds on constructed script', () {
      final hash = hexDecode('751e76e8199196d454941c45d1b3a323f1433bd6');
      final locking = PayToWitnessPubKey(hash);
      final matched = PayToWitnessPubKey.match(locking.script);
      expect(matched, isNotNull);
      expect(matched!.pubKeyHash, equals(hash));
    });

    test('rejects invalid hash length', () {
      expect(() => PayToWitnessPubKey(Uint8List(19)), throwsArgumentError);
      expect(() => PayToWitnessPubKey(Uint8List(21)), throwsArgumentError);
    });
  });

  group('P2WSH locking script', () {
    test('produces correct scriptPubKey bytes', () {
      final hash = Uint8List(32);
      for (var i = 0; i < 32; i++) hash[i] = i;
      final locking = PayToWitnessScript(hash);
      final compiled = locking.compiled;

      expect(compiled.length, 34);
      expect(compiled[0], Op.op0);
      expect(compiled[1], 32);
      expect(compiled.sublist(2, 34), equals(hash));
    });

    test('match succeeds on constructed script', () {
      final hash = Uint8List(32);
      for (var i = 0; i < 32; i++) hash[i] = 0xff - i;
      final locking = PayToWitnessScript(hash);
      final matched = PayToWitnessScript.match(locking.script);
      expect(matched, isNotNull);
      expect(matched!.scriptHash, equals(hash));
    });

    test('rejects invalid hash length', () {
      expect(() => PayToWitnessScript(Uint8List(31)), throwsArgumentError);
      expect(() => PayToWitnessScript(Uint8List(33)), throwsArgumentError);
    });
  });

  group('P2TR locking script', () {
    test('produces correct scriptPubKey bytes', () {
      final key = hexDecode(
          'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9');
      final locking = PayToTaproot(key);
      final compiled = locking.compiled;

      expect(compiled.length, 34);
      expect(compiled[0], Op.op1);
      expect(compiled[1], 32);
      expect(compiled.sublist(2, 34), equals(key));
    });

    test('match round-trips via decompile', () {
      final key = hexDecode(
          'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9');
      final locking = PayToTaproot(key);
      final decompiled = Script.decompile(locking.compiled);
      final matched = PayToTaproot.match(decompiled);
      expect(matched, isNotNull);
      expect(matched!.outputKey, equals(key));
    });

    test('rejects invalid key length', () {
      expect(() => PayToTaproot(Uint8List(31)), throwsArgumentError);
      expect(() => PayToTaproot(Uint8List(33)), throwsArgumentError);
    });
  });

  group('MultiSig locking script', () {
    test('2-of-3 produces correct scriptPubKey structure', () {
      final pk1 = Uint8List.fromList(List.filled(33, 0x02));
      final pk2 = Uint8List.fromList(List.filled(33, 0x03));
      final pk3 = Uint8List.fromList(List.filled(33, 0x04));
      final locking = MultiSig(threshold: 2, publicKeys: [pk1, pk2, pk3]);
      final compiled = locking.compiled;

      expect(compiled[0], Op.op2);
      expect(compiled[1], 33);
      expect(compiled.sublist(2, 35), equals(pk1));
      expect(compiled[35], 33);
      expect(compiled.sublist(36, 69), equals(pk2));
      expect(compiled[69], 33);
      expect(compiled.sublist(70, 103), equals(pk3));
      expect(compiled[103], Op.op3);
      expect(compiled[104], Op.checkMultiSig);
      expect(compiled.length, 105);
    });

    test('rejects invalid threshold', () {
      final pk = Uint8List.fromList(List.filled(33, 0x02));
      expect(() => MultiSig(threshold: 0, publicKeys: [pk]),
          throwsArgumentError);
      expect(() => MultiSig(threshold: 3, publicKeys: [pk, pk]),
          throwsArgumentError);
    });
  });

  group('PayToWitness generic witness program', () {
    test('version 0 with 20-byte program matches P2WPKH layout', () {
      final program = Uint8List(20);
      final locking = PayToWitness(0, program);
      final compiled = locking.compiled;

      expect(compiled[0], Op.op0);
      expect(compiled[1], 20);
      expect(compiled.sublist(2), equals(program));
    });

    test('version 1 with 32-byte program matches P2TR layout', () {
      final program = Uint8List(32);
      final locking = PayToWitness(1, program);
      final compiled = locking.compiled;

      expect(compiled[0], Op.op1);
      expect(compiled[1], 32);
      expect(compiled.sublist(2), equals(program));
    });

    test('match succeeds on constructed script (version 0)', () {
      final program = Uint8List.fromList(List.filled(20, 0xab));
      final locking = PayToWitness(0, program);
      final matched = PayToWitness.match(locking.script);
      expect(matched, isNotNull);
      expect(matched!.version, 0);
      expect(matched.program, equals(program));
    });

    test('match succeeds on constructed script (version 1)', () {
      final program = Uint8List.fromList(List.filled(32, 0xcd));
      final locking = PayToWitness(1, program);
      final matched = PayToWitness.match(locking.script);
      expect(matched, isNotNull);
      expect(matched!.version, 1);
      expect(matched.program, equals(program));
    });

    test('rejects invalid witness version', () {
      expect(() => PayToWitness(-1, Uint8List(20)), throwsArgumentError);
      expect(() => PayToWitness(17, Uint8List(20)), throwsArgumentError);
    });

    test('rejects invalid program length', () {
      expect(() => PayToWitness(0, Uint8List(1)), throwsArgumentError);
      expect(() => PayToWitness(0, Uint8List(41)), throwsArgumentError);
    });
  });

  group('Script compile/decompile round-trip', () {
    test('P2PKH round-trips', () {
      final hash = hexDecode('89abcdefabbaabbaabbaabbaabbaabbaabbaabba');
      final original = PayToPubKeyHash(hash);
      final bytes = original.compiled;
      final decompiled = Script.decompile(bytes);
      final recompiled = decompiled.compiled;
      expect(recompiled, equals(bytes));
    });

    test('P2SH round-trips', () {
      final hash = hexDecode('b472a266d0bd89c13706a4132ccfb16f7c3b9fcb');
      final original = PayToScriptHash(hash);
      final bytes = original.compiled;
      final decompiled = Script.decompile(bytes);
      final recompiled = decompiled.compiled;
      expect(recompiled, equals(bytes));
    });

    test('P2WPKH round-trips', () {
      final hash = hexDecode('751e76e8199196d454941c45d1b3a323f1433bd6');
      final original = PayToWitnessPubKey(hash);
      final bytes = original.compiled;
      final decompiled = Script.decompile(bytes);
      final recompiled = decompiled.compiled;
      expect(recompiled, equals(bytes));
    });

    test('P2WSH round-trips', () {
      final hash = Uint8List(32);
      for (var i = 0; i < 32; i++) hash[i] = i;
      final original = PayToWitnessScript(hash);
      final bytes = original.compiled;
      final decompiled = Script.decompile(bytes);
      final recompiled = decompiled.compiled;
      expect(recompiled, equals(bytes));
    });

    test('P2TR round-trips', () {
      final key = hexDecode(
          'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9');
      final original = PayToTaproot(key);
      final bytes = original.compiled;
      final decompiled = Script.decompile(bytes);
      final recompiled = decompiled.compiled;
      expect(recompiled, equals(bytes));
    });

    test('arbitrary script round-trips via ASM', () {
      final s = Script.fromAsm(
        'OP_DUP OP_HASH160 89abcdefabbaabbaabbaabbaabbaabbaabbaabba '
        'OP_EQUALVERIFY OP_CHECKSIG',
      );
      final bytes = s.compiled;
      final decompiled = Script.decompile(bytes);
      expect(decompiled.asm, s.asm);
      expect(decompiled.compiled, equals(bytes));
    });
  });

  group('Script.fromAsm', () {
    test('parses P2PKH ASM', () {
      final s = Script.fromAsm(
        'OP_DUP OP_HASH160 751e76e8199196d454941c45d1b3a323f1433bd6 '
        'OP_EQUALVERIFY OP_CHECKSIG',
      );
      expect(s.ops.length, 5);
      expect(s.ops[0], equals(OpCode(Op.dup)));
      expect(s.ops[1], equals(OpCode(Op.hash160)));
      expect(s.ops[2], isA<PushData>());
      expect((s.ops[2] as PushData).data.length, 20);
      expect(s.ops[3], equals(OpCode(Op.equalVerify)));
      expect(s.ops[4], equals(OpCode(Op.checkSig)));
    });

    test('parses OP_RETURN data', () {
      final s = Script.fromAsm('OP_RETURN deadbeef');
      expect(s.ops.length, 2);
      expect(s.ops[0], equals(OpCode(Op.returnOp)));
      expect(s.ops[1], isA<PushData>());
      expect((s.ops[1] as PushData).data,
          equals(hexDecode('deadbeef')));
    });
  });

  group('PushData compilation edge cases', () {
    test('empty data compiles to OP_0', () {
      final op = PushData(Uint8List(0));
      expect(op.compile(), equals(Uint8List.fromList([Op.op0])));
    });

    test('single byte 1-16 compiles to OP_N', () {
      for (var n = 1; n <= 16; n++) {
        final op = PushData(Uint8List.fromList([n]));
        final compiled = op.compile();
        expect(compiled.length, 1);
        expect(compiled[0], Op.numberOp(n));
      }
    });

    test('75-byte data uses direct length prefix', () {
      final data = Uint8List(75);
      final op = PushData(data);
      final compiled = op.compile();
      expect(compiled.length, 76);
      expect(compiled[0], 75);
    });

    test('76-byte data uses OP_PUSHDATA1', () {
      final data = Uint8List(76);
      final op = PushData(data);
      final compiled = op.compile();
      expect(compiled.length, 78);
      expect(compiled[0], Op.pushData1);
      expect(compiled[1], 76);
    });
  });
}
