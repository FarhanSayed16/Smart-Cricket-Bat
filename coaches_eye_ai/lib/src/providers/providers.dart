import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/hardware_simulator.dart';
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

/// Provider for HardwareSimulator
final hardwareSimulatorProvider = Provider<HardwareSimulator>((ref) {
  final simulator = HardwareSimulator();
  ref.onDispose(() => simulator.dispose());
  return simulator;
});

/// Stream provider for authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user model
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return authState.when(
    data: (user) async {
      if (user != null) {
        return await firestoreService.getUserProfile(user.uid);
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Stream provider for shot data from hardware simulator
final shotStreamProvider = StreamProvider<ShotModel>((ref) {
  final simulator = ref.watch(hardwareSimulatorProvider);
  return simulator.getShotStream();
});

/// Provider for current session
final currentSessionProvider = StateProvider<String?>((ref) => null);

/// Provider for current session shots
final currentSessionShotsProvider = StateProvider<List<ShotModel>>((ref) => []);

/// Provider for sessions list
final sessionsProvider = FutureProvider.family<List<SessionModel>, String>((
  ref,
  playerId,
) async {
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

/// Stream provider for shots for a specific session
final sessionShotsStreamProvider =
    StreamProvider.family<List<ShotModel>, String>((ref, sessionId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getShotsStream(sessionId);
    });

/// Provider for session statistics
final sessionStatsProvider =
    Provider.family<Map<String, dynamic>, List<ShotModel>>((ref, shots) {
      if (shots.isEmpty) {
        return {
          'totalShots': 0,
          'averageBatSpeed': 0.0,
          'maxBatSpeed': 0.0,
          'minBatSpeed': 0.0,
          'averagePower': 0.0,
          'maxPower': 0,
          'minPower': 0,
          'averageTiming': 0.0,
          'perfectTimingCount': 0,
          'averageSweetSpot': 0.0,
          'perfectSweetSpotCount': 0,
          'duration': 0,
        };
      }

      final batSpeeds = shots.map((s) => s.batSpeed).toList();
      final powers = shots.map((s) => s.powerIndex).toList();
      final timings = shots.map((s) => s.timingScore).toList();
      final sweetSpots = shots.map((s) => s.sweetSpotAccuracy).toList();

      final startTime = shots.first.timestamp;
      final endTime = shots.last.timestamp;
      final duration = endTime.difference(startTime).inMinutes;

      return {
        'totalShots': shots.length,
        'averageBatSpeed': batSpeeds.reduce((a, b) => a + b) / batSpeeds.length,
        'maxBatSpeed': batSpeeds.reduce((a, b) => a > b ? a : b),
        'minBatSpeed': batSpeeds.reduce((a, b) => a < b ? a : b),
        'averagePower': powers.reduce((a, b) => a + b) / powers.length,
        'maxPower': powers.reduce((a, b) => a > b ? a : b),
        'minPower': powers.reduce((a, b) => a < b ? a : b),
        'averageTiming': timings.reduce((a, b) => a + b) / timings.length,
        'perfectTimingCount': timings.where((t) => t.abs() < 5.0).length,
        'averageSweetSpot':
            sweetSpots.reduce((a, b) => a + b) / sweetSpots.length,
        'perfectSweetSpotCount': sweetSpots.where((s) => s >= 0.95).length,
        'duration': duration,
      };
    });

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

      // Start hardware simulator
      final simulator = ref.read(hardwareSimulatorProvider);
      simulator.startSession(sessionId);

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
      if (state.currentSessionId == null) return;

      state = state.copyWith(isLoading: true, error: null);

      final firestoreService = ref.read(firestoreServiceProvider);
      final simulator = ref.read(hardwareSimulatorProvider);

      // End session in Firestore
      await firestoreService.endSession(
        state.currentSessionId!,
        state.sessionShots,
      );

      // Stop hardware simulator
      simulator.stopSession();

      state = state.copyWith(
        isLoading: false,
        currentSessionId: null,
        sessionShots: [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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

// ===== COACH-PLAYER RELATIONSHIP PROVIDERS =====

/// Stream provider for players linked to a coach
final playersForCoachProvider =
    StreamProvider.family<List<PlayerProfile>, String>((ref, coachId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getPlayersForCoach(coachId: coachId);
    });

/// Provider for coach profile
final coachProfileProvider = FutureProvider.family<CoachProfile?, String>((
  ref,
  coachId,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getCoachProfile(coachId);
});

/// Provider for player profile
final playerProfileProvider = FutureProvider.family<PlayerProfile?, String>((
  ref,
  playerId,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getPlayerProfile(playerId);
});

/// Stream provider for sessions for a specific player (coach view)
final sessionsForPlayerByCoachProvider =
    StreamProvider.family<List<SessionModel>, String>((ref, playerId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getSessionsStreamForPlayerByCoach(playerId);
    });
