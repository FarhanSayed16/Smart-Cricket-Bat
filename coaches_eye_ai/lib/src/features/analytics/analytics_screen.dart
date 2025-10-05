import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/firestore_service.dart';
import '../../models/session_model.dart';

/// Comprehensive analytics screen showing all user data
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  Map<String, dynamic>? _analyticsData;
  List<SessionModel> _sessions = [];
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authStateProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      if (authState.hasValue && authState.value != null) {
        final userId = authState.value!.uid;

        // Load all data in parallel
        final results = await Future.wait([
          firestoreService.getUserAnalytics(userId),
          firestoreService.getSessionsForPlayer(userId),
          firestoreService.getVideosForPlayer(userId),
        ]);

        _analyticsData = results[0] as Map<String, dynamic>;
        _sessions = results[1] as List<SessionModel>;
        _videos = results[2] as List<Map<String, dynamic>>;
      }
    } catch (e) {
      print('Error loading analytics data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAnalyticsData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCard(),
                  const SizedBox(height: 20),
                  _buildSessionsCard(),
                  const SizedBox(height: 20),
                  _buildVideosCard(),
                  const SizedBox(height: 20),
                  _buildPerformanceCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    final data = _analyticsData ?? {};

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Training Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Sessions',
                    '${data['totalSessions'] ?? 0}',
                    Icons.sports_cricket,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Shots',
                    '${data['totalShots'] ?? 0}',
                    Icons.flash_on,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Training Time',
                    '${data['totalTrainingTime'] ?? 0} min',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Improvement',
                    '${(data['improvementRate'] ?? 0).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Sessions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_sessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.sports_cricket, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No sessions recorded yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._sessions.take(5).map((session) => _buildSessionItem(session)),
            if (_sessions.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    'And ${_sessions.length - 5} more sessions...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(SessionModel session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_cricket, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session ${session.sessionId.substring(0, 8)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.totalShots} shots • ${session.durationInMinutes} min',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Avg Speed: ${session.averageBatSpeed.toStringAsFixed(1)} km/h',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${session.date.day}/${session.date.month}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recorded Videos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_videos.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No videos recorded yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._videos.take(5).map((video) => _buildVideoItem(video)),
            if (_videos.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    'And ${_videos.length - 5} more videos...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    final recordedAt = DateTime.fromMillisecondsSinceEpoch(
      video['recordedAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle_outline, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['videoPath']?.split('/').last ?? 'Unknown Video',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${video['durationInSeconds'] ?? 0} seconds',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Session: ${video['sessionId']?.substring(0, 8) ?? 'Unknown'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${recordedAt.day}/${recordedAt.month}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final data = _analyticsData ?? {};

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMetricRow(
              'Average Bat Speed',
              '${(data['averageBatSpeed'] ?? 0).toStringAsFixed(1)} km/h',
              Colors.green,
            ),
            _buildMetricRow(
              'Best Shot Speed',
              '${(data['bestShotSpeed'] ?? 0).toStringAsFixed(1)} km/h',
              Colors.blue,
            ),
            _buildMetricRow(
              'Average Power Index',
              '${(data['averagePowerIndex'] ?? 0).toStringAsFixed(1)}',
              Colors.orange,
            ),
            _buildMetricRow(
              'Average Timing Score',
              '${(data['averageTimingScore'] ?? 0).toStringAsFixed(1)}',
              Colors.purple,
            ),
            _buildMetricRow(
              'Sweet Spot Accuracy',
              '${(data['averageSweetSpotAccuracy'] ?? 0).toStringAsFixed(1)}%',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
