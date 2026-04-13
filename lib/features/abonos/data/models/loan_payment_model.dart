import 'package:abonos_app/features/abonos/domain/entities/loan_payment.dart';

class LoanPaymentModel extends LoanPayment {
  LoanPaymentModel({
    required super.id,
    required super.date,
    required super.loanId,
    required super.amount,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory LoanPaymentModel.fromMap(Map<String, Object?> map) {
    return LoanPaymentModel(
      id: map['id'] as String,
      date: DateTime.parse(map['fecha'] as String),
      loanId: map['id_prestamo'] as String,
      amount: (map['cantidad'] as num).toDouble(),
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
      'fecha': date.toIso8601String(),
      'id_prestamo': loanId,
      'cantidad': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
