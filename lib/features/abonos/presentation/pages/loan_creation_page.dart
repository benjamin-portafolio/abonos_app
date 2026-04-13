import 'package:flutter/material.dart';

import 'package:abonos_app/features/abonos/data/repositories/sqflite_category_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_loan_product_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_loan_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_product_repository.dart';
import 'package:abonos_app/features/abonos/data/services/sqflite_loan_workflow_service.dart';
import 'package:abonos_app/features/abonos/domain/entities/category.dart';
import 'package:abonos_app/features/abonos/domain/entities/client.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan.dart';
import 'package:abonos_app/features/abonos/domain/entities/loan_product.dart';
import 'package:abonos_app/features/abonos/domain/entities/product.dart';
import 'package:abonos_app/features/abonos/domain/repositories/category_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_product_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/loan_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/product_repository.dart';
import 'package:abonos_app/features/abonos/presentation/pages/loan_statement_page.dart';

class LoanCreationPage extends StatefulWidget {
  const LoanCreationPage({super.key, required this.client});

  final Client client;

  @override
  State<LoanCreationPage> createState() => _LoanCreationPageState();
}

class _LoanCreationPageState extends State<LoanCreationPage> {
  final CategoryRepository _categoryRepository = SqfliteCategoryRepository();
  final ProductRepository _productRepository = SqfliteProductRepository();
  final LoanRepository _loanRepository = SqfliteLoanRepository();
  final LoanProductRepository _loanProductRepository =
      SqfliteLoanProductRepository();
  final SqfliteLoanWorkflowService _loanWorkflowService =
      SqfliteLoanWorkflowService();

  List<Category> _categories = [];
  List<Product> _products = [];
  Map<String, _SelectedLoanProduct> _selectedProducts = {};
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<_LoanTabDefinition> get _tabs => [
    const _LoanTabDefinition(id: '__loan__', label: 'Préstamo'),
    const _LoanTabDefinition(id: '__all__', label: 'Todos'),
    ..._categories.map(
      (category) => _LoanTabDefinition(id: category.id, label: category.name),
    ),
  ];

