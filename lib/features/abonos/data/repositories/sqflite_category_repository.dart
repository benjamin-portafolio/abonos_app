import 'package:abonos_app/features/abonos/data/datasources/app_database.dart';
import 'package:abonos_app/features/abonos/data/models/category_model.dart';
import 'package:abonos_app/features/abonos/domain/entities/category.dart';
import 'package:abonos_app/features/abonos/domain/repositories/category_repository.dart';

class SqfliteCategoryRepository implements CategoryRepository {
  SqfliteCategoryRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<List<Category>> getAll({bool includeDeleted = false}) async {
    final db = await _database.database;
    final rows = await db.query(
      'categoria',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    return rows.map(CategoryModel.fromMap).toList();
  }

  @override
  Future<void> add(Category category) async {
    final db = await _database.database;
    final now = DateTime.now();
    final model = CategoryModel(
      id: category.id,
      name: category.name,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('categoria', model.toMap());
  }
}
