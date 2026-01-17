import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'google_vision_service.dart';
import 'package:http/http.dart' as http;

class ReceiptProcessingService {
  final Random _random = Random();
  final GoogleVisionService _visionService;

  ReceiptProcessingService(this._visionService);

  /// Process receipt with real OCR if API key is configured, otherwise simulate
  Future<Expense> processReceipt(String imagePath) async {
    try {
      if (kDebugMode) {
        debugPrint('ReceiptProcessingService: Processing receipt at path: $imagePath');
        debugPrint('ReceiptProcessingService: API configured: ${_visionService.isConfigured}');
      }
      
      if (_visionService.isConfigured) {
        // Use real OCR
        if (kDebugMode) {
          debugPrint('ReceiptProcessingService: Using OCR for processing');
        }
        return await _processReceiptWithOCR(imagePath);
      } else {
        // Fallback to simulation
        if (kDebugMode) {
          debugPrint('ReceiptProcessingService: Using simulation (API not configured)');
        }
        return await _simulateReceiptProcessing(imagePath);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ReceiptProcessingService: Error processing receipt: $e');
        debugPrint('ReceiptProcessingService: Stack trace: $stackTrace');
      }
      // Fallback to simulation on error
      return await _simulateReceiptProcessing(imagePath);
    }
  }

  /// Process receipt using Google Cloud Vision API
  Future<Expense> _processReceiptWithOCR(String imagePath) async {
    if (kDebugMode) {
      debugPrint('OCR: Starting OCR processing for $imagePath');
    }
    
    try {
      if (kDebugMode) {
        debugPrint('OCR: Reading image file from: $imagePath');
      }
      
      // For web, imagePath is actually a blob URL or data URL
      // We need to fetch it using HTTP
      String base64Image;
      
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('OCR: Web platform detected, fetching image via HTTP...');
        }
        
        // Fetch the blob URL
        final response = await http.get(Uri.parse(imagePath));
        
        if (response.statusCode == 200) {
          final imageBytes = response.bodyBytes;
          
          if (kDebugMode) {
            debugPrint('OCR: Image fetched successfully (${imageBytes.length} bytes)');
          }
          
          base64Image = base64Encode(imageBytes);
        } else {
          throw Exception('Failed to fetch image: ${response.statusCode}');
        }
      } else {
        // For mobile platforms (not implemented yet)
        throw Exception('Mobile platform not yet supported');
      }
      
      if (kDebugMode) {
        debugPrint('OCR: Image encoded to base64 (${base64Image.length} chars)');
      }

      // Extract text from image
      if (kDebugMode) {
        debugPrint('OCR: Calling Google Vision API...');
      }
      
      final extractedText = await _visionService.extractTextFromImage(base64Image);
      
      if (kDebugMode) {
        debugPrint('OCR: Text extracted successfully');
        debugPrint('OCR: Extracted text: $extractedText');
      }

      // Extract expense details
      final amount = _visionService.extractAmount(extractedText);
      final date = _visionService.extractDate(extractedText);
      final merchantName = _visionService.extractMerchantName(extractedText);

      if (kDebugMode) {
        debugPrint('OCR: Amount: ¥${amount ?? "not found"}');
        debugPrint('OCR: Date: ${date ?? "not found"}');
        debugPrint('OCR: Merchant: ${merchantName ?? "not found"}');
      }

      // Try to determine category based on merchant name
      final category = _determineCategoryFromText(extractedText);

      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: category.id,
        cost: amount ?? 1000.0,
        description: merchantName?.isNotEmpty == true ? '${merchantName}での購入' : '経費',
        date: date ?? DateTime.now(),
        merchantName: merchantName ?? '不明な店舗',
        imagePath: imagePath,
        memo: 'OCRから自動抽出',
        reward: 0,
        brandId: null,
      );
      
      if (kDebugMode) {
        debugPrint('OCR: Expense created successfully - Cost: ¥${expense.cost}');
      }
      
      return expense;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('OCR: ERROR in _processReceiptWithOCR: $e');
        debugPrint('OCR: Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Simulate receipt processing (fallback when API key not configured)
  Future<Expense> _simulateReceiptProcessing(String imagePath) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    final categories = ExpenseCategory.getDefaultCategories();
    final category = categories[_random.nextInt(categories.length)];
    
    final merchants = [
      'セブンイレブン',
      'ファミリーマート',
      'ローソン',
      'イオン',
      'スターバックス',
      'マクドナルド',
      'ビックカメラ',
      'ヨドバシカメラ',
      'Amazon',
      'ガソリンスタンド',
    ];

    final descriptions = [
      '事務用品購入',
      'ビジネスランチ',
      '機器メンテナンス',
      '月額サブスクリプション',
      '専門サービス',
      '交通費',
      '接待費',
      'マーケティング資材',
      'ソフトウェアライセンス',
      '出張旅費',
    ];

    // Simulate realistic Japanese receipt amounts
    final basePrices = [
      500, 800, 1000, 1200, 1500, 1800, 2000, 2500, 3000, 3500, 4000, 4500, 5000,
      5500, 6000, 7000, 8000, 9000, 10000, 12000, 15000, 18000, 20000, 25000, 30000
    ];
    
    final cost = basePrices[_random.nextInt(basePrices.length)].toDouble();
    
    return Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: category.id,
      cost: cost,
      description: descriptions[_random.nextInt(descriptions.length)],
      date: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      merchantName: merchants[_random.nextInt(merchants.length)],
      imagePath: imagePath,
      memo: 'シミュレーション（API未設定）',
      reward: 0,
      brandId: null,
    );
  }

  /// Determine category from text content
  ExpenseCategory _determineCategoryFromText(String text) {
    final categories = ExpenseCategory.getDefaultCategories();
    
    // Food & Dining keywords
    if (text.contains('スターバックス') || text.contains('マクドナルド') || 
        text.contains('レストラン') || text.contains('飲食')) {
      return categories.firstWhere((c) => c.id == 'food');
    }
    
    // Transportation keywords
    if (text.contains('ガソリン') || text.contains('電車') || 
        text.contains('タクシー') || text.contains('交通')) {
      return categories.firstWhere((c) => c.id == 'transport');
    }
    
    // Office supplies keywords
    if (text.contains('文房具') || text.contains('事務') || 
        text.contains('オフィス')) {
      return categories.firstWhere((c) => c.id == 'office');
    }
    
    // Equipment keywords
    if (text.contains('ビックカメラ') || text.contains('ヨドバシ') || 
        text.contains('家電') || text.contains('PC')) {
      return categories.firstWhere((c) => c.id == 'equipment');
    }
    
    // Default to other
    return categories.firstWhere((c) => c.id == 'other');
  }

  /// Simulates credit card statement processing
  Future<List<Expense>> processCreditCardStatement(String imagePath) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 3));

    // Generate multiple expenses from statement
    final expenseCount = 5 + _random.nextInt(10); // 5-15 expenses
    final expenses = <Expense>[];

    for (int i = 0; i < expenseCount; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final expense = await processReceipt(imagePath);
      expenses.add(expense);
    }

    return expenses;
  }
}
