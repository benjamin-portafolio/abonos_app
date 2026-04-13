import 'package:abonos_app/core/entities/auditable_entity.dart';

class Category extends AuditableEntity {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    super.deletedAt,
  }) : super(
         createdAt: createdAt ?? DateTime.now(),
         updatedAt: updatedAt ?? DateTime.now(),
       );
}
