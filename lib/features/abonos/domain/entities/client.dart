import 'package:abonos_app/core/entities/auditable_entity.dart';

class Client extends AuditableEntity {
  final String id;
  final String name;

  Client({
    required this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) : super(
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt ?? DateTime.now(),
          deletedAt: deletedAt,
        );

  Client copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
