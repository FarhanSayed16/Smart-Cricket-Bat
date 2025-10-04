import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/shot_model.dart';
import 'session_summary_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final shotStream = ref.watch(shotStreamProvider);
    final appState = ref.watch(appStateProvider);

    // Listen to shot stream
    ref.listen(shotStreamProvider, (previous, next) {
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

          // Main Shot Display
          Expanded(
            child: _latestShot == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_cricket,
                          size: 100,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Waiting for shots...',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connect your smart cricket bat',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Bat Speed
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.speed,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${_latestShot!.batSpeed.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    ' km/h',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

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

                              const SizedBox(height: 24),

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
            child: ElevatedButton.icon(
              onPressed: () => _showEndSessionDialog(context, ref),
              icon: const Icon(Icons.stop),
              label: const Text(
                'End Session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$value$unit',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
