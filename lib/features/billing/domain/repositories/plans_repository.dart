// lib/features/billing/domain/repositories/plans_repository.dart

import 'package:botslode/features/billing/domain/models/plan.dart';

abstract class PlansRepository {
  /// Returns all publicly available plans sorted by price ascending.
  Future<List<Plan>> listPublic();
}
