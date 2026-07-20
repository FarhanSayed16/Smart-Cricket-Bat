import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:knoq_app/features/coach/providers/coach_provider.dart';
import 'package:knoq_app/features/coach/presentation/player_detail_screen.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/features/academy/data/academy_repository.dart';
import 'package:shimmer/shimmer.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  String _searchQuery = '';
  String _sortBy = 'Name';
  String _filterMode = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(assignedPlayersProvider);

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
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Coach Dashboard'),
            Consumer(builder: (ctx, ref, _) {
              final user = ref.watch(currentUserProvider).valueOrNull;
              if (user?.isAcademyOwner == true) {
                return Text('Academy Owner', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary));
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        actions: [
          Consumer(builder: (ctx, ref, _) {
            final user = ref.watch(currentUserProvider).valueOrNull;
            if (user?.isAcademyOwner == true) {
              return IconButton(
                icon: const Icon(Icons.group_add),
                tooltip: 'Manage Academy',
                onPressed: () {
                  _showManageAcademyDialog(context, ref);
                },
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Consumer(builder: (ctx, ref, _) {
            final user = ref.watch(currentUserProvider).valueOrNull;
            if (user?.isAcademyOwner == true) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All Players')),
                    ButtonSegment(value: 'roster', label: Text('My Roster')),
                  ],
                  selected: {_filterMode},
                  onSelectionChanged: (val) {
                    setState(() => _filterMode = val.first);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          _buildFilterRow(theme),
          Expanded(
            child: playersAsync.when(
              data: (players) {
                if (players.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No players assigned. Contact your academy admin.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                
                final currentUser = ref.read(currentUserProvider).valueOrNull;
                
                var filtered = players.where((p) {
                  final matchesSearch = p.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
                  if (!matchesSearch) return false;
                  
                  if (_filterMode == 'roster') {
                    // Filter for players whose assignedCoachId matches the current user's ID
                    return p.assignedCoachId == currentUser?.id;
                  }
                  
                  return true;
                }).toList();
                
                filtered.sort((a, b) {
                  if (_sortBy == 'Name') {
                    return (a.name ?? '').compareTo(b.name ?? '');
                  }
                  // Otherwise, mock sort fallback
                  return (a.name ?? '').compareTo(b.name ?? '');
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(assignedPlayersProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildPlayerCard(filtered[index], theme, currentUser);
                    },
                  ),
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: 4,
                itemBuilder: (_, __) => _buildShimmerCard(theme),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load players: $err'),
                    TextButton(
                      onPressed: () => ref.invalidate(assignedPlayersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildFilterRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search player...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _sortBy,
            underline: const SizedBox.shrink(),
            items: ['Name', 'Last Active'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _sortBy = val);
            },
          )
        ],
      ),
    );
  }

  Widget _buildPlayerCard(UserModel player, ThemeData theme, UserModel? currentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to Player Detail using go_router, passing the player as extra
          context.push('/coach-home/player/${player.id}', extra: player);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name ?? 'Unknown Player', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Age ${player.age ?? '--'} • ${player.battingHand ?? 'R'} Hand', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    // Fix #11: Show inline stats per player
                    Consumer(builder: (ctx, ref, _) {
                      final statsAsync = ref.watch(coachPlayerStatsProvider(player.id));
                      return statsAsync.when(
                        data: (stats) => Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _buildMiniStat('Sweet', '${stats.overallSweetPct}%', theme),
                            _buildMiniStat('Power', '${stats.overallAvgPower}', theme),
                            _buildMiniStat('Sessions', '${stats.totalSessions}', theme),
                          ],
                        ),
                        loading: () => const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 1.5)),
                        error: (_, __) => Text('--', style: theme.textTheme.bodySmall),
                      );
                    }),
                  ],
                ),
              ),
              if (currentUser?.isAcademyOwner == true && player.assignedCoachId == null && currentUser?.academyId != null)
                TextButton(
                  onPressed: () => _showAssignPlayerDialog(context, ref, player),
                  child: const Text('Assign Coach'),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(16.0),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showAssignPlayerDialog(BuildContext context, WidgetRef ref, UserModel player) async {
    final userAsync = ref.read(currentUserProvider);
    final currentUser = userAsync.valueOrNull;
    if (currentUser?.academyId == null) return;

    try {
      final members = await ref.read(academyRepositoryProvider).getMembers(currentUser!.academyId!);
      final coaches = members.where((m) => m['role'] == 'coach').toList();

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Assign ${player.name} to:', style: Theme.of(ctx).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              if (coaches.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No coaches found in this academy.'),
                ),
              for (final coach in coaches)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(coach['name'] ?? coach['email'] ?? 'Unknown Coach'),
                  subtitle: coach['id'] == currentUser.id ? const Text('You') : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(coachRepositoryProvider).assignCoach(
                        player.id, 
                        currentUser.academyId!,
                        targetCoachId: coach['id'],
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Assigned ${player.name} to ${coach['name'] ?? 'Coach'}'))
                        );
                        ref.invalidate(assignedPlayersProvider);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load coaches: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showManageAcademyDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    String role = 'coach';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Manage Academy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invite a new member to your academy:'),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'coach', child: Text('Coach')),
                  DropdownMenuItem(value: 'player', child: Text('Player')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => role = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (emailCtrl.text.isEmpty) return;
                      setDialogState(() => isLoading = true);
                      try {
                        final userAsync = ref.read(currentUserProvider);
                        final user = userAsync.valueOrNull;
                        if (user == null || user.academyId == null) {
                          throw Exception('You must belong to an academy to invite members.');
                        }
                        
                        await ref.read(academyRepositoryProvider).inviteMember(
                              user.academyId!,
                              emailCtrl.text,
                              role,
                            );
                        
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invite sent to ${emailCtrl.text}')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }
}
