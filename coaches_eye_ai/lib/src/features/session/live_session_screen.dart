import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/shot_model.dart';
import '../../services/camera_service.dart';
import 'session_summary_screen.dart';
import '../connection/device_scan_screen.dart';

/// Live session screen showing real-time shot data
class LiveSessionScreen extends ConsumerStatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  ShotModel? _latestShot;
  int _shotCount = 0;
  DateTime? _sessionStartTime;
  CameraService? _cameraService;
  bool _isRecording = false;
  String? _videoPath;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      print('🎥 Initializing camera for live session...');
      _cameraService = CameraService();
      final success = await _cameraService!.initialize();

      if (success) {
        print('✅ Camera initialized successfully');
      } else {
        print('❌ Camera initialization failed');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Camera initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final bleConnection = ref.watch(bleConnectionProvider);

    // Listen to ESP32 shot stream (real hardware data only)
    ref.listen(esp32ShotStreamProvider, (previous, next) {
      next.whenData((shot) {
        print(
          '📡 ESP32 Shot received: ${shot.batSpeed} km/h, Power: ${shot.powerIndex}%',
        );
        setState(() {
          _latestShot = shot;
          _shotCount++;
        });

        // Add shot to app state
        ref.read(appStateProvider.notifier).addShot(shot);
      });
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Session'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showEndSessionDialog(context, ref),
        ),
      ),
      body: Column(
        children: [
          // Enhanced Session Analytics Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              children: [
                // Main stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SessionInfoItem(
                      icon: Icons.timer,
                      label: 'Duration',
                      value: _getSessionDuration(),
                    ),
                    _SessionInfoItem(
                      icon: Icons.sports_cricket,
                      label: 'Shots',
                      value: '$_shotCount',
                    ),
                    _SessionInfoItem(
                      icon: Icons.speed,
                      label: 'Avg Speed',
                      value: _getAverageSpeed(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Additional analytics row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SessionInfoItem(
                      icon: Icons.flash_on,
                      label: 'Avg Power',
                      value: _getAveragePower(),
                    ),
                    _SessionInfoItem(
                      icon: Icons.center_focus_strong,
                      label: 'Sweet Spot',
                      value: _getAverageSweetSpot(),
                    ),
                    _SessionInfoItem(
                      icon: Icons.trending_up,
                      label: 'Timing',
                      value: _getAverageTiming(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ESP32 Connection Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bluetooth, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ESP32 Smart Bat',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          bleConnection.when(
                            data: (isConnected) =>
                                isConnected ? 'Connected' : 'Disconnected',
                            loading: () => 'Connecting...',
                            error: (_, __) => 'Error',
                          ),
                          style: TextStyle(
                            color: bleConnection.when(
                              data: (isConnected) =>
                                  isConnected ? Colors.green : Colors.red,
                              loading: () => Colors.yellow,
                              error: (_, __) => Colors.red,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DeviceScanScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bluetooth_searching),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // ESP32 Status Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey[800],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESP32 Status:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shots Received: $_shotCount',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Session Duration: ${_getSessionDuration()}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'BLE Status: ${bleConnection.when(data: (isConnected) => isConnected ? "Connected" : "Disconnected", loading: () => "Loading...", error: (_, __) => "Error")}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Main Shot Display
          Expanded(
            child: _latestShot == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 100,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Waiting for ESP32 data...',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect your ESP32 Smart Bat to start receiving shot data',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DeviceScanScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bluetooth_searching),
                          label: const Text('Connect ESP32'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Latest Shot Stats
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.green, Colors.greenAccent],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'LATEST SHOT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Bat Speed
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.speed,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_latestShot!.batSpeed.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    ' km/h',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Power and Timing Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatDisplay(
                                    icon: Icons.flash_on,
                                    label: 'Power',
                                    value: '${_latestShot!.powerIndex}',
                                    unit: '',
                                    color: _getPowerColor(
                                      _latestShot!.powerIndex,
                                    ),
                                  ),
                                  _StatDisplay(
                                    icon: Icons.schedule,
                                    label: 'Timing',
                                    value: _latestShot!.timingScoreText,
                                    unit: '',
                                    color: _getTimingColor(
                                      _latestShot!.timingScore,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Sweet Spot
                              _StatDisplay(
                                icon: Icons.center_focus_strong,
                                label: 'Sweet Spot',
                                value: _latestShot!.sweetSpotAccuracyText,
                                unit: '',
                                color: _getSweetSpotColor(
                                  _latestShot!.sweetSpotAccuracy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Camera Preview Section
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                // Camera Preview
                                SizedBox.expand(
                                  child:
                                      _cameraService?.getCameraPreview() ??
                                      Container(
                                        color: Colors.black,
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.camera_alt,
                                                size: 80,
                                                color: Colors.white54,
                                              ),
                                              SizedBox(height: 20),
                                              Text(
                                                'Camera Preview',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Live camera feed will appear here',
                                                style: TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                ),

                                // Recording indicator
                                if (_isRecording)
                                  Positioned(
                                    top: 16,
                                    left: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.fiber_manual_record,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'REC',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Shot detection overlay
                                if (_latestShot != null)
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Shot Detected!',
                                            style: TextStyle(
                                              color: Colors.green[400],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Speed: ${_latestShot!.batSpeed.toStringAsFixed(1)} km/h',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Power: ${_latestShot!.powerIndex}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Recent Shots List
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recent Shots',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: appState.sessionShots.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No shots recorded yet',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: appState.sessionShots.length,
                                        itemBuilder: (context, index) {
                                          final shot =
                                              appState.sessionShots[index];
                                          return _ShotListItem(shot: shot);
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // End Session Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Camera Toggle Button
                if (_cameraService?.isInitialized == true)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleRecording,
                      icon: Icon(
                        _isRecording ? Icons.videocam_off : Icons.videocam,
                      ),
                      label: Text(
                        _isRecording ? 'Stop Recording' : 'Start Recording',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? Colors.red
                            : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (_cameraService?.isInitialized == true)
                  const SizedBox(width: 8),

                // End Session Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEndSessionDialog(context, ref),
                    icon: const Icon(Icons.stop),
                    label: const Text('End Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSessionDuration() {
    if (_sessionStartTime == null) return '0m';
    final duration = DateTime.now().difference(_sessionStartTime!);
    return '${duration.inMinutes}m';
  }

  String _getAverageSpeed() {
    if (_shotCount == 0) return '0 km/h';
    final appState = ref.read(appStateProvider);
    if (appState.sessionShots.isEmpty) return '0 km/h';

    final totalSpeed = appState.sessionShots.fold<double>(
      0.0,
      (sum, shot) => sum + shot.batSpeed,
    );
    final average = totalSpeed / appState.sessionShots.length;
    return '${average.toStringAsFixed(1)} km/h';
  }

  String _getAveragePower() {
    if (_shotCount == 0) return '0%';
    final appState = ref.read(appStateProvider);
    if (appState.sessionShots.isEmpty) return '0%';

    final totalPower = appState.sessionShots.fold<double>(
      0.0,
      (sum, shot) => sum + shot.powerIndex,
    );
    final average = totalPower / appState.sessionShots.length;
    return '${average.toStringAsFixed(0)}%';
  }

  String _getAverageSweetSpot() {
    if (_shotCount == 0) return '0%';
    final appState = ref.read(appStateProvider);
    if (appState.sessionShots.isEmpty) return '0%';

    final totalSweetSpot = appState.sessionShots.fold<double>(
      0.0,
      (sum, shot) => sum + shot.sweetSpotAccuracy,
    );
    final average = totalSweetSpot / appState.sessionShots.length;
    return '${(average * 100).toStringAsFixed(0)}%';
  }

  String _getAverageTiming() {
    if (_shotCount == 0) return '0ms';
    final appState = ref.read(appStateProvider);
    if (appState.sessionShots.isEmpty) return '0ms';

    final totalTiming = appState.sessionShots.fold<double>(
      0.0,
      (sum, shot) => sum + shot.timingScore.abs(),
    );
    final average = totalTiming / appState.sessionShots.length;
    return '${average.toStringAsFixed(1)}ms';
  }

  Color _getPowerColor(int power) {
    if (power >= 90) return Colors.green;
    if (power >= 80) return Colors.lightGreen;
    if (power >= 70) return Colors.yellow;
    if (power >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getTimingColor(double timing) {
    if (timing.abs() <= 5) return Colors.green;
    if (timing.abs() <= 15) return Colors.yellow;
    return Colors.red;
  }

  Color _getSweetSpotColor(double accuracy) {
    if (accuracy >= 0.9) return Colors.green;
    if (accuracy >= 0.8) return Colors.lightGreen;
    if (accuracy >= 0.7) return Colors.yellow;
    return Colors.red;
  }

  Future<void> _toggleRecording() async {
    if (_cameraService == null) return;

    try {
      if (_isRecording) {
        _videoPath = await _cameraService!.stopVideoRecording();
        setState(() => _isRecording = false);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Video saved: $_videoPath')));
        }
      } else {
        final authState = ref.read(authStateProvider);
        final appState = ref.read(appStateProvider);

        _videoPath = await _cameraService!.startVideoRecording(
          sessionId: appState.currentSessionId,
          playerId: authState.value?.uid,
        );
        setState(() => _isRecording = true);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Recording started')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  void _showEndSessionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('End Session', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to end this session? You\'ve recorded $_shotCount shots.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _endSession(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession(BuildContext context, WidgetRef ref) async {
    try {
      final appState = ref.read(appStateProvider.notifier);
      await appState.endSession();

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SessionSummaryScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to end session: $e')));
      }
    }
  }
}

/// Widget for displaying session info items
class _SessionInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SessionInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

/// Widget for displaying individual stats
class _StatDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatDisplay({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          '$value$unit',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}

/// Widget for displaying shot list items
class _ShotListItem extends StatelessWidget {
  final ShotModel shot;

  const _ShotListItem({required this.shot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${shot.batSpeed.toStringAsFixed(1)} km/h',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Power: ${shot.powerIndex}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                shot.timingScoreText,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                shot.sweetSpotAccuracyText,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
