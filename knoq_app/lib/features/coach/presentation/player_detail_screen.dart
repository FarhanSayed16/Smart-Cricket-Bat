import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/features/coach/providers/coach_provider.dart';
import 'package:knoq_app/features/analytics/data/analytics_repository.dart';
import 'package:knoq_app/features/analytics/domain/analytics_model.dart';
import 'package:knoq_app/features/coach/services/pdf_export_service.dart';
import 'package:knoq_app/services/analytics_service.dart';

final coachPlayerStatsProvider = FutureProvider.autoDispose.family<AnalyticsModel, String>((ref, playerId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getPlayerAnalytics(playerId, range: 'all');
});

class PlayerDetailScreen extends ConsumerWidget {
  final UserModel player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(coachPlayerStatsProvider(player.id));
    final sessionsAsync = ref.watch(playerSessionsProvider(player.id));

    // Fire analytics event
    ref.read(analyticsServiceProvider).logPlayerViewed(player.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name ?? 'Player Detail'),
        actions: [
          IconButton(
            tooltip: 'Export Player Report',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              final sessions = sessionsAsync.valueOrNull ?? [];
              PdfExportService().exportAndSharePlayerReport(player, sessions);
              ref.read(analyticsServiceProvider).logReportExported(player.id);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/coach-compare');
        },
        icon: const Icon(Icons.compare_arrows),
        label: const Text('Compare'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(theme),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: statsAsync.when(
                data: (stats) => _buildAnalyticsSummary(stats, theme),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading stats: $e'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
              child: Text(
                'RECENT SESSIONS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No sessions recorded yet.'),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = sessions[index];
                    return _buildSessionTile(context, session, theme);
                  },
                  childCount: sessions.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error loading sessions: $e')),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(
            player.name ?? 'Unknown',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Age: ${player.age ?? '--'} | Hand: ${player.battingHand ?? 'Right'}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary(AnalyticsModel stats, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Sweet %', '${stats.overallSweetPct}%', theme),
                _buildStatColumn('Avg Power', '${stats.overallAvgPower}', theme),
                _buildStatColumn('Avg Swing', '${stats.overallAvgSwing}', theme),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total Hits', '${stats.totalHits}', theme),
                _buildStatColumn('Sessions', '${stats.totalSessions}', theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildSessionTile(BuildContext context, SessionModel session, ThemeData theme) {
    final date = session.startTime.toLocal().toString().split(' ')[0];
    return ListTile(
      title: Text('Session on $date'),
      subtitle: Text('Hits: ${session.totalHits}  |  Sweet: ${session.sweetSpotPct}%'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/coach-home/session/${session.id}', extra: session);
      },
    );
  }
}
