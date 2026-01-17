import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String categoryId;

  @HiveField(2)
  double cost; // Renamed from amount - Cost in JPY

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime date; // Payment date on receipt

  @HiveField(5)
  String? merchantName;

  @HiveField(6)
  String? imagePath;

  @HiveField(7)
  String? memo; // Renamed from notes - max 100 chars

  @HiveField(8)
  double reward; // Amount to subtract from cost

  @HiveField(9)
  String? brandId; // Brand label

  Expense({
    required this.id,
    required this.categoryId,
    required this.cost,
    required this.description,
    required this.date,
    this.merchantName,
    this.imagePath,
    this.memo,
    this.reward = 0,
    this.brandId,
  });

  // Calculate actual expense (Cost - Reward)
  double get actualAmount => cost - reward;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'cost': cost,
        'description': description,
        'date': date.toIso8601String(),
        'merchantName': merchantName,
        'imagePath': imagePath,
        'memo': memo,
        'reward': reward,
        'brandId': brandId,
      };
  
  // toMap is an alias for toJson for Firestore compatibility
  Map<String, dynamic> toMap() => toJson();

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        cost: (json['cost'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
        merchantName: json['merchantName'] as String?,
        imagePath: json['imagePath'] as String?,
        memo: json['memo'] as String? ?? json['notes'] as String?,
        reward: (json['reward'] as num?)?.toDouble() ?? 0,
        brandId: json['brandId'] as String?,
      );
  
  // fromMap is an alias for fromJson for Firestore compatibility
  factory Expense.fromMap(Map<String, dynamic> map) => Expense.fromJson(map);

  // CSV export format
  String toCsvRow() {
    return [
      date.toIso8601String().split('T')[0],
      categoryId,
      cost.toStringAsFixed(0),
      reward.toStringAsFixed(0),
      actualAmount.toStringAsFixed(0),
      brandId ?? '',
      memo ?? '',
    ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(',');
  }
}
