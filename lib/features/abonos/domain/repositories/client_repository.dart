import 'package:abonos_app/features/abonos/domain/entities/client.dart';

abstract class ClientRepository {
  Future<List<Client>> getAll({bool includeDeleted = false});
  Future<Client?> getById(String id);
  Future<void> add(Client client);
  Future<void> update(Client client);
  Future<void> delete(String id);
}
