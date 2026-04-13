import 'package:flutter/material.dart';

import 'package:abonos_app/features/abonos/data/repositories/sqflite_client_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_loan_payment_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_loan_repository.dart';
import 'package:abonos_app/features/abonos/data/services/sqflite_loan_workflow_service.dart';
import 'package:abonos_app/features/abonos/domain/entities/client.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan_payment.dart';
import 'package:abonos_app/features/abonos/domain/repositories/client_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_payment_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_repository.dart';
import 'package:abonos_app/features/abonos/presentation/pages/loan_creation_page.dart';
import 'package:abonos_app/features/abonos/presentation/pages/loan_statement_page.dart';

class ClientLoanPaymentsPage extends StatefulWidget {
  const ClientLoanPaymentsPage({super.key, required this.client});

  final Client client;

  @override
  State<ClientLoanPaymentsPage> createState() => _ClientLoanPaymentsPageState();
}

class _ClientLoanPaymentsPageState extends State<ClientLoanPaymentsPage> {
  final ClientRepository _clientRepository = SqfliteClientRepository();
  final LoanRepository _loanRepository = SqfliteLoanRepository();
  final LoanPaymentRepository _loanPaymentRepository =
      SqfliteLoanPaymentRepository();
  final SqfliteLoanWorkflowService _loanWorkflowService =
      SqfliteLoanWorkflowService();

  Client? _client;
  List<Loan> _loans = [];
  Loan? _activeLoan;
  List<LoanPayment> _payments = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait<Object?>([
        _clientRepository.getById(widget.client.id),
        _loanRepository.getByClientId(widget.client.id),
        _loanRepository.getActiveByClientId(widget.client.id),
      ]);

