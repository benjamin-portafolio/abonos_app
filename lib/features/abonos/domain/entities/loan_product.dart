import 'package:abonos_app/core/entities/auditable_entity.dart';

class LoanProduct extends AuditableEntity {
  static const _unset = Object();

  final String id;
  final String productId;
  final String loanId;
  final int quantity;
  final double amount;

  LoanProduct({
    required this.id,
    required this.productId,
    required this.loanId,
    required this.quantity,
    required this.amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    super.deletedAt,
  }) : super(
         createdAt: createdAt ?? DateTime.now(),
         updatedAt: updatedAt ?? DateTime.now(),
       );

  LoanProduct copyWith({
    String? id,
    String? productId,
    String? loanId,
    int? quantity,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return LoanProduct(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      loanId: loanId ?? this.loanId,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt:
          identical(deletedAt, _unset)
              ? this.deletedAt
              : deletedAt as DateTime?,
    );
  }
}
