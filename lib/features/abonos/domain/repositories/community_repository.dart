import 'package:abonos_app/features/abonos/domain/entities/community.dart';

abstract class CommunityRepository {
  Future<List<Community>> getAll({bool includeDeleted = false});
  Future<void> add(Community community);
}
