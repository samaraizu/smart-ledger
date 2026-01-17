import 'package:flutter/foundation.dart';
import 'dart:html' as html show window;

/// Simple storage service that works reliably on Web
class StorageService {
  static const String _apiKeyKey = 'google_vision_api_key';

  /// Save API key to storage
  static Future<void> saveApiKey(String apiKey) async {
    if (kIsWeb) {
      // Use localStorage for web
      html.window.localStorage[_apiKeyKey] = apiKey;
      if (kDebugMode) {
        debugPrint('StorageService: API key saved to localStorage');
      }
    } else {
      // For mobile, we would use SharedPreferences here
      if (kDebugMode) {
        debugPrint('StorageService: Mobile storage not implemented');
      }
    }
  }

  /// Load API key from storage
  static Future<String?> loadApiKey() async {
    if (kIsWeb) {
      // Use localStorage for web
      final apiKey = html.window.localStorage[_apiKeyKey];
      if (kDebugMode) {
        debugPrint('StorageService: API key loaded from localStorage (${apiKey?.length ?? 0} chars)');
      }
      return apiKey;
    } else {
      // For mobile, we would use SharedPreferences here
      if (kDebugMode) {
        debugPrint('StorageService: Mobile storage not implemented');
      }
      return null;
    }
  }

  /// Remove API key from storage
  static Future<void> removeApiKey() async {
    if (kIsWeb) {
      // Use localStorage for web
      html.window.localStorage.remove(_apiKeyKey);
      if (kDebugMode) {
        debugPrint('StorageService: API key removed from localStorage');
      }
    } else {
      // For mobile, we would use SharedPreferences here
      if (kDebugMode) {
        debugPrint('StorageService: Mobile storage not implemented');
      }
    }
  }

  /// Check if API key exists
  static Future<bool> hasApiKey() async {
    final apiKey = await loadApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
}
