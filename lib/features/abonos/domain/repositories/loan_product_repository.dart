import 'package:abonos_app/features/abonos/domain/entities/loan_product.dart';

abstract class LoanProductRepository {
  Future<List<LoanProduct>> getAll({bool includeDeleted = false});
  Future<List<LoanProduct>> getByLoanId(
    String loanId, {
    bool includeDeleted = false,
  });
  Future<void> add(LoanProduct loanProduct);
}
