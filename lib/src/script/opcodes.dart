class Op {
  Op._();

  static const int op0 = 0x00;
  static const int pushData1 = 0x4c;
  static const int pushData2 = 0x4d;
  static const int pushData4 = 0x4e;
  static const int op1Negate = 0x4f;
  static const int op1 = 0x51;
  static const int op2 = 0x52;
  static const int op3 = 0x53;
  static const int op4 = 0x54;
  static const int op5 = 0x55;
  static const int op6 = 0x56;
  static const int op7 = 0x57;
  static const int op8 = 0x58;
  static const int op9 = 0x59;
  static const int op10 = 0x5a;
  static const int op11 = 0x5b;
  static const int op12 = 0x5c;
  static const int op13 = 0x5d;
  static const int op14 = 0x5e;
  static const int op15 = 0x5f;
  static const int op16 = 0x60;

  static const int nop = 0x61;
  static const int ifOp = 0x63;
  static const int notIf = 0x64;
  static const int elseOp = 0x67;
  static const int endIf = 0x68;
  static const int verify = 0x69;
  static const int returnOp = 0x6a;

  static const int toAltStack = 0x6b;
  static const int fromAltStack = 0x6c;
  static const int drop2 = 0x6d;
  static const int dup2 = 0x6e;
  static const int dup3 = 0x6f;
  static const int over2 = 0x70;
  static const int rot2 = 0x71;
  static const int swap2 = 0x72;
  static const int ifDup = 0x73;
  static const int depth = 0x74;
  static const int drop = 0x75;
  static const int dup = 0x76;
  static const int nip = 0x77;
  static const int over = 0x78;
  static const int pick = 0x79;
  static const int roll = 0x7a;
  static const int rot = 0x7b;
  static const int swap = 0x7c;
  static const int tuck = 0x7d;

  static const int size = 0x82;

  static const int equal = 0x87;
  static const int equalVerify = 0x88;

  static const int add1 = 0x8b;
  static const int sub1 = 0x8c;
  static const int negate = 0x8f;
  static const int abs = 0x90;
  static const int not = 0x91;
  static const int notEqual0 = 0x92;
  static const int add = 0x93;
  static const int sub = 0x94;

  static const int boolAnd = 0x9a;
  static const int boolOr = 0x9b;
  static const int numEqual = 0x9c;
  static const int numEqualVerify = 0x9d;
  static const int numNotEqual = 0x9e;
  static const int lessThan = 0x9f;
  static const int greaterThan = 0xa0;
  static const int lessThanOrEqual = 0xa1;
  static const int greaterThanOrEqual = 0xa2;
  static const int min = 0xa3;
  static const int max = 0xa4;
  static const int within = 0xa5;

  static const int ripemd160 = 0xa6;
  static const int sha1 = 0xa7;
  static const int sha256 = 0xa8;
  static const int hash160 = 0xa9;
  static const int hash256 = 0xaa;

  static const int codeSeparator = 0xab;
  static const int checkSig = 0xac;
  static const int checkSigVerify = 0xad;
  static const int checkMultiSig = 0xae;
  static const int checkMultiSigVerify = 0xaf;

  static const int nop1 = 0xb0;
  static const int checkLockTimeVerify = 0xb1;
  static const int checkSequenceVerify = 0xb2;
  static const int nop4 = 0xb3;

  // Tapscript
  static const int checkSigAdd = 0xba;

  static int numberOp(int n) {
    if (n == 0) return op0;
    if (n == -1) return op1Negate;
    if (n >= 1 && n <= 16) return op1 + n - 1;
    throw ArgumentError('No small number opcode for $n');
  }

  static final Map<int, String> names = {
    op0: 'OP_0', pushData1: 'OP_PUSHDATA1', pushData2: 'OP_PUSHDATA2',
    pushData4: 'OP_PUSHDATA4', op1Negate: 'OP_1NEGATE',
    op1: 'OP_1', op2: 'OP_2', op3: 'OP_3', op4: 'OP_4', op5: 'OP_5',
    op6: 'OP_6', op7: 'OP_7', op8: 'OP_8', op9: 'OP_9', op10: 'OP_10',
    op11: 'OP_11', op12: 'OP_12', op13: 'OP_13', op14: 'OP_14',
    op15: 'OP_15', op16: 'OP_16',
    nop: 'OP_NOP', ifOp: 'OP_IF', notIf: 'OP_NOTIF', elseOp: 'OP_ELSE',
    endIf: 'OP_ENDIF', verify: 'OP_VERIFY', returnOp: 'OP_RETURN',
    dup: 'OP_DUP', drop: 'OP_DROP', swap: 'OP_SWAP',
    equal: 'OP_EQUAL', equalVerify: 'OP_EQUALVERIFY',
    hash160: 'OP_HASH160', hash256: 'OP_HASH256',
    sha256: 'OP_SHA256', ripemd160: 'OP_RIPEMD160',
    checkSig: 'OP_CHECKSIG', checkSigVerify: 'OP_CHECKSIGVERIFY',
    checkMultiSig: 'OP_CHECKMULTISIG',
    checkMultiSigVerify: 'OP_CHECKMULTISIGVERIFY',
    checkLockTimeVerify: 'OP_CHECKLOCKTIMEVERIFY',
    checkSequenceVerify: 'OP_CHECKSEQUENCEVERIFY',
    checkSigAdd: 'OP_CHECKSIGADD',
  };

  static String name(int opcode) => names[opcode] ?? 'OP_UNKNOWN($opcode)';
}
