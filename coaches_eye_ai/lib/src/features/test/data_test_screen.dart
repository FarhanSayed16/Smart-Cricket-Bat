import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/firestore_service.dart';
import '../../models/session_model.dart';
import '../../models/shot_model.dart';
import 'package:uuid/uuid.dart';

/// Screen to test data storage and create sample data
class DataTestScreen extends ConsumerStatefulWidget {
  const DataTestScreen({super.key});

  @override
  ConsumerState<DataTestScreen> createState() => _DataTestScreenState();
}

class _DataTestScreenState extends ConsumerState<DataTestScreen> {
  bool _isLoading = false;
  String _status = 'Ready to test data storage';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Data Storage Test'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Data Storage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _createSampleSession,
                      icon: const Icon(Icons.sports_cricket),
                      label: const Text('Create Sample Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _createSampleShots,
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Create Sample Shots'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _createSampleVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Create Sample Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _testDataRetrieval,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Test Data Retrieval'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSampleSession() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating sample session...';
    });

    try {
      final authState = ref.read(authStateProvider);
      if (authState.hasValue && authState.value != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final sessionId = await firestoreService.startNewSession(
          authState.value!.uid,
        );

        setState(() {
          _status = 'Sample session created: $sessionId';
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Session created: $sessionId')));
      } else {
        setState(() {
          _status = 'Error: User not authenticated';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error creating session: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createSampleShots() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating sample shots...';
    });

    try {
      final authState = ref.read(authStateProvider);
      if (authState.hasValue && authState.value != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final uuid = const Uuid();

        // Create a sample session first
        final sessionId = await firestoreService.startNewSession(
          authState.value!.uid,
        );

        // Create sample shots
        for (int i = 0; i < 5; i++) {
          final shot = ShotModel(
            shotId: uuid.v4(),
            sessionId: sessionId,
            timestamp: DateTime.now().subtract(Duration(minutes: i)),
            batSpeed: 20.0 + (i * 2.0),
            powerIndex: 70 + (i * 5),
            timingScore: 0.8 + (i * 0.05),
            sweetSpotAccuracy: 0.75 + (i * 0.05),
          );

          await firestoreService.addShotToSession(shot);
        }

        // End the session
        final shots = await firestoreService.getShotsForSession(sessionId);
        await firestoreService.endSession(sessionId, shots);

        setState(() {
          _status = 'Sample shots created for session: $sessionId';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample shots created successfully')),
        );
      } else {
        setState(() {
          _status = 'Error: User not authenticated';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error creating shots: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createSampleVideo() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating sample video metadata...';
    });

    try {
      final authState = ref.read(authStateProvider);
      if (authState.hasValue && authState.value != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final uuid = const Uuid();

        // Create a sample session first
        final sessionId = await firestoreService.startNewSession(
          authState.value!.uid,
        );

        // Create sample video metadata
        await firestoreService.saveVideoMetadata(
          videoId: uuid.v4(),
          sessionId: sessionId,
          playerId: authState.value!.uid,
          videoPath:
              '/sample/path/video_${DateTime.now().millisecondsSinceEpoch}.mp4',
          recordedAt: DateTime.now(),
          durationInSeconds: 120,
        );

        setState(() {
          _status = 'Sample video metadata created for session: $sessionId';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample video metadata created')),
        );
      } else {
        setState(() {
          _status = 'Error: User not authenticated';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error creating video: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testDataRetrieval() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing data retrieval...';
    });

    try {
      final authState = ref.read(authStateProvider);
      if (authState.hasValue && authState.value != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final userId = authState.value!.uid;

        // Test retrieving all data
        final results = await Future.wait([
          firestoreService.getSessionsForPlayer(userId),
          firestoreService.getVideosForPlayer(userId),
          firestoreService.getUserAnalytics(userId),
        ]);

        final sessions = results[0] as List<SessionModel>;
        final videos = results[1] as List<Map<String, dynamic>>;
        final analytics = results[2] as Map<String, dynamic>;

        setState(() {
          _status =
              'Data retrieval successful!\n'
              'Sessions: ${sessions.length}\n'
              'Videos: ${videos.length}\n'
              'Total Shots: ${analytics['totalShots'] ?? 0}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Retrieved ${sessions.length} sessions, ${videos.length} videos, ${analytics['totalShots'] ?? 0} shots',
            ),
          ),
        );
      } else {
        setState(() {
          _status = 'Error: User not authenticated';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error retrieving data: $e';
      });
    }

    setState(() => _isLoading = false);
  }
}

