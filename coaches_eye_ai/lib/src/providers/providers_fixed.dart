import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/hardware_simulator.dart';
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

/// Provider for HardwareSimulator
final hardwareSimulatorProvider = Provider<HardwareSimulator>((ref) {
  return HardwareSimulator();
});

/// Provider for BLEService
final bleServiceProvider = Provider<BLEService>((ref) {
  return BLEService();
});

/// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

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
final playersProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  coachId,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getPlayersUnderCoach(coachId);
});

/// Provider for sessions for a player
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

/// Provider for current session
final currentSessionProvider = Provider<String?>((ref) => null);

/// Provider for current session shots
final currentSessionShotsProvider = Provider<List<ShotModel>>((ref) => []);

/// Provider for app state management
final appStateProvider = Provider<AppState>((ref) {
  return const AppState();
});

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
