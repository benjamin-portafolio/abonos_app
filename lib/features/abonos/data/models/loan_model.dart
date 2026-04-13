import 'package:abonos_app/features/abonos/domain/entities/loan.dart';

class LoanModel extends Loan {
  LoanModel({
    required super.id,
    required super.clientId,
    required super.date,
    required super.extraPercentage,
    required super.loanAmount,
    required super.paidAmount,
    required super.isPaid,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory LoanModel.fromMap(Map<String, Object?> map) {
    return LoanModel(
      id: map['id'] as String,
      clientId: map['id_cliente'] as String,
      date: DateTime.parse(map['fecha'] as String),
      extraPercentage: (map['porcentaje_extra'] as num?)?.toDouble() ?? 0,
      loanAmount: (map['cantidad_prestada'] as num).toDouble(),
      paidAmount: (map['cantidad_pagada'] as num).toDouble(),
      isPaid: ((map['pagado'] as int?) ?? 0) == 1,
      isActive: ((map['activo'] as int?) ?? 0) == 1,
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
      'id_cliente': clientId,
      'fecha': date.toIso8601String(),
      'porcentaje_extra': extraPercentage,
      'cantidad_prestada': loanAmount,
      'cantidad_pagada': paidAmount,
      'pagado': isPaid ? 1 : 0,
      'activo': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