  double get _productsSubtotal =>
      _selectedProducts.values.fold(0, (total, item) => total + item.amount);

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _categoryRepository.getAll(),
        _productRepository.getAll(),
      ]);

      final categories = results[0] as List<Category>;
      final products = results[1] as List<Product>;
      final reconciledSelection = _reconcileSelection(
        products: products,
        previousSelection: _selectedProducts,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _products = products;
        _selectedProducts = reconciledSelection;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      _logError('load_loan_creation_data', error, stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Map<String, _SelectedLoanProduct> _reconcileSelection({
    required List<Product> products,
    required Map<String, _SelectedLoanProduct> previousSelection,
  }) {
    final reconciled = <String, _SelectedLoanProduct>{};

    for (final product in products) {
      final previousItem = previousSelection[product.id];
      if (previousItem == null) {
        continue;
      }

      final maxQuantity = product.stock;
      if (maxQuantity <= 0) {
        continue;
      }

      final quantity =
          previousItem.quantity > maxQuantity
              ? maxQuantity
              : previousItem.quantity;

      if (quantity <= 0) {
        continue;
      }

      reconciled[product.id] = _SelectedLoanProduct(
        product: product,
        quantity: quantity,
      );
    }

    return reconciled;
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

  Future<String> _nextCategoryId() async {
    final allCategories = await _categoryRepository.getAll(
      includeDeleted: true,
    );
    var maxId = 0;

    for (final category in allCategories) {
      final parsedId = int.tryParse(category.id);
      if (parsedId != null && parsedId > maxId) {
        maxId = parsedId;
      }
    }

    return (maxId + 1).toString();
  }

  Future<String> _nextProductId() async {
    final allProducts = await _productRepository.getAll(includeDeleted: true);
    var maxId = 0;

    for (final product in allProducts) {
      final parsedId = int.tryParse(product.id);
      if (parsedId != null && parsedId > maxId) {
        maxId = parsedId;
      }
    }

    return (maxId + 1).toString();
  }

  Future<String> _nextLoanId() async {
    final allLoans = await _loanRepository.getAll(includeDeleted: true);
    var maxId = 0;

    for (final loan in allLoans) {
      final parsedId = int.tryParse(loan.id);
      if (parsedId != null && parsedId > maxId) {
        maxId = parsedId;
      }
    }

    return (maxId + 1).toString();
  }

  Future<int> _nextLoanProductSequence() async {
    final allLoanProducts = await _loanProductRepository.getAll(
      includeDeleted: true,
    );
    var maxId = 0;

    for (final loanProduct in allLoanProducts) {
      final parsedId = int.tryParse(loanProduct.id);
      if (parsedId != null && parsedId > maxId) {
        maxId = parsedId;
      }
    }

    return maxId + 1;
  }

  Future<void> _openCreateCategoryDialog() async {
    String nextId;

    try {
      nextId = await _nextCategoryId();
    } catch (error, stackTrace) {
      _logError('prepare_category_creation', error, stackTrace);
      _showMessage('No se pudo preparar el alta de la categoría.');
      return;
    }

    if (!mounted) {
      return;
    }

    final didSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _CategoryFormDialog(
            categoryId: nextId,
            onSubmit: (name) {
              return _categoryRepository.add(Category(id: nextId, name: name));
            },
            onError: (error, stackTrace) {
              _logError('save_category', error, stackTrace);
              if (!mounted) {
                return;
              }
              _showMessage('No se pudo guardar la categoría.');
            },
          ),
    );

    if (didSave == true) {
      await _loadData();
    }
  }

  Future<void> _openCreateProductDialog() async {
    if (_categories.isEmpty) {
      _showMessage('Primero agrega una categoría.');
      return;
    }

    String nextId;

    try {
      nextId = await _nextProductId();
    } catch (error, stackTrace) {
      _logError('prepare_product_creation', error, stackTrace);
      _showMessage('No se pudo preparar el alta del producto.');
      return;
    }

    if (!mounted) {
      return;
    }

    final didSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _ProductFormDialog(
            productId: nextId,
            categories: _categories,
            onSubmit: (name, price, originalPrice, stock, categoryId) {
              return _productRepository.add(
                Product(
                  id: nextId,
                  name: name,
                  price: price,
                  originalPrice: originalPrice,
                  stock: stock,
                  categoryId: categoryId,
                ),
              );
            },
            onError: (error, stackTrace) {
              _logError('save_product', error, stackTrace);
              if (!mounted) {
                return;
              }
              _showMessage('No se pudo guardar el producto.');
            },
          ),
    );

    if (didSave == true) {
      await _loadData();
    }
  }

  void _addProductToLoan(Product product) {
    final existing = _selectedProducts[product.id];
    final currentQuantity = existing?.quantity ?? 0;

    if (product.stock <= currentQuantity) {
      _showMessage('Ya no hay más existencia disponible para ${product.name}.');
      return;
    }

    setState(() {
      _selectedProducts = Map<String, _SelectedLoanProduct>.from(
          _selectedProducts,
        )
        ..[product.id] = _SelectedLoanProduct(
          product: product,
          quantity: currentQuantity + 1,
        );
    });
  }

  Future<void> _editSelectedQuantity(_SelectedLoanProduct item) async {
    final selectedQuantity = await showDialog<int>(
      context: context,
      builder:
          (_) => _QuantitySelectorDialog(
            productName: item.product.name,
            maxQuantity: item.product.stock,
            selectedQuantity: item.quantity,
          ),
    );

    if (selectedQuantity == null) {
      return;
    }

    setState(() {
      final updated = Map<String, _SelectedLoanProduct>.from(_selectedProducts);
      if (selectedQuantity == 0) {
        updated.remove(item.product.id);
      } else {
        updated[item.product.id] = item.copyWith(quantity: selectedQuantity);
      }
      _selectedProducts = updated;
    });
  }

  Future<void> _saveLoan() async {
    if (_selectedProducts.isEmpty) {
      _showMessage('Agrega al menos un producto al préstamo.');
      return;
    }

    String nextLoanId;
    int nextLoanProductSequence;

    try {
      nextLoanId = await _nextLoanId();
      nextLoanProductSequence = await _nextLoanProductSequence();
    } catch (error, stackTrace) {
      _logError('prepare_loan_save', error, stackTrace);
      _showMessage('No se pudo preparar el guardado del préstamo.');
      return;
    }

    if (!mounted) {
      return;
    }

    final extraPercentage = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ExtraPercentageDialog(),
    );

    if (extraPercentage == null) {
      return;
    }

    final now = DateTime.now();
    final subtotal = _productsSubtotal;
    final totalAmount = subtotal + (subtotal * (extraPercentage / 100));
    final selectedItems =
        _selectedProducts.values.toList()..sort(
          (left, right) => left.product.name.compareTo(right.product.name),
        );

    final loanProducts = <LoanProduct>[];
    final updatedProducts = <Product>[];

    for (final item in selectedItems) {
      loanProducts.add(
        LoanProduct(
          id: nextLoanProductSequence.toString(),
          productId: item.product.id,
          loanId: nextLoanId,
          quantity: item.quantity,
          amount: item.amount,
          createdAt: now,
          updatedAt: now,
        ),
      );
      nextLoanProductSequence += 1;

      updatedProducts.add(
        item.product.copyWith(
          stock: item.product.stock - item.quantity,
          updatedAt: now,
        ),
      );
    }

    final loan = Loan(
      id: nextLoanId,
      clientId: widget.client.id,
      date: now,
      extraPercentage: extraPercentage,
      loanAmount: totalAmount,
      paidAmount: 0,
      isPaid: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await _loanWorkflowService.createLoan(
        client: widget.client,
        loan: loan,
        loanProducts: loanProducts,
        updatedProducts: updatedProducts,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder:
              (_) => LoanStatementPage(client: widget.client, loanId: loan.id),
        ),
      );
    } catch (error, stackTrace) {
      _logError('save_loan', error, stackTrace);
      if (!mounted) {
        return;
      }
      _showMessage('No se pudo guardar el préstamo.');
      setState(() {
        _isSaving = false;
      });
    }
  }

  List<Product> _productsForCategory(String categoryId) {
    return _products
        .where((product) => product.categoryId == categoryId)
        .toList()
      ..sort((left, right) => left.name.compareTo(right.name));
  }

  Widget _buildTabSection(List<_LoanTabDefinition> tabs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos para ${widget.client.name}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        TabBar(
          isScrollable: true,
          tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            children: [
              _LoanSelectionTab(
                items:
                    _selectedProducts.values.toList()..sort(
                      (left, right) =>
                          left.product.name.compareTo(right.product.name),
                    ),
                onEditQuantity: _editSelectedQuantity,
              ),
              _ProductsCatalogTab(
                products: _products,
                selectedProducts: _selectedProducts,
                onAddProduct: _addProductToLoan,
              ),
              ..._categories.map(
                (category) => _ProductsCatalogTab(
                  products: _productsForCategory(category.id),
                  selectedProducts: _selectedProducts,
                  onAddProduct: _addProductToLoan,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;

    return Scaffold(
      appBar: AppBar(title: Text('Nuevo préstamo de ${widget.client.name}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _openCreateProductDialog,
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('Agregar producto'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar:
          _isLoading || _hasError
              ? null
              : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveLoan,
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Guardar préstamo'),
                ),
              ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                  ? _LoanCreationErrorCard(onRetry: _loadData)
                  : DefaultTabController(
                    length: tabs.length,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 900;
                        final tabSection = _buildTabSection(tabs);
                        final summarySection = _LoanSummaryPanel(
                          client: widget.client,
                          categories: _categories,
                          selectedProducts: _selectedProducts,
                          subtotal: _productsSubtotal,
                          onAddCategory: _openCreateCategoryDialog,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: tabSection),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: summarySection),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Expanded(flex: 3, child: tabSection),
                            const SizedBox(height: 16),
                            SizedBox(height: 280, child: summarySection),
                          ],
                        );
                      },
                    ),
                  ),
        ),
      ),
    );
  }
}

