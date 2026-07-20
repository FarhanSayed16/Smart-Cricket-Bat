import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/services/sync_service.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  String _lastUpdatedText() {
    try {
      final box = Hive.box('sessions_cache');
      final tsStr = box.get('_cache_timestamp') as String?;
      if (tsStr == null) return 'Never synced';
      final ts = DateTime.parse(tsStr);
      final diff = DateTime.now().difference(ts);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncServiceProvider);
    
    // Offline State
    if (!syncState.isOnline) {
       final lastUpdated = _lastUpdatedText();
       return IconButton(
         tooltip: 'Offline – Last synced: $lastUpdated',
         icon: Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.error),
         onPressed: () {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Working offline. Last updated: $lastUpdated')),
           );
         },
       );
    }
    
    // Currently Syncing State
    if (syncState.isSyncing) {
       return const Padding(
         padding: EdgeInsets.symmetric(horizontal: 16.0),
         child: Center(
           child: SizedBox(
             width: 20, 
             height: 20, 
             child: CircularProgressIndicator(strokeWidth: 2),
           ),
         ),
       );
    }
    
    // Pending items
    if (syncState.pendingCount > 0 || syncState.failedCount > 0) {
       return IconButton(
         tooltip: '${syncState.pendingCount} pending, ${syncState.failedCount} failed',
         icon: Stack(
           alignment: Alignment.topRight,
           children: [
             const Icon(Icons.cloud_upload_outlined),
             Container(
               padding: const EdgeInsets.all(2),
               decoration: BoxDecoration(
                 color: syncState.failedCount > 0 ? Colors.red : Colors.orange,
                 shape: BoxShape.circle,
               ),
               constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
             )
           ],
         ),
         onPressed: () {
           ref.read(syncServiceProvider.notifier).manualRetry();
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Retrying sync...')),
           );
         },
       );
    }

    // Fully Synced
    final lastUpdated = _lastUpdatedText();
    return IconButton(
      tooltip: 'All synced – $lastUpdated',
      icon: const Icon(Icons.cloud_done_outlined, color: Colors.green),
      onPressed: () {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('All data backed up. Last sync: $lastUpdated')),
         );
      },
    );
  }
}
