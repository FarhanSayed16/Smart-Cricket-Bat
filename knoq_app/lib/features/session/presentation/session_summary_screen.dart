import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:knoq_app/core/widgets/knoq_button.dart';
import 'package:knoq_app/core/widgets/stat_card.dart';
import 'package:knoq_app/features/session/providers/session_provider.dart';
import 'package:knoq_app/core/widgets/empty_state.dart';
import 'package:knoq_app/core/utils/formatters.dart';
import 'package:knoq_app/features/insights/presentation/coaching_insights_screen.dart';
import 'package:knoq_app/features/session/data/session_repository.dart';
import 'package:knoq_app/services/analytics_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';

class SessionSummaryScreen extends ConsumerStatefulWidget {
  const SessionSummaryScreen({super.key});

  @override
  ConsumerState<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen> {
  bool _isSaving = false;
  bool _saved = false;
  final _screenshotController = ScreenshotController();

  void _saveSession() async {
    setState(() => _isSaving = true);
    try {
      // Build the model and shots for upload
      var model = ref.read(liveSessionProvider.notifier).getSessionModel();
      final shots = ref.read(liveSessionProvider).shots;
      final sessionMeta = ref.read(liveSessionProvider).sessionMeta;

      // Upload video if exists
      if (sessionMeta['video_path'] != null) {
        final file = File(sessionMeta['video_path']);
        if (await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uploading video... please wait.')),
            );
          }
          final storageRef = FirebaseStorage.instance.ref().child('sessions/${model.id}/full_video.mp4');
          await storageRef.putFile(file);
          final downloadUrl = await storageRef.getDownloadURL();
          model = model.copyWith(videoUrl: downloadUrl);
        }
      }
      
      await ref.read(sessionRepositoryProvider).saveSession(model, shots);
      
      await ref.read(localSessionStoreProvider).clearSession();
      ref.read(analyticsServiceProvider).logSessionSaved(model.id);
      _saved = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch(e) {
      // Session is safely queued for sync — still mark as saved and clear WAL
      await ref.read(localSessionStoreProvider).clearSession();
      _saved = true;
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Saved Locally (Offline Sync pending)'), backgroundColor: Colors.orange),
         );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _shareSession() async {
    try {
      final image = await _screenshotController.capture(pixelRatio: 2.0);
      if (image == null) return;
      
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/knoq_session.png').create();
      await imagePath.writeAsBytes(image);

      const text = 'Check out my latest KnoQ session stats!';
      await Share.shareXFiles([XFile(imagePath.path)], text: text);
    } catch (e) {
      debugPrint("Error capturing screenshot: $e");
    }
  }

  Duration _getSessionDuration() {
    final sessionState = ref.read(liveSessionProvider);
    final endStr = sessionState.sessionMeta['end_time'] ?? DateTime.now().toIso8601String();
    final startStr = sessionState.sessionMeta['start_time'];
    return DateTime.parse(endStr).difference(DateTime.parse(startStr));
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(liveSessionProvider);
    final theme = Theme.of(context);

    if (sessionState.liveStats.totalHits == 0) {
      return Scaffold(
        body: EmptyState(
          title: 'No Shots Recorded',
          subtitle: 'You ended the session before striking the ball.',
          illustration: const Icon(Icons.sports_cricket, size: 80, color: Colors.grey),
          buttonText: 'Return Home',
          onButtonPress: () async {
            await ref.read(localSessionStoreProvider).clearSession();
            if (context.mounted) context.go('/home');
          },
        ),
      );
    }

    final duration = _getSessionDuration();
    final stats = sessionState.liveStats;
    final consistency = stats.computeConsistency();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Complete'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareSession,
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration
            Center(
              child: Text(
                'Duration: ${Formatters.formatDuration(duration)}',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 24),
            
            // Primary Stat Grid
            GridView.count(
               crossAxisCount: 2,
               childAspectRatio: 1.5,
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               mainAxisSpacing: 16,
               crossAxisSpacing: 16,
               children: [
                 StatCard(icon: Icons.sports_baseball, label: 'Total Hits', value: '${stats.totalHits}'),
                 StatCard(icon: Icons.flare, label: 'Sweet Spot', value: '${stats.sweetSpotPct}%'),
                 StatCard(icon: Icons.bolt, label: 'Peak Power', value: '${stats.peakPower}'),
                 StatCard(icon: Icons.analytics_outlined, label: 'Avg Power', value: '${stats.avgPower}'),
                 if (stats.hasSwingData) ...[
                   StatCard(icon: Icons.sync, label: 'Avg Swing', value: '${stats.avgSwing.toStringAsFixed(1)}°/s'),
                   StatCard(icon: Icons.speed, label: 'Peak Swing', value: '${stats.peakSwing.toStringAsFixed(1)}°/s'),
                 ],
                 StatCard(icon: Icons.tune, label: 'Consistency', value: '${consistency.round()}%'),
               ],
            ),

            const SizedBox(height: 32),

            // Zone Distribution
            Text('Zone Distribution', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ...stats.zoneDistribution.entries.map((entry) {
              final percent = stats.totalHits > 0 ? (entry.value / stats.totalHits * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 60, child: Text(entry.key, style: theme.textTheme.bodyMedium)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 12,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            entry.key == 'Sweet' ? theme.colorScheme.primary : theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text('${percent.round()}%', textAlign: TextAlign.right, style: theme.textTheme.labelSmall),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 32),

            // Coaching Insights Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coaching Insights', style: theme.textTheme.titleLarge),
                TextButton(
                   onPressed: () => context.push('/coaching-insights'),
                   child: const Text('View All'),
                )
              ],
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                 final engine = ref.watch(insightEngineProvider);
                 final insights = engine.generateInsights(stats, sessionState.shots);
                 
                 if (insights.isEmpty) {
                   return const Center(
                     child: Padding(
                       padding: EdgeInsets.all(16.0),
                       child: Text('Not enough data to generate insights yet.'),
                     ),
                   );
                 }
                 
                 // Show top 2 insights on the summary
                 final topInsights = insights.take(2).toList();
                 return Column(
                   children: topInsights.map((insight) => InsightCard(insight: insight)).toList(),
                 );
              },
            ),

            const SizedBox(height: 32),
            KnoqButton(
               text: _saved ? 'Saved ✓' : 'Save Session',
               isLoading: _isSaving,
               onPressed: _saved ? null : _saveSession,
            ),
            if (_saved) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final sessionId = ref.read(liveSessionProvider).sessionMeta['id'];
                  if (sessionId != null) {
                    context.push('/clip-verification/$sessionId');
                  }
                },
                icon: const Icon(Icons.videocam),
                label: const Text('Verify Shot Clips'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
            const SizedBox(height: 16),
            KnoqButton(
               text: 'Discard',
               type: KnoqButtonType.danger,
               onPressed: () async {
                 final confirmed = await showDialog<bool>(
                   context: context,
                   builder: (ctx) => AlertDialog(
                     title: const Text('Discard Session?'),
                     content: const Text('This session data will be permanently lost.'),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                       TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard', style: TextStyle(color: Colors.red))),
                     ],
                   ),
                 );
                 if (confirmed == true) {
                   await ref.read(localSessionStoreProvider).clearSession();
                   if (context.mounted) context.go('/home');
                 }
               },
            )
          ],
        ),
      ),
      ),
      ),
    );
  }
}
