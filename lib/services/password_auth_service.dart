import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class PasswordAuthService {
  static const String _authBoxName = 'auth_data';
  static const String _userIdKey = 'user_id';
  static const String _passwordHashKey = 'password_hash';

  Box? _authBox;

  // Initialize Hive box
  Future<void> init() async {
    _authBox = await Hive.openBox(_authBoxName);
  }

  // Generate user ID from password (SHA-256 hash)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Check if user is logged in
  bool get isLoggedIn {
    return _authBox?.get(_userIdKey) != null;
  }

  // Get current user ID
  String? get userId {
    return _authBox?.get(_userIdKey);
  }

  // Login with password
  Future<String> login(String password) async {
    if (password.isEmpty) {
      throw Exception('パスワードを入力してください');
    }

    if (password.length < 6) {
      throw Exception('パスワードは6文字以上にしてください');
    }

    // Hash password to create user ID
    final userId = _hashPassword(password);
    final passwordHash = _hashPassword(password); // Store hash for verification

    // Save to local storage
    await _authBox?.put(_userIdKey, userId);
    await _authBox?.put(_passwordHashKey, passwordHash);

    return userId;
  }

  // Verify password (for password change)
  bool verifyPassword(String password) {
    final currentHash = _authBox?.get(_passwordHashKey);
    if (currentHash == null) return false;

    final inputHash = _hashPassword(password);
    return currentHash == inputHash;
  }

  // Change password
  Future<String> changePassword(String oldPassword, String newPassword) async {
    if (!verifyPassword(oldPassword)) {
      throw Exception('現在のパスワードが正しくありません');
    }

    if (newPassword.isEmpty) {
      throw Exception('新しいパスワードを入力してください');
    }

    if (newPassword.length < 6) {
      throw Exception('新しいパスワードは6文字以上にしてください');
    }

    // Generate new user ID
    final newUserId = _hashPassword(newPassword);
    final newPasswordHash = _hashPassword(newPassword);

    // Save new credentials
    await _authBox?.put(_userIdKey, newUserId);
    await _authBox?.put(_passwordHashKey, newPasswordHash);

    return newUserId;
  }

  // Logout (clear local storage)
  Future<void> logout() async {
    await _authBox?.clear();
  }

  // Get masked user ID for display (first 8 characters)
  String get maskedUserId {
    final id = userId;
    if (id == null || id.length < 8) return 'Unknown';
    return '${id.substring(0, 8)}...';
  }
}
