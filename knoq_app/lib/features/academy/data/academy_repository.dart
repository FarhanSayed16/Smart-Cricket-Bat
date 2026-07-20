import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

class AcademyRepository {
  final Dio _dio;

  AcademyRepository(this._dio);

  Future<void> inviteMember(String academyId, String email, String role) async {
    try {
      await _dio.post('/academy/$academyId/invite', data: {
        'email': email,
        'role': role,
      });
    } catch (e) {
      throw Exception('Failed to send invite: $e');
    }
  }

  Future<List<dynamic>> getMembers(String academyId) async {
    try {
      final response = await _dio.get('/academy/$academyId/members');
      return response.data['data'] as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to get members: $e');
    }
  }

  Future<void> removeMember(String academyId, String userId) async {
    try {
      await _dio.delete('/academy/$academyId/members/$userId');
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }
}

final academyRepositoryProvider = Provider<AcademyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AcademyRepository(apiClient.dio);
});
