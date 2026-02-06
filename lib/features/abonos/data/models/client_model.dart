import 'package:abonos_app/features/abonos/domain/entities/client.dart';

class ClientModel extends Client {
  ClientModel({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory ClientModel.fromMap(Map<String, Object?> map) {
    return ClientModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
