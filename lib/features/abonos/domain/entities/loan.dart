import 'package:abonos_app/core/entities/auditable_entity.dart';

class Loan extends AuditableEntity {
  static const _unset = Object();

  final String id;
  final String clientId;
  final DateTime date;
  final double extraPercentage;
  final double loanAmount;
  final double paidAmount;
  final bool isPaid;
  final bool isActive;

  Loan({
    required this.id,
    required this.clientId,
    required this.date,
    this.extraPercentage = 0,
    required this.loanAmount,
    required this.paidAmount,
    required this.isPaid,
    this.isActive = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    super.deletedAt,
  }) : super(
         createdAt: createdAt ?? DateTime.now(),
         updatedAt: updatedAt ?? DateTime.now(),
       );

  Loan copyWith({
    String? id,
    String? clientId,
    DateTime? date,
    double? extraPercentage,
    double? loanAmount,
    double? paidAmount,
    bool? isPaid,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    return Loan(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      extraPercentage: extraPercentage ?? this.extraPercentage,
      loanAmount: loanAmount ?? this.loanAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      isPaid: isPaid ?? this.isPaid,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt:
          identical(deletedAt, _unset)
              ? this.deletedAt
              : deletedAt as DateTime?,
    );
  }

  double get pendingAmount {
    final pending = loanAmount - paidAmount;
    return pending < 0 ? 0 : pending;
  }
}
