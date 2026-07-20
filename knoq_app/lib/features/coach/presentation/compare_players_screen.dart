import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/features/coach/providers/coach_provider.dart';
import 'package:knoq_app/features/coach/presentation/player_detail_screen.dart'; // For coachPlayerStatsProvider
import 'package:knoq_app/services/analytics_service.dart';

class ComparePlayersScreen extends ConsumerStatefulWidget {
  const ComparePlayersScreen({super.key});

  @override
  ConsumerState<ComparePlayersScreen> createState() => _ComparePlayersScreenState();
}

class _ComparePlayersScreenState extends ConsumerState<ComparePlayersScreen> {
  UserModel? _player1;
  UserModel? _player2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(assignedPlayersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Players')),
      body: playersAsync.when(
        data: (players) {
          if (players.length < 2) {
            return const Center(child: Text('Not enough players to compare.'));
          }

          // Default selection if not set
          _player1 ??= players.first;
          _player2 ??= players[1];

          return Column(
            children: [
              _buildSelectionHeader(players, theme),
              Expanded(
                child: _buildComparisonBody(theme),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading players: $e')),
      ),
    );
  }

  Widget _buildSelectionHeader(List<UserModel> players, ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              value: _player1,
              players: players,
              onChanged: (val) {
                if (val != null) setState(() => _player1 = val);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _buildDropdown(
              value: _player2,
              players: players,
              onChanged: (val) {
                if (val != null) setState(() => _player2 = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required UserModel? value,
    required List<UserModel> players,
    required ValueChanged<UserModel?> onChanged,
  }) {
    return DropdownButton<UserModel>(
      isExpanded: true,
      value: value,
      items: players.map((p) => DropdownMenuItem(value: p, child: Text(p.name ?? 'Unknown', overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildComparisonBody(ThemeData theme) {
    if (_player1 == null || _player1?.id == null) return const SizedBox.shrink();
    if (_player2 == null || _player2?.id == null) return const SizedBox.shrink();

    final p1StatsAsync = ref.watch(coachPlayerStatsProvider(_player1!.id));
    final p2StatsAsync = ref.watch(coachPlayerStatsProvider(_player2!.id));

    return p1StatsAsync.when(
      data: (p1Stats) => p2StatsAsync.when(
        data: (p2Stats) {
          // Fire analytics event when comparison is rendered
          ref.read(analyticsServiceProvider).logPlayersCompared();
          return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildComparisonRow('Sweet %', p1Stats.overallSweetPct.toDouble(), p2Stats.overallSweetPct.toDouble(), (val) => '${val.toInt()}%', theme),
              _buildComparisonRow('Avg Power', p1Stats.overallAvgPower.toDouble(), p2Stats.overallAvgPower.toDouble(), (val) => val.toInt().toString(), theme),
              _buildComparisonRow('Avg Swing', p1Stats.overallAvgSwing ?? 0.0, p2Stats.overallAvgSwing ?? 0.0, (val) => val.toStringAsFixed(1), theme),
              _buildComparisonRow('Total Hits', p1Stats.totalHits.toDouble(), p2Stats.totalHits.toDouble(), (val) => val.toInt().toString(), theme),
              _buildComparisonRow('Total Sessions', p1Stats.totalSessions.toDouble(), p2Stats.totalSessions.toDouble(), (val) => val.toInt().toString(), theme),
            ],
          ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading P2: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading P1: $e')),
    );
  }

  Widget _buildComparisonRow(
    String label, 
    double val1, 
    double val2, 
    String Function(double) formatter, 
    ThemeData theme
  ) {
    // Determine advantage
    final p1Wins = val1 > val2;
    final p2Wins = val2 > val1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p1Wins ? Colors.green.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: p1Wins ? Border.all(color: Colors.green) : null,
                  ),
                  child: Center(
                    child: Text(
                      formatter(val1), 
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: p1Wins ? FontWeight.bold : FontWeight.normal,
                      )
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p2Wins ? Colors.green.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: p2Wins ? Border.all(color: Colors.green) : null,
                  ),
                  child: Center(
                    child: Text(
                      formatter(val2), 
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: p2Wins ? FontWeight.bold : FontWeight.normal,
                      )
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
