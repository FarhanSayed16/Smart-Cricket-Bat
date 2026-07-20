import 'package:knoq_app/core/network/api_client.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';
import 'package:knoq_app/services/sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class CoachRepository {
  final ApiClient apiClient;
  final SyncService syncService;

  CoachRepository({required this.apiClient, required this.syncService});

  Future<List<UserModel>> getAssignedPlayers() async {
    try {
      final response = await apiClient.dio.get('/coach/players');
      final items = response.data['data'] as List;
      return items.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching assigned players: $e');
      // Return empty list instead of mock data — real errors surface properly
      return [];
    }
  }

  Future<List<SessionModel>> getPlayerSessions(String playerId) async {
    try {
      final response = await apiClient.dio.get('/coach/players/$playerId/sessions');
      final items = response.data['data'] as List;
      return items.map((e) => SessionModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching player sessions: $e');
      return [];
    }
  }

  Future<void> assignCoach(String playerId, String academyId, {String? targetCoachId}) async {
    try {
      final payload = {
        'playerId': playerId,
        'academyId': academyId,
      };
      if (targetCoachId != null) {
        payload['coachId'] = targetCoachId;
      }
      await apiClient.dio.post('/coach/assign', data: payload);
    } catch (e) {
      throw Exception('Failed to assign coach: $e');
    }
  }

  Future<void> postCoachNote(String sessionId, String note, List<String> tags) async {
    final payload = {
      'session_id': sessionId,
      'note': note,
      'tags': tags,
    };
    try {
      await apiClient.dio.post('/coach/notes', data: payload);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
         // Queue offline if network error
         await syncService.queueAction(type: 'coach_note', payload: payload);
      } else {
         debugPrint('Coach note post failed: $e');
         await syncService.queueAction(type: 'coach_note', payload: payload);
      }
    } catch (e) {
       await syncService.queueAction(type: 'coach_note', payload: payload);
    }
  }
  
  Future<List<dynamic>> getDrills(String playerId) async {
    try {
      final response = await apiClient.dio.get('/drills/player/$playerId');
      return response.data['data'] as List;
    } catch (e) {
      debugPrint('Error fetching drills: $e');
      return [];
    }
  }

  Future<List<dynamic>> getNoteReplies(String noteId) async {
    try {
      final response = await apiClient.dio.get('/coach/notes/$noteId/replies');
      return response.data['data'] as List;
    } catch (e) {
      debugPrint('Error fetching note replies: $e');
      return [];
    }
  }

  Future<void> postNoteReply(String noteId, String replyText) async {
    final payload = {
      'reply_text': replyText,
    };
    try {
      await apiClient.dio.post('/coach/notes/$noteId/reply', data: payload);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
         await syncService.queueAction(type: 'note_reply', payload: {'note_id': noteId, ...payload});
      } else {
         debugPrint('Note reply post failed: $e');
         await syncService.queueAction(type: 'note_reply', payload: {'note_id': noteId, ...payload});
      }
    } catch (e) {
       await syncService.queueAction(type: 'note_reply', payload: {'note_id': noteId, ...payload});
    }
  }
}