class _LoanSummaryPanel extends StatelessWidget {
  const _LoanSummaryPanel({
    required this.client,
    required this.categories,
    required this.selectedProducts,
    required this.subtotal,
    required this.onAddCategory,
  });

  final Client client;
  final List<Category> categories;
  final Map<String, _SelectedLoanProduct> selectedProducts;
  final double subtotal;
  final Future<void> Function() onAddCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedItems =
        selectedProducts.values.toList()..sort(
          (left, right) => left.product.name.compareTo(right.product.name),
        );
    final totalUnits = selectedItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

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
                    'Resumen del préstamo',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onAddCategory,
                  icon: const Icon(Icons.category_outlined),
                  label: const Text('Agregar categoría'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryChip(label: 'Cliente ${client.id}'),
            const SizedBox(height: 8),
            _SummaryChip(label: '${categories.length} categorías'),
            const SizedBox(height: 8),
            _SummaryChip(label: '$totalUnits unidades'),
            const SizedBox(height: 16),
            Text('Productos seleccionados', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child:
                  selectedItems.isEmpty
                      ? const Center(
                        child: Text('Agrega productos desde las pestañas.'),
                      )
                      : ListView.separated(
                        itemCount: selectedItems.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = selectedItems[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.product.name),
                            subtitle: Text(
                              '${item.quantity} x ${_formatMoney(item.product.price)}',
                            ),
                            trailing: Text(_formatMoney(item.amount)),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            Text('Subtotal', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(_formatMoney(subtotal), style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}

class _LoanSelectionTab extends StatelessWidget {
  const _LoanSelectionTab({required this.items, required this.onEditQuantity});

  final List<_SelectedLoanProduct> items;
  final Future<void> Function(_SelectedLoanProduct item) onEditQuantity;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Todavía no hay productos agregados al préstamo.'),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          color: Colors.green.withValues(alpha: 0.12),
          child: ListTile(
            title: Text(item.product.name),
            subtitle: Text(
              'Importe: ${_formatMoney(item.amount)} | Existencia: ${item.product.stock}',
            ),
            trailing: FilledButton.tonal(
              onPressed: () => onEditQuantity(item),
              child: Text('x${item.quantity}'),
            ),
          ),
        );
      },
    );
  }
}

class _ProductsCatalogTab extends StatelessWidget {
  const _ProductsCatalogTab({
    required this.products,
    required this.selectedProducts,
    required this.onAddProduct,
  });

