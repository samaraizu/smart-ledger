import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/brand.dart';

class ExpenseService extends ChangeNotifier {
  static const String _expenseBoxName = 'expenses';
  static const String _categoryBoxName = 'categories';
  static const String _brandBoxName = 'brands';
  
  Box<Expense>? _expenseBox;
  Box<ExpenseCategory>? _categoryBox;
  Box<Brand>? _brandBox;
  
  bool _isInitialized = false;
  final String? userId;

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
    
    _isInitialized = true;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  // Expense operations
  List<Expense> getAllExpenses() {
    return _expenseBox?.values.toList() ?? [];
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseBox?.put(expense.id, expense);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseBox?.put(expense.id, expense);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox?.delete(id);
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
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox?.delete(id);
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
    notifyListeners();
  }

  Future<void> deleteBrand(String id) async {
    await _brandBox?.delete(id);
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
