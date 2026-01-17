import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/brand.dart';

/// Firestore service for cloud data synchronization
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  FirestoreService({required this.userId});

  // Collection references
  CollectionReference get _expensesCollection =>
      _firestore.collection('users').doc(userId).collection('expenses');
  
  CollectionReference get _categoriesCollection =>
      _firestore.collection('users').doc(userId).collection('categories');
  
  CollectionReference get _brandsCollection =>
      _firestore.collection('users').doc(userId).collection('brands');

  // ==================== EXPENSE OPERATIONS ====================

  /// Get all expenses as a stream (real-time updates)
  Stream<List<Expense>> getExpensesStream() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  /// Get all expenses once
  Future<List<Expense>> getAllExpenses() async {
    try {
      final snapshot = await _expensesCollection
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error getting expenses: $e');
      }
      return [];
    }
  }

  /// Add new expense
  Future<void> addExpense(Expense expense) async {
    try {
      await _expensesCollection.doc(expense.id).set(expense.toMap());
      if (kDebugMode) {
        debugPrint('FirestoreService: Expense added successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error adding expense: $e');
      }
      rethrow;
    }
  }

  /// Update existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      await _expensesCollection.doc(expense.id).update(expense.toMap());
      if (kDebugMode) {
        debugPrint('FirestoreService: Expense updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error updating expense: $e');
      }
      rethrow;
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expensesCollection.doc(expenseId).delete();
      if (kDebugMode) {
        debugPrint('FirestoreService: Expense deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error deleting expense: $e');
      }
      rethrow;
    }
  }

  // ==================== CATEGORY OPERATIONS ====================

  /// Get all categories as a stream
  Stream<List<ExpenseCategory>> getCategoriesStream() {
    return _categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExpenseCategory.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  /// Get all categories once
  Future<List<ExpenseCategory>> getAllCategories() async {
    try {
      final snapshot = await _categoriesCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExpenseCategory.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error getting categories: $e');
      }
      return [];
    }
  }

  /// Add new category
  Future<void> addCategory(ExpenseCategory category) async {
    try {
      await _categoriesCollection.doc(category.id).set(category.toMap());
      if (kDebugMode) {
        debugPrint('FirestoreService: Category added successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error adding category: $e');
      }
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
      if (kDebugMode) {
        debugPrint('FirestoreService: Category deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error deleting category: $e');
      }
      rethrow;
    }
  }

  /// Initialize default categories if none exist
  Future<void> initializeDefaultCategories() async {
    try {
      final snapshot = await _categoriesCollection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('FirestoreService: Initializing default categories...');
        }
        
        final defaultCategories = ExpenseCategory.getDefaultCategories();
        for (var category in defaultCategories) {
          await addCategory(category);
        }
        
        if (kDebugMode) {
          debugPrint('FirestoreService: Default categories initialized');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error initializing categories: $e');
      }
    }
  }

  // ==================== BRAND OPERATIONS ====================

  /// Get all brands as a stream
  Stream<List<Brand>> getBrandsStream() {
    return _brandsCollection.orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Brand.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  /// Get all brands once
  Future<List<Brand>> getAllBrands() async {
    try {
      final snapshot = await _brandsCollection.orderBy('order').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Brand.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error getting brands: $e');
      }
      return [];
    }
  }

  /// Add new brand
  Future<void> addBrand(Brand brand) async {
    try {
      await _brandsCollection.doc(brand.id).set(brand.toMap());
      if (kDebugMode) {
        debugPrint('FirestoreService: Brand added successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error adding brand: $e');
      }
      rethrow;
    }
  }

  /// Delete brand
  Future<void> deleteBrand(String brandId) async {
    try {
      await _brandsCollection.doc(brandId).delete();
      if (kDebugMode) {
        debugPrint('FirestoreService: Brand deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error deleting brand: $e');
      }
      rethrow;
    }
  }

  // ==================== DATA MIGRATION ====================

  /// Migrate local Hive data to Firestore
  Future<void> migrateFromHive({
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
    required List<Brand> brands,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('FirestoreService: Starting data migration...');
        debugPrint('  - ${expenses.length} expenses');
        debugPrint('  - ${categories.length} categories');
        debugPrint('  - ${brands.length} brands');
      }

      // Batch write for better performance
      final batch = _firestore.batch();

      // Migrate categories
      for (var category in categories) {
        final docRef = _categoriesCollection.doc(category.id);
        batch.set(docRef, category.toMap());
      }

      // Migrate brands
      for (var brand in brands) {
        final docRef = _brandsCollection.doc(brand.id);
        batch.set(docRef, brand.toMap());
      }

      // Migrate expenses
      for (var expense in expenses) {
        final docRef = _expensesCollection.doc(expense.id);
        batch.set(docRef, expense.toMap());
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('FirestoreService: Migration completed successfully!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService: Error during migration: $e');
      }
      rethrow;
    }
  }
}