  final List<Product> products;
  final Map<String, _SelectedLoanProduct> selectedProducts;
  final void Function(Product product) onAddProduct;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay productos disponibles en esta pestaña.'),
        ),
      );
    }

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        final selected = selectedProducts[product.id];
        final selectedQuantity = selected?.quantity ?? 0;
        final isSelected = selectedQuantity > 0;

        return Card(
          color: isSelected ? Colors.green.withValues(alpha: 0.18) : null,
          child: ListTile(
            enabled: product.stock > selectedQuantity,
            onTap: () => onAddProduct(product),
            title: Text(product.name),
            subtitle: Text(
              '${_formatMoney(product.price)} | Existencia: ${product.stock}',
            ),
            trailing:
                isSelected
                    ? Text(
                      'x$selectedQuantity',
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                    : const Icon(Icons.add_circle_outline),
          ),
        );
      },
    );
  }
}

class _LoanCreationErrorCard extends StatelessWidget {
  const _LoanCreationErrorCard({required this.onRetry});

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
            const Text('No se pudo cargar la información del préstamo.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({
    required this.categoryId,
    required this.onSubmit,
    required this.onError,
  });

  final String categoryId;
  final Future<void> Function(String name) onSubmit;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _nameController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Completa el nombre de la categoría.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(name);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva categoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Id asignado: ${widget.categoryId}'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({
    required this.productId,
    required this.categories,
    required this.onSubmit,
    required this.onError,
  });

  final String productId;
  final List<Category> categories;
  final Future<void> Function(
    String name,
    double price,
    double? originalPrice,
    int stock,
    String categoryId,
  )
  onSubmit;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _stockController;
  late String _selectedCategoryId;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _originalPriceController = TextEditingController();
    _stockController = TextEditingController(text: '0');
    _selectedCategoryId = widget.categories.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final price = _parseAmount(_priceController.text);
    final originalPrice = _parseOptionalAmount(_originalPriceController.text);
    final stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty) {
      _showMessage('Completa el nombre del producto.');
      return;
    }

    if (price == null || price <= 0) {
      _showMessage('Captura un precio válido.');
      return;
    }

    if (_originalPriceController.text.trim().isNotEmpty &&
        (originalPrice == null || originalPrice < 0)) {
      _showMessage('Captura un precio original válido.');
      return;
    }

    if (stock == null || stock < 0) {
      _showMessage('Captura una existencia válida.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(
        name,
        price,
        originalPrice,
        stock,
        _selectedCategoryId,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  double? _parseOptionalAmount(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return _parseAmount(value);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Id asignado: ${widget.productId}'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items:
                  widget.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
              onChanged:
                  _isSaving
                      ? null
                      : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _originalPriceController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio original (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stockController,
              enabled: !_isSaving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Existencia',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _ExtraPercentageDialog extends StatefulWidget {
  const _ExtraPercentageDialog();

  @override
  State<_ExtraPercentageDialog> createState() => _ExtraPercentageDialogState();
}

class _ExtraPercentageDialogState extends State<_ExtraPercentageDialog> {
  late final TextEditingController _percentageController;

  @override
  void initState() {
    super.initState();
    _percentageController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  void _submit() {
    final percentage = double.tryParse(
      _percentageController.text.trim().replaceAll(',', '.'),
    );

    if (percentage == null || percentage < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Captura un porcentaje válido.')),
      );
      return;
    }

    Navigator.of(context).pop(percentage);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar préstamo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Captura el porcentaje aumentado del préstamo.'),
          const SizedBox(height: 12),
          TextField(
            controller: _percentageController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Porcentaje extra',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}

class _QuantitySelectorDialog extends StatefulWidget {
  const _QuantitySelectorDialog({
    required this.productName,
    required this.maxQuantity,
    required this.selectedQuantity,
  });

  final String productName;
  final int maxQuantity;
  final int selectedQuantity;

  @override
  State<_QuantitySelectorDialog> createState() =>
      _QuantitySelectorDialogState();
}

class _QuantitySelectorDialogState extends State<_QuantitySelectorDialog> {
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final options = <DropdownMenuItem<int>>[
      for (var value = 1; value <= widget.maxQuantity; value += 1)
        DropdownMenuItem<int>(value: value, child: Text('$value')),
      const DropdownMenuItem<int>(value: 0, child: Text('Eliminar')),
    ];

    return AlertDialog(
      title: Text(widget.productName),
      content: DropdownButtonFormField<int>(
        value: _selectedValue,
        decoration: const InputDecoration(
          labelText: 'Cantidad',
          border: OutlineInputBorder(),
        ),
        items: options,
        onChanged: (value) {
          if (value == null) {
            return;
          }

          setState(() {
            _selectedValue = value;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedValue),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _LoanTabDefinition {
  const _LoanTabDefinition({required this.id, required this.label});

  final String id;
  final String label;
}

class _SelectedLoanProduct {
  const _SelectedLoanProduct({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get amount => product.price * quantity;

  _SelectedLoanProduct copyWith({Product? product, int? quantity}) {
    return _SelectedLoanProduct(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';
