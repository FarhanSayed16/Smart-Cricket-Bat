import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ble_service.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/shot_model.dart';
import '../models/profile_models.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Provider for BLEService (ESP32 data only)
final bleServiceProvider = Provider<BLEService>((ref) {
  return BLEService();
});

/// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for auth state (alias for currentUserProvider)
final authStateProvider = currentUserProvider;

/// Provider for current user profile
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  final user = authService.currentUser;
  if (user == null) return null;

  return await firestoreService.getUserProfile(user.uid);
});

/// Provider for user profile by ID
final userProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUserProfile(userId);
});

/// Provider for players under a coach
final playersForCoachProvider =
    FutureProvider.family<List<PlayerProfile>, String>((ref, coachId) async {
      final firestoreService = ref.watch(firestoreServiceProvider);
      final players = await firestoreService.getPlayersUnderCoach(coachId);
      // Convert UserModel to PlayerProfile
      return players
          .map(
            (user) => PlayerProfile(
              uid: user.uid,
              displayName: user.displayName,
              coachId: user.coachId,
            ),
          )
          .toList();
    });

/// Provider for sessions for a player by coach
final sessionsForPlayerByCoachProvider =
    FutureProvider.family<List<SessionModel>, String>((ref, playerId) async {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return await firestoreService.getSessionsForPlayer(playerId);
    });

/// Stream provider for sessions list
final sessionsStreamProvider =
    StreamProvider.family<List<SessionModel>, String>((ref, playerId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getSessionsStream(playerId);
    });

/// Provider for shots for a specific session
final sessionShotsProvider = FutureProvider.family<List<ShotModel>, String>((
  ref,
  sessionId,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getShotsForSession(sessionId);
});

/// Stream provider for shots in a session
final sessionShotsStreamProvider =
    StreamProvider.family<List<ShotModel>, String>((ref, sessionId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getShotsStream(sessionId);
    });

/// Provider for BLE connection state
final bleConnectionProvider = StreamProvider<bool>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.connectionStream;
});

/// Provider for BLE scan results
final bleScanProvider = StreamProvider<List<BluetoothDevice>>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.scanStream;
});

/// Provider for ESP32 shot stream (real hardware data only)
final esp32ShotStreamProvider = StreamProvider<ShotModel>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.shotStream;
});

/// Provider for session stats
final sessionStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, sessionId) async {
      final firestoreService = ref.watch(firestoreServiceProvider);
      final shots = await firestoreService.getShotsForSession(sessionId);

      if (shots.isEmpty) {
        return {
          'totalShots': 0,
          'averageBatSpeed': 0.0,
          'averagePower': 0.0,
          'averageTiming': 0.0,
          'sweetSpotPercentage': 0.0,
          'perfectSweetSpotCount': 0,
          'duration': 0,
        };
      }

      final batSpeeds = shots.map((s) => s.batSpeed).toList();
      final powers = shots.map((s) => s.powerIndex.toDouble()).toList();
      final timings = shots.map((s) => s.timingScore).toList();
      final sweetSpots = shots.map((s) => s.sweetSpotAccuracy).toList();

      final averageBatSpeed =
          batSpeeds.reduce((a, b) => a + b) / batSpeeds.length;
      final averagePower = powers.reduce((a, b) => a + b) / powers.length;
      final averageTiming = timings.reduce((a, b) => a + b) / timings.length;
      final sweetSpotPercentage =
          sweetSpots.where((s) => s >= 0.8).length / sweetSpots.length;

      // Calculate duration (assuming shots are in chronological order)
      final duration = shots.isNotEmpty
          ? shots.last.timestamp.difference(shots.first.timestamp).inMinutes
          : 0;

      return {
        'totalShots': shots.length,
        'averageBatSpeed': averageBatSpeed,
        'averagePower': averagePower,
        'averageTiming': averageTiming,
        'sweetSpotPercentage': sweetSpotPercentage,
        'perfectSweetSpotCount': sweetSpots.where((s) => s >= 0.95).length,
        'duration': duration,
      };
    });

/// Provider for current session
final currentSessionProvider = StateProvider<String?>((ref) => null);

/// Provider for current session shots
final currentSessionShotsProvider = StateProvider<List<ShotModel>>((ref) => []);

/// Provider for app state management
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  return AppStateNotifier(ref);
});

/// App state notifier for managing global app state
class AppStateNotifier extends StateNotifier<AppState> {
  final Ref ref;

  AppStateNotifier(this.ref) : super(const AppState());

  /// Start a new session
  Future<void> startSession(String playerId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final firestoreService = ref.read(firestoreServiceProvider);
      final sessionId = await firestoreService.startNewSession(playerId);

      // Start ESP32 BLE service for real hardware data
      final bleService = ref.read(bleServiceProvider);
      bleService.startSession(sessionId);

      state = state.copyWith(
        isLoading: false,
        currentSessionId: sessionId,
        sessionShots: [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add shot to current session
  Future<void> addShot(ShotModel shot) async {
    try {
      final currentShots = List<ShotModel>.from(state.sessionShots);
      currentShots.add(shot);

      // Save shot to Firestore immediately
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addShotToSession(shot);

      state = state.copyWith(sessionShots: currentShots);
    } catch (e) {
      print('Error saving shot to Firestore: $e');
      // Still add to local state even if Firestore fails
      final currentShots = List<ShotModel>.from(state.sessionShots);
      currentShots.add(shot);
      state = state.copyWith(sessionShots: currentShots);
    }
  }

  /// End current session
  Future<void> endSession() async {
    try {
      // Stop ESP32 BLE service
      final bleService = ref.read(bleServiceProvider);
      bleService.stopSession();

      state = state.copyWith(currentSessionId: null, sessionShots: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// App state model
class AppState {
  final bool isLoading;
  final String? error;
  final String? currentSessionId;
  final List<ShotModel> sessionShots;

  const AppState({
    this.isLoading = false,
    this.error,
    this.currentSessionId,
    this.sessionShots = const [],
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
    String? currentSessionId,
    List<ShotModel>? sessionShots,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      sessionShots: sessionShots ?? this.sessionShots,
    );
  }
}
