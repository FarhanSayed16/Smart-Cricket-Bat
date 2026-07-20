import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/features/coach/data/coach_repository.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:knoq_app/services/sync_service.dart';

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepository(
    apiClient: ref.watch(apiClientProvider),
    syncService: ref.watch(syncServiceProvider.notifier),
  );
});

final assignedPlayersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.watch(coachRepositoryProvider);
  return await repo.getAssignedPlayers();
});

final playerSessionsProvider = FutureProvider.autoDispose.family<List<SessionModel>, String>((ref, playerId) async {
  final repo = ref.watch(coachRepositoryProvider);
  return await repo.getPlayerSessions(playerId);
});

final playerDrillsProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, playerId) async {
  final repo = ref.watch(coachRepositoryProvider);
  return await repo.getDrills(playerId);
});

final noteRepliesProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, noteId) async {
  final repo = ref.watch(coachRepositoryProvider);
  return await repo.getNoteReplies(noteId);
});
