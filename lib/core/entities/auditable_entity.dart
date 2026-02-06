abstract class AuditableEntity {
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  AuditableEntity({
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
}
