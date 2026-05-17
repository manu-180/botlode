import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/repositories/plans_repository.dart';

class FakePlansRepository implements PlansRepository {
  final Map<String, Plan> _byCode = {};
  final Map<String, Plan> _byId = {};

  void addPlan(Plan plan) {
    _byCode[plan.code] = plan;
    _byId[plan.id] = plan;
  }

  @override
  Future<List<Plan>> listPublic() async =>
      _byCode.values.where((p) => p.public && p.archivedAt == null).toList();

  @override
  Future<Plan?> getByCode(String code) async => _byCode[code];

  @override
  Future<Plan?> getById(String id) async => _byId[id];

  @override
  void invalidateCache() {}
}
