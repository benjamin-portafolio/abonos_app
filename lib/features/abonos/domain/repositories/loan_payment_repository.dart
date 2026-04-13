import 'package:abonos_app/features/abonos/domain/entities/loan_payment.dart';

abstract class LoanPaymentRepository {
  Future<List<LoanPayment>> getAll({bool includeDeleted = false});
  Future<List<LoanPayment>> getByLoanId(
    String loanId, {
    bool includeDeleted = false,
  });
  Future<void> add(LoanPayment loanPayment);
}
