import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/features/coach/providers/coach_provider.dart';
import 'package:knoq_app/core/utils/formatters.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

class NoteRepliesScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> note;

  const NoteRepliesScreen({super.key, required this.note});

  @override
  ConsumerState<NoteRepliesScreen> createState() => _NoteRepliesScreenState();
}

class _NoteRepliesScreenState extends ConsumerState<NoteRepliesScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final repo = ref.read(coachRepositoryProvider);
      await repo.postNoteReply(widget.note['id'], text);
      _replyController.clear();
      // Refresh replies
      ref.invalidate(noteRepliesProvider(widget.note['id']));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending reply: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repliesAsync = ref.watch(noteRepliesProvider(widget.note['id']));
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Coach Note')),
      body: Column(
        children: [
          // Original Note
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: widget.note['coach_avatar'] != null ? NetworkImage(widget.note['coach_avatar']) : null,
                  child: widget.note['coach_avatar'] == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.note['coach_name'] ?? 'Coach', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        (widget.note['note'] ?? '').replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatDateTime(DateTime.parse(widget.note['created_at'])),
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Replies
          Expanded(
            child: repliesAsync.when(
              data: (replies) {
                if (replies.isEmpty) {
                  return const Center(child: Text('No replies yet. Start the conversation!'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: replies.length,
                  itemBuilder: (context, index) {
                    final reply = replies[index];
                    final isMe = user?.id == reply['sender_id'];
                    return _buildReplyBubble(reply, isMe, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          // Input
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: 'Type a reply...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                    : IconButton(
                        icon: const Icon(Icons.send),
                        color: theme.colorScheme.primary,
                        onPressed: _sendReply,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBubble(Map<String, dynamic> reply, bool isMe, ThemeData theme) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(reply['sender_name'] ?? 'User', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
            ],
            Text(
              reply['reply_text'] ?? '',
              style: TextStyle(color: isMe ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
