import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class ExpenseCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  IconData icon;

  @HiveField(3)
  Color color;

  @HiveField(4)
  bool isDefault;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });
  
  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'isDefault': isDefault,
    };
  }
  
  // Create from Map for Firestore
  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(
        map['iconCodePoint'] as int,
        fontFamily: map['iconFontFamily'] as String?,
      ),
      color: Color(map['colorValue'] as int),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  static List<ExpenseCategory> getDefaultCategories() {
    return [
      ExpenseCategory(
        id: 'food',
        name: 'Food & Dining',
        icon: Icons.restaurant,
        color: const Color(0xFF1A237E),
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'transport',
        name: 'Transportation',
        icon: Icons.directions_car,
        color: const Color(0xFF263238),
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'utilities',
        name: 'Utilities',
        icon: Icons.lightbulb_outline,
        color: const Color(0xFF37474F),
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'office',
        name: 'Office Supplies',
        icon: Icons.business_center,
        color: const Color(0xFF455A64),
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'equipment',
        name: 'Equipment',
        icon: Icons.computer,
        color: const Color(0xFF546E7A),
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'marketing',
        name: 'Marketing',
        icon: Icons.campaign,
        color: const Color(0xFF607D8B),
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'communication',
        name: 'Communication',
        icon: Icons.phone,
        color: const Color(0xFF78909C),
        isDefault: true,
      ),
      ExpenseCategory(
        id: 'other',
        name: 'Other',
        icon: Icons.more_horiz,
        color: const Color(0xFF90A4AE),
        isDefault: true,
      ),
    ];
  }
}
