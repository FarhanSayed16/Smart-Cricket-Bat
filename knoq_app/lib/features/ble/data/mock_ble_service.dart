import 'dart:async';
import 'dart:math';
import 'package:knoq_app/features/ble/domain/shot_data.dart';

/// Simulates the KnoQ-Bat-V1 BLE device for development without hardware.
/// Toggle via environment config in dev flavor.
class MockBleService {
  final bool nullSwingMode;
  final int? disconnectAfterShots;
  Timer? _shotTimer;
  final StreamController<ShotData> _shotCtrl = StreamController.broadcast();
  final StreamController<SessionSummary> _summaryCtrl = StreamController.broadcast();
  int _hitCount = 0;
  final Random _rnd = Random();
  bool _isConnected = false;

  MockBleService({this.nullSwingMode = false, this.disconnectAfterShots});

  Stream<ShotData> get shotStream => _shotCtrl.stream;
  Stream<SessionSummary> get summaryStream => _summaryCtrl.stream;
  bool get isConnected => _isConnected;

  /// Simulates scanning — returns after 2 seconds.
  Future<String> scan() async {
    await Future.delayed(const Duration(seconds: 2));
    return 'KnoQ-Bat-V1'; // Fake device name
  }

  /// Simulates connection — transitions to connected after 1 second.
  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 1));
    _hitCount = 0;
    _isConnected = true;
    _startSimulatingShots();
  }

  void _startSimulatingShots() {
    _shotTimer?.cancel();
    // Random interval between 3-5 seconds per masterplan spec
    _scheduleNextShot();
  }

  void _scheduleNextShot() {
    final delayMs = 3000 + _rnd.nextInt(2000); // 3-5 seconds
    _shotTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_isConnected) return;

      _hitCount++;

      // Simulate random disconnect if configured
      if (disconnectAfterShots != null && _hitCount > disconnectAfterShots!) {
        _simulateDisconnect();
        return;
      }

      final zones = ['Sweet', 'Top', 'Left', 'Right', 'Bottom'];
      final targetZone = zones[_rnd.nextInt(zones.length)];
      final power = 40 + _rnd.nextInt(60);
      final hasSwingData = nullSwingMode ? false : _rnd.nextBool();
      
      final Map<String, dynamic> fakeJson = {
         'hit': _hitCount,
         'zone': targetZone,
         'power': power,
         if (hasSwingData) 'swing': 90.0 + _rnd.nextDouble() * 40.0,
         'sweetPct': targetZone == 'Sweet' ? 80 : 20,
         'avgPower': 65,
         'totalHits': _hitCount
      };

      _shotCtrl.add(ShotData.fromJson(fakeJson));
      _scheduleNextShot();
    });
  }

  void _simulateDisconnect() {
    _isConnected = false;
    _shotTimer?.cancel();
    // Simulate reconnect succeeding after 1 retry
    Future.delayed(const Duration(seconds: 3), () {
      _isConnected = true;
      _startSimulatingShots();
    });
  }

  /// Ends the mock session and emits a summary.
  Future<void> endSession() async {
    _shotTimer?.cancel();
    
    final summary = SessionSummary(
      totalShots: _hitCount,
      avgPower: 65,
      zoneDistribution: {
        'Sweet': 0.4, 'Top': 0.15, 'Left': 0.15, 'Right': 0.15, 'Bottom': 0.15,
      },
    );
    _summaryCtrl.add(summary);
  }

  Future<void> disconnect() async {
    _shotTimer?.cancel();
    _isConnected = false;
  }

  void dispose() {
    _shotTimer?.cancel();
    _shotCtrl.close();
    _summaryCtrl.close();
  }
}
