import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/providers.dart';
import '../../models/shot_model.dart';
import '../dashboard/dashboard_screen.dart';

/// Session summary screen showing detailed statistics
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final currentUserProfile = ref.watch(currentUserProfileProvider);
    final sessionStats = ref.watch(
      sessionStatsProvider(appState.currentSessionId ?? ''),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Session Summary'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: appState.sessionShots.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_cricket, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No shots recorded',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start a session to see your performance',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  sessionStats.when(
                    data: (stats) => _SummaryCards(stats: stats),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Error: $error'),
                  ),
                  const SizedBox(height: 24),

                  // Performance Chart
                  _PerformanceChart(shots: appState.sessionShots),
                  const SizedBox(height: 24),

                  // Heatmap
                  _BatFaceHeatmap(shots: appState.sessionShots),
                  const SizedBox(height: 24),

                  // Performance Insights
                  sessionStats.when(
                    data: (stats) => _PerformanceInsights(stats: stats),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Error: $error'),
                  ),
                  const SizedBox(height: 24),

                  // Shot History
                  _ShotHistory(shots: appState.sessionShots),
                ],
              ),
            ),
    );
  }
}

/// Widget for displaying performance chart
class _PerformanceChart extends StatelessWidget {
  final List<ShotModel> shots;

  const _PerformanceChart({required this.shots});

  @override
  Widget build(BuildContext context) {
    if (shots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No data available for chart',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bat Speed Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    shots
                        .map((s) => s.batSpeed)
                        .reduce((a, b) => a > b ? a : b) +
                    10,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'Shot ${groupIndex + 1}\n${rod.toY.toStringAsFixed(1)} km/h',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < shots.length) {
                          return Text(
                            '${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: shots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final shot = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: shot.batSpeed,
                        color: _getSpeedColor(shot.batSpeed),
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpeedColor(double speed) {
    if (speed >= 120) return Colors.green;
    if (speed >= 100) return Colors.lightGreen;
    if (speed >= 80) return Colors.yellow;
    if (speed >= 70) return Colors.orange;
    return Colors.red;
  }
}

/// Widget for displaying bat face heatmap
class _BatFaceHeatmap extends StatelessWidget {
  final List<ShotModel> shots;

  const _BatFaceHeatmap({required this.shots});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hit Location Heatmap',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bat face contact zones (simulated)',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  return _HeatmapCell(index: index, shots: shots);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_HeatmapLegend()],
          ),
        ],
      ),
    );
  }
}

/// Widget for individual heatmap cell
class _HeatmapCell extends StatelessWidget {
  final int index;
  final List<ShotModel> shots;

  const _HeatmapCell({required this.index, required this.shots});

