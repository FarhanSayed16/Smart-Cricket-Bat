import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/camera_service.dart';
import '../../models/session_model.dart';
import '../../models/shot_model.dart';

/// Screen to view saved recordings, images, and session data
class MediaGalleryScreen extends ConsumerStatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  ConsumerState<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends ConsumerState<MediaGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CameraService _cameraService = CameraService();
  List<String> _savedVideos = [];
  List<SessionModel> _savedSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load saved videos
      _savedVideos = await _cameraService.getSavedVideos();
      
      // Load saved sessions from Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      final authState = ref.read(authStateProvider);
      
      if (authState.hasValue && authState.value != null) {
        _savedSessions = await firestoreService.getSessionsForPlayer(authState.value!.uid);
      } else {
        _savedSessions = [];
      }
    } catch (e) {
      print('Error loading data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Media Gallery'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.videocam), text: 'Videos'),
            Tab(icon: Icon(Icons.analytics), text: 'Sessions'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
            Tab(icon: Icon(Icons.storage), text: 'Storage'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVideosTab(),
                _buildSessionsTab(),
                _buildReportsTab(),
                _buildStorageTab(),
              ],
            ),
    );
  }

  Widget _buildVideosTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recorded Videos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _savedVideos.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No videos recorded yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start recording during a session',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 16 / 9,
                    ),
                    itemCount: _savedVideos.length,
                    itemBuilder: (context, index) {
                      final videoPath = _savedVideos[index];
                      return _VideoCard(
                        videoPath: videoPath,
                        onDelete: () => _deleteVideo(videoPath),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Training Sessions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _savedSessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_cricket,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No sessions recorded yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a new training session',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _savedSessions.length,
                    itemBuilder: (context, index) {
                      final session = _savedSessions[index];
                      return _SessionCard(session: session);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    final appState = ref.watch(appStateProvider);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Reports',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatsCard('Total Sessions', '${_savedSessions.length}'),
                  _buildStatsCard('Total Shots', '${appState.sessionShots.length}'),
                  _buildStatsCard('Average Bat Speed', '${_calculateAverageBatSpeed(appState.sessionShots).toStringAsFixed(1)} km/h'),
                  _buildStatsCard('Best Shot Speed', '${_getBestShotSpeed(appState.sessionShots).toStringAsFixed(1)} km/h'),
                  _buildStatsCard('Total Training Time', '${_calculateTotalTime(_savedSessions)}'),
                  _buildStatsCard('Improvement Rate', '${_calculateImprovementRate(appState.sessionShots).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                _buildStorageInfoCard(
                  'Videos',
                  '${_savedVideos.length} files',
                  Icons.videocam,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildStorageInfoCard(
                  'Sessions',
                  '${_savedSessions.length} sessions',
                  Icons.sports_cricket,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildStorageInfoCard(
                  'Data',
                  'All data synced to cloud',
                  Icons.cloud_done,
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildStorageInfoCard(
                  'Backup',
                  'Automatic backup enabled',
                  Icons.backup,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfoCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideo(String videoPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Video', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this video?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _cameraService.deleteVideo(videoPath);
      if (success) {
        setState(() {
          _savedVideos.remove(videoPath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted successfully')),
        );
      }
    }
  }

  double _calculateAverageBatSpeed(List<ShotModel> shots) {
    if (shots.isEmpty) return 0.0;
    return shots.map((s) => s.batSpeed).reduce((a, b) => a + b) / shots.length;
  }

  double _getBestShotSpeed(List<ShotModel> shots) {
    if (shots.isEmpty) return 0.0;
    return shots.map((s) => s.batSpeed).reduce((a, b) => a > b ? a : b);
  }

  String _calculateTotalTime(List<SessionModel> sessions) {
    if (sessions.isEmpty) return '0 min';
    final totalMinutes = sessions.fold<int>(0, (sum, session) {
      return sum + session.durationInMinutes;
    });
    return '${totalMinutes} min';
  }

  double _calculateImprovementRate(List<ShotModel> shots) {
    if (shots.length < 2) return 0.0;
    final firstHalf = shots.take(shots.length ~/ 2).map((s) => s.batSpeed).reduce((a, b) => a + b) / (shots.length ~/ 2);
    final secondHalf = shots.skip(shots.length ~/ 2).map((s) => s.batSpeed).reduce((a, b) => a + b) / (shots.length - shots.length ~/ 2);
    return ((secondHalf - firstHalf) / firstHalf) * 100;
  }
}

/// Widget for displaying video cards
class _VideoCard extends StatelessWidget {
  final String videoPath;
  final VoidCallback onDelete;

  const _VideoCard({
    required this.videoPath,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Video Preview',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    videoPath.split('/').last,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying session cards
class _SessionCard extends StatelessWidget {
  final SessionModel session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session ${session.sessionId.substring(0, 8)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${session.durationInMinutes} min',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${session.totalShots} shots recorded',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Date: ${session.date.toString().substring(0, 16)}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
