import 'package:abonos_app/features/abonos/data/datasources/app_database.dart';
import 'package:abonos_app/features/abonos/data/models/loan_payment_model.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan_payment.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_payment_repository.dart';

class SqfliteLoanPaymentRepository implements LoanPaymentRepository {
  SqfliteLoanPaymentRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<List<LoanPayment>> getAll({bool includeDeleted = false}) async {
    final db = await _database.database;
    final rows = await db.query(
      'abono',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'fecha DESC, created_at DESC',
    );

    return rows.map(LoanPaymentModel.fromMap).toList();
  }

  @override
  Future<List<LoanPayment>> getByLoanId(
    String loanId, {
    bool includeDeleted = false,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'abono',
      where:
          includeDeleted
              ? 'id_prestamo = ?'
              : 'id_prestamo = ? AND deleted_at IS NULL',
      whereArgs: [loanId],
      orderBy: 'fecha DESC, created_at DESC',
    );

    return rows.map(LoanPaymentModel.fromMap).toList();
  }

  @override
  Future<void> add(LoanPayment loanPayment) async {
    final db = await _database.database;
    final now = DateTime.now();
    final model = LoanPaymentModel(
      id: loanPayment.id,
      date: loanPayment.date,
      loanId: loanPayment.loanId,
      amount: loanPayment.amount,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('abono', model.toMap());
  }
}
