import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class GoogleVisionService {
  String? _apiKey;

  // Initialize and load API key from storage
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('GoogleVisionService: Initializing...');
      }
      
      final apiKey = await StorageService.loadApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        _apiKey = apiKey;
        if (kDebugMode) {
          debugPrint('GoogleVisionService: API key loaded successfully (${apiKey.length} chars)');
        }
      } else {
        _apiKey = null;
        if (kDebugMode) {
          debugPrint('GoogleVisionService: No API key found in storage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GoogleVisionService: Error loading API key: $e');
      }
      _apiKey = null;
    }
  }

  // Set API key
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  // Check if API key is configured
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Extract text from image using Google Cloud Vision API
  Future<String> extractTextFromImage(String base64Image) async {
    if (!isConfigured) {
      throw Exception('Google Cloud Vision API key not configured');
    }

    if (kDebugMode) {
      debugPrint('GoogleVisionService: Starting text extraction...');
      debugPrint('GoogleVisionService: API Key configured: ${_apiKey?.substring(0, 10)}...');
    }

    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey',
    );

    final requestBody = {
      'requests': [
        {
          'image': {
            'content': base64Image,
          },
          'features': [
            {
              'type': 'TEXT_DETECTION',
              'maxResults': 1,
            }
          ],
        }
      ]
    };

    try {
      if (kDebugMode) {
        debugPrint('GoogleVisionService: Sending request to Google Vision API...');
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        debugPrint('GoogleVisionService: Response status code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (kDebugMode) {
          debugPrint('GoogleVisionService: Response parsed successfully');
        }
        
        if (data['responses'] != null &&
            data['responses'].isNotEmpty &&
            data['responses'][0]['textAnnotations'] != null &&
            data['responses'][0]['textAnnotations'].isNotEmpty) {
          // Get full text
          final fullText = data['responses'][0]['textAnnotations'][0]['description'] as String;
          
          if (kDebugMode) {
            debugPrint('GoogleVisionService: Text extracted successfully (${fullText.length} chars)');
          }
          
          return fullText;
        } else {
          if (kDebugMode) {
            debugPrint('GoogleVisionService: No text detected in image');
            debugPrint('GoogleVisionService: Response data: $data');
          }
          throw Exception('No text detected in image');
        }
      } else {
        final error = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('GoogleVisionService: API Error (${response.statusCode}): $error');
        }
        throw Exception('API Error: ${error['error']['message']}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GoogleVisionService: Exception occurred: $e');
      }
      rethrow;
    }
  }

  /// Extract amount from Japanese receipt text
  double? extractAmount(String text) {
    // Remove all whitespace and newlines for easier pattern matching
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ');
    
    if (kDebugMode) {
      debugPrint('Extracting amount from text: $cleanText');
    }

    // Pattern 1: Look for 合計 (total) followed by amount
    // Examples: 合計 ¥3,280, 合計 3,280円, 合計：¥3,280
    final totalPatterns = [
      RegExp(r'合計[：:]*\s*¥?\s*([0-9,]+)\s*円?'),
      RegExp(r'ご請求額[：:]*\s*¥?\s*([0-9,]+)\s*円?'),
      RegExp(r'お支払い金額[：:]*\s*¥?\s*([0-9,]+)\s*円?'),
      RegExp(r'小計[：:]*\s*¥?\s*([0-9,]+)\s*円?'),
    ];

    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        final amount = double.tryParse(amountStr ?? '');
        if (amount != null) {
          if (kDebugMode) {
            debugPrint('Found total amount: ¥$amount');
          }
          return amount;
        }
      }
    }

    // Pattern 2: Look for ¥ followed by numbers
    // Examples: ¥3,280, ¥ 3,280
    final yenPattern = RegExp(r'¥\s*([0-9,]+)');
    final yenMatches = yenPattern.allMatches(cleanText);
    final amounts = <double>[];
    
    for (final match in yenMatches) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      final amount = double.tryParse(amountStr ?? '');
      if (amount != null && amount > 0) {
        amounts.add(amount);
      }
    }

    // Pattern 3: Look for numbers followed by 円
    // Examples: 3,280円, 3280円
    final yenSuffixPattern = RegExp(r'([0-9,]+)\s*円');
    final yenSuffixMatches = yenSuffixPattern.allMatches(cleanText);
    
    for (final match in yenSuffixMatches) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      final amount = double.tryParse(amountStr ?? '');
      if (amount != null && amount > 0) {
        amounts.add(amount);
      }
    }

    // Return the largest amount found (likely to be the total)
    if (amounts.isNotEmpty) {
      amounts.sort();
      final maxAmount = amounts.last;
      if (kDebugMode) {
        debugPrint('Found amounts: $amounts, using max: ¥$maxAmount');
      }
      return maxAmount;
    }

    if (kDebugMode) {
      debugPrint('No amount found in text');
    }
    return null;
  }

  /// Extract date from Japanese receipt text
  DateTime? extractDate(String text) {
    // Pattern: YYYY年MM月DD日, YYYY/MM/DD, YYYY-MM-DD
    final datePatterns = [
      RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日'),
      RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})'),
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          return DateTime(year, month, day);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing date: $e');
          }
        }
      }
    }

    return null;
  }

  /// Extract merchant name from Japanese receipt text
  String? extractMerchantName(String text) {
    // Common Japanese store names
    final stores = [
      'セブンイレブン', 'ファミリーマート', 'ローソン', 
      'イオン', 'スターバックス', 'マクドナルド',
      'ビックカメラ', 'ヨドバシカメラ', 'Amazon',
      'コンビニ', '飲食店', 'スーパー',
    ];

    for (final store in stores) {
      if (text.contains(store)) {
        return store;
      }
    }

    // Try to get first line as merchant name
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      return lines.first.trim();
    }

    return null;
  }
}
