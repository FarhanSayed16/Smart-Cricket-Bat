import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:knoq_app/core/constants/ble_constants.dart';
import 'package:knoq_app/core/errors/app_exceptions.dart';

class BleRepository {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;

  /// Returns the scan results stream after starting the scan.
  Stream<List<ScanResult>> startScan({Duration timeout = const Duration(seconds: 10)}) {
    FlutterBluePlus.startScan(
      timeout: timeout,
      withNames: [BleConstants.deviceName],
    );
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    await device.connect(autoConnect: false, mtu: null);
    
    // Negotiate MTU natively on Android
    try {
      await device.requestMtu(512);
    } catch(_) {
      // Ignored for iOS or failed negotiation (fall back to default MTU)
    }
  }

  Future<void> disconnect() async {
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {
        // Device may already be disconnected
      }
      _device = null;
      _txChar = null;
      _rxChar = null;
    }
  }

  Stream<BluetoothConnectionState>? getConnectionState() {
    return _device?.connectionState;
  }

  BluetoothDevice? get connectedDevice => _device;

  Future<void> discoverServices() async {
    if (_device == null) {
      throw BleConnectionException('No device connected');
    }
    
    _txChar = null;
    _rxChar = null;
    
    List<BluetoothService> services = await _device!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == BleConstants.serviceUuid.toUpperCase()) {
        for (var characteristic in service.characteristics) {
          final charUuid = characteristic.uuid.toString().toUpperCase();
          if (charUuid == BleConstants.txUuid.toUpperCase()) {
            _txChar = characteristic;
          }
          if (charUuid == BleConstants.rxUuid.toUpperCase()) {
             _rxChar = characteristic;
          }
        }
      }
    }

    if (_txChar == null) {
      throw BleConnectionException('TX characteristic not found on device');
    }
  }

  Future<Stream<List<int>>?> subscribeToTx() async {
    if (_txChar == null) return null;
    
    await _txChar!.setNotifyValue(true);
    return _txChar!.onValueReceived;
  }

  Future<void> sendCommand(String jsonString) async {
    if (_rxChar == null) {
      throw BleConnectionException('RX Characteristic not found — cannot send command');
    }
    await _rxChar!.write(utf8.encode(jsonString), withoutResponse: true);
  }
}
