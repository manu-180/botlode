// lib/features/billing/domain/repositories/payment_methods_repository.dart

import 'package:botslode/features/billing/domain/models/payment_method.dart';

abstract class PaymentMethodsRepository {
  /// Returns all payment methods for [tenantId] (not deleted).
  Future<List<PaymentMethod>> listForTenant(String tenantId);
}
