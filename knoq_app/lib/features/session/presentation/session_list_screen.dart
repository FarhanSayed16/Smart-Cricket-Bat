import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:knoq_app/features/session/data/session_repository.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/core/utils/formatters.dart';
import 'package:knoq_app/core/widgets/empty_state.dart';
import 'package:knoq_app/services/sync_service.dart';
import 'package:shimmer/shimmer.dart';

final sessionsProvider = FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getSessions(limit: 50, page: 1); // Simple fetch for now
});

class SessionListScreen extends ConsumerWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sessions'),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: EmptyState(
                title: 'No sessions yet',
                subtitle: 'Connect your bat and start practicing to see history here.',
                illustration: const Icon(Icons.history, size: 80, color: Colors.grey),
                buttonText: 'Go Home',
                onButtonPress: () => context.go('/home'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(sessionsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionCard(context, ref, theme, session);
              },
            ),
          );
        },
        loading: () => _buildShimmerList(theme),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading sessions', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(sessionsProvider),
                child: const Text('Try Again'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const SizedBox(height: 90),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, WidgetRef ref, ThemeData theme, SessionModel session) {
    // For V1, the detailed view will navigate to /sessions/:id which loads ShotHistoryScreen
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/session-history/${session.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        Formatters.formatDateTime(session.startTime),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      _buildSyncStatusIcon(context, ref, session.syncStatus),
                    ],
                  ),
                  Text(
                    '${session.totalHits} Shots',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(label: 'Avg Power', value: '${session.avgPower}'),
                  _StatItem(label: 'Peak Power', value: '${session.peakPower}'),
                  _StatItem(label: 'Sweet Spot', value: '${session.sweetSpotPct}%'),
                  if (session.avgSwing != null)
                     _StatItem(label: 'Avg Swing', value: '${session.avgSwing!.toStringAsFixed(1)}°/s'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusIcon(BuildContext context, WidgetRef ref, String status) {
    if (status == 'synced') {
      return const Icon(Icons.cloud_done, size: 16, color: Colors.green);
    } else if (status == 'pending') {
      return const Icon(Icons.cloud_upload, size: 16, color: Colors.orange);
    } else if (status == 'failed') {
      return InkWell(
        onTap: () {
          ref.read(syncServiceProvider.notifier).manualRetry();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retrying failed sync...')),
          );
        },
        child: const Row(
          children: [
            Icon(Icons.error, size: 16, color: Colors.red),
            SizedBox(width: 4),
            Text('Tap to retry', style: TextStyle(fontSize: 10, color: Colors.red)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
