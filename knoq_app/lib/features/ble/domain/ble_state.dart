import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BleConnectionPhase {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  error
}

class BleState {
  final BleConnectionPhase phase;
  final BluetoothDevice? connectedDevice;
  final String? errorMessage;
  final int reconnectAttempt;

  const BleState({
    this.phase = BleConnectionPhase.disconnected,
    this.connectedDevice,
    this.errorMessage,
    this.reconnectAttempt = 0,
  });

  bool get isConnected => phase == BleConnectionPhase.connected;
  bool get isScanning => phase == BleConnectionPhase.scanning;
  bool get isReconnecting => phase == BleConnectionPhase.reconnecting;

  BleState copyWith({
    BleConnectionPhase? phase,
    BluetoothDevice? connectedDevice,
    String? errorMessage,
    int? reconnectAttempt,
  }) {
    return BleState(
      phase: phase ?? this.phase,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      errorMessage: errorMessage, // Intentionally nullable — null clears the error
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
    );
  }
}
