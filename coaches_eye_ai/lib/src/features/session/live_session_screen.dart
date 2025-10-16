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
    _initializeBLE();
  }

  Future<void> _initializeBLE() async {
    try {
      final bleService = ref.read(bleServiceProvider);
      final appState = ref.read(appStateProvider);

      // Start BLE session if we have a current session
      if (appState.currentSessionId != null) {
        bleService.startSession(appState.currentSessionId!);
      }
    } catch (e) {
      print('Error initializing BLE: $e');
    }
  }

  Future<void> _initializeCamera() async {
    _cameraService = CameraService();
    await _cameraService!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cameraService?.dispose();
    // Stop BLE session
    try {
      final bleService = ref.read(bleServiceProvider);
      bleService.stopSession();
    } catch (e) {
      print('Error stopping BLE session: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final bleConnection = ref.watch(bleConnectionProvider);

    // Listen to BLE shot stream instead of simulator
    ref.listen(bleShotStreamProvider, (previous, next) {
      next.whenData((shot) {
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
          // Session Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
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
          ),

          // BLE Connection Status Overlay
          if (!bleConnection.when(
            data: (isConnected) => isConnected,
            loading: () => false,
            error: (_, __) => false,
          ))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade900,
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_disabled, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Smart Bat not connected. Connect to start receiving shot data.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DeviceScanScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade900,
                    ),
                    child: const Text('Connect'),
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
                          bleConnection.when(
                            data: (isConnected) => isConnected
                                ? Icons.sports_cricket
                                : Icons.bluetooth_disabled,
                            loading: () => Icons.bluetooth_searching,
                            error: (_, __) => Icons.error,
                          ),
                          size: 100,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          bleConnection.when(
                            data: (isConnected) => isConnected
                                ? 'Waiting for shots...'
                                : 'Smart Bat not connected',
                            loading: () => 'Connecting...',
                            error: (_, __) => 'Connection error',
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bleConnection.when(
                            data: (isConnected) => isConnected
                                ? 'Take a shot with your smart bat'
                                : 'Connect your smart cricket bat',
                            loading: () => 'Establishing connection...',
                            error: (_, __) => 'Please check connection',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
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
    if (_shotCount == 0) return '0.0';
    // This would be calculated from all shots, but for simplicity showing latest
    return _latestShot?.batSpeed.toStringAsFixed(1) ?? '0.0';
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
