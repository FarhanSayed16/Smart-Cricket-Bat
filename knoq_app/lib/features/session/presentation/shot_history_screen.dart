import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/features/session/data/session_repository.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';
import 'package:knoq_app/core/widgets/zone_badge.dart';
import 'package:knoq_app/features/session/providers/session_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:knoq_app/core/widgets/bat_zone_diagram.dart';
import 'package:knoq_app/core/widgets/empty_state.dart';


final sessionHistoryProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, sessionId) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getSession(sessionId);
});

class ShotHistoryScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ShotHistoryScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ShotHistoryScreen> createState() => _ShotHistoryScreenState();
}

class _ShotHistoryScreenState extends ConsumerState<ShotHistoryScreen> {
  // Filters: 'All', 'Sweet', 'Weak', 'Strong'
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(sessionHistoryProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: historyAsync.when(
        data: (data) {
          final SessionModel session = data['session'];
          final List<ShotData> allShots = data['shots'];

          List<ShotData> filteredShots = allShots;
          if (_activeFilter == 'Sweet') {
            filteredShots = allShots.where((s) => s.zone == 'Sweet').toList();
          } else if (_activeFilter == 'Weak') {
            filteredShots = allShots.where((s) => s.power < 40).toList();
          } else if (_activeFilter == 'Strong') {
            filteredShots = allShots.where((s) => s.power > 75).toList();
          }

          return Column(
            children: [
               _buildSessionHeader(context, theme, session),
               _buildCoachNotes(context, theme),
               
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 24.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     SizedBox(
                       height: 120,
                       width: 80,
                       child: BatZoneDiagram(
                         zoneDistribution: session.zoneDistribution.isNotEmpty 
                           ? session.zoneDistribution.map((k, v) => MapEntry(k, (v as num).toDouble()))
                           : {'Sweet': session.sweetSpotPct / 100.0, 'Top': (100 - session.sweetSpotPct) / 200.0, 'Bottom': (100 - session.sweetSpotPct) / 200.0}
                       ),
                     ),
                     const SizedBox(width: 32),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Impact Heatmap', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         Text('Based on ${session.totalHits} hits', style: theme.textTheme.bodySmall),
                       ]
                     )
                   ]
                 )
               ),

               _buildFilterBar(theme),
               Expanded(
                 child: filteredShots.isEmpty 
                   ? const EmptyState(
                       illustration: Icon(Icons.sports_cricket, size: 64, color: Colors.grey),
                       title: 'No Shot Logs',
                       subtitle: 'Individual shot logs were not recorded or synced for this session.',
                     )
                   : ListView.builder(
                       padding: const EdgeInsets.only(top: 8, bottom: 24),
                       itemCount: filteredShots.length,
                       itemBuilder: (context, index) {
                         return _buildShotRow(context, theme, filteredShots[index]);
                       },
                     ),
               )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading session: $error', textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _buildSessionHeader(BuildContext context, ThemeData theme, SessionModel session) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _HeaderStat('Hits', '${session.totalHits}', theme),
          _HeaderStat('Sweet', '${session.sweetSpotPct}%', theme),
          _HeaderStat('Avg Pwr', '${session.avgPower}', theme),
          _HeaderStat('Peak Pwr', '${session.peakPower}', theme),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Sweet', 'Weak', 'Strong'].map((filter) {
            final isActive = _activeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(filter),
                selected: isActive,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _activeFilter = filter);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShotRow(BuildContext context, ThemeData theme, ShotData shot) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text('#${shot.hit}', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12)),
      ),
      title: Row(
        children: [
          ZoneBadge(zone: shot.zone),
          const Spacer(),
          Text('Power: ${shot.power}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      subtitle: shot.swing != null ? Text('Swing: ${shot.swing!.toStringAsFixed(1)}°/s') : null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detailed Shot Data', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              // Shows underlying debug values like totalHits, sweetPct at that moment
              Text('Internal Session Hits (at shot time): ${shot.totalHits}'),
              Text('Internal Avg Power: ${shot.avgPower}'),
              Text('Internal Sweet pct: ${shot.sweetPct}%'),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCoachNotes(BuildContext context, ThemeData theme) {
    final notesAsync = ref.watch(sessionNotesProvider(widget.sessionId));
    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.speaker_notes, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Coach Notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ...notes.map((note) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundImage: note['coach_avatar'] != null ? NetworkImage(note['coach_avatar']) : null,
                      child: note['coach_avatar'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(note['coach_name'] ?? 'Coach', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        // Rich text rendered as simple text for MVP, or we can parse HTML tags simply
                        Text(
                          (note['note'] ?? '').replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note['tags'] != null && (note['tags'] as List).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: (note['tags'] as List).map((t) => Chip(
                              label: Text(t, style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            )).toList(),
                          )
                        ]
                      ],
                    ),
                    trailing: const Icon(Icons.reply),
                    onTap: () {
                      // Navigate to replies screen
                      context.push('/note-replies/${note['id']}', extra: note);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _HeaderStat(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
