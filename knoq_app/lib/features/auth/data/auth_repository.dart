import 'package:firebase_auth/firebase_auth.dart';
import 'package:knoq_app/core/errors/app_exceptions.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? getCurrentUser() => _firebaseAuth.currentUser;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Login failed', e.code);
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration failed', e.code);
    }
  }

  /// Google Sign-In for mobile platforms.
  /// Requires the `google_sign_in` package to be installed and configured
  /// with the correct OAuth client ID in Firebase console.
  ///
  /// Current implementation uses a placeholder that gracefully throws.
  /// Replace the body once google_sign_in is configured with real
  /// SHA-1 fingerprints and OAuth consent screen.
  Future<User?> signInWithGoogle() async {
    // --- Production implementation (uncomment when google_sign_in is configured) ---
    // import 'package:google_sign_in/google_sign_in.dart';
    //
    // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    // if (googleUser == null) return null; // User cancelled
    //
    // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    // final credential = GoogleAuthProvider.credential(
    //   accessToken: googleAuth.accessToken,
    //   idToken: googleAuth.idToken,
    // );
    // final userCredential = await _firebaseAuth.signInWithCredential(credential);
    // return userCredential.user;
    // --- End production implementation ---

    throw AuthException(
      'Google Sign-In is not yet configured. '
      'Configure SHA-1 fingerprint and OAuth client ID first.',
      'google_sign_in_not_configured',
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to send reset link', e.code);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> deleteAccount(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('Not authenticated');

    try {
      // Re-authenticate before delete
      final authCred = EmailAuthProvider.credential(
          email: user.email!, password: password);
      await user.reauthenticateWithCredential(authCred);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to delete account', e.code);
    }
  }
}
