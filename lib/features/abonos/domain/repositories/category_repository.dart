import 'package:abonos_app/features/abonos/domain/entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll({bool includeDeleted = false});
  Future<void> add(Category category);
}
