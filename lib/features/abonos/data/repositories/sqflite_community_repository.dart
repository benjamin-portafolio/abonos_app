import 'package:abonos_app/features/abonos/data/datasources/app_database.dart';
import 'package:abonos_app/features/abonos/data/models/community_model.dart';
import 'package:abonos_app/features/abonos/domain/entities/community.dart';
import 'package:abonos_app/features/abonos/domain/repositories/community_repository.dart';

class SqfliteCommunityRepository implements CommunityRepository {
  SqfliteCommunityRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<List<Community>> getAll({bool includeDeleted = false}) async {
    final db = await _database.database;
    final rows = await db.query(
      'comunidad',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'nombre COLLATE NOCASE ASC',
    );

    return rows.map(CommunityModel.fromMap).toList();
  }

  @override
  Future<void> add(Community community) async {
    final db = await _database.database;
    final now = DateTime.now();
    final model = CommunityModel(
      id: community.id,
      name: community.name,
      paymentDay: community.paymentDay,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('comunidad', model.toMap());
  }
}
