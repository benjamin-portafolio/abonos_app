import 'package:abonos_app/features/abonos/domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.name,
    required super.price,
    super.originalPrice,
    required super.stock,
    super.categoryId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory ProductModel.fromMap(Map<String, Object?> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['nombre'] as String,
      price: (map['precio'] as num).toDouble(),
      originalPrice: (map['precio_original'] as num?)?.toDouble(),
      stock: (map['existencia'] as int?) ?? 0,
      categoryId: map['id_categoria'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt:
          map['deleted_at'] == null
              ? null
              : DateTime.parse(map['deleted_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nombre': name,
      'precio': price,
      'precio_original': originalPrice,
      'existencia': stock,
      'id_categoria': categoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
