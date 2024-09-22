import 'dart:typed_data';

import '../evm/evm_addr.dart';
import '../evm/evm_tx.dart';
import 'key_agent.dart';

/// Hardware signing device (Ledger, Trezor, etc.).
/// The private key never leaves the device.
abstract class HardwareKeyAgent implements KeyAgent {
  String get derivationPath;
  Future<bool> isConnected();
  Future<void> connect();
  Future<void> disconnect();
  Future<Uint8List> getPublicKey();
}

class LedgerAgent extends HardwareKeyAgent {
  @override
  final String derivationPath;

  LedgerAgent({this.derivationPath = "m/44'/60'/0'/0/0"});

  @override
  Future<bool> isConnected() {
    throw UnimplementedError('LedgerAgent.isConnected not yet implemented');
  }

  @override
  Future<void> connect() {
    throw UnimplementedError('LedgerAgent.connect not yet implemented');
  }

  @override
  Future<void> disconnect() {
    throw UnimplementedError('LedgerAgent.disconnect not yet implemented');
  }

  @override
  Future<Uint8List> getPublicKey() {
    throw UnimplementedError('LedgerAgent.getPublicKey not yet implemented');
  }

  @override
  Future<EvmAddr> getAddress() {
    throw UnimplementedError('LedgerAgent.getAddress not yet implemented');
  }

  @override
  Future<Uint8List> signTransaction(Envelope envelope) {
    throw UnimplementedError(
        'LedgerAgent.signTransaction not yet implemented');
  }

  @override
  Future<Uint8List> signMessage(Uint8List message) {
    throw UnimplementedError('LedgerAgent.signMessage not yet implemented');
  }

  @override
  Future<Uint8List> signHash(Uint8List hash32) {
    throw UnimplementedError('LedgerAgent.signHash not yet implemented');
  }

  @override
  Future<Uint8List> signTypedData(Map<String, dynamic> typedData) {
    throw UnimplementedError(
        'LedgerAgent.signTypedData not yet implemented');
  }
}

class TrezorAgent extends HardwareKeyAgent {
  @override
  final String derivationPath;

  TrezorAgent({this.derivationPath = "m/44'/60'/0'/0/0"});

  @override
  Future<bool> isConnected() {
    throw UnimplementedError('TrezorAgent.isConnected not yet implemented');
  }

  @override
  Future<void> connect() {
    throw UnimplementedError('TrezorAgent.connect not yet implemented');
  }

  @override
  Future<void> disconnect() {
    throw UnimplementedError('TrezorAgent.disconnect not yet implemented');
  }

  @override
  Future<Uint8List> getPublicKey() {
    throw UnimplementedError('TrezorAgent.getPublicKey not yet implemented');
  }

  @override
  Future<EvmAddr> getAddress() {
    throw UnimplementedError('TrezorAgent.getAddress not yet implemented');
  }

  @override
  Future<Uint8List> signTransaction(Envelope envelope) {
    throw UnimplementedError(
        'TrezorAgent.signTransaction not yet implemented');
  }

  @override
  Future<Uint8List> signMessage(Uint8List message) {
    throw UnimplementedError('TrezorAgent.signMessage not yet implemented');
  }

  @override
  Future<Uint8List> signHash(Uint8List hash32) {
    throw UnimplementedError('TrezorAgent.signHash not yet implemented');
  }

  @override
  Future<Uint8List> signTypedData(Map<String, dynamic> typedData) {
    throw UnimplementedError(
        'TrezorAgent.signTypedData not yet implemented');
  }
}
