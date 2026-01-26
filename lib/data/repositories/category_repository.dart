import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../../core/constants/app_constants.dart';

class CategoryRepository {
  late Box<Category> _categoryBox;
  final _uuid = const Uuid();

  Future<void> init() async {
    _categoryBox = await Hive.openBox<Category>(AppConstants.categoriesBox);

    // Initialize default categories if empty
    if (_categoryBox.isEmpty) {
      await _initDefaultCategories();
    }
  }

  Future<void> _initDefaultCategories() async {
    for (final cat in AppConstants.defaultCategories) {
      final category = Category(
        id: _uuid.v4(),
        name: cat['name'] as String,
        icon: cat['icon'] as String,
        color: cat['color'] as int,
        createdAt: DateTime.now(),
      );
      await _categoryBox.put(category.id, category);
    }
  }

  List<Category> getAllCategories() {
    return _categoryBox.values.toList();
  }

  Category? getCategoryById(String id) {
    try {
      return _categoryBox.values.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addCategory(Category category) async {
    await _categoryBox.put(category.id, category);
  }

  Future<void> updateCategory(Category category) async {
    await _categoryBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }
}
