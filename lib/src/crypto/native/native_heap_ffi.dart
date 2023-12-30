import 'dart:typed_data';
import 'native_heap.dart';

class HeapArrayFfi implements HeapArray {
  final int _size;
  // In production: Pointer<Uint8> from malloc
  // Placeholder for FFI integration
  late final Uint8List _buffer;

  HeapArrayFfi(this._size) : _buffer = Uint8List(_size);

  @override
  int get ptr => 0; // Would be pointer address

  @override
  Uint8List get list => _buffer;

  @override
  void load(Uint8List data) {
    _buffer.setRange(0, data.length, data);
  }

  @override
  void free() {
    // Would call malloc.free()
  }
}
