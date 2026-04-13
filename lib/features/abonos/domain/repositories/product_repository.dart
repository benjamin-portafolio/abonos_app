import 'package:abonos_app/features/abonos/domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAll({bool includeDeleted = false});
  Future<void> add(Product product);
  Future<void> update(Product product);
}
