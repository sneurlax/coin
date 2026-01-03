import 'dart:typed_data';
import 'native_heap.dart';

class HeapArrayWeb implements HeapArray {
  late final Uint8List _buffer;

  HeapArrayWeb(int size) : _buffer = Uint8List(size);

  @override
  int get ptr => 0; // Would be WASM memory offset

  @override
  Uint8List get list => _buffer;

  @override
  void load(Uint8List data) {
    _buffer.setRange(0, data.length, data);
  }

  @override
  void free() {
    // Would free WASM memory
  }
}
