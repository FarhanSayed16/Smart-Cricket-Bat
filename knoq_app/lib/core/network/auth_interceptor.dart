import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Attaches the Firebase JWT to every outgoing API request.
/// If the token is expired, forces a refresh before sending.
class AuthInterceptor extends Interceptor {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Force refresh if the cached token is expired
        final token = await user.getIdToken(false);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      // If token retrieval fails, continue without token.
      // The API will return 401, which onError handles.
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token invalid or expired — the UI auth state listener
      // will handle logging the user out when Firebase auth state changes.
    }
    return handler.next(err);
  }
}
