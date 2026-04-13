import 'package:flutter/material.dart';

import 'package:abonos_app/features/abonos/data/repositories/sqflite_client_repository.dart';
import 'package:abonos_app/features/abonos/data/repositories/sqflite_community_repository.dart';
import 'package:abonos_app/features/abonos/domain/entities/client.dart';
import 'package:abonos_app/features/abonos/domain/entities/community.dart';
import 'package:abonos_app/features/abonos/domain/repositories/client_repository.dart';
import 'package:abonos_app/features/abonos/domain/repositories/community_repository.dart';
import 'package:abonos_app/features/abonos/presentation/pages/client_payments_page.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  static const _allCommunitiesFilter = '__all__';
  static const _withoutCommunityFilter = '__without_community__';
  static const _weekDays = <String>[
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];

  final ClientRepository _repository = SqfliteClientRepository();
  final CommunityRepository _communityRepository = SqfliteCommunityRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Client> _clients = [];
  List<Community> _communities = [];
  String _searchQuery = '';
  String _selectedCommunityFilter = _allCommunitiesFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> get _visibleClients {
    final query = _searchQuery.trim().toLowerCase();

    return _clients.where((client) {
      final matchesQuery =
          query.isEmpty ||
          client.id.toLowerCase().contains(query) ||
          client.name.toLowerCase().contains(query);

      if (!matchesQuery) {
        return false;
      }

      if (_selectedCommunityFilter == _allCommunitiesFilter) {
        return true;
      }

      if (_selectedCommunityFilter == _withoutCommunityFilter) {
        return client.communityId == null;
      }

      return client.communityId == _selectedCommunityFilter;
    }).toList();
  }

  Future<void> _loadPageData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _repository.getAll(),
        _communityRepository.getAll(),
      ]);

      if (!mounted) {
        return;
      }

      final clients = results[0] as List<Client>;
      final communities = results[1] as List<Community>;

      setState(() {
        _clients = clients;
        _communities = communities;
        _selectedCommunityFilter = _normalizedSelectedFilter(communities);
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      _logError('load_page_data', error, stackTrace);
      setState(() {
        _isLoading = false;
      });
      _showMessage('No se pudo cargar la información.');
    }
  }

  Future<void> _loadCommunities() async {
    final communities = await _communityRepository.getAll();
    if (!mounted) {
      return;
    }

    setState(() {
      _communities = communities;
      _selectedCommunityFilter = _normalizedSelectedFilter(communities);
    });
  }

  String _normalizedSelectedFilter(List<Community> communities) {
    if (_selectedCommunityFilter == _allCommunitiesFilter ||
        _selectedCommunityFilter == _withoutCommunityFilter) {
      return _selectedCommunityFilter;
    }

    final exists = communities.any(
      (community) => community.id == _selectedCommunityFilter,
    );

    return exists ? _selectedCommunityFilter : _allCommunitiesFilter;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logError(String scope, Object error, StackTrace stackTrace) {
    debugPrint('[$scope] $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  Future<String> _nextClientId() async {
    final allClients = await _repository.getAll(includeDeleted: true);
    var maxId = 0;

    for (final client in allClients) {
      final parsedId = int.tryParse(client.id);
      if (parsedId != null && parsedId > maxId) {
        maxId = parsedId;
      }
    }

    return (maxId + 1).toString();
  }

  Future<String> _nextCommunityId() async {
    final allCommunities = await _communityRepository.getAll(
      includeDeleted: true,
    );
    var maxId = 0;

    for (final community in allCommunities) {
      final parsedId = int.tryParse(community.id);
      if (parsedId != null && parsedId > maxId) {
        maxId = parsedId;
      }
    }

    return (maxId + 1).toString();
  }

  Future<void> _openCreateClientModal() async {
    String nextId;
    try {
      nextId = await _nextClientId();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _logError('prepare_create_client', error, stackTrace);
      _showMessage('No se pudo preparar el alta del cliente.');
      return;
    }

    if (!mounted) {
      return;
    }

    await _openClientModal(
      title: 'Nuevo cliente',
      actionLabel: 'Agregar',
      clientId: nextId,
    );
  }

  Future<void> _openClientModal({
    required String title,
    required String actionLabel,
    required String clientId,
    String initialName = '',
    String? initialCommunityId,
    String? editingClientId,
  }) async {
    final didSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _ClientFormDialog(
            title: title,
            actionLabel: actionLabel,
            clientId: clientId,
            initialName: initialName,
            initialCommunityId: initialCommunityId,
            communities: _communities,
            onSubmit: (name, selectedCommunityId) async {
              if (editingClientId == null) {
                await _repository.add(
                  Client(
                    id: clientId,
                    name: name,
                    communityId: selectedCommunityId,
                  ),
                );
                return;
              }

              final current = await _repository.getById(editingClientId);
              if (current == null) {
                throw const _ClientNotFoundException();
              }

              final updated = current.copyWith(
                name: name,
                communityId: selectedCommunityId,
                updatedAt: DateTime.now(),
              );
              await _repository.update(updated);
            },
            onError: (error, stackTrace) {
              if (error is _ClientNotFoundException) {
                if (mounted) {
                  _showMessage('El cliente ya no existe.');
                }
                return;
              }

              _logError('save_client', error, stackTrace);
              if (mounted) {
                _showMessage(
                  editingClientId == null
                      ? 'No se pudo guardar el cliente.'
                      : 'No se pudo actualizar el cliente.',
                );
              }
            },
          ),
    );

    if (didSave == true) {
      await _loadPageData();
    }
  }

  Future<void> _openCreateCommunityModal() async {
    String nextId;
    try {
      nextId = await _nextCommunityId();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _logError('prepare_create_community', error, stackTrace);
      _showMessage('No se pudo preparar el alta de la comunidad.');
      return;
    }

    if (!mounted) {
      return;
    }

    final didSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _CommunityFormDialog(
            communityId: nextId,
            weekDays: _weekDays,
            onSubmit: (name, paymentDay) async {
              await _communityRepository.add(
                Community(id: nextId, name: name, paymentDay: paymentDay),
              );
            },
            onError: (error, stackTrace) {
              _logError('save_community', error, stackTrace);
              if (mounted) {
                _showMessage('No se pudo guardar la comunidad.');
              }
            },
            weekdayLabelBuilder: _weekdayLabel,
          ),
    );

    if (didSave == true) {
      try {
        await _loadCommunities();
      } catch (error, stackTrace) {
        _logError('reload_communities', error, stackTrace);
        if (mounted) {
          _showMessage(
            'La comunidad se guardó, pero no se pudo refrescar la lista.',
          );
        }
      }
    }
  }

  Future<void> _openClientDetailPage(Client client) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ClientLoanPaymentsPage(client: client),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadPageData();
  }

  String _weekdayLabel(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final clients = _visibleClients;

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Agregar cliente',
        onPressed: _openCreateClientModal,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Todos'),
                            selected:
                                _selectedCommunityFilter ==
                                _allCommunitiesFilter,
                            onSelected: (_) {
                              setState(() {
                                _selectedCommunityFilter =
                                    _allCommunitiesFilter;
                              });
                            },
                          ),

                          for (final community in _communities) ...[
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(community.name),
                              selected:
                                  _selectedCommunityFilter == community.id,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCommunityFilter = community.id;
                                });
                              },
                            ),
                          ],
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Sin comunidad'),
                            selected:
                                _selectedCommunityFilter ==
                                _withoutCommunityFilter,
                            onSelected: (_) {
                              setState(() {
                                _selectedCommunityFilter =
                                    _withoutCommunityFilter;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('+'),
                    onPressed: _openCreateCommunityModal,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : clients.isEmpty
                        ? const Center(
                          child: Text('No hay clientes para mostrar.'),
                        )
                        : ListView.separated(
                          itemCount: clients.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            return Card(
                              child: ListTile(
                                title: Text(client.name),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openClientDetailPage(client),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientFormDialog extends StatefulWidget {
  const _ClientFormDialog({
    required this.title,
    required this.actionLabel,
    required this.clientId,
    required this.initialName,
    required this.initialCommunityId,
    required this.communities,
    required this.onSubmit,
    required this.onError,
  });

  final String title;
  final String actionLabel;
  final String clientId;
  final String initialName;
  final String? initialCommunityId;
  final List<Community> communities;
  final Future<void> Function(String name, String? communityId) onSubmit;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  State<_ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<_ClientFormDialog> {
  late final TextEditingController _nameController;
  late String? _selectedCommunityId;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedCommunityId = widget.initialCommunityId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa el nombre del cliente.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(name, _selectedCommunityId);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Id asignado: ${widget.clientId}'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _selectedCommunityId,
              decoration: const InputDecoration(
                labelText: 'Comunidad',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin comunidad'),
                ),
                ...widget.communities.map(
                  (community) => DropdownMenuItem<String?>(
                    value: community.id,
                    child: Text(community.name),
                  ),
                ),
              ],
              onChanged:
                  _isSaving
                      ? null
                      : (value) {
                        setState(() {
                          _selectedCommunityId = value;
                        });
                      },
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
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _CommunityFormDialog extends StatefulWidget {
  const _CommunityFormDialog({
    required this.communityId,
    required this.weekDays,
    required this.onSubmit,
    required this.onError,
    required this.weekdayLabelBuilder,
  });

  final String communityId;
  final List<String> weekDays;
  final Future<void> Function(String name, String paymentDay) onSubmit;
  final void Function(Object error, StackTrace stackTrace) onError;
  final String Function(String value) weekdayLabelBuilder;

  @override
  State<_CommunityFormDialog> createState() => _CommunityFormDialogState();
}

class _CommunityFormDialogState extends State<_CommunityFormDialog> {
  late final TextEditingController _nameController;
  late String _selectedPaymentDay;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedPaymentDay = widget.weekDays.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa el nombre de la comunidad.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(name, _selectedPaymentDay);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva comunidad'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Id asignado: ${widget.communityId}'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPaymentDay,
              decoration: const InputDecoration(
                labelText: 'Día de pago',
                border: OutlineInputBorder(),
              ),
              items:
                  widget.weekDays
                      .map(
                        (day) => DropdownMenuItem<String>(
                          value: day,
                          child: Text(widget.weekdayLabelBuilder(day)),
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
                          _selectedPaymentDay = value;
                        });
                      },
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

class _ClientNotFoundException implements Exception {
  const _ClientNotFoundException();
}
