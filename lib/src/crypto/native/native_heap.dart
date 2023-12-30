import 'dart:typed_data';

abstract class HeapArray {
  int get ptr;
  Uint8List get list;
  void load(Uint8List data);
  void free();
}
