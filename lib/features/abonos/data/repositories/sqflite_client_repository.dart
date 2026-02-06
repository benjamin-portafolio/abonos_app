import 'package:abonos_app/features/abonos/data/datasources/app_database.dart';
import 'package:abonos_app/features/abonos/data/models/client_model.dart';
import 'package:abonos_app/features/abonos/domain/entities/client.dart';
import 'package:abonos_app/features/abonos/domain/repositories/client_repository.dart';

class SqfliteClientRepository implements ClientRepository {
  SqfliteClientRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<List<Client>> getAll({bool includeDeleted = false}) async {
    final db = await _database.database;
    final rows = await db.query(
      'clients',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );

    return rows.map(ClientModel.fromMap).toList();
  }

  @override
  Future<Client?> getById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'clients',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ClientModel.fromMap(rows.first);
  }

  @override
  Future<void> add(Client client) async {
    final db = await _database.database;
    final now = DateTime.now();
    final model = ClientModel(
      id: client.id,
      name: client.name,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('clients', model.toMap());
  }

  @override
  Future<void> update(Client client) async {
    final db = await _database.database;
    final model = ClientModel(
      id: client.id,
      name: client.name,
      createdAt: client.createdAt,
      updatedAt: client.updatedAt,
      deletedAt: client.deletedAt,
    );

    await db.update(
      'clients',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'clients',
      {
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
