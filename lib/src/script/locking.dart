import 'dart:typed_data';
import 'script.dart';

abstract class Locking {
  Script get script;

  Uint8List get compiled => script.compiled;

  factory Locking.fromScript(Uint8List bytes) {
    final s = Script.decompile(bytes);
    // Importers will register concrete types; this is the fallback chain.
    return RawLocking(s);
  }
}

class RawLocking implements Locking {
  @override
  final Script script;

  RawLocking(this.script);

  @override
  Uint8List get compiled => script.compiled;
}
