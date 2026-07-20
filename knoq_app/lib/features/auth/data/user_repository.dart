import 'package:dio/dio.dart';
import 'package:knoq_app/core/network/api_client.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/core/errors/app_exceptions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> registerUser(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post('/auth/register', data: data);
    } on DioException catch (e) {
      throw NetworkException(e.response?.data['message'] ?? 'Failed to initialize account');
    }
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final box = Hive.box('app_settings');
    try {
      final response = await _apiClient.dio.get('/users/me');
      if (response.data['status'] == 'success') {
        final userData = response.data['data'];
        await box.put('cached_user_profile', json.encode(userData));
        await box.put('cached_user_profile_at', DateTime.now().toIso8601String());
        return UserModel.fromJson(userData);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // Profile not generated yet
      
      // Fallback to offline cache
      final cachedStr = box.get('cached_user_profile');
      if (cachedStr != null) {
        return UserModel.fromJson(json.decode(cachedStr));
      }
      
      throw NetworkException(e.response?.data['message'] ?? 'Failed to fetch profile and no offline data exists.');
    }
  }

  Future<List<UserModel>> getAssignedCoaches() async {
    try {
      final response = await _apiClient.dio.get('/users/me/coaches');
      final data = response.data['data'] as List;
      return data.map((json) => UserModel(
        id: json['id'],
        firebaseUid: '', // not needed for this view
        name: json['name'],
        email: json['email'],
        role: 'coach',
        profileImageUrl: json['profile_image_url'],
      )).toList();
    } on DioException catch (e) {
      throw NetworkException(e.response?.data['message'] ?? 'Failed to fetch coaches');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    try {
      await _apiClient.dio.patch('/users/me', data: fields);
    } on DioException catch (e) {
      throw NetworkException(e.response?.data['message'] ?? 'Failed to update profile');
    }
  }

  Future<void> deleteUserData() async {
    try {
      await _apiClient.dio.delete('/users/me');
    } on DioException catch (e) {
      throw NetworkException(e.response?.data['message'] ?? 'Failed to delete user profile metadata');
    }
  }

  Future<void> joinAcademy(String joinCode) async {
    try {
      await _apiClient.dio.post('/academy/join', data: {'join_code': joinCode});
    } on DioException catch (e) {
      throw NetworkException(e.response?.data['message'] ?? 'Failed to join academy');
    }
  }

  Future<void> leaveAcademy() async {
    try {
      await _apiClient.dio.post('/academy/leave');
    } on DioException catch (e) {
      throw NetworkException(e.response?.data['message'] ?? 'Failed to leave academy');
    }
  }
}
