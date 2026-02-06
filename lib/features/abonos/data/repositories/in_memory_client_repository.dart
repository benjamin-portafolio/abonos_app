import 'package:abonos_app/features/abonos/domain/entities/client.dart';
import 'package:abonos_app/features/abonos/domain/repositories/client_repository.dart';

class InMemoryClientRepository implements ClientRepository {
  final List<Client> _clients = [];

  @override
  Future<List<Client>> getAll({bool includeDeleted = false}) async {
    if (includeDeleted) {
      return List<Client>.unmodifiable(_clients);
    }
    return _clients.where((client) => !client.isDeleted).toList();
  }

  @override
  Future<Client?> getById(String id) async {
    for (final client in _clients) {
      if (client.id == id) {
        return client;
      }
    }
    return null;
  }

  @override
  Future<void> add(Client client) async {
    _clients.add(client);
  }

  @override
  Future<void> update(Client client) async {
    final index = _clients.indexWhere((item) => item.id == client.id);
    if (index == -1) {
      return;
    }
    _clients[index] = client;
  }

  @override
  Future<void> delete(String id) async {
    final index = _clients.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    final current = _clients[index];
    _clients[index] = current.copyWith(
      updatedAt: DateTime.now(),
      deletedAt: DateTime.now(),
    );
  }
}
