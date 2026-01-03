import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'native_heap.dart';

typedef UCharPointer = Pointer<UnsignedChar>;

/// FFI heap-allocated unsigned char array with Dart Uint8List view.
/// Uses a [Finalizer] to free memory when the object is garbage-collected.
class HeapArrayFfi implements HeapArray {
  static final Finalizer<UCharPointer> _finalizer = Finalizer(
    (ptr) => malloc.free(ptr),
  );

  final int size;
  final UCharPointer _ptr;

  HeapArrayFfi(this.size) : _ptr = malloc.allocate(size) {
    _finalizer.attach(this, _ptr);
  }

  @override
  int get ptr => _ptr.address;

  /// The raw FFI pointer for passing to C functions.
  UCharPointer get ffiPtr => _ptr;

  @override
  Uint8List get list => _ptr.cast<Uint8>().asTypedList(size);

  @override
  void load(Uint8List data) => list.setAll(0, data);

  @override
  void free() {
    _finalizer.detach(this);
    malloc.free(_ptr);
  }
}
