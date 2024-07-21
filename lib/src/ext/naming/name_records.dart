import 'dart:typed_data';

/// ENS text records and contenthash resolution.
class NameRecords {
  final String name;

  NameRecords(this.name);

  /// Text record by key ("email", "url", "avatar", "com.twitter", etc.).
  Future<String?> getText(String key) {
    throw UnimplementedError('NameRecords.getText not yet implemented');
  }

  Future<void> setText(String key, String value) {
    throw UnimplementedError('NameRecords.setText not yet implemented');
  }

  /// Contenthash record (IPFS, Swarm, etc.).
  Future<Uint8List?> getContentHash() {
    throw UnimplementedError('NameRecords.getContentHash not yet implemented');
  }

  Future<void> setContentHash(Uint8List hash) {
    throw UnimplementedError('NameRecords.setContentHash not yet implemented');
  }

  Future<Uint8List?> getAbi() {
    throw UnimplementedError('NameRecords.getAbi not yet implemented');
  }

  Future<List<String>> getTextKeys() {
    throw UnimplementedError('NameRecords.getTextKeys not yet implemented');
  }
}
