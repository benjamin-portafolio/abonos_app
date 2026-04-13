import 'package:abonos_app/features/abonos/domain/entities/loan_product.dart';

class LoanProductModel extends LoanProduct {
  LoanProductModel({
    required super.id,
    required super.productId,
    required super.loanId,
    required super.quantity,
    required super.amount,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory LoanProductModel.fromMap(Map<String, Object?> map) {
    return LoanProductModel(
      id: map['id'] as String,
      productId: map['id_producto'] as String,
      loanId: map['id_prestamo'] as String,
      quantity: (map['cantidad'] as int?) ?? 1,
      amount: (map['importe'] as num?)?.toDouble() ?? 0,
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
      'id_producto': productId,
      'id_prestamo': loanId,
      'cantidad': quantity,
      'importe': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