      final client = results[0] as Client?;
      final loans = results[1] as List<Loan>;
      final activeLoan = results[2] as Loan?;
      final payments =
          activeLoan == null
              ? <LoanPayment>[]
              : await _loanPaymentRepository.getByLoanId(activeLoan.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _client = client ?? widget.client;
        _loans = loans;
        _activeLoan = activeLoan;
        _payments = payments;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      _logError('load_client_payments', error, stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<String> _nextPaymentId() async {
    final allPayments = await _loanPaymentRepository.getAll(
      includeDeleted: true,
    );
    var maxId = 0;

    for (final payment in allPayments) {
      final parsedId = int.tryParse(payment.id);
      if (parsedId != null && parsedId > maxId) {
        maxId = parsedId;
      }
    }

    return (maxId + 1).toString();
  }

  void _logError(String scope, Object error, StackTrace stackTrace) {
    debugPrint('[$scope] $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLoanCreationPage() async {
    final client = _client ?? widget.client;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => LoanCreationPage(client: client)),
    );

    if (!mounted) {
      return;
    }

    await _loadPageData();
  }

  Future<void> _openLoanStatementPage(Loan loan) async {
    final client = _client ?? widget.client;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LoanStatementPage(client: client, loanId: loan.id),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadPageData();
  }

  Future<void> _openRegisterPaymentDialog() async {
    final client = _client;
    final activeLoan = _activeLoan;
    if (client == null || activeLoan == null) {
      return;
    }

    String nextId;
    try {
      nextId = await _nextPaymentId();
    } catch (error, stackTrace) {
      _logError('prepare_payment', error, stackTrace);
      _showMessage('No se pudo preparar el registro del abono.');
      return;
    }

    if (!mounted) {
      return;
    }

    final didCloseLoan = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _PaymentAmountDialog(
            paymentId: nextId,
            pendingAmount: activeLoan.pendingAmount,
            onSubmit: (amount) async {
              final now = DateTime.now();
              return _loanWorkflowService.registerPayment(
                client: client,
                currentLoan: activeLoan,
                payment: LoanPayment(
                  id: nextId,
                  date: now,
                  loanId: activeLoan.id,
                  amount: amount,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
            },
            onError: (error, stackTrace) {
              _logError('register_payment', error, stackTrace);
              if (!mounted) {
                return;
              }
              _showMessage('No se pudo registrar el abono.');
            },
          ),
    );

    if (didCloseLoan == null) {
      return;
    }

    await _loadPageData();

    if (!mounted) {
      return;
    }

    _showMessage(
      didCloseLoan ? 'El préstamo quedó liquidado.' : 'Abono registrado.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = _client ?? widget.client;
    final activeLoan = _activeLoan;

    return Scaffold(
      appBar: AppBar(title: Text('Pagos de ${client.name}')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPageData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_hasError)
                _ErrorCard(onRetry: _loadPageData)
              else ...[
                if (activeLoan == null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Este cliente no tiene un préstamo activo.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _openLoanCreationPage,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar préstamos'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  _SectionHeader(
                    title: 'Préstamo activo',
                    action: FilledButton.icon(
                      onPressed: _openRegisterPaymentDialog,
                      icon: const Icon(Icons.attach_money),
                      label: const Text('Registrar abono'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActiveLoanCard(
                    loan: activeLoan,
                    onOpenDetail: () => _openLoanStatementPage(activeLoan),
                  ),
                  const SizedBox(height: 24),
                  Text('Abonos', style: Theme.of(context).textTheme.titleLarge),
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
                      (payment) => _PaymentCard(payment: payment),
                    ),
                ],
                if (_loans.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Historial de préstamos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ..._loans.map(
                    (loan) => _LoanHistoryCard(
                      loan: loan,
                      onOpenDetail: () => _openLoanStatementPage(loan),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveLoanCard extends StatelessWidget {
  const _ActiveLoanCard({required this.loan, required this.onOpenDetail});

  final Loan loan;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Chip(label: Text('Activo')),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DetailItem(label: 'Fecha', value: _formatDate(loan.date)),
                _DetailItem(
                  label: 'Porcentaje extra',
                  value: _formatPercentage(loan.extraPercentage),
                ),
                _DetailItem(
                  label: 'Cantidad prestada',
                  value: _formatMoney(loan.loanAmount),
                ),
                _DetailItem(
                  label: 'Cantidad pagada',
                  value: _formatMoney(loan.paidAmount),
                ),
                _DetailItem(
                  label: 'Pendiente',
                  value: _formatMoney(loan.pendingAmount),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

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

class _LoanHistoryCard extends StatelessWidget {
  const _LoanHistoryCard({required this.loan, required this.onOpenDetail});

  final Loan loan;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        loan.isActive
            ? 'Activo'
            : loan.isPaid
            ? 'Pagado'
            : 'Cerrado';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(label: Text(statusLabel)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DetailItem(label: 'Fecha', value: _formatDate(loan.date)),
                  _DetailItem(
                    label: 'Prestado',
                    value: _formatMoney(loan.loanAmount),
                  ),
                  _DetailItem(
                    label: 'Pagado',
                    value: _formatMoney(loan.paidAmount),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Abrir estado de cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        action,
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No se pudo cargar la información del cliente.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

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

class _PaymentAmountDialog extends StatefulWidget {
  const _PaymentAmountDialog({
    required this.paymentId,
    required this.pendingAmount,
    required this.onSubmit,
    required this.onError,
  });

  final String paymentId;
  final double pendingAmount;
  final Future<bool> Function(double amount) onSubmit;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  State<_PaymentAmountDialog> createState() => _PaymentAmountDialogState();
}

class _PaymentAmountDialogState extends State<_PaymentAmountDialog> {
  late final TextEditingController _amountController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      _showMessage('Captura una cantidad válida.');
      return;
    }

    if (amount > widget.pendingAmount) {
      _showMessage('El abono no puede ser mayor al saldo pendiente.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final didCloseLoan = await widget.onSubmit(amount);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(didCloseLoan);
    } catch (error, stackTrace) {
      widget.onError(error, stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  double? _parseAmount(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar abono'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Id asignado: ${widget.paymentId}'),
            const SizedBox(height: 12),
            Text('Saldo pendiente: ${_formatMoney(widget.pendingAmount)}'),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              enabled: !_isSaving,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
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

String _formatPercentage(double value) => '${value.toStringAsFixed(2)}%';

String _twoDigits(int value) => value.toString().padLeft(2, '0');
