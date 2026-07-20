import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/features/coach/providers/coach_provider.dart';
import 'package:knoq_app/services/analytics_service.dart';

class SessionDetailCoachScreen extends ConsumerStatefulWidget {
  final SessionModel session;

  const SessionDetailCoachScreen({super.key, required this.session});

  @override
  ConsumerState<SessionDetailCoachScreen> createState() => _SessionDetailCoachScreenState();
}

class _SessionDetailCoachScreenState extends ConsumerState<SessionDetailCoachScreen> {
  final _noteController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isSaving = false;

  final List<String> _availableTags = [
    'Footwork',
    'Timing',
    'Power',
    'Stance',
    'Grip',
    'Follow-through'
  ];

  Future<void> _saveNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty && _selectedTags.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(coachRepositoryProvider).postCoachNote(
        widget.session.id, 
        note, 
        _selectedTags.toList(),
      );
      if (mounted) {
        ref.read(analyticsServiceProvider).logNoteAdded(widget.session.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = widget.session.startTime.toLocal().toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(title: Text('Coach Evaluation: $date')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatSummaryRow(theme),
            const SizedBox(height: 24),
            Text(
              'COACH FEEDBACK',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add your observations...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Quick Tags', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveNote,
                icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Save Note'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatSummaryRow(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCol('Sweet %', '${widget.session.sweetSpotPct}%', theme),
            _buildStatCol('Hits', '${widget.session.totalHits}', theme),
            _buildStatCol('Power', '${widget.session.avgPower}', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}
