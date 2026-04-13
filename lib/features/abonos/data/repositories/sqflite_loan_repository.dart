import 'package:abonos_app/features/abonos/data/datasources/app_database.dart';
import 'package:abonos_app/features/abonos/data/models/loan_model.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_repository.dart';

class SqfliteLoanRepository implements LoanRepository {
  SqfliteLoanRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<List<Loan>> getAll({bool includeDeleted = false}) async {
    final db = await _database.database;
    final rows = await db.query(
      'prestamos',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'fecha DESC, created_at DESC',
    );

    return rows.map(LoanModel.fromMap).toList();
  }

  @override
  Future<Loan?> getById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'prestamos',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return LoanModel.fromMap(rows.first);
  }

  @override
  Future<List<Loan>> getByClientId(
    String clientId, {
    bool includeDeleted = false,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'prestamos',
      where:
          includeDeleted
              ? 'id_cliente = ?'
              : 'id_cliente = ? AND deleted_at IS NULL',
      whereArgs: [clientId],
      orderBy: 'fecha DESC, created_at DESC',
    );

    return rows.map(LoanModel.fromMap).toList();
  }

  @override
  Future<Loan?> getActiveByClientId(String clientId) async {
    final db = await _database.database;
    final rows = await db.query(
      'prestamos',
      where: 'id_cliente = ? AND activo = 1 AND deleted_at IS NULL',
      whereArgs: [clientId],
      orderBy: 'fecha DESC, created_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return LoanModel.fromMap(rows.first);
  }

  @override
  Future<void> add(Loan loan) async {
    final db = await _database.database;
    final now = DateTime.now();
    final model = LoanModel(
      id: loan.id,
      clientId: loan.clientId,
      date: loan.date,
      extraPercentage: loan.extraPercentage,
      loanAmount: loan.loanAmount,
      paidAmount: loan.paidAmount,
      isPaid: loan.isPaid,
      isActive: loan.isActive,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('prestamos', model.toMap());
  }

  @override
  Future<void> update(Loan loan) async {
    final db = await _database.database;
    final model = LoanModel(
      id: loan.id,
      clientId: loan.clientId,
      date: loan.date,
      extraPercentage: loan.extraPercentage,
      loanAmount: loan.loanAmount,
      paidAmount: loan.paidAmount,
      isPaid: loan.isPaid,
      isActive: loan.isActive,
      createdAt: loan.createdAt,
      updatedAt: loan.updatedAt,
      deletedAt: loan.deletedAt,
    );

    await db.update(
      'prestamos',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }
}
