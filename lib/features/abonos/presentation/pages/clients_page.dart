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
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Client> _clients = [];
  String _searchQuery = '';
  String? _editingId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Client> get _visibleClients {
    if (_searchQuery.trim().isEmpty) {
      return _clients;
    }
    final query = _searchQuery.trim().toLowerCase();
    return _clients
        .where((client) =>
            client.id.toLowerCase().contains(query) ||
            client.name.toLowerCase().contains(query))
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

  void _setEditing(Client client) {
    setState(() {
      _editingId = client.id;
      _idController.text = client.id;
      _nameController.text = client.name;
    });
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _idController.clear();
      _nameController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveClient() async {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();

    if (id.isEmpty || name.isEmpty) {
      _showMessage('Completa el id y el nombre.');
      return;
    }

    if (_editingId == null) {
      final allClients = await _repository.getAll(includeDeleted: true);
      final exists = allClients.any((client) => client.id == id);
      if (exists) {
        _showMessage('El id ya existe.');
        return;
      }

      try {
        await _repository.add(Client(id: id, name: name));
        _resetForm();
        await _loadClients();
      } catch (_) {
        _showMessage('No se pudo guardar el cliente.');
      }
      return;
    }

    final current = await _repository.getById(_editingId!);
    if (current == null) {
      _showMessage('El cliente ya no existe.');
      _resetForm();
      await _loadClients();
      return;
    }

    final updated = current.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );
    try {
      await _repository.update(updated);
      _resetForm();
      await _loadClients();
    } catch (_) {
      _showMessage('No se pudo actualizar el cliente.');
    }
  }

  Future<void> _deleteClient(Client client) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      if (_editingId == client.id) {
        _resetForm();
      }
      await _loadClients();
    } catch (_) {
      _showMessage('No se pudo eliminar el cliente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = _visibleClients;
    final isEditing = _editingId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar por id o nombre',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Editar cliente' : 'Nuevo cliente',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _idController,
                              enabled: !isEditing,
                              decoration: const InputDecoration(
                                labelText: 'Id',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _saveClient(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: _saveClient,
                            child: Text(isEditing ? 'Guardar cambios' : 'Agregar'),
                          ),
                          OutlinedButton(
                            onPressed: _resetForm,
                            child: const Text('Limpiar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : clients.isEmpty
                        ? const Center(
                            child: Text('No hay clientes para mostrar.'),
                          )
                        : ListView.separated(
                            itemCount: clients.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
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
                                        onPressed: () => _setEditing(client),
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
