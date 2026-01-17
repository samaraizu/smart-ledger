import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user display name
  String? get displayName => _auth.currentUser?.displayName;

  // Sign in with Google (Web only)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web platform: Use popup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Add scopes for more permissions
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        
        if (kDebugMode) {
          print('✅ Google Sign-In successful: ${userCredential.user?.email}');
        }
        
        return userCredential;
      } else {
        // Mobile platforms not supported yet
        throw UnsupportedError('Google Sign-In is only supported on Web platform');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Sign-In error: $e');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (kDebugMode) {
        print('✅ Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out error: $e');
      }
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      if (kDebugMode) {
        print('✅ Account deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete account error: $e');
      }
      rethrow;
    }
  }
}
