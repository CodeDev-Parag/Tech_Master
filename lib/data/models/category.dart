import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 5)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  int color;

  @HiveField(4)
  DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
