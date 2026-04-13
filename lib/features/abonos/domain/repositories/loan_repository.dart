import 'package:abonos_app/features/abonos/domain/entities/loan.dart';

abstract class LoanRepository {
  Future<List<Loan>> getAll({bool includeDeleted = false});
  Future<Loan?> getById(String id);
  Future<List<Loan>> getByClientId(
    String clientId, {
    bool includeDeleted = false,
  });
  Future<Loan?> getActiveByClientId(String clientId);
  Future<void> add(Loan loan);
  Future<void> update(Loan loan);
}
