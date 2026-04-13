import 'package:abonos_app/features/abonos/data/datasources/app_database.dart';
import 'package:abonos_app/features/abonos/data/models/loan_product_model.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan_product.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_product_repository.dart';

class SqfliteLoanProductRepository implements LoanProductRepository {
  SqfliteLoanProductRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<List<LoanProduct>> getAll({bool includeDeleted = false}) async {
    final db = await _database.database;
    final rows = await db.query(
      'prestamo_producto',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'created_at ASC',
    );

    return rows.map(LoanProductModel.fromMap).toList();
  }

  @override
  Future<List<LoanProduct>> getByLoanId(
    String loanId, {
    bool includeDeleted = false,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'prestamo_producto',
      where:
          includeDeleted
              ? 'id_prestamo = ?'
              : 'id_prestamo = ? AND deleted_at IS NULL',
      whereArgs: [loanId],
      orderBy: 'created_at ASC',
    );

    return rows.map(LoanProductModel.fromMap).toList();
  }

  @override
  Future<void> add(LoanProduct loanProduct) async {
    final db = await _database.database;
    final now = DateTime.now();
    final model = LoanProductModel(
      id: loanProduct.id,
      productId: loanProduct.productId,
      loanId: loanProduct.loanId,
      quantity: loanProduct.quantity,
      amount: loanProduct.amount,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('prestamo_producto', model.toMap());
  }
}
