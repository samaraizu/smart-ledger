import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/brand.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's expenses collection
  CollectionReference _getUserExpensesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  // Get user's categories collection
  CollectionReference _getUserCategoriesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  // Get user's brands collection
  CollectionReference _getUserBrandsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('brands');
  }

  // ============================================================
  // EXPENSE OPERATIONS
  // ============================================================

  // Save expense to Firestore
  Future<void> saveExpense(String userId, Expense expense) async {
    await _getUserExpensesCollection(userId)
        .doc(expense.id)
        .set(expense.toMap());
  }

  // Get all expenses for a user
  Future<List<Expense>> getExpenses(String userId) async {
    final querySnapshot = await _getUserExpensesCollection(userId).get();
    return querySnapshot.docs
        .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream expenses (real-time updates)
  Stream<List<Expense>> streamExpenses(String userId) {
    return _getUserExpensesCollection(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Update expense
  Future<void> updateExpense(String userId, Expense expense) async {
    await _getUserExpensesCollection(userId)
        .doc(expense.id)
        .update(expense.toMap());
  }

  // Delete expense
  Future<void> deleteExpense(String userId, String expenseId) async {
    await _getUserExpensesCollection(userId).doc(expenseId).delete();
  }

  // ============================================================
  // CATEGORY OPERATIONS
  // ============================================================

  // Save category to Firestore
  Future<void> saveCategory(String userId, ExpenseCategory category) async {
    await _getUserCategoriesCollection(userId)
        .doc(category.id)
        .set(category.toMap());
  }

  // Get all categories for a user
  Future<List<ExpenseCategory>> getCategories(String userId) async {
    final querySnapshot = await _getUserCategoriesCollection(userId).get();
    return querySnapshot.docs
        .map((doc) =>
            ExpenseCategory.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream categories (real-time updates)
  Stream<List<ExpenseCategory>> streamCategories(String userId) {
    return _getUserCategoriesCollection(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  ExpenseCategory.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Update category
  Future<void> updateCategory(String userId, ExpenseCategory category) async {
    await _getUserCategoriesCollection(userId)
        .doc(category.id)
        .update(category.toMap());
  }

  // Delete category
  Future<void> deleteCategory(String userId, String categoryId) async {
    await _getUserCategoriesCollection(userId).doc(categoryId).delete();
  }

  // ============================================================
  // BRAND OPERATIONS
  // ============================================================

  // Save brand to Firestore
  Future<void> saveBrand(String userId, Brand brand) async {
    await _getUserBrandsCollection(userId).doc(brand.id).set(brand.toMap());
  }

  // Get all brands for a user
  Future<List<Brand>> getBrands(String userId) async {
    final querySnapshot = await _getUserBrandsCollection(userId).get();
    return querySnapshot.docs
        .map((doc) => Brand.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Stream brands (real-time updates)
  Stream<List<Brand>> streamBrands(String userId) {
    return _getUserBrandsCollection(userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Brand.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Update brand
  Future<void> updateBrand(String userId, Brand brand) async {
    await _getUserBrandsCollection(userId).doc(brand.id).update(brand.toMap());
  }

  // Delete brand
  Future<void> deleteBrand(String userId, String brandId) async {
    await _getUserBrandsCollection(userId).doc(brandId).delete();
  }

  // ============================================================
  // BULK OPERATIONS
  // ============================================================

  // Migrate all local data to Firestore
  Future<void> migrateLocalData(
    String userId,
    List<Expense> expenses,
    List<ExpenseCategory> categories,
    List<Brand> brands,
  ) async {
    final batch = _firestore.batch();

    // Migrate expenses
    for (final expense in expenses) {
      final docRef = _getUserExpensesCollection(userId).doc(expense.id);
      batch.set(docRef, expense.toMap());
    }

    // Migrate categories
    for (final category in categories) {
      final docRef = _getUserCategoriesCollection(userId).doc(category.id);
      batch.set(docRef, category.toMap());
    }

    // Migrate brands
    for (final brand in brands) {
      final docRef = _getUserBrandsCollection(userId).doc(brand.id);
      batch.set(docRef, brand.toMap());
    }

    await batch.commit();
  }
}
