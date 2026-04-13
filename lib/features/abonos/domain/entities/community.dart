import 'package:abonos_app/core/entities/auditable_entity.dart';

class Community extends AuditableEntity {
  final String id;
  final String name;
  final String paymentDay;

  Community({
    required this.id,
    required this.name,
    required this.paymentDay,
    DateTime? createdAt,
    DateTime? updatedAt,
    super.deletedAt,
  }) : super(
         createdAt: createdAt ?? DateTime.now(),
         updatedAt: updatedAt ?? DateTime.now(),
       );
}
