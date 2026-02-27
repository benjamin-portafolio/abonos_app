import 'package:flutter/material.dart';

import 'package:abonos_app/features/abonos/data/repositories/sqflite_client_repository.dart';
import 'package:abonos_app/features/abonos/domain/entities/client.dart';
import 'package:abonos_app/features/abonos/domain/repositories/client_repository.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final ClientRepository _repository = SqfliteClientRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Client> _clients = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> get _visibleClients {
    if (_searchQuery.trim().isEmpty) {
      return _clients;
    }
    final query = _searchQuery.trim().toLowerCase();
    return _clients
        .where(
          (client) =>
              client.id.toLowerCase().contains(query) ||
              client.name.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clients = await _repository.getAll();
      if (!mounted) {
        return;
      }

      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _showMessage('No se pudo cargar la lista de clientes.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _openCreateClientModal() async {
    String nextId;
    try {
      nextId = await _nextClientId();
    } catch (_) {
      _showMessage('No se pudo preparar el alta del cliente.');
      return;
    }

    await _openClientModal(
      title: 'Nuevo cliente',
      actionLabel: 'Agregar',
      clientId: nextId,
    );
  }

  Future<void> _openEditClientModal(Client client) async {
    await _openClientModal(
      title: 'Editar cliente',
      actionLabel: 'Guardar cambios',
      clientId: client.id,
      initialName: client.name,
      editingClientId: client.id,
    );
  }

  Future<void> _openClientModal({
    required String title,
    required String actionLabel,
    required String clientId,
    String initialName = '',
    String? editingClientId,
  }) async {
    final nameController = TextEditingController(text: initialName);
    var isSaving = false;

    final didSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                _showMessage('Completa el nombre del cliente.');
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                if (editingClientId == null) {
                  await _repository.add(Client(id: clientId, name: name));
                } else {
                  final current = await _repository.getById(editingClientId);
                  if (current == null) {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(false);
                    }
                    _showMessage('El cliente ya no existe.');
                    return;
                  }

                  final updated = current.copyWith(
                    name: name,
                    updatedAt: DateTime.now(),
                  );
                  await _repository.update(updated);
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } catch (_) {
                setDialogState(() {
                  isSaving = false;
                });
                _showMessage(
                  editingClientId == null
                      ? 'No se pudo guardar el cliente.'
                      : 'No se pudo actualizar el cliente.',
                );
              }
            }

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Id asignado: $clientId'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    enabled: !isSaving,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!isSaving) {
                        submit();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving
                          ? null
                          : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : submit,
                  child: Text(actionLabel),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (didSave == true) {
      await _loadClients();
    }
  }

  Future<void> _deleteClient(Client client) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar cliente'),
            content: Text('Eliminar a ${client.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _repository.delete(client.id);
      await _loadClients();
    } catch (_) {
      _showMessage('No se pudo eliminar el cliente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = _visibleClients;

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por id o nombres',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    tooltip: 'Agregar cliente',
                    onPressed: _openCreateClientModal,
                    icon: const Icon(Icons.add),
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
                                title: Text('${client.id} - ${client.name}'),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed:
                                          () => _openEditClientModal(client),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteClient(client),
                                    ),
                                  ],
                                ),
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
