import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/core/network/api_client.dart';
import 'package:knoq_app/core/constants/api_endpoints.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:knoq_app/services/sync_service.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final syncService = ref.watch(syncServiceProvider.notifier);
  return SessionRepository(apiClient: apiClient, syncService: syncService);
});

class SessionRepository {
  final ApiClient apiClient;
  final SyncService syncService;

  SessionRepository({required this.apiClient, required this.syncService});

  /// Queues a session to SyncService immediately.
  /// The SyncService will attempt to sync it if online, or keep it pending.
  Future<void> saveSession(SessionModel session, List<ShotData> shots) async {
    final payload = {
      'session': session.toJson(),
      'shots': shots.map((s) => s.toJson()).toList(),
    };
    await syncService.queueAction(
      type: 'save_session',
      payload: payload,
    );
  }

  /// Returns paginated list of sessions.
  /// Blends remotely fetched sessions with local pending ones if asking for page 1.
  Future<List<SessionModel>> getSessions({int limit = 20, int page = 1}) async {
    final cacheBox = Hive.box('sessions_cache');
    List<SessionModel> remotelyFetched = [];

    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.sessions,
        queryParameters: {
          'limit': limit,
          'page': page,
        },
      );
      
      final data = response.data['data'] as List;
      remotelyFetched = data.map((j) => SessionModel.fromJson(j)).toList();
      
      // Update cache
      if (page == 1) {
        await cacheBox.clear();
        for (var s in remotelyFetched) {
          await cacheBox.put(s.id, json.encode(s.toJson()));
        }
        await cacheBox.put('_cache_timestamp', DateTime.now().toIso8601String());
      }
    } catch (e) {
      // Offline fallback: Return locally cached sessions
      if (cacheBox.isNotEmpty) {
        remotelyFetched = cacheBox.values.map((raw) => SessionModel.fromJson(json.decode(raw as String))).toList();
        remotelyFetched.sort((a, b) => b.startTime.compareTo(a.startTime));
        remotelyFetched = remotelyFetched.take(limit).toList();
      }
    }

    // Blend with pending sessions from SyncService 
    // (Only on page 1 so we don't duplicate them on infinite scroll)
    if (page == 1) {
      final pendingBox = Hive.box('pending_sync');
      final List<SessionModel> pendingSessions = [];
      
      for (var value in pendingBox.values) {
        final item = json.decode(value as String) as Map<String, dynamic>;
        if (item['type'] == 'save_session') {
          var sessionJson = item['payload']['session'] as Map<String, dynamic>;
          sessionJson['sync_status'] = item['status']; // 'pending' or 'failed'
          pendingSessions.add(SessionModel.fromJson(sessionJson));
        }
      }
      
      // Merge and sort
      final allSessions = [...pendingSessions, ...remotelyFetched];
      // Deduplicate in case a session was uploaded but we haven't refreshed fully yet
      final uniqueSessions = <String, SessionModel>{};
      for (var s in allSessions) {
         if (!uniqueSessions.containsKey(s.id)) {
            uniqueSessions[s.id] = s;
         }
      }
      
      var finalizedList = uniqueSessions.values.toList();
      finalizedList.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      return finalizedList.take(limit).toList();
    }

    return remotelyFetched;
  }

  /// Returns a specific session with its full shot history
  Future<Map<String, dynamic>> getSession(String id) async {
    // Check pending first
    final pendingBox = Hive.box('pending_sync');
    for (var value in pendingBox.values) {
      final item = json.decode(value as String) as Map<String, dynamic>;
      if (item['type'] == 'save_session') {
        final sessionJson = item['payload']['session'];
        if (sessionJson['id'] == id) {
          sessionJson['sync_status'] = item['status'];
          final shotsList = item['payload']['shots'] as List;
          return {
            'session': SessionModel.fromJson(sessionJson),
            'shots': shotsList.map((s) => ShotData.fromJson(s)).toList(),
          };
        }
      }
    }

    // Try API
    final response = await apiClient.dio.get(ApiEndpoints.sessionById(id));
    final data = response.data['data'];
    
    final session = SessionModel.fromJson(data['session']);
    final shotsRaw = data['shots'] as List;
    final shots = shotsRaw.map((s) => ShotData.fromJson(s)).toList();

    return {
      'session': session,
      'shots': shots,
    };
  }

  /// Returns recent sessions for home screen
  Future<List<SessionModel>> getRecentSessions({int limit = 3}) async {
    return getSessions(limit: limit, page: 1);
  }

  /// Deletes a session by ID
  Future<void> deleteSession(String id) async {
    // If pending, just delete from queue
    final pendingBox = Hive.box('pending_sync');
    final keysToDel = [];
    for (var key in pendingBox.keys) {
      final item = json.decode(pendingBox.get(key) as String) as Map<String, dynamic>;
      if (item['type'] == 'save_session' && item['payload']['session']['id'] == id) {
        keysToDel.add(key);
      }
    }
    
    if (keysToDel.isNotEmpty) {
      await pendingBox.deleteAll(keysToDel);
      return;
    }

    await apiClient.dio.delete(ApiEndpoints.sessionById(id));
  }
}