  @override
  Widget build(BuildContext context) {
    // Simulate hit distribution based on sweet spot accuracy
    final hitCount = _getHitCountForZone(index);
    final intensity = hitCount / shots.length;

    return Container(
      decoration: BoxDecoration(
        color: _getHeatmapColor(intensity),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Center(
        child: Text(
          hitCount > 0 ? '$hitCount' : '',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: intensity > 0.5 ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  int _getHitCountForZone(int zoneIndex) {
    // Simulate hit distribution - zones 5, 6, 9, 10 are sweet spot areas
    final sweetSpotZones = [5, 6, 9, 10];
    final isSweetSpot = sweetSpotZones.contains(zoneIndex);

    int count = 0;
    for (final shot in shots) {
      if (isSweetSpot) {
        // Higher chance of hits in sweet spot zones
        if (shot.sweetSpotAccuracy > 0.8) {
          count++;
        }
      } else {
        // Lower chance of hits in other zones
        if (shot.sweetSpotAccuracy < 0.7) {
          count++;
        }
      }
    }

    return count;
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity == 0) return Colors.grey[100]!;
    if (intensity < 0.2) return Colors.blue[100]!;
    if (intensity < 0.4) return Colors.blue[300]!;
    if (intensity < 0.6) return Colors.blue[500]!;
    if (intensity < 0.8) return Colors.red[400]!;
    return Colors.red[600]!;
  }
}

/// Widget for heatmap legend
class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Low', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Container(width: 20, height: 12, color: Colors.grey[100]),
        const SizedBox(width: 4),
        Container(width: 20, height: 12, color: Colors.blue[100]),
        const SizedBox(width: 4),
        Container(width: 20, height: 12, color: Colors.blue[300]),
        const SizedBox(width: 4),
        Container(width: 20, height: 12, color: Colors.blue[500]),
        const SizedBox(width: 4),
        Container(width: 20, height: 12, color: Colors.red[400]),
        const SizedBox(width: 4),
        Container(width: 20, height: 12, color: Colors.red[600]),
        const SizedBox(width: 8),
        const Text('High', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Widget for displaying summary statistics cards
class _SummaryCards extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _SummaryCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'Total Shots',
              value: '${stats['totalShots']}',
              icon: Icons.sports_cricket,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Duration',
              value: '${stats['duration']}m',
              icon: Icons.timer,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Avg Speed',
              value: '${stats['averageBatSpeed'].toStringAsFixed(1)} km/h',
              icon: Icons.speed,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Max Speed',
              value: '${stats['maxBatSpeed'].toStringAsFixed(1)} km/h',
              icon: Icons.flash_on,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget for displaying individual stat cards
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying performance insights
class _PerformanceInsights extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _PerformanceInsights({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _InsightItem(
            icon: Icons.power,
            title: 'Power Performance',
            value: '${stats['averagePower'].toStringAsFixed(1)}',
            subtitle: 'Average power index',
            color: _getPowerColor(stats['averagePower']),
          ),
          const SizedBox(height: 16),

          _InsightItem(
            icon: Icons.schedule,
            title: 'Timing Accuracy',
            value: '${stats['perfectTimingCount']}/${stats['totalShots']}',
            subtitle: 'Perfect timing shots',
            color: _getTimingColor(
              stats['perfectTimingCount'],
              stats['totalShots'],
            ),
          ),
          const SizedBox(height: 16),

          _InsightItem(
            icon: Icons.center_focus_strong,
            title: 'Sweet Spot Hits',
            value: '${stats['perfectSweetSpotCount']}/${stats['totalShots']}',
            subtitle: 'Perfect sweet spot shots',
            color: _getSweetSpotColor(
              stats['perfectSweetSpotCount'],
              stats['totalShots'],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPowerColor(double averagePower) {
    if (averagePower >= 85) return Colors.green;
    if (averagePower >= 75) return Colors.lightGreen;
    if (averagePower >= 65) return Colors.yellow;
    return Colors.red;
  }

  Color _getTimingColor(int perfectCount, int totalCount) {
    final percentage = totalCount > 0 ? perfectCount / totalCount : 0;
    if (percentage >= 0.7) return Colors.green;
    if (percentage >= 0.5) return Colors.lightGreen;
    if (percentage >= 0.3) return Colors.yellow;
    return Colors.red;
  }

  Color _getSweetSpotColor(int perfectCount, int totalCount) {
    final percentage = totalCount > 0 ? perfectCount / totalCount : 0;
    if (percentage >= 0.6) return Colors.green;
    if (percentage >= 0.4) return Colors.lightGreen;
    if (percentage >= 0.2) return Colors.yellow;
    return Colors.red;
  }
}

/// Widget for displaying individual insight items
class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying shot history
class _ShotHistory extends StatelessWidget {
  final List<ShotModel> shots;

  const _ShotHistory({required this.shots});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shot History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: shots.length,
              itemBuilder: (context, index) {
                final shot = shots[index];
                return _ShotListItem(shot: shot, index: index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying individual shot list items
class _ShotListItem extends ConsumerWidget {
  final ShotModel shot;
  final int index;

  const _ShotListItem({required this.shot, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserProfile = ref.watch(currentUserProfileProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Shot Number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Shot Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${shot.batSpeed.toStringAsFixed(1)} km/h',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Power: ${shot.powerIndex}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Timing: ${shot.timingScoreText}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Sweet Spot: ${shot.sweetSpotAccuracyText}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Coach Note Button (only for coaches)
              currentUserProfile.when(
                data: (userModel) {
                  if (userModel?.role == 'coach') {
                    return IconButton(
                      icon: Icon(
                        shot.coachNotes != null ? Icons.note : Icons.note_add,
                        color: shot.coachNotes != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: () => _showCoachNoteDialog(context, ref, shot),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),

          // Coach Note Display (for players)
          if (shot.coachNotes != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shot.coachNotes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        fontStyle: FontStyle.italic,
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

  void _showCoachNoteDialog(
    BuildContext context,
    WidgetRef ref,
    ShotModel shot,
  ) {
    final noteController = TextEditingController(text: shot.coachNotes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coach Note - Shot ${index}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${shot.batSpeed.toStringAsFixed(1)} km/h • Power: ${shot.powerIndex} • ${shot.timingScoreText}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Coach Note',
                hintText: 'Add feedback for this shot...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final firestoreService = ref.read(firestoreServiceProvider);
                await firestoreService.addCoachNoteToShot(
                  shotId: shot.shotId,
                  note: noteController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coach note saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save note: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
