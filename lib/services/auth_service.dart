import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication service for Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get user ID
  String? get userId => currentUser?.uid;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  /// Sign in with Google (Web only)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        debugPrint('AuthService: Starting Google sign in...');
      }

      // Create Google Auth Provider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes if needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Sign in with popup (Web only)
      final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      
      if (kDebugMode) {
        debugPrint('AuthService: Sign in successful - User: ${userCredential.user?.email}');
      }
      
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Error signing in with Google: $e');
      }
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        debugPrint('AuthService: Signing out...');
      }
      
      await _auth.signOut();
      
      if (kDebugMode) {
        debugPrint('AuthService: Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Error signing out: $e');
      }
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      if (kDebugMode) {
        debugPrint('AuthService: Deleting account...');
      }
      
      await currentUser?.delete();
      
      if (kDebugMode) {
        debugPrint('AuthService: Account deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Error deleting account: $e');
      }
      rethrow;
    }
  }
}
