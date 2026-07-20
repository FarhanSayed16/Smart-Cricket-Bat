import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/features/session/data/local_session_store.dart';
import 'package:knoq_app/features/session/domain/session_stats.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:knoq_app/features/ble/providers/ble_provider.dart';
import 'package:knoq_app/features/session/services/video_sync_service.dart';
import 'package:knoq_app/services/analytics_service.dart';
import 'package:uuid/uuid.dart';

class LiveSessionState {
  final Map<String, dynamic> sessionMeta;
  final List<ShotData> shots;
  final SessionStats liveStats;
  final bool isActive;
  final String? lastShotZone;

  LiveSessionState({
    required this.sessionMeta,
    required this.shots,
    required this.liveStats,
    required this.isActive,
    this.lastShotZone,
  });

  LiveSessionState copyWith({
    Map<String, dynamic>? sessionMeta,
    List<ShotData>? shots,
    SessionStats? liveStats,
    bool? isActive,
    String? lastShotZone,
  }) {
    return LiveSessionState(
      sessionMeta: sessionMeta ?? this.sessionMeta,
      shots: shots ?? this.shots,
      liveStats: liveStats ?? this.liveStats,
      isActive: isActive ?? this.isActive,
      lastShotZone: lastShotZone ?? this.lastShotZone,
    );
  }
}

final localSessionStoreProvider = Provider<LocalSessionStore>((ref) {
  // Initialized globally in main_dev.dart / main_prod.dart via Hive.openBox
  return LocalSessionStore();
});

class LiveSessionNotifier extends StateNotifier<LiveSessionState> {
  final LocalSessionStore _store;
  final String userId;
  final Ref _ref;
  StreamSubscription? _shotSub;

  LiveSessionNotifier(this._store, this.userId, this._ref) : super(LiveSessionState(
     sessionMeta: {},
     shots: [],
     liveStats: SessionStats(),
     isActive: false,
  )) {
    // Auto-listen to the BLE shot stream
    _shotSub = _ref.listen(shotStreamProvider, (_, next) {
      next.whenData((shot) {
        onShotReceived(shot);
      });
    }) as StreamSubscription?;
  }

  Future<void> startSession(String deviceId) async {
    final meta = {
      'id': const Uuid().v4(),
      'player_id': userId,
      'device_id': deviceId,
      'start_time': DateTime.now().toIso8601String(),
      'status': 'in_progress'
    };

    await _store.startSession(meta);
    
    state = LiveSessionState(
      sessionMeta: meta,
      shots: [],
      liveStats: SessionStats(),
      isActive: true,
    );

    _ref.read(analyticsServiceProvider).logSessionStarted();
  }

  Future<void> onShotReceived(ShotData shot) async {
    if (!state.isActive) return;

    // Calculate video offset if recording
    final syncService = _ref.read(videoSyncServiceProvider);
    final offsetMs = syncService.getShotOffsetMs(shot.timestamp ?? DateTime.now());
    
    final updatedShot = ShotData(
      hit: shot.hit,
      zone: shot.zone,
      power: shot.power,
      swing: shot.swing,
      sweetPct: shot.sweetPct,
      avgPower: shot.avgPower,
      totalHits: shot.totalHits,
      timestamp: shot.timestamp ?? DateTime.now(),
      videoOffsetMs: offsetMs,
    );

    // Persist immediately per Write-Ahead bounds
    await _store.addShot(updatedShot);

    final updatedShots = List<ShotData>.from(state.shots)..add(updatedShot);
    final stats = state.liveStats;
    stats.addShot(updatedShot);

    state = state.copyWith(
      shots: updatedShots,
      liveStats: stats,
      lastShotZone: updatedShot.zone,
    );

    _ref.read(analyticsServiceProvider).logShotReceived();
  }

  Future<void> endSession() async {
    await _store.endSession();
    
    // Explicitly disconnect BLE to save battery per Phase 16
    try {
      await _ref.read(bleProvider.notifier).disconnect();
    } catch (_) {
      // Ignore disconnect errors
    }
    
    final meta = Map<String, dynamic>.from(state.sessionMeta);
    meta['end_time'] = DateTime.now().toIso8601String();
    meta['status'] = 'completed';

    state = state.copyWith(
      isActive: false,
      sessionMeta: meta,
    );

    _ref.read(analyticsServiceProvider).logSessionEnded(state.liveStats.totalHits);
  }

  void setVideoPath(String path) {
    final meta = Map<String, dynamic>.from(state.sessionMeta);
    meta['video_path'] = path;
    state = state.copyWith(sessionMeta: meta);
  }

  /// Recovers a crashed session from Hive storage.
  Future<bool> recoverFromCrash() async {
    if (!_store.hasActiveSession()) return false;

    final recovered = _store.recoverSession();
    if (recovered == null) return false;

    final metadata = recovered['metadata'] as Map<String, dynamic>;
    final shots = recovered['shots'] as List<ShotData>;
    
    final stats = SessionStats();
    for (var shot in shots) {
      stats.addShot(shot);
    }

    state = LiveSessionState(
      sessionMeta: metadata,
      shots: shots,
      liveStats: stats,
      isActive: true,
      lastShotZone: shots.isNotEmpty ? shots.last.zone : null,
    );

    return true;
  }

  SessionModel getSessionModel() {
    final stats = state.liveStats;
    return SessionModel(
       id: state.sessionMeta['id'],
       playerId: state.sessionMeta['player_id'],
       deviceId: state.sessionMeta['device_id'],
       startTime: DateTime.parse(state.sessionMeta['start_time']),
       endTime: state.sessionMeta['end_time'] != null 
           ? DateTime.parse(state.sessionMeta['end_time']) 
           : DateTime.now(),
       status: state.sessionMeta['status'],
       totalHits: stats.totalHits,
       sweetSpotHits: stats.sweetSpotHits,
       sweetSpotPct: stats.sweetSpotPct,
       avgPower: stats.avgPower,
       peakPower: stats.peakPower,
       avgSwing: stats.hasSwingData ? stats.avgSwing : null,
       peakSwing: stats.hasSwingData ? stats.peakSwing : null,
       zoneDistribution: stats.zoneDistribution,
       consistencyScore: stats.computeConsistency(),
       syncStatus: 'pending',
    );
  }

  @override
  void dispose() {
    _shotSub?.cancel();
    super.dispose();
  }
}

final liveSessionProvider = StateNotifierProvider<LiveSessionNotifier, LiveSessionState>((ref) {
  final store = ref.watch(localSessionStoreProvider);
  final user = ref.watch(currentUserProvider).valueOrNull;
  return LiveSessionNotifier(store, user?.id ?? 'unknown_user', ref);
});

final sessionNotesProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, sessionId) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.dio.get('/sessions/$sessionId/notes');
    return response.data['data'] as List;
  } catch (e) {
    return [];
  }
});
