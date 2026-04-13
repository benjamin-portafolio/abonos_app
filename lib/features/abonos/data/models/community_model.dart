import 'package:abonos_app/features/abonos/domain/entities/community.dart';

class CommunityModel extends Community {
  CommunityModel({
    required super.id,
    required super.name,
    required super.paymentDay,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CommunityModel.fromMap(Map<String, Object?> map) {
    return CommunityModel(
      id: map['id'] as String,
      name: map['nombre'] as String,
      paymentDay: map['dia_pago'] as String,
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
      'dia_pago': paymentDay,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
