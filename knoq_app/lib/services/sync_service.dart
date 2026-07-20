import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:knoq_app/core/network/api_client.dart';
import 'package:knoq_app/core/constants/api_endpoints.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:knoq_app/services/crash_reporting_service.dart';

class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;

  const SyncState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }
}

final syncServiceProvider = NotifierProvider<SyncService, SyncState>(() {
  return SyncService();
});

class SyncService extends Notifier<SyncState> {
  static const _boxName = 'pending_sync';
  late Box _box;
  final _uuid = const Uuid();

  @override
  SyncState build() {
    _box = Hive.box(_boxName);
    
    // Listen to network changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
       final isOnline = results.any((r) => r != ConnectivityResult.none);
       state = state.copyWith(isOnline: isOnline);
       
       if (isOnline && !state.isSyncing) {
         _processQueue();
       }
    });

    // Initial check
    _checkInitialNetwork();
    
    // Update counts whenever box changes
    _box.listenable().addListener(() {
      _updateCounts();
    });

    // Calculate initial counts
    int pending = 0;
    int failed = 0;
    for (var value in _box.values) {
      final item = json.decode(value) as Map<String, dynamic>;
      if (item['status'] == 'failed') {
        failed++;
      } else {
        pending++;
      }
    }

    return SyncState(pendingCount: pending, failedCount: failed);
  }

  void _updateCounts() {
    int pending = 0;
    int failed = 0;
    for (var value in _box.values) {
      final item = json.decode(value) as Map<String, dynamic>;
      if (item['status'] == 'failed') {
        failed++;
      } else {
        pending++;
      }
    }
    state = state.copyWith(pendingCount: pending, failedCount: failed);
  }

  Future<void> _checkInitialNetwork() async {
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    state = state.copyWith(isOnline: isOnline);
    if (isOnline && !state.isSyncing) {
      _processQueue();
    }
  }

  /// Add a generic action to the queue
  Future<void> queueAction({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final id = _uuid.v4();
    final item = {
      'id': id,
      'type': type, // e.g. 'save_session', 'coach_note'
      'payload': payload,
      'retryCount': 0,
      'status': 'pending',
    };
    await _box.put(id, json.encode(item));
    
    // Attempt sync immediately if online
    if (state.isOnline && !state.isSyncing) {
      _processQueue();
    }
  }

  /// Manually retry processing queue
  Future<void> manualRetry() async {
    if (!state.isOnline) return;
    
    // Reset all 'failed' back to 'pending'
    for (var key in _box.keys) {
      final item = json.decode(_box.get(key)) as Map<String, dynamic>;
      if (item['status'] == 'failed') {
        item['status'] = 'pending';
        item['retryCount'] = 0; // Reset retries
        await _box.put(key, json.encode(item));
      }
    }
    
    if (!state.isSyncing) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_box.isEmpty) return;
    state = state.copyWith(isSyncing: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final keys = _box.keys.toList();
      for (var key in keys) {
        if (!state.isOnline) break; // Network dropped mid-sync

        final item = json.decode(_box.get(key)) as Map<String, dynamic>;
        
        if (item['status'] == 'failed') continue;

        bool success = false;
        
        try {
          if (item['type'] == 'save_session') {
            await _syncSession(apiClient, item['payload']);
          } else if (item['type'] == 'coach_note') {
            await _syncCoachNote(apiClient, item['payload']);
          }
          success = true;
        } catch (e, st) {
          ref.read(crashReportingServiceProvider).handleException(e, st);
        }

        if (success) {
          await _box.delete(key);
        } else {
          int retries = (item['retryCount'] as int) + 1;
          if (retries >= 5) {
            item['status'] = 'failed';
          }
          item['retryCount'] = retries;
          await _box.put(key, json.encode(item));

          // Exponential backoff: wait 2^retries seconds before next attempt
          if (item['status'] != 'failed') {
            final delay = Duration(seconds: min(pow(2, retries).toInt(), 32));
            await Future.delayed(delay);
          }
        }
      }
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> _syncSession(ApiClient apiClient, Map<String, dynamic> payload) async {
    // The backend POST /sessions expects a flat body with session fields + shots array.
    // Build a single payload combining session metadata and shots.
    final sessionData = payload['session'] as Map<String, dynamic>;
    final shotsList = payload['shots'] as List?;

    final body = Map<String, dynamic>.from(sessionData);
    if (shotsList != null && shotsList.isNotEmpty) {
      // Map shot fields from camelCase (Flutter) to snake_case (backend)
      body['shots'] = shotsList.map((s) {
        final shot = s as Map<String, dynamic>;
        return {
          'zone': shot['zone'],
          'power': shot['power'],
          'swing': shot['swing'],
          'timestamp': shot['timestamp'],
          'video_offset_ms': shot['videoOffsetMs'],
        };
      }).toList();
    }

    await apiClient.dio.post(
      ApiEndpoints.sessions,
      data: body,
    );
  }

  Future<void> _syncCoachNote(ApiClient apiClient, Map<String, dynamic> payload) async {
    await apiClient.dio.post(
      '/coach-notes', // Use specific endpoint
      data: payload,
    );
  }
}
