import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/features/insights/domain/insight_model.dart';
import 'package:knoq_app/features/insights/data/insight_engine.dart';
import 'package:knoq_app/features/session/data/session_repository.dart';
import 'package:knoq_app/features/session/domain/session_stats.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';
import 'package:shimmer/shimmer.dart';
import 'package:knoq_app/services/analytics_service.dart';

final insightEngineProvider = Provider((ref) => InsightEngine());

/// Fetches insights for the most recent session automatically.
/// Falls back gracefully if the API is unreachable.
final latestInsightsProvider = FutureProvider.autoDispose<List<InsightModel>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final engine = ref.watch(insightEngineProvider);
  
  final recent = await repo.getRecentSessions(limit: 5);
  if (recent.isEmpty) return [];

  // Single-session insights from the latest session
  List<InsightModel> singleInsights = [];
  try {
    final sessionData = await repo.getSession(recent.first.id);
    final List<ShotData> shots = sessionData['shots'] as List<ShotData>;
    
    final stats = SessionStats();
    for (var shot in shots) {
      stats.addShot(shot);
    }

    singleInsights = engine.generateInsights(stats, shots);
  } catch (_) {
    // API/network error — skip single-session insights gracefully
  }

  // Cross-session trend insights (needs >= 3 sessions)
  List<InsightModel> trendInsights = [];
  if (recent.length >= 3) {
    // Oldest → newest order
    final ordered = recent.reversed.toList();
    trendInsights = engine.generateCrossSessionInsights(
      recentSweetPcts: ordered.map((s) => s.sweetSpotPct.toDouble()).toList(),
      recentAvgPowers: ordered.map((s) => s.avgPower.toDouble()).toList(),
      recentConsistencies: ordered.map((s) => s.consistencyScore ?? 0.0).toList(),
    );
  }

  // Merge: single-session first, then trends, cap at 5
  return [...singleInsights, ...trendInsights].take(5).toList();
});

class CoachingInsightsScreen extends ConsumerWidget {
  final String? sessionId;

  const CoachingInsightsScreen({super.key, this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // If we're inside a live session flow (session summary), we use live SessionProvider data
    // Usually Session Summary passes nothing, but watches liveSessionProvider locally.
    // Wait, SessionSummaryScreen renders Insights inline, it doesn't navigate to this screen. 
    // This screen is used purely for global bottom nav global view!
    
    final asyncInsights = ref.watch(latestInsightsProvider);

    // Fire analytics event
    ref.read(analyticsServiceProvider).logInsightViewed();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaching Insights'),
      ),
      body: asyncInsights.when(
        data: (insights) {
          if (insights.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assessment_outlined, size: 80, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Need more data', style: theme.textTheme.headlineSmall),
                  const Text('Play your first session to see insights!'),
                ],
              ),
            );
          }

          return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: insights.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                return InsightCard(insight: insights[i]);
              },
            );
        },
        loading: () => _buildShimmerLoading(theme),
        error: (err, stack) => Center(child: Text('Failed to load insights: $err')),
      )
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
        itemBuilder: (ctx, i) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const SizedBox(height: 140),
          );
        },
      )
    );
  }
}

class InsightCard extends StatelessWidget {
  final InsightModel insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color bgColor;
    Color iconColor;
    
    switch (insight.severity) {
      case InsightSeverity.positive:
        bgColor = Colors.green.withValues(alpha: 0.1);
        iconColor = Colors.green;
        break;
      case InsightSeverity.improvement:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        iconColor = Colors.orange;
        break;
      case InsightSeverity.priority:
        bgColor = Colors.red.withValues(alpha: 0.1);
        iconColor = Colors.red;
        break;
      case InsightSeverity.info:
        bgColor = theme.colorScheme.surfaceContainerHighest;
        iconColor = theme.colorScheme.primary;
        break;
    }

    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: iconColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(insight.icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.title, 
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                    )
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    insight.type,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(insight.detail, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.action, 
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
