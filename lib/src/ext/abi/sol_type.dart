import 'dart:typed_data';

abstract class SolType {
  String get name;
  bool get isDynamic;

  /// ABI-encode [value] as a 32-byte-aligned Uint8List.
  /// For dynamic types, returns the tail; the caller places the offset in the head.
  Uint8List encode(dynamic value);

  /// ABI-decode from [data] at byte [offset].
  /// Returns (decoded value, bytes consumed from head).
  (dynamic value, int consumed) decode(Uint8List data, int offset);

  @override
  String toString() => name;
}
