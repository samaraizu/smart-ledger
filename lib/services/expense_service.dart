import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/brand.dart';
import 'firestore_service.dart';

class ExpenseService extends ChangeNotifier {
  static const String _expenseBoxName = 'expenses';
  static const String _categoryBoxName = 'categories';
  static const String _brandBoxName = 'brands';
  static const String _migrationKey = 'has_migrated_to_firestore';
  
  Box<Expense>? _expenseBox;
  Box<ExpenseCategory>? _categoryBox;
  Box<Brand>? _brandBox;
  
  bool _isInitialized = false;
  final String? userId;
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _brandsSubscription;

  ExpenseService({this.userId});

  Future<void> init() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExpenseCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BrandAdapter());
    }
    
    // Open Hive boxes
    _expenseBox = await Hive.openBox<Expense>(_expenseBoxName);
    _categoryBox = await Hive.openBox<ExpenseCategory>(_categoryBoxName);
    _brandBox = await Hive.openBox<Brand>(_brandBoxName);
    
    // Initialize default categories if box is empty
    if (_categoryBox!.isEmpty) {
      final defaultCategories = ExpenseCategory.getDefaultCategories();
      for (var category in defaultCategories) {
        await _categoryBox!.put(category.id, category);
      }
    }
    
    // If user is logged in, sync with Firestore
    if (userId != null) {
      await _syncWithFirestore();
      _setupRealtimeListeners();
    }
    
    _isInitialized = true;
    notifyListeners();
  }
  
  // Migrate local data to Firestore (one-time operation)
  Future<void> _syncWithFirestore() async {
    if (userId == null) return;
    
    try {
      final prefs = await Hive.openBox('settings');
      final migrationKey = '${_migrationKey}_$userId';
      final hasMigrated = prefs.get(migrationKey, defaultValue: false);
      
      if (!hasMigrated) {
        // This is the first time logging in with this password
        // Migrate local data to Firestore
        final expenses = getAllExpenses();
        final categories = getAllCategories();
        final brands = getAllBrands();
        
        if (expenses.isNotEmpty || categories.isNotEmpty || brands.isNotEmpty) {
          await _firestoreService.migrateLocalData(
            userId!,
            expenses,
            categories,
            brands,
          );
          
          await prefs.put(migrationKey, true);
          
          if (kDebugMode) {
            print('✅ Local data migrated to Firestore');
          }
        }
      } else {
        // Load data from Firestore
        await _loadFromFirestore();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing with Firestore: $e');
      }
    }
  }
  
  // Load data from Firestore to local Hive
  Future<void> _loadFromFirestore() async {
    if (userId == null) return;
    
    try {
      // Load expenses
      final expenses = await _firestoreService.getExpenses(userId!);
      await _expenseBox!.clear();
      for (final expense in expenses) {
        await _expenseBox!.put(expense.id, expense);
      }
      
      // Load categories
      final categories = await _firestoreService.getCategories(userId!);
      if (categories.isNotEmpty) {
        await _categoryBox!.clear();
        for (final category in categories) {
          await _categoryBox!.put(category.id, category);
        }
      }
      
      // Load brands
      final brands = await _firestoreService.getBrands(userId!);
      await _brandBox!.clear();
      for (final brand in brands) {
        await _brandBox!.put(brand.id, brand);
      }
      
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Data loaded from Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading from Firestore: $e');
      }
    }
  }
  
  // Setup real-time listeners for Firestore changes
  void _setupRealtimeListeners() {
    if (userId == null) return;
    
    // Listen to expenses changes
    _expensesSubscription = _firestoreService.streamExpenses(userId!).listen(
      (expenses) async {
        await _expenseBox!.clear();
        for (final expense in expenses) {
          await _expenseBox!.put(expense.id, expense);
        }
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ Error in expenses stream: $error');
        }
      },
    );
    
    // Listen to categories changes
    _categoriesSubscription = _firestoreService.streamCategories(userId!).listen(
      (categories) async {
        if (categories.isNotEmpty) {
          await _categoryBox!.clear();
          for (final category in categories) {
            await _categoryBox!.put(category.id, category);
          }
          notifyListeners();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ Error in categories stream: $error');
        }
      },
    );
    
    // Listen to brands changes
    _brandsSubscription = _firestoreService.streamBrands(userId!).listen(
      (brands) async {
        await _brandBox!.clear();
        for (final brand in brands) {
          await _brandBox!.put(brand.id, brand);
        }
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ Error in brands stream: $error');
        }
      },
    );
  }
  
  @override
  void dispose() {
    _expensesSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _brandsSubscription?.cancel();
    super.dispose();
  }

  // Expense operations
  List<Expense> getAllExpenses() {
    return _expenseBox?.values.toList() ?? [];
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseBox?.put(expense.id, expense);
    
    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestoreService.saveExpense(userId!, expense);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error saving expense to Firestore: $e');
        }
      }
    }
    
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseBox?.put(expense.id, expense);
    
    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestoreService.updateExpense(userId!, expense);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error updating expense in Firestore: $e');
        }
      }
    }
    
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox?.delete(id);
    
    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestoreService.deleteExpense(userId!, id);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error deleting expense from Firestore: $e');
        }
      }
    }
    
    notifyListeners();
  }

  // Category operations
  List<ExpenseCategory> getAllCategories() {
    return _categoryBox?.values.toList() ?? [];
  }

  ExpenseCategory? getCategoryById(String id) {
    return _categoryBox?.get(id);
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _categoryBox?.put(category.id, category);
    
    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestoreService.saveCategory(userId!, category);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error saving category to Firestore: $e');
        }
      }
    }
    
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox?.delete(id);
    
    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestoreService.deleteCategory(userId!, id);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error deleting category from Firestore: $e');
        }
      }
    }
    
    notifyListeners();
  }

  // Brand operations
  List<Brand> getAllBrands() {
    final brands = _brandBox?.values.toList() ?? [];
    brands.sort((a, b) => a.order.compareTo(b.order));
    return brands;
  }

  Brand? getBrandById(String id) {
    return _brandBox?.get(id);
  }

  Future<void> addBrand(Brand brand) async {
    await _brandBox?.put(brand.id, brand);
    
    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestoreService.saveBrand(userId!, brand);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error saving brand to Firestore: $e');
        }
      }
    }
    
    notifyListeners();
  }

  Future<void> deleteBrand(String id) async {
    await _brandBox?.delete(id);
    
    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestoreService.deleteBrand(userId!, id);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error deleting brand from Firestore: $e');
        }
      }
    }
    
    notifyListeners();
  }

  // Dashboard data - use actualAmount (cost - reward)
  Map<String, double> getCategoryTotals() {
    final expenses = getAllExpenses();
    final totals = <String, double>{};
    
    for (var expense in expenses) {
      totals[expense.categoryId] = 
          (totals[expense.categoryId] ?? 0) + expense.actualAmount;
    }
    
    return totals;
  }

  double getTotalExpenses() {
    return getAllExpenses().fold(0, (sum, expense) => sum + expense.actualAmount);
  }

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return getAllExpenses()
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .toList();
  }

  Map<String, double> getMonthlyTotals() {
    final expenses = getAllExpenses();
    final totals = <String, double>{};
    
    for (var expense in expenses) {
      final monthKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      totals[monthKey] = (totals[monthKey] ?? 0) + expense.actualAmount;
    }
    
    return totals;
  }

  // CSV Export
  String exportToCsv() {
    final expenses = getAllExpenses();
    expenses.sort((a, b) => a.date.compareTo(b.date));
    
    // CSV header
    final header = 'Date,Category,Cost,Reward,Actual Amount,Brand,Memo\n';
    
    // CSV rows
    final rows = expenses.map((expense) => expense.toCsvRow()).join('\n');
    
    return header + rows;
  }
}
