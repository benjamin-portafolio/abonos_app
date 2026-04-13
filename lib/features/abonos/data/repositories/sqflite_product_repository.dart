import 'package:abonos_app/features/abonos/data/datasources/app_database.dart';
import 'package:abonos_app/features/abonos/data/models/product_model.dart';
import 'package:abonos_app/features/abonos/domain/entities/product.dart';
import 'package:abonos_app/features/abonos/domain/repositories/product_repository.dart';

class SqfliteProductRepository implements ProductRepository {
  SqfliteProductRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<List<Product>> getAll({bool includeDeleted = false}) async {
    final db = await _database.database;
    final rows = await db.query(
      'producto',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    return rows.map(ProductModel.fromMap).toList();
  }

  @override
  Future<void> add(Product product) async {
    final db = await _database.database;
    final now = DateTime.now();
    final model = ProductModel(
      id: product.id,
      name: product.name,
      price: product.price,
      originalPrice: product.originalPrice,
      stock: product.stock,
      categoryId: product.categoryId,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('producto', model.toMap());
  }

  @override
  Future<void> update(Product product) async {
    final db = await _database.database;
    final model = ProductModel(
      id: product.id,
      name: product.name,
      price: product.price,
      originalPrice: product.originalPrice,
      stock: product.stock,
      categoryId: product.categoryId,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      deletedAt: product.deletedAt,
    );

    await db.update(
      'producto',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }
}
