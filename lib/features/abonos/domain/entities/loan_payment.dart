import 'package:abonos_app/core/entities/auditable_entity.dart';

class LoanPayment extends AuditableEntity {
  final String id;
  final DateTime date;
  final String loanId;
  final double amount;

  LoanPayment({
    required this.id,
    required this.date,
    required this.loanId,
    required this.amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    super.deletedAt,
  }) : super(
         createdAt: createdAt ?? DateTime.now(),
         updatedAt: updatedAt ?? DateTime.now(),
       );
}
