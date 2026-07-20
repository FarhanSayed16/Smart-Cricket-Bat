import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knoq_app/features/auth/data/auth_repository.dart';
import 'package:knoq_app/features/auth/data/user_repository.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/core/network/api_client.dart';
import 'package:knoq_app/core/errors/app_exceptions.dart';
import 'package:knoq_app/services/analytics_service.dart';
import 'package:knoq_app/services/crash_reporting_service.dart';
import 'package:knoq_app/services/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

// -- Singletons --

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserRepository(apiClient: client);
});

// -- State Streams --

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final crashRepo = ref.read(crashReportingServiceProvider);
  final analytics = ref.read(analyticsServiceProvider);
  final fcm = ref.read(notificationServiceProvider);
  
  if (user == null) {
    crashRepo.setUserIdentifier(null);
    analytics.setUserId(null);
    return null;
  }
  
  final userRepo = ref.watch(userRepositoryProvider);
  final profile = await userRepo.getCurrentUserProfile();
  
  if (profile != null) {
    crashRepo.setUserIdentifier(profile.id);
    analytics.setUserId(profile.id);

    // Fire-and-forget: FCM init should not block profile resolution
    _initFcmInBackground(fcm, userRepo);
  }
  return profile;
});

final assignedCoachesProvider = FutureProvider<List<UserModel>>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.getAssignedCoaches();
});

/// Fire-and-forget FCM initialization — keeps profile loading fast.
void _initFcmInBackground(NotificationService fcm, UserRepository userRepo) async {
  try {
    await fcm.initialize();
    final fcmToken = await fcm.getToken();
    if (fcmToken != null) {
      try {
        await userRepo.updateProfile({'fcm_token': fcmToken});
      } catch (_) {}
    }
    fcm.listenToTokenRefresh((newToken) async {
      try {
        await userRepo.updateProfile({'fcm_token': newToken});
      } catch (_) {}
    });
  } catch (_) {}
}

// -- State Notifier --

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final Ref _ref;

  AuthNotifier(this._authRepo, this._userRepo, this._ref) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepo.signInWithEmail(email, password);
      _ref.read(analyticsServiceProvider).logLogin();
      _ref.invalidate(currentUserProvider);
      // IMPORTANT: Wait for profile to fully resolve before returning,
      // so GoRouter's redirect evaluates against a settled state.
      await _ref.read(currentUserProvider.future);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.signUpWithEmail(email, password);
      if (user != null) {
        // CRITICAL: Register in backend IMMEDIATELY after Firebase signup.
        // authStateProvider will fire from signUpWithEmail, causing 
        // currentUserProvider to try GET /users/me. We need the DB row
        // to exist before that fetch resolves, so register first.
        await _userRepo.registerUser({
          'email': email,
          'name': name,
          'role': 'player',
        });
        _ref.read(analyticsServiceProvider).logSignUp();
        // Now invalidate and await — the backend row exists so GET /users/me will succeed.
        _ref.invalidate(currentUserProvider);
        await _ref.read(currentUserProvider.future);
      }
      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      // Provide user-friendly message for common Firebase errors
      String message = e.message;
      if (e.code == 'email-already-in-use') {
        message = 'An account with this email already exists. Please log in instead.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Please use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      }
      state = AsyncValue.error(message, StackTrace.current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _authRepo.signOut();
      
      // Clear local sensitive data
      try {
        final activeSessionBox = Hive.box('active_session');
        await activeSessionBox.clear();
        final pendingSyncBox = Hive.box('pending_sync');
        await pendingSyncBox.clear();
        final sessionsCacheBox = Hive.box('sessions_cache');
        await sessionsCacheBox.clear();
      } catch (e) {
        // Ignore if boxes aren't open yet or error out
      }

      _ref.read(analyticsServiceProvider).logLogout();
      _ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return AuthNotifier(authRepo, userRepo, ref);
});
