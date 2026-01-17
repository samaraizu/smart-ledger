import 'package:hive/hive.dart';

part 'brand.g.dart';

@HiveType(typeId: 4)
class Brand extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int order;

  Brand({
    required this.id,
    required this.name,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
      };
  
  // toMap is an alias for toJson for Firestore compatibility
  Map<String, dynamic> toMap() => toJson();

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'] as String,
        name: json['name'] as String,
        order: json['order'] as int? ?? 0,
      );
  
  // fromMap is an alias for fromJson for Firestore compatibility
  factory Brand.fromMap(Map<String, dynamic> map) => Brand.fromJson(map);
}
