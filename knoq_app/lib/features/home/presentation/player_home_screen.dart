import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:knoq_app/features/analytics/data/analytics_repository.dart';
import 'package:knoq_app/features/analytics/domain/analytics_model.dart';
import 'package:knoq_app/core/utils/formatters.dart';
import 'package:knoq_app/features/ble/providers/ble_provider.dart';
import 'package:knoq_app/features/ble/domain/ble_state.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/features/session/data/session_repository.dart';
import 'package:knoq_app/features/session/providers/session_provider.dart';
import 'package:knoq_app/core/widgets/sync_indicator.dart';
import 'package:knoq_app/features/coach/providers/coach_provider.dart';

/// Provider: fetches only 3 recent sessions for home screen
final recentSessionsProvider = FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getRecentSessions(limit: 3);
});

/// Provider: fetches lifetime ("all") stats for the home quick-stats cards
final lifetimeStatsProvider = FutureProvider.autoDispose<AnalyticsModel>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAnalytics(range: 'all');
});

class PlayerHomeScreen extends ConsumerStatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  ConsumerState<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends ConsumerState<PlayerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-connect BLE in background when Home mounts
    Future.microtask(() {
      ref.read(bleProvider.notifier).attemptAutoConnect();
    });
    // Check for crashed/unsaved session recovery (Phase 8.4)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionRecovery();
    });
  }

  Future<void> _checkSessionRecovery() async {
    final box = Hive.box('active_session');
    final isActive = box.get('is_active', defaultValue: false) as bool;
    if (!isActive) return;

    // Count shots in WAL
    final shotsRaw = box.get('shots', defaultValue: <String>[]) as List;
    final shotCount = shotsRaw.length;
    if (shotCount == 0) {
      // No actual shots — just clear the stale flag
      await box.clear();
      return;
    }

    if (!mounted) return;

    final shouldRecover = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Session Found'),
        content: Text('You have an unsaved session with $shotCount shots. Would you like to recover it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Recover'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldRecover == true) {
      // Hydrate LiveSessionState from the Hive WAL before navigating
      final recovered = await ref.read(liveSessionProvider.notifier).recoverFromCrash();
      if (!mounted) return;
      if (recovered) {
        // End the session (set end_time) so summary can display it
        await ref.read(liveSessionProvider.notifier).endSession();
        if (!mounted) return;
        context.push('/session-summary');
      } else {
        // Recovery failed (corrupted data) — discard
        await box.clear();
      }
    } else {
      // Discard the stale WAL data
      await box.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final bleState = ref.watch(bleProvider);
    final recentSessionsAsync = ref.watch(recentSessionsProvider);
    final lifetimeStatsAsync = ref.watch(lifetimeStatsProvider);
    final drillsAsync = user?.id != null ? ref.watch(playerDrillsProvider(user!.id)) : const AsyncValue<List<dynamic>>.loading();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit KnoQ?'),
            content: const Text('Are you sure you want to exit the application?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Exit')),
            ],
          ),
        );
        if (shouldExit == true) {
          // If using dart:io, we could exit. But typical Flutter handling is to pop system navigator.
          // Since we are at root, popping the system navigator will close the app.
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 12),
            Text("Hey, ${user?.name ?? 'Player'}!", style: theme.textTheme.titleMedium),
          ],
        ),
        actions: const [
          SyncIndicator(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBleStatusPill(bleState, theme),
            const SizedBox(height: 24),
            _buildQuickStats(lifetimeStatsAsync, theme),
            const SizedBox(height: 24),
            if (user?.id != null) _buildActiveDrills(drillsAsync, theme),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_cricket, size: 32),
              label: const Text('Start Live Session', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => context.push('/permission-check'),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('Recent Sessions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                 TextButton(
                    onPressed: () => context.push('/session-list'),
                    child: const Text('View All'),
                 )
              ],
            ),
            const SizedBox(height: 8),
            _buildRecentSessions(recentSessionsAsync, theme),
          ],
        ),
      ),
    ));
  }


  Widget _buildBleStatusPill(BleState bleState, ThemeData theme) {
    Color pillColor;
    IconData pillIcon;
    String pillText;

    if (bleState.phase == BleConnectionPhase.connected) {
      pillColor = Colors.green;
      pillIcon = Icons.bluetooth_connected;
      pillText = '${bleState.connectedDevice?.platformName ?? "KnoQ Bat"} Connected';
    } else if (bleState.phase == BleConnectionPhase.connecting || bleState.phase == BleConnectionPhase.reconnecting) {
      pillColor = Colors.orange;
      pillIcon = Icons.bluetooth_searching;
      pillText = 'Connecting...';
    } else {
      pillColor = theme.colorScheme.onSurfaceVariant;
      pillIcon = Icons.bluetooth_disabled;
      pillText = 'Bat Not Connected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pillColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(pillIcon, size: 16, color: pillColor),
          const SizedBox(width: 8),
          Text(pillText, style: theme.textTheme.labelMedium?.copyWith(color: pillColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AsyncValue lifetimeStatsAsync, ThemeData theme) {
    return lifetimeStatsAsync.when(
      data: (data) {
        return Row(
          children: [
            Expanded(child: _buildMiniStatCard('Lifetime Hits', '${data.totalHits}', Icons.sports_baseball, theme)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStatCard('Lifetime Sweet %', '${data.overallSweetPct}%', Icons.flare, theme)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(AsyncValue<List<SessionModel>> sessionsAsync, ThemeData theme) {
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('No sessions yet.')),
          );
        }
        return Column(
          children: sessions.map((session) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => context.push('/session-history/${session.id}'),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.sports_cricket, color: theme.colorScheme.onPrimaryContainer),
                ),
                title: Text(Formatters.formatDateTime(session.startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${session.totalHits} hits | Sweet Spot: ${session.sweetSpotPct}%'),
                trailing: const Icon(Icons.chevron_right),
              )
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildActiveDrills(AsyncValue<List<dynamic>> drillsAsync, ThemeData theme) {
    return drillsAsync.when(
      data: (drills) {
        // Show active drills first, then recently completed ones
        final activeDrills = drills.where((d) => d['status'] == 'assigned').toList();
        final completedDrills = drills.where((d) => d['status'] == 'completed').take(3).toList();
        final allDrills = [...activeDrills, ...completedDrills];
        if (allDrills.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Drills', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allDrills.length,
                itemBuilder: (context, index) {
                  final drill = allDrills[index];
                  final isCompleted = drill['status'] == 'completed';
                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.15)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: isCompleted ? Border.all(color: Colors.green, width: 2) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.flag,
                              size: 18,
                              color: isCompleted ? Colors.green : theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                drill['title'] ?? 'Drill',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isCompleted ? Colors.green.shade800 : theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('DONE ✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          drill['description'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCompleted ? Colors.green.shade700 : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target: ${drill['target_shot_count']} shots',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isCompleted ? Colors.green.shade700 : theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            if (!isCompleted)
                              Icon(Icons.arrow_forward_ios, size: 12, color: theme.colorScheme.onPrimaryContainer),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
