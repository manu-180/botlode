import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/repositories/payment_methods_repository.dart';

class FakePaymentMethodsRepository implements PaymentMethodsRepository {
  final List<PaymentMethod> _methods;

  FakePaymentMethodsRepository([List<PaymentMethod>? methods])
      : _methods = List.of(methods ?? []);

  void addMethod(PaymentMethod pm) => _methods.add(pm);

  @override
  Future<List<PaymentMethod>> listForTenant(String tenantId) async =>
      List.unmodifiable(_methods);

  @override
  Future<PaymentMethod?> getDefault(String tenantId) async =>
      _methods.where((pm) => pm.isDefault).firstOrNull;

  @override
  Stream<List<PaymentMethod>> watchForTenant(String tenantId) =>
      Stream.value(List.unmodifiable(_methods));
}
