import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/profile_models.dart';
import 'firestore_service.dart';

/// Service class for Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _firestoreService.getUserProfile(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign up with email and password
  Future<UserModel?> signUpWithEmail(
    String email,
    String password,
    String displayName,
    String role,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);

        // Create user profile in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
        );

        await _firestoreService.createUserProfile(userModel);

        // Create role-specific profile
        if (role == 'player') {
          final playerProfile = PlayerProfile(
            uid: credential.user!.uid,
            displayName: displayName,
          );
          await _firestoreService.createPlayerProfile(playerProfile);
        } else if (role == 'coach') {
          final coachProfile = CoachProfile(
            uid: credential.user!.uid,
            displayName: displayName,
          );
          await _firestoreService.createCoachProfile(coachProfile);
        }

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({String? displayName, String? role}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Update Firebase Auth profile
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      // Update Firestore profile
      final userModel = await _firestoreService.getUserProfile(user.uid);
      if (userModel != null) {
        final updatedUser = userModel.copyWith(
          displayName: displayName ?? userModel.displayName,
          role: role ?? userModel.role,
        );
        await _firestoreService.createUserProfile(updatedUser);
      }
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Delete user data from Firestore
      // Note: You might want to implement cascade deletion for user's sessions and shots

      // Delete Firebase Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Delete account failed: $e');
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
