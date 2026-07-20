import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/features/ble/data/ble_repository.dart';
import 'package:knoq_app/features/ble/domain/ble_state.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';
import 'package:knoq_app/features/ble/data/shot_parser.dart';
import 'package:knoq_app/core/constants/ble_constants.dart';
import 'package:knoq_app/services/analytics_service.dart';

final bleRepositoryProvider = Provider<BleRepository>((ref) {
  return BleRepository();
});

/// StreamController that the BleNotifier pushes parsed shots into.
/// Downstream consumers (LiveSessionNotifier) listen to this.
final _shotStreamController = StreamController<ShotData>.broadcast();
final shotStreamProvider = StreamProvider<ShotData>((ref) {
  return _shotStreamController.stream;
});

/// StreamController for session summaries from the firmware.
final _summaryStreamController = StreamController<SessionSummary>.broadcast();
final summaryStreamProvider = StreamProvider<SessionSummary>((ref) {
  return _summaryStreamController.stream;
});

class BleNotifier extends StateNotifier<BleState> {
  final BleRepository _repo;
  final Ref _ref;
  final ShotParser _parser = ShotParser();
  StreamSubscription? _connectionSub;
  StreamSubscription? _dataSub;
  
  /// Stored MAC for reconnection attempts.
  String? _lastDeviceId;

  BleNotifier(this._repo, this._ref) : super(const BleState());

  Stream<List<ScanResult>> scan() {
    state = state.copyWith(phase: BleConnectionPhase.scanning, errorMessage: null);
    _ref.read(analyticsServiceProvider).logBleScanStarted();
    return _repo.startScan();
  }
  
  Future<void> stopScan() async {
    await _repo.stopScan();
    if (state.phase == BleConnectionPhase.scanning) {
      state = state.copyWith(phase: BleConnectionPhase.disconnected);
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    state = state.copyWith(phase: BleConnectionPhase.connecting, errorMessage: null);
    await _repo.stopScan();

    try {
      await _repo.connect(device);
      _lastDeviceId = device.remoteId.str;
      // Persist the last connected device ID for auto-reconnect
      Hive.box('app_settings').put('last_ble_device_id', _lastDeviceId);
      _monitorConnectionState();
      
      await _repo.discoverServices();
      final rxStream = await _repo.subscribeToTx();
      
      if (rxStream != null) {
         _parser.reset();
         _dataSub = rxStream.listen((data) {
             final chunk = utf8.decode(data, allowMalformed: true);
             final objects = _parser.ingest(chunk);
             for (var obj in objects) {
                 if (obj is ShotData) {
                    _shotStreamController.add(obj);
                 }
                 if (obj is SessionSummary) {
                    _summaryStreamController.add(obj);
                 }
             }
         });
      }

      state = state.copyWith(
        phase: BleConnectionPhase.connected,
        connectedDevice: device,
      );

      _ref.read(analyticsServiceProvider).logBleConnected();

    } catch(e) {
      state = state.copyWith(
        phase: BleConnectionPhase.error,
        errorMessage: 'Failed to connect: $e',
      );
    }
  }

  void _monitorConnectionState() {
     _connectionSub?.cancel();
     _connectionSub = _repo.getConnectionState()?.listen((st) {
        if (st == BluetoothConnectionState.disconnected && state.phase == BleConnectionPhase.connected) {
           _dataSub?.cancel();
           // Attempt auto-reconnect
           _attemptReconnect();
        }
     });
  }

  Future<void> _attemptReconnect() async {
    state = state.copyWith(phase: BleConnectionPhase.reconnecting, errorMessage: null);

    for (int i = 0; i < BleConstants.maxReconnectAttempts; i++) {
      await Future.delayed(const Duration(seconds: BleConstants.reconnectDelaySeconds));
      
      try {
        if (state.connectedDevice != null) {
          await _repo.connect(state.connectedDevice!);
          await _repo.discoverServices();
          final rxStream = await _repo.subscribeToTx();
          
          if (rxStream != null) {
            _parser.reset();
            _dataSub = rxStream.listen((data) {
              final chunk = utf8.decode(data, allowMalformed: true);
              final objects = _parser.ingest(chunk);
              for (var obj in objects) {
                if (obj is ShotData) _shotStreamController.add(obj);
                if (obj is SessionSummary) _summaryStreamController.add(obj);
              }
            });
          }
          
          state = state.copyWith(phase: BleConnectionPhase.connected);
          _monitorConnectionState();
          return; // Success
        }
      } catch (_) {
        // Retry on next iteration
      }
    }

    // All retries exhausted
    state = state.copyWith(
      phase: BleConnectionPhase.disconnected,
      errorMessage: 'Connection lost. Tap to retry.',
    );
  }

  /// Attempts to automatically reconnect to the last known device ID from local storage.
  /// Used by the dashboard to silently establish connection in the background.
  Future<void> attemptAutoConnect() async {
    // Prevent overriding if already scanning or connected
    if (state.phase == BleConnectionPhase.connected || state.phase == BleConnectionPhase.connecting) {
      return;
    }

    final savedId = Hive.box('app_settings').get('last_ble_device_id');
    if (savedId == null) return;

    try {
      final device = BluetoothDevice.fromId(savedId);
      // Try connection silently. If it fails or device isn't around, it throws.
      await connect(device);
    } catch (_) {
      // Background silent fail, revert cleanly.
      state = const BleState(phase: BleConnectionPhase.disconnected);
    }
  }

  Future<void> disconnect() async {
    _connectionSub?.cancel();
    _dataSub?.cancel();
    await _repo.disconnect();
    _ref.read(analyticsServiceProvider).logBleDisconnected();
    state = const BleState(phase: BleConnectionPhase.disconnected);
  }

  Future<void> sendCalibrate() async {
    await _repo.sendCommand('{"cmd": "calibrate"}');
  }

  Future<void> sendResetSession() async {
     await _repo.sendCommand('{"cmd": "reset_session"}');
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _dataSub?.cancel();
    _repo.disconnect();
    super.dispose();
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  final repo = ref.watch(bleRepositoryProvider);
  return BleNotifier(repo, ref);
});
