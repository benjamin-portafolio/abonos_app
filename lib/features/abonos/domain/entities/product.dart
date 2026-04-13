import 'package:abonos_app/core/entities/auditable_entity.dart';

class Product extends AuditableEntity {
  static const _unset = Object();

  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final int stock;
  final String? categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.stock = 0,
    this.categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    super.deletedAt,
  }) : super(
         createdAt: createdAt ?? DateTime.now(),
         updatedAt: updatedAt ?? DateTime.now(),
       );

  Product copyWith({
    String? id,
    String? name,
    double? price,
    Object? originalPrice = _unset,
    int? stock,
    Object? categoryId = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice:
          identical(originalPrice, _unset)
              ? this.originalPrice
              : originalPrice as double?,
      stock: stock ?? this.stock,
      categoryId:
          identical(categoryId, _unset)
              ? this.categoryId
              : categoryId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt:
          identical(deletedAt, _unset)
              ? this.deletedAt
              : deletedAt as DateTime?,
    );
  }
}
