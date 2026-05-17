// lib/features/billing/domain/exceptions/billing_exception.dart

class BillingRepositoryException implements Exception {
  final String code;
  final String message;

  const BillingRepositoryException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'BillingRepositoryException($code): $message';
}
