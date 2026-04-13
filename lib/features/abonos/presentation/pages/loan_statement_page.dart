import 'package:flutter/material.dart';

import 'package:abonos_app/features/abonos/data/repositories/sqflite_category_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_loan_payment_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_loan_product_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_loan_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_product_repository.dart';
import 'package:abonos_app/features/abonos/domain/entities/category.dart';
import 'package:abonos_app/features/abonos/domain/entities/client.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan_payment.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan_product.dart';
import 'package:abonos_app/features/abonos/domain/entities/product.dart';
import 'package:abonos_app/features/abonos/domain/repositories/category_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_payment_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_product_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/product_repository.dart';

class LoanStatementPage extends StatefulWidget {
  const LoanStatementPage({
    super.key,
    required this.client,
    required this.loanId,
  });

  final Client client;
  final String loanId;

  @override
  State<LoanStatementPage> createState() => _LoanStatementPageState();
}

class _LoanStatementPageState extends State<LoanStatementPage> {
  final LoanRepository _loanRepository = SqfliteLoanRepository();
  final LoanProductRepository _loanProductRepository =
      SqfliteLoanProductRepository();
  final ProductRepository _productRepository = SqfliteProductRepository();
  final LoanPaymentRepository _loanPaymentRepository =
      SqfliteLoanPaymentRepository();
  final CategoryRepository _categoryRepository = SqfliteCategoryRepository();

  Loan? _loan;
  List<LoanProduct> _loanProducts = [];
  List<Product> _products = [];
  List<LoanPayment> _payments = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final loan = await _loanRepository.getById(widget.loanId);
      if (loan == null) {
        throw const _LoanNotFoundException();
      }

      final results = await Future.wait([
        _loanProductRepository.getByLoanId(widget.loanId),
        _productRepository.getAll(),
        _loanPaymentRepository.getByLoanId(widget.loanId),
        _categoryRepository.getAll(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _loan = loan;
        _loanProducts = results[0] as List<LoanProduct>;
        _products = results[1] as List<Product>;
        _payments = results[2] as List<LoanPayment>;
        _categories = results[3] as List<Category>;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[load_loan_statement] $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = _loan;

    return Scaffold(
      appBar: AppBar(title: const Text('Estado de cuenta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError || loan == null
                  ? _StatementErrorCard(onRetry: _loadStatement)
                  : RefreshIndicator(
                    onRefresh: _loadStatement,
                    child: ListView(
                      children: [
                        _StatementHeaderCard(client: widget.client, loan: loan),
                        const SizedBox(height: 16),
                        _LoanTotalsCard(
                          loan: loan,
                          subtotal: _subtotal,
                          extraAmount: _extraAmount,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Productos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (_lineItems.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Este préstamo no tiene productos.'),
                            ),
                          )
                        else
                          ..._lineItems.map(
                            (line) => _StatementLineCard(line: line),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Abonos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (_payments.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Todavía no hay abonos registrados.'),
                            ),
                          )
                        else
                          ..._payments.map(
                            (payment) =>
                                _StatementPaymentCard(payment: payment),
                          ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  List<_StatementLineItem> get _lineItems {
    final productsById = {for (final product in _products) product.id: product};
    final categoriesById = {
      for (final category in _categories) category.id: category,
    };

    return _loanProducts.map((loanProduct) {
      final product = productsById[loanProduct.productId];
      final category =
          product?.categoryId == null
              ? null
              : categoriesById[product!.categoryId];

      return _StatementLineItem(
        loanProduct: loanProduct,
        product: product,
        category: category,
      );
    }).toList();
  }

  double get _subtotal =>
      _loanProducts.fold(0, (total, item) => total + item.amount);

  double get _extraAmount {
    final loan = _loan;
    if (loan == null) {
      return 0;
    }

    final extra = loan.loanAmount - _subtotal;
    return extra < 0 ? 0 : extra;
  }
}

class _StatementHeaderCard extends StatelessWidget {
  const _StatementHeaderCard({required this.client, required this.loan});

  final Client client;
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        loan.isActive
            ? 'Activo'
            : loan.isPaid
            ? 'Pagado'
            : 'Cerrado';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Préstamo ${loan.id}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Chip(label: Text(statusLabel)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatementDetailItem(label: 'Cliente', value: client.name),
                _StatementDetailItem(label: 'Id cliente', value: client.id),
                _StatementDetailItem(
                  label: 'Fecha',
                  value: _formatDate(loan.date),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanTotalsCard extends StatelessWidget {
  const _LoanTotalsCard({
    required this.loan,
    required this.subtotal,
    required this.extraAmount,
  });

  final Loan loan;
  final double subtotal;
  final double extraAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatementDetailItem(
                  label: 'Subtotal productos',
                  value: _formatMoney(subtotal),
                ),
                _StatementDetailItem(
                  label: 'Porcentaje extra',
                  value: '${loan.extraPercentage.toStringAsFixed(2)}%',
                ),
                _StatementDetailItem(
                  label: 'Monto extra',
                  value: _formatMoney(extraAmount),
                ),
                _StatementDetailItem(
                  label: 'Total préstamo',
                  value: _formatMoney(loan.loanAmount),
                ),
                _StatementDetailItem(
                  label: 'Cantidad pagada',
                  value: _formatMoney(loan.paidAmount),
                ),
                _StatementDetailItem(
                  label: 'Pendiente',
                  value: _formatMoney(loan.pendingAmount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementLineCard extends StatelessWidget {
  const _StatementLineCard({required this.line});

  final _StatementLineItem line;

  @override
  Widget build(BuildContext context) {
    final categoryName = line.category?.name ?? 'Sin categoría';
    final productName = line.product?.name ?? 'Producto eliminado';
    final unitPrice =
        line.loanProduct.quantity == 0
            ? 0.0
            : line.loanProduct.amount / line.loanProduct.quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          title: Text(productName),
          subtitle: Text(
            '$categoryName | ${line.loanProduct.quantity} x ${_formatMoney(unitPrice)}',
          ),
          trailing: Text(_formatMoney(line.loanProduct.amount)),
        ),
      ),
    );
  }
}

class _StatementPaymentCard extends StatelessWidget {
  const _StatementPaymentCard({required this.payment});

  final LoanPayment payment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
          title: Text(_formatMoney(payment.amount)),
          subtitle: Text(_formatDateTime(payment.date)),
        ),
      ),
    );
  }
}

class _StatementDetailItem extends StatelessWidget {
  const _StatementDetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _StatementErrorCard extends StatelessWidget {
  const _StatementErrorCard({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No se pudo cargar el estado de cuenta.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _StatementLineItem {
  const _StatementLineItem({
    required this.loanProduct,
    required this.product,
    required this.category,
  });

  final LoanProduct loanProduct;
  final Product? product;
  final Category? category;
}

class _LoanNotFoundException implements Exception {
  const _LoanNotFoundException();
}

String _formatDate(DateTime value) {
  return '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';
}

String _formatDateTime(DateTime value) {
  final date = _formatDate(value);
  final time =
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}:${_twoDigits(value.second)}';
  return '$date $time';
}

String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

String _twoDigits(int value) => value.toString().padLeft(2, '0');
