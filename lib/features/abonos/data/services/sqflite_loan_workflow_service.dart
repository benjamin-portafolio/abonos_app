import 'package:abonos_app/features/abonos/data/datasources/app_database.dart';
import 'package:abonos_app/features/abonos/data/models/client_model.dart';
import 'package:abonos_app/features/abonos/data/models/loan_model.dart';
import 'package:abonos_app/features/abonos/data/models/loan_payment_model.dart';
import 'package:abonos_app/features/abonos/data/models/loan_product_model.dart';
import 'package:abonos_app/features/abonos/data/models/product_model.dart';
import 'package:abonos_app/features/abonos/domain/entities/client.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan_payment.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan_product.dart';
import 'package:abonos_app/features/abonos/domain/entities/product.dart';

class SqfliteLoanWorkflowService {
  SqfliteLoanWorkflowService({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> createLoan({
    required Client client,
    required Loan loan,
    required List<LoanProduct> loanProducts,
    required List<Product> updatedProducts,
  }) async {
    final db = await _database.database;

    await db.transaction((txn) async {
      final loanModel = LoanModel(
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

      await txn.insert('prestamos', loanModel.toMap());

      for (final loanProduct in loanProducts) {
        final loanProductModel = LoanProductModel(
          id: loanProduct.id,
          productId: loanProduct.productId,
          loanId: loanProduct.loanId,
          quantity: loanProduct.quantity,
          amount: loanProduct.amount,
          createdAt: loanProduct.createdAt,
          updatedAt: loanProduct.updatedAt,
          deletedAt: loanProduct.deletedAt,
        );

        await txn.insert('prestamo_producto', loanProductModel.toMap());
      }

      for (final product in updatedProducts) {
        final productModel = ProductModel(
          id: product.id,
          name: product.name,
          price: product.price,
          originalPrice: product.originalPrice,
          stock: product.stock,
          categoryId: product.categoryId,
          createdAt: product.createdAt,
          updatedAt: product.updatedAt,
          deletedAt: product.deletedAt,
        );

        await txn.update(
          'producto',
          productModel.toMap(),
          where: 'id = ?',
          whereArgs: [product.id],
        );
      }

      final updatedClient = client.copyWith(
        prestamoActivo: true,
        updatedAt: loan.updatedAt,
      );

      final clientModel = ClientModel(
        id: updatedClient.id,
        name: updatedClient.name,
        prestamoActivo: updatedClient.prestamoActivo,
        communityId: updatedClient.communityId,
        createdAt: updatedClient.createdAt,
        updatedAt: updatedClient.updatedAt,
        deletedAt: updatedClient.deletedAt,
      );

      await txn.update(
        'clientes',
        clientModel.toMap(),
        where: 'id = ?',
        whereArgs: [updatedClient.id],
      );
    });
  }

  Future<bool> registerPayment({
    required Client client,
    required Loan currentLoan,
    required LoanPayment payment,
  }) async {
    final db = await _database.database;
    final updatedPaidAmount = currentLoan.paidAmount + payment.amount;
    final isPaid = updatedPaidAmount >= currentLoan.loanAmount;
    final updatedLoan = currentLoan.copyWith(
      paidAmount: updatedPaidAmount,
      isPaid: isPaid,
      isActive: !isPaid,
      updatedAt: payment.updatedAt,
    );

    await db.transaction((txn) async {
      final paymentModel = LoanPaymentModel(
        id: payment.id,
        date: payment.date,
        loanId: payment.loanId,
        amount: payment.amount,
        createdAt: payment.createdAt,
        updatedAt: payment.updatedAt,
        deletedAt: payment.deletedAt,
      );

      await txn.insert('abono', paymentModel.toMap());

      final loanModel = LoanModel(
        id: updatedLoan.id,
        clientId: updatedLoan.clientId,
        date: updatedLoan.date,
        extraPercentage: updatedLoan.extraPercentage,
        loanAmount: updatedLoan.loanAmount,
        paidAmount: updatedLoan.paidAmount,
        isPaid: updatedLoan.isPaid,
        isActive: updatedLoan.isActive,
        createdAt: updatedLoan.createdAt,
        updatedAt: updatedLoan.updatedAt,
        deletedAt: updatedLoan.deletedAt,
      );

      await txn.update(
        'prestamos',
        loanModel.toMap(),
        where: 'id = ?',
        whereArgs: [updatedLoan.id],
      );

      final updatedClient = client.copyWith(
        prestamoActivo: !isPaid,
        updatedAt: payment.updatedAt,
      );

      final clientModel = ClientModel(
        id: updatedClient.id,
        name: updatedClient.name,
        prestamoActivo: updatedClient.prestamoActivo,
        communityId: updatedClient.communityId,
        createdAt: updatedClient.createdAt,
        updatedAt: updatedClient.updatedAt,
        deletedAt: updatedClient.deletedAt,
      );

      await txn.update(
        'clientes',
        clientModel.toMap(),
        where: 'id = ?',
        whereArgs: [updatedClient.id],
      );
    });

    return isPaid;
  }
}
